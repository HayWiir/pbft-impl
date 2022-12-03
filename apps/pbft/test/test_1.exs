defmodule Test1 do
  use ExUnit.Case
  doctest Pbft
  import Emulation, only: [spawn: 2, send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  test "Nothing crashes during startup and heartbeats" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(2)])

    {a_public, a_private} = :crypto.generate_key(:eddsa, :ed25519)
    {b_public, b_private} = :crypto.generate_key(:eddsa, :ed25519)
    {c_public, c_private} = :crypto.generate_key(:eddsa, :ed25519)

    {client_public, client_private} = :crypto.generate_key(:eddsa, :ed25519)
    {c2_public, c2_private} = :crypto.generate_key(:eddsa, :ed25519)

    cluster_pub_keys = %{:a => a_public, :b => b_public, :c => c_public}
    client_pub_keys = %{:client => client_public, :c2 => c2_public}

    cluster = {:a, :b, :c}

    a_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        a_private
      )

    b_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        b_private
      )

    c_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        c_private
      )

    spawn(:a, fn -> Pbft.become_primary(a_config) end)
    spawn(:b, fn -> Pbft.become_replica(b_config) end)
    spawn(:c, fn -> Pbft.become_replica(b_config) end)

    client =
      spawn(:client, fn ->
        client = Pbft.Client.new_client(:b, client_private)

        Pbft.Client.nop(client)

        receive do
        after
          5_000 -> true
        end
      end)

    handle = Process.monitor(client)
    # Timeout.
    receive do
      {:DOWN, ^handle, _, _, _} -> true
    after
      30_000 -> assert false
    end
  after
    Emulation.terminate()
  end
end
