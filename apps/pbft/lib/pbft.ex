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
    current_term: nil,
    log: nil,
    is_primary: nil,

    # Service State
    queue: nil,

    # Cryptography
    private_key: nil,
    public_key: nil,
    cluster_pub_keys: nil,
    client_pub_keys: nil
  )

  @doc """
  Create state for an initial Pbft cluster. Each
  process should get an appropriately updated version
  of this state.
  """
  @spec new_configuration(
          [atom()],
          [binary()],
          map(),
          binary()
        ) :: %Pbft{}
  def new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        private_key
      ) do
    %Pbft{
      cluster: cluster,
      cluster_pub_keys: cluster_pub_keys,
      client_pub_keys: client_pub_keys,
      private_key: private_key,
      current_term: 0,
      log: [],
      queue: :queue.new(),
      is_primary: false
    }
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

  @doc """
  make_primary changes process state for a process that
  has just been elected primary.
  """
  @spec make_primary(%Pbft{}) :: %Pbft{is_primary: true}
  def make_primary(state) do
    %{
      state
      | is_primary: true
    }
  end

  @doc """
  This function transitions a process that is not currently
  the primary so it is a primary.
  """
  @spec become_primary(%Pbft{is_primary: false}) :: no_return()
  def become_primary(state) do
    # Send initial AppendEntry heartbeat

    primary(make_primary(state), %{})
  end

  @doc """
  This function implements the state machine for a process
  that is currently the primary.
  """
  @spec primary(%Pbft{is_primary: true}, any()) :: no_return()
  def primary(state, extra_state) do
    receive do
      {sender,
       {%Pbft.ClientMessageRequest{
          client_id: client_id,
          operation: operation,
          request_timestamp: request_timestamp
        }, digest}} ->
        IO.puts("Primary #{whoami} Received command from #{sender} ")

        if verify_digest(
             digest,
             %Pbft.ClientMessageRequest{
               client_id: client_id,
               operation: operation,
               request_timestamp: request_timestamp
             },
             state.client_pub_keys[sender]
           ) do
          IO.puts("Verified")
        else
          IO.puts("Not Verified")
        end
    end
  end
end

defmodule Pbft.Client do
  import Emulation, only: [send: 2, whoami: 0]

  import Pbft, only: [sign_message: 2, verify_digest: 3]

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
    private_key: nil
  )

  @doc """
  Construct a new Pbft Client. This takes an ID of
  any process that is in the RSM. We rely on
  redirect messages to find the correct primary.
  """
  @spec new_client(atom(), binary()) :: %Client{primary: atom()}
  def new_client(member, private_key) do
    %Client{
      primary: member,
      request_timestamp: 0,
      private_key: private_key
    }
  end

  @doc """
  Send a nop request to the RSM.
  """
  @spec nop(%Client{}) :: {:ok, %Client{}}
  def nop(client) do
    primary = client.primary

    req = Pbft.ClientMessageRequest.new(whoami, :nop, client.request_timestamp)

    client = %{client | request_timestamp: client.request_timestamp + 1}

    digest = sign_message(req, client.private_key)

    send(primary, {req, digest})

    :ok

    # receive do
    #   {_, {:redirect, new_primary}} ->
    #     nop(%{client | primary: new_primary})

    #   {_, :ok} ->
    #     {:ok, client}
    # end
  end
end
