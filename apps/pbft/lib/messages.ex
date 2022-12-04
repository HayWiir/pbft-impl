defmodule Pbft.LogEntry do
  @moduledoc """
  Log entry for Pbft implementation.
  """
  alias __MODULE__
  @enforce_keys [:sequence_number, :view]
  defstruct(
    sequence_number: nil,
    view: nil,
    operation: nil,
    requester: nil,
    argument: nil,
    request_digest: nil,
    prepared_count: nil,
    commited_count: nil,
    is_committed: nil
  )

  @doc """
  Return a new LogEntry
  """
  @spec new(non_neg_integer(), non_neg_integer(), atom(), atom(), any(), binary()) ::
          %LogEntry{
            sequence_number: non_neg_integer(),
            view: non_neg_integer(),
            requester: atom() | pid(),
            operation: :enq,
            argument: any(),
            request_digest: binary(),
            prepared_count: non_neg_integer(),
            commited_count: non_neg_integer(),
            is_committed: boolean()
          }
  def new(sequence_number, view, requester, operation, item \\ nil, request_digest) do
    %LogEntry{
      sequence_number: sequence_number,
      view: view,
      operation: operation,
      requester: requester,
      argument: item,
      request_digest: request_digest,
      prepared_count: 0,
      commited_count: 0,
      is_committed: false
    }
  end
end

defmodule Pbft.ClientMessageRequest do
  @moduledoc """
  Client Message RPC request.
  Sent by client to replicas.
  """
  alias __MODULE__

  # Require that any ClientMessageRequest contains
  # a :request_timestamp, :client_id.
  @enforce_keys [
    :request_timestamp,
    :client_id
  ]

  defstruct(
    client_id: nil,
    operation: nil,
    request_timestamp: nil
  )

  @doc """
  Create a new ClientMessage
  """
  @spec new(
          atom(),
          any(),
          non_neg_integer()
        ) ::
          %ClientMessageRequest{
            client_id: atom(),
            operation: any(),
            request_timestamp: non_neg_integer()
          }

  def new(
        client_id,
        operation,
        request_timestamp
      ) do
    %ClientMessageRequest{
      client_id: client_id,
      operation: operation,
      request_timestamp: request_timestamp
    }
  end
end

# defmodule Pbft.ClientMessageResponse do
#   @moduledoc """
#   Client Message RPC response.
#   Sent by replicas to client.
#   """
#   alias __MODULE__

#   # Require that any ClientMessageResponse contains
#   # the following.
#   @enforce_keys [
#     :current_view,
#     :client_id,
#     :replica_id,
#     :result,
#     :request_timestamp
#   ]

#   defstruct(
#     current_view: nil,
#     client_id: nil,
#     replica_id: nil,
#     result: nil,
#     request_timestamp: nil
#   )

#   @doc """
#   Create a new ClientMessageResponse
#   """
#   @spec new(
#           non_neg_integer(),
#           atom(),
#           atom(),
#           any(),
#           non_neg_integer()
#         ) ::
#           %ClientMessageResponse{
#             current_view: non_neg_integer(),
#             client_id: atom(),
#             replica_id: atom(),
#             result: any(),
#             request_timestamp: non_neg_integer()
#           }

#   def new(
#         current_view,
#         client_id,
#         replica_id,
#         result,
#         request_timestamp
#       ) do
#     %ClientMessageResponse{
#       current_view: current_view,
#       client_id: client_id,
#       replica_id: replica_id,
#       result: result,
#       request_timestamp: request_timestamp
#     }
#   end
# end

defmodule Pbft.AppendRequest do
  @moduledoc """
  PrePrepare, Prepare and Commit RPCs.
  """
  alias __MODULE__

  @enforce_keys [
    :type,
    :current_view,
    :sequence_number
  ]

  defstruct(
    type: nil,
    current_view: nil,
    sequence_number: nil,
    message_digest: nil,
    message: nil,
    replica_id: nil
  )

  @doc """
  Create a new PrePepare
  """
  @spec new_prepepare(
          non_neg_integer(),
          non_neg_integer(),
          any()
        ) ::
          %AppendRequest{
            type: atom(),
            current_view: non_neg_integer(),
            sequence_number: non_neg_integer(),
            message_digest: any(),
            current_view: any()
          }

  def new_prepepare(
        current_view,
        sequence_number,
        message_digest
      ) do
    %AppendRequest{
      type: "pre",
      current_view: current_view,
      sequence_number: sequence_number,
      message_digest: message_digest
    }
  end

  @doc """
  Create a new Pepare
  """
  @spec new_pepare(
          non_neg_integer(),
          non_neg_integer(),
          any(),
          atom()
        ) ::
          %AppendRequest{
            type: atom(),
            current_view: non_neg_integer(),
            sequence_number: non_neg_integer(),
            message_digest: any(),
            replica_id: atom()
          }

  def new_pepare(
        current_view,
        sequence_number,
        message_digest,
        replica_id
      ) do
    %AppendRequest{
      type: "prepare",
      current_view: current_view,
      sequence_number: sequence_number,
      message_digest: message_digest,
      replica_id: replica_id
    }
  end

  @doc """
  Create a new Commit
  """
  @spec new_commit(
          non_neg_integer(),
          non_neg_integer(),
          any(),
          atom()
        ) ::
          %AppendRequest{
            type: atom(),
            current_view: non_neg_integer(),
            sequence_number: non_neg_integer(),
            message_digest: any(),
            replica_id: atom()
          }

  def new_commit(
        current_view,
        sequence_number,
        message_digest,
        replica_id
      ) do
    %AppendRequest{
      type: "commit",
      current_view: current_view,
      sequence_number: sequence_number,
      message_digest: message_digest,
      replica_id: replica_id
    }
  end
end
