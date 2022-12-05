# TODO: Implement client Tstamp filter

defmodule Pbft do
  @moduledoc """
  An implementation of the Pbft consensus protocol.
  """
  import Emulation,
    only: [send: 2, timer: 1, cancel_timer: 1, now: 0, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  require Fuzzers
  # This allows you to use Elixir's loggers
  # for messages. See
  # https://timber.io/blog/the-ultimate-guide-to-logging-in-elixir/
  # if you are interested in this. Note we currently purge all logs
  # below Info
  require Logger

  # This structure contains all the process state
  # required by the Pbft protocol.
  defstruct(
    # The list of current proceses.
    cluster: nil,
    current_view: nil,
    log: nil,
    commit_index: nil,
    next_index: nil,
    max_index: nil,
    is_primary: nil,
    max_failures: nil,
    election_timer: nil,
    election_timeout: nil,
    is_changing: nil,

    # Service State
    queue: nil,

    # Cryptography
    private_key: nil,
    cluster_pub_keys: nil,
    client_pub_keys: nil
  )

  @doc """
  Create state for an initial Pbft cluster. Each
  process should get an appropriately updated version
  of this state.
  """
  @spec new_configuration(
          tuple(),
          map(),
          map(),
          binary(),
          non_neg_integer()
        ) :: %Pbft{}
  def new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        private_key,
        election_timeout
      ) do
    %Pbft{
      cluster: cluster,
      cluster_pub_keys: cluster_pub_keys,
      client_pub_keys: client_pub_keys,
      private_key: private_key,
      current_view: 0,
      log: %{},
      commit_index: -1,
      next_index: nil,
      queue: :queue.new(),
      is_primary: false,
      max_failures: div(tuple_size(cluster), 3),
      election_timeout: election_timeout,
      max_index: -1,
      is_changing: false
    }
  end

  # Gets current primary process
  @spec get_primary(%Pbft{}, non_neg_integer()) :: atom()
  defp get_primary(state, view \\ nil) do
    if view == nil do
      index = rem(state.current_view, tuple_size(state.cluster))
      elem(state.cluster, index)
    else
      index = rem(view, tuple_size(state.cluster))
      elem(state.cluster, index)
    end
  end

  # Enqueue an item, this **modifies** the state
  # machine, and should only be called when a log
  # entry is committed.
  @spec enqueue(%Pbft{}, any()) :: %Pbft{}
  defp enqueue(state, item) do
    %{state | queue: :queue.in(item, state.queue)}
  end

  # Dequeue an item, modifying the state machine.
  # This function should only be called once a
  # log entry has been committed.
  @spec dequeue(%Pbft{}) :: {:empty | {:value, any()}, %Pbft{}}
  defp dequeue(state) do
    {ret, queue} = :queue.out(state.queue)
    {ret, %{state | queue: queue}}
  end

  @doc """
  Commit a log entry, advancing the state machine. This
  function returns a tuple:
  * The first element is {requester, return value}. Your
    implementation should ensure that the replica who committed
    the log entry sends the return value to the requester.
  * The second element is the updated state.
  """
  @spec commit_log_entry(%Pbft{}, %Pbft.LogEntry{}) ::
          {{atom() | pid(), :ok | :empty | {:value, any()}, non_neg_integer()}, %Pbft{}}
  def commit_log_entry(state, entry) do
    case entry do
      %Pbft.LogEntry{operation: :nop, requester: r, sequence_number: i} ->
        {{r, :ok, entry.request_timestamp}, %{state | commit_index: i}}

      %Pbft.LogEntry{operation: :enq, requester: r, argument: e, sequence_number: i} ->
        {{r, :ok, entry.request_timestamp}, %{enqueue(state, e) | commit_index: i}}

      %Pbft.LogEntry{operation: :deq, requester: r, sequence_number: i} ->
        {ret, state} = dequeue(state)
        {{r, ret, entry.request_timestamp}, %{state | commit_index: i}}

      %Pbft.LogEntry{} ->
        raise "Log entry with an unknown operation: maybe an empty entry?"

      _ ->
        raise "Attempted to commit something that is not a log entry."
    end
  end

  @doc """
  Commit log at sequence_number.
  """
  @spec commit_log_index(%Pbft{}, non_neg_integer()) ::
          {:noentry | {atom(), :ok | :empty | {:value, any()}}, %Pbft{}}
  def commit_log_index(state, sequence_number) do
    if Map.has_key?(state.log, sequence_number) do
      commit_log_entry(state, state.log[sequence_number])
    else
      {:noentry, state}
    end
  end

  @doc """
  Commits all committed log entries until first entry that is uncommitted.
  """
  @spec commit_log(%Pbft{}) :: {%Pbft{}}
  def commit_log(state) do
    if Map.has_key?(state.log, state.commit_index + 1) and
         state.log[state.commit_index + 1].is_committed do
      {{client, result, request_timestamp}, state} = commit_log_index(state, state.commit_index + 1)

      # send(client, result) TODO ClientResponse
      response = Pbft.ClientMessageResponse.new(state.current_view, client, whoami, result, request_timestamp)

      send(client, {response, sign_message(response, state.private_key)})

      IO.puts("#{whoami} committed log entry #{state.commit_index} with response #{inspect({client, result})}")

      commit_log(state)
    else
      # IO.puts("#{whoami} state: #{inspect(state)}\n")
      state
    end
  end

  @doc """
  Add log entries to the log. This adds entries to the beginning
  of the log, we assume that entries are already correctly ordered
  (see structural note about log above.).
  """
  @spec add_log_entry(%Pbft{}, non_neg_integer(), %Pbft.LogEntry{}) :: %Pbft{}
  def add_log_entry(state, sequence_number, entry) do
    state = %{state | max_index: max(sequence_number, state.max_index)}
    %{state | log: Map.put(state.log, sequence_number, entry)}
  end

  @doc """
  Creates updated log for view change
  """
  @spec generate_new_log(%Pbft{}, map(), non_neg_integer()) :: map()
  defp generate_new_log(state, curr_map, curr_index) do
    if Map.has_key?(state.log, curr_index) do
      curr_log = state.log[curr_index]
      curr_log = %{curr_log | view: state.current_view}
      curr_map = Map.put(curr_map, curr_index, curr_log)
      generate_new_log(state, curr_map, curr_index + 1)
    else
      curr_map
    end
  end

  @doc """
  Verifies a message digest for a given message and public key
  """
  @spec verify_digest(binary(), any(), binary()) :: {true | false}
  def verify_digest(digest, message, pub_key) do
    :crypto.verify(:eddsa, :none, inspect(message), digest, [pub_key, :ed25519])
  end

  @doc """
  Signs a message for a given message and private key
  """
  @spec sign_message(any(), binary()) :: binary()
  def sign_message(message, private_key) do
    :crypto.sign(:eddsa, :none, inspect(message), [private_key, :ed25519])
  end

  # Save a handle to the election timer.
  @spec save_election_timer(%Pbft{}, reference()) :: %Pbft{}
  defp save_election_timer(state, timer) do
    %{state | election_timer: timer}
  end

  # Cancel the election timer.
  @spec cancel_election_timer(%Pbft{}) :: %Pbft{}
  defp cancel_election_timer(state) do
    if not Kernel.is_nil(state.election_timer) do
      Emulation.cancel_timer(state.election_timer)
    end

    save_election_timer(state, nil)
  end

  # Start Election timer if not started previously
  @spec start_election_timer(%Pbft{}) :: %Pbft{}
  defp start_election_timer(state) do
    if Kernel.is_nil(state.election_timer) do
      save_election_timer(state, Emulation.timer(state.election_timeout))
    else
      state
    end
  end

  # Reset Election Timer
  @spec reset_election_timer(%Pbft{}) :: %Pbft{}
  defp reset_election_timer(state) do
    # You might find `save_election_timer` of use.
    state = cancel_election_timer(state)
    start_election_timer(state)
  end

  # Utility function to send a message to all
  # processes other than the caller. Should only be used by leader.
  @spec broadcast_to_all(%Pbft{is_primary: true}, any()) :: [boolean()]
  def broadcast_to_all(state, message) do
    me = whoami()

    Tuple.to_list(state.cluster)
    |> Enum.map(fn pid -> send(pid, message) end)
  end

  @doc """
  make_primary changes process state for a process that
  has just been elected primary.
  """
  @spec make_primary(%Pbft{}) :: %Pbft{is_primary: true}
  def make_primary(state) do
    %{
      state
      | is_primary: true,
        next_index: state.commit_index + 1
    }
  end

  # Verift list of View Change Messages
  @spec verify_view_change(%Pbft{}, list(), non_neg_integer()) :: boolean()
  defp verify_view_change(state, view_change_list, count) do
    cond do
      view_change_list == [] and count < 2 * state.max_failures ->
        false

      view_change_list == [] and count >= 2 * state.max_failures ->
        true

      view_change_list != [] ->
        [head | view_change_list] = view_change_list
        mssg = elem(head, 0)
        digest = elem(head, 1)
        replica_id = mssg.replica_id

        if verify_digest(digest, mssg, state.cluster_pub_keys[replica_id]) do
          verify_view_change(state, view_change_list, count + 1)
        else
          false
        end
    end
  end

  @doc """
  make_replica changes process state for a process
  to mark it as a replica.
  """
  @spec make_replica(%Pbft{}) :: %Pbft{
          is_primary: false
        }
  def make_replica(state) do
    %{state | is_primary: false}
  end

  @doc """
  This function transitions a process that is not currently
  the primary so it is a primary.
  """
  @spec become_primary(%Pbft{is_primary: false}) :: no_return()
  def become_primary(state) do
    # Send initial AppendEntry heartbeat

    replica(make_primary(state), %{})
  end

  @doc """
  This function transitions a process so it is
  a replica.
  """
  @spec become_replica(%Pbft{}) :: no_return()
  def become_replica(state) do
    # state = start_election_timer(state)
    replica(make_replica(state), %{})
  end

  @doc """
  This function implements the state machine for a process
  that is currently a replica.
  """
  @spec replica(%Pbft{}, any()) :: no_return()
  def replica(state, extra_state) do
    receive do
      :timer ->
        IO.puts("Replica #{whoami} timer expired.\n")
        trigger_view_change(state, extra_state)

      {sender,
       {%Pbft.ClientMessageRequest{
          client_id: client_id,
          operation: operation,
          request_timestamp: request_timestamp
        }, request_digest}} ->
        IO.puts("Replica #{whoami} received command from #{sender}\n")

        request_mssg = %Pbft.ClientMessageRequest{
          client_id: client_id,
          operation: operation,
          request_timestamp: request_timestamp
        }

        if state.is_primary do
          if verify_digest(request_digest, request_mssg, state.client_pub_keys[client_id]) do
            if not (Map.has_key?(extra_state, client_id) and MapSet.member?(extra_state[client_id], request_timestamp)) do
              # Broadcast PrePrepare Message
              append_message =
                Pbft.AppendRequest.new_prepepare(
                  state.current_view,
                  state.next_index,
                  request_digest
                )

              request_message = %Pbft.ClientMessageRequest{
                client_id: client_id,
                operation: operation,
                request_timestamp: request_timestamp
              }

              client_set = Map.get(extra_state, client_id, MapSet.new())
              extra_state = Map.put(extra_state, client_id, MapSet.put(client_set, request_timestamp))

              broadcast_to_all(
                state,
                {append_message, sign_message(append_message, state.private_key), request_message}
              )

              state = %{state | next_index: state.next_index + 1}
              replica(state, extra_state)
            else
              replica(state, extra_state)
            end
          else
            IO.puts("Not Verified")
            replica(state, extra_state)
          end
        else
          # Forward client message to primary
          state = start_election_timer(state)

          send(
            get_primary(state),
            {%Pbft.ClientMessageRequest{
               client_id: client_id,
               operation: operation,
               request_timestamp: request_timestamp
             }, request_digest}
          )

          replica(state, extra_state)
        end

      {sender,
       {%Pbft.AppendRequest{
          type: "pre",
          current_view: append_view,
          sequence_number: sequence_number,
          message_digest: request_digest
        }, append_digest,
        %Pbft.ClientMessageRequest{
          client_id: client_id,
          operation: operation,
          request_timestamp: request_timestamp
        }}} ->
        IO.puts("Replica #{whoami} received PrePrepare from #{sender}\n")

        append_mssg = %Pbft.AppendRequest{
          type: "pre",
          current_view: append_view,
          sequence_number: sequence_number,
          message_digest: request_digest
        }

        request_mssg = %Pbft.ClientMessageRequest{
          client_id: client_id,
          operation: operation,
          request_timestamp: request_timestamp
        }

        if sender == get_primary(state) and
             verify_digest(append_digest, append_mssg, state.cluster_pub_keys[sender]) and
             verify_digest(request_digest, request_mssg, state.client_pub_keys[client_id]) and
             append_view == state.current_view do
          if Map.has_key?(state.log, sequence_number) and state.log[sequence_number].view == append_view do
            IO.puts("Received PrePrepare present in #{whoami}\n")
            replica(state, extra_state)
          else
            {op, arg} = operation
            log_entry = Pbft.LogEntry.new(sequence_number, state.current_view, client_id, request_timestamp, op, arg, request_digest)
            state = add_log_entry(state, sequence_number, log_entry)
            client_set = Map.get(extra_state, client_id, MapSet.new())
            extra_state = Map.put(extra_state, client_id, MapSet.put(client_set, request_timestamp))
            state = start_election_timer(state)

            prepare_message = Pbft.AppendRequest.new_pepare(state.current_view, sequence_number, request_digest, whoami)
            broadcast_to_all(state, {prepare_message, sign_message(prepare_message, state.private_key)})

            replica(state, extra_state)
          end
        else
          IO.puts("Replica #{whoami} Not Verified PrePrepare from #{sender}\n")
          replica(state, extra_state)
        end

      {sender,
       {%Pbft.AppendRequest{
          type: "prepare",
          current_view: current_view,
          sequence_number: sequence_number,
          message_digest: request_digest,
          replica_id: replica_id
        }, append_digest}} ->
        append_mssg = %Pbft.AppendRequest{
          type: "prepare",
          current_view: current_view,
          sequence_number: sequence_number,
          message_digest: request_digest,
          replica_id: replica_id
        }

        if verify_digest(append_digest, append_mssg, state.cluster_pub_keys[sender]) and
             Map.has_key?(state.log, sequence_number) and
             state.log[sequence_number].view == current_view and
             state.log[sequence_number].request_digest == request_digest do
          IO.puts("Replica #{whoami}  Verified Prepare from #{sender} \n")

          # Add prepared count
          new_log_entry = %{state.log[sequence_number] | prepared_count: state.log[sequence_number].prepared_count + 1}
          state = %{state | log: %{state.log | sequence_number => new_log_entry}}

          if state.log[sequence_number].prepared_count == 2 * state.max_failures + 1 do
            IO.puts("Replica #{whoami} log: #{inspect(state.log)} \n")

            # Broadcast commit messages
            commit_message = Pbft.AppendRequest.new_commit(state.current_view, sequence_number, request_digest, whoami)
            broadcast_to_all(state, {commit_message, sign_message(commit_message, state.private_key)})
            replica(state, extra_state)
          end

          replica(state, extra_state)
        else
          IO.puts("Replica #{whoami}  Failed Prepare from #{sender}\n")
          replica(state, extra_state)
        end

      {sender,
       {%Pbft.AppendRequest{
          type: "commit",
          current_view: current_view,
          sequence_number: sequence_number,
          message_digest: request_digest,
          replica_id: replica_id
        }, append_digest}} ->
        append_mssg = %Pbft.AppendRequest{
          type: "commit",
          current_view: current_view,
          sequence_number: sequence_number,
          message_digest: request_digest,
          replica_id: replica_id
        }

        if verify_digest(append_digest, append_mssg, state.cluster_pub_keys[sender]) and
             Map.has_key?(state.log, sequence_number) and
             state.log[sequence_number].view == current_view and
             state.log[sequence_number].request_digest == request_digest do
          IO.puts("Replica #{whoami}  Verified Commit from #{sender} \n")

          # Add committed count
          new_log_entry = %{state.log[sequence_number] | commited_count: state.log[sequence_number].commited_count + 1}
          state = %{state | log: %{state.log | sequence_number => new_log_entry}}

          if state.log[sequence_number].commited_count == 2 * state.max_failures + 1 do
            # Set committed
            new_log_entry = %{state.log[sequence_number] | is_committed: true}
            state = %{state | log: %{state.log | sequence_number => new_log_entry}}
            IO.puts("Replica #{whoami} log: #{inspect(state.log)} \n")

            # Call commit_log function
            state = commit_log(state)

            if state.commit_index == state.max_index do
              state = cancel_election_timer(state)
              replica(state, extra_state)
            else
              state = reset_election_timer(state)
              replica(state, extra_state)
            end
          else
            replica(state, extra_state)
          end
        else
          IO.puts("Replica #{whoami}  Failed Commit from #{sender}\n")
          replica(state, extra_state)
        end

      {sender,
       {%Pbft.ViewChange{
          type: "change",
          new_view: new_view,
          replica_id: replica_id
        }, change_digest}} ->
        change_mssg = %Pbft.ViewChange{
          type: "change",
          new_view: new_view,
          replica_id: replica_id
        }

        if get_primary(state, new_view) == whoami and
             new_view > state.current_view and
             verify_digest(change_digest, change_mssg, state.cluster_pub_keys[sender]) do
          extra_state = Map.put(extra_state, :change_count, Map.get(extra_state, :change_count, 0) + 1)
          extra_state = Map.put(extra_state, :view_change_list, Map.get(extra_state, :view_change_list, []) ++ [{change_mssg, change_digest}])

          IO.puts("Replica #{whoami}  received view_change from #{sender}\n")

          if extra_state.change_count == state.max_failures * 2 do
            state = %{state | current_view: state.current_view + 1}

            new_log = generate_new_log(state, %{}, 0)
            state = %{state | log: new_log}

            view_change = extra_state.view_change_list

            new_view_mssg = Pbft.ViewChange.new_view(state.current_view, view_change, new_log)
            extra_state = Map.put(extra_state, :change_count, 0)
            extra_state = Map.put(extra_state, :view_change_list, [])

            IO.puts("Replica View Change log: #{inspect(state.log)}\n")

            broadcast_to_all(state, {new_view_mssg, sign_message(new_view_mssg, state.private_key)})

            state = make_primary(state)

            replica(state, extra_state)
          else
            replica(state, extra_state)
          end
        else
          replica(state, extra_state)
        end

      {sender,
       {%Pbft.ViewChange{
          type: "new",
          new_view: new_view,
          view_change_list: view_change_list,
          updated_log: updated_log
        }, new_view_digest}} ->
        new_view_mssg = %Pbft.ViewChange{
          type: "new",
          new_view: new_view,
          view_change_list: view_change_list,
          updated_log: updated_log
        }

        if whoami != get_primary(state, new_view) and
             verify_digest(new_view_digest, new_view_mssg, state.cluster_pub_keys[sender]) and
             verify_view_change(state, view_change_list, 0) do 
          IO.puts("Replica #{whoami} received NEW VIEW from #{sender}\n")

          new_log = generate_new_log(%{state | current_view: state.current_view+1}, %{}, 0)
          if new_log == updated_log do
            #TODO: Function to properly verify partially true logs.
            IO.puts("Replica #{whoami} verified new log from #{sender}\n")
            state = %{state | current_view: state.current_view + 1, is_primary: false, log: new_log}
            # state = reset_election_timer
            replica(state, extra_state)
          else
            replica(state, extra_state)
            IO.puts("Replica #{whoami} FAILED new log from #{sender}\n")
          end

        else
          IO.puts("Replica #{whoami} FAILED mssg from #{sender}\n")
          replica(state, extra_state)
        end

      {sender, :send_log} ->
        send(sender, state.log)
        replica(state, extra_state)

      {sender, :die} ->
        Process.exit(self(), :normal)
    end
  end

  @doc """
  This function transitions a process so it is
  in flux.
  """
  @spec trigger_view_change(%Pbft{}, any()) :: no_return()
  def trigger_view_change(state, extra_state) do
    view_change = Pbft.ViewChange.new_change(state.current_view + 1, whoami)
    broadcast_to_all(state, {view_change, sign_message(view_change, state.private_key)})
    IO.puts("Replica #{whoami}  triggered view change")
    replica(%{state | is_changing: true}, extra_state)
  end
