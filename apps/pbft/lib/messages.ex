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

  # @doc """
  # Create a new Pepare
  # """
  # @spec new_pepare(
  #         non_neg_integer(),
  #         non_neg_integer(),
  #         any(),
  #         atom()
  #       ) ::
  #         %AppendRequest{
  #           type: atom(),
  #           current_view: non_neg_integer(),
  #           sequence_number: non_neg_integer(),
  #           message_digest: any(),
  #           replica_id: atom()
  #         }

  # def new_prepepare(
  #       current_view,
  #       sequence_number,
  #       message_digest,
  #       replica_id
  #     ) do
  #   %AppendRequest{
  #     type: "prepare",
  #     current_view: current_view,
  #     sequence_number: sequence_number,
  #     message_digest: message_digest,
  #     replica_id: replica_id
  #   }
  # end

  # @doc """
  # Create a new Commit
  # """
  # @spec new_commit(
  #         non_neg_integer(),
  #         non_neg_integer(),
  #         any(),
  #         atom()
  #       ) ::
  #         %AppendRequest{
  #           type: atom(),
  #           current_view: non_neg_integer(),
  #           sequence_number: non_neg_integer(),
  #           message_digest: any(),
  #           replica_id: atom()
  #         }

  # def new_commit(
  #       current_view,
  #       sequence_number,
  #       message_digest,
  #       replica_id
  #     ) do
  #   %AppendRequest{
  #     type: "commit",
  #     current_view: current_view,
  #     sequence_number: sequence_number,
  #     message_digest: message_digest,
  #     replica_id: replica_id
  #   }
  # end
end
