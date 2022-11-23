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
    # required by the Raft protocol.
    defstruct(
      # The list of current proceses.
      cluster: nil,

      current_term: nil,
      log: nil,

      #Service State
      queue: nil







      #********************************************************************
      # Current leader.
      current_leader: nil,
      # Time before starting an election.
      min_election_timeout: nil,
      max_election_timeout: nil,
      election_timer: nil,
      # Time between heartbeats from the leader.
      heartbeat_timeout: nil,
      heartbeat_timer: nil,
      # Persistent state on all servers.
      current_term: nil,
      voted_for: nil,
      # A short note on log structure: The functions that follow
      # (e.g., get_last_log_index, commit_log_index, etc.) all
      # assume that the log is a list with later entries (i.e.,
      # entries with higher index numbers) appearing closer to
      # the head of the list, and that index numbers start with 1.
      # For example if the log contains 3 entries committe in term
      # 2, 2, and 1 we would expect:
      #
      # `[{index: 3, term: 2, ..}, {index: 2, term: 2, ..},
      #     {index: 1, term: 1}]`
      #
      # If you change this structure, you will need to change
      # those functions.
      #
      # Finally, it might help to know that two lists can be
      # concatenated using `l1 ++ l2`
      log: nil,
      # Volatile state on all servers
      commit_index: nil,
      last_applied: nil,
      # Volatile state on leader
      is_leader: nil,
      next_index: nil,
      match_index: nil,
      # The queue we are building using this RSM.
      queue: nil
    )