end

defmodule Pbft.Client do
  import Emulation, only: [send: 2, whoami: 0]

  import Pbft, only: [sign_message: 2, verify_digest: 3, broadcast_to_all: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  @moduledoc """
  A client that can be used to connect and send
  requests to the RSM.
  """
  alias __MODULE__
  @enforce_keys [:primary, :request_timestamp]
  defstruct(
    primary: nil,
    request_timestamp: nil,
    private_key: nil,
    cluster_pub_keys: nil,
    max_failures: nil,
    response_timer: nil,
    cluster: nil,
    response_timeout: nil
  )

  @doc """
  Construct a new Pbft Client. This takes an ID of
  any process that is in the RSM. We rely on
  redirect messages to find the correct primary.
  """
  @spec new_client(atom(), binary(), map(), tuple()) :: %Client{primary: atom()}
  def new_client(member, private_key, cluster_pub_keys, cluster) do
    %Client{
      primary: member,
      request_timestamp: 0,
      private_key: private_key,
      cluster_pub_keys: cluster_pub_keys,
      max_failures: div(map_size(cluster_pub_keys), 3),
      response_timer: nil,
      cluster: cluster,
      response_timeout: 2000
    }
  end

  # Save a handle to the response timer.
  @spec save_response_timer(%Pbft{}, reference()) :: %Pbft{}
  defp save_response_timer(state, timer) do
    %{state | response_timer: timer}
  end

  # Cancel the response timer.
  @spec cancel_response_timer(%Client{}) :: %Client{}
  defp cancel_response_timer(state) do
    if not Kernel.is_nil(state.response_timer) do
      Emulation.cancel_timer(state.response_timer)
    end

    save_response_timer(state, nil)
  end

  # Start response timer if not started previously
  @spec start_response_timer(%Client{}) :: %Client{}
  defp start_response_timer(state) do
    if Kernel.is_nil(state.response_timer) do
      save_response_timer(state, Emulation.timer(state.response_timeout))
    else
      state
    end
  end

  # Reset response Timer
  @spec reset_response_timer(%Client{}) :: %Client{}
  defp reset_response_timer(state) do
    # You might find `save_response_timer` of use.
    state = cancel_response_timer(state)
    start_response_timer(state)
  end

  @doc """
  Send a enq request to the RSM.
  """
  @spec enq(%Client{}, any()) :: {:ok, %Client{}}
  def enq(state, item) do
    req = Pbft.ClientMessageRequest.new(whoami, {:enq, item}, state.request_timestamp)
    state = %{state | request_timestamp: state.request_timestamp + 1}

    IO.puts("Client #{whoami} broadcast enq ")
    # broadcast_to_all(state, {req, sign_message(req, state.private_key)})
    send(state.primary, {req, sign_message(req, state.private_key)})
    state = reset_response_timer(state)
    client(state, %{resp: 0, mssg: {req, sign_message(req, state.private_key)}})
  end

  @doc """
  Send a deq request to the RSM.
  """
  @spec deq(%Client{}) :: {:empty | {:value, any()}, %Client{}}
  def deq(state) do
    req = Pbft.ClientMessageRequest.new(whoami, {:deq, nil}, state.request_timestamp)
    state = %{state | request_timestamp: state.request_timestamp + 1}

    IO.puts("Client #{whoami} sent deq ")
    # broadcast_to_all(state, {req, sign_message(req, state.private_key)})
    send(state.primary, {req, sign_message(req, state.private_key)})
    state = reset_response_timer(state)
    client(state, %{resp: 0, mssg: {req, sign_message(req, state.private_key)}})
  end

  @doc """
  Send a nop request to the RSM.
  """
  @spec nop(%Client{}) :: {:ok, %Client{}}
  def nop(state) do
    req = Pbft.ClientMessageRequest.new(whoami, {:nop, nil}, state.request_timestamp)
    state = %{state | request_timestamp: state.request_timestamp + 1}
    # broadcast_to_all(state, {req, sign_message(req, state.private_key)})
    send(state.primary, {req, sign_message(req, state.private_key)})
    state = reset_response_timer(state)
    client(state, %{resp: 0, mssg: {req, sign_message(req, state.private_key)}})
  end

  @doc """
  This function implements the state machine for a client.
  """
  @spec client(%Client{}, any()) :: {:empty | {:value, any()} | :ok, %Client{}}
  def client(state, extra_state) do
    receive do
      # {sender, :nop} ->
      #   req = Pbft.ClientMessageRequest.new(whoami, {:nop, nil}, state.request_timestamp)
      #   state = %{state | request_timestamp: state.request_timestamp + 1}
      #   send(state.primary, {req, sign_message(req, state.private_key)})

      #   client(state, extra_state)
      
      # {sender, {:enq}  

      :timer ->
        IO.puts("Client #{whoami} response timer expired")
        state = reset_response_timer(state)
        broadcast_to_all(state, extra_state.mssg)
        client(state, extra_state)

      {sender,
       {%Pbft.ClientMessageResponse{
          current_view: current_view,
          client_id: client_id,
          replica_id: replica_id,
          result: result,
          request_timestamp: request_timestamp
        }, response_digest}} ->
        response_mssg = %Pbft.ClientMessageResponse{
          current_view: current_view,
          client_id: client_id,
          replica_id: replica_id,
          result: result,
          request_timestamp: request_timestamp
        }

        if verify_digest(response_digest, response_mssg, state.cluster_pub_keys[sender]) and
             request_timestamp == state.request_timestamp - 1 do
          extra_state = %{extra_state | resp: extra_state.resp + 1}
          IO.puts("Client #{whoami} response #{inspect(response_mssg)} ")

          if extra_state.resp == state.max_failures + 1 do
            {result, state}
          else
            client(state, extra_state)
          end
        else
          client(state, extra_state)
        end
    end
  end
end
