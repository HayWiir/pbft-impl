defmodule Test1 do
  use ExUnit.Case
  doctest Pbft
  import Emulation, only: [spawn: 2, send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  test "Nothing crashes during startup and heartbeats" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(0)])

    {a_public, a_private} = :crypto.generate_key(:eddsa, :ed25519)
    {b_public, b_private} = :crypto.generate_key(:eddsa, :ed25519)
    {c_public, c_private} = :crypto.generate_key(:eddsa, :ed25519)
    {d_public, d_private} = :crypto.generate_key(:eddsa, :ed25519)

    {client_public, client_private} = :crypto.generate_key(:eddsa, :ed25519)
    {c2_public, c2_private} = :crypto.generate_key(:eddsa, :ed25519)

    cluster_pub_keys = %{:a => a_public, :b => b_public, :c => c_public, :d => d_public}
    client_pub_keys = %{:client => client_public, :c2 => c2_public}

    cluster = {:a, :b, :c, :d}

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

    d_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        d_private
      )

    spawn(:a, fn -> Pbft.become_primary(a_config) end)
    spawn(:b, fn -> Pbft.become_replica(b_config) end)
    spawn(:c, fn -> Pbft.become_replica(c_config) end)
    spawn(:d, fn -> Pbft.become_replica(d_config) end)

    client =
      spawn(:client, fn ->
        client = Pbft.Client.new_client(:b, client_private, cluster_pub_keys)

        Pbft.Client.nop(client)

        receive do
        after
          1_000 -> true
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

  test "RSM Operations Work" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(0)])

    {a_public, a_private} = :crypto.generate_key(:eddsa, :ed25519)
    {b_public, b_private} = :crypto.generate_key(:eddsa, :ed25519)
    {c_public, c_private} = :crypto.generate_key(:eddsa, :ed25519)
    {d_public, d_private} = :crypto.generate_key(:eddsa, :ed25519)

    {client_public, client_private} = :crypto.generate_key(:eddsa, :ed25519)
    {c2_public, c2_private} = :crypto.generate_key(:eddsa, :ed25519)

    cluster_pub_keys = %{:a => a_public, :b => b_public, :c => c_public, :d => d_public}
    client_pub_keys = %{:client => client_public, :c2 => c2_public}

    cluster = {:a, :b, :c, :d}

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

    d_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        d_private
      )

    spawn(:a, fn -> Pbft.become_primary(a_config) end)
    spawn(:b, fn -> Pbft.become_replica(b_config) end)
    spawn(:c, fn -> Pbft.become_replica(c_config) end)
    spawn(:d, fn -> Pbft.become_replica(d_config) end)

    proc =
      spawn(:c2, fn ->
        c2 = Pbft.Client.new_client(:a, c2_private, cluster_pub_keys)

        {:ok, c2} = Pbft.Client.enq(c2, 5)
        {{:value, v}, c2} = Pbft.Client.deq(c2)
        assert v == 5
        {v, c2} = Pbft.Client.deq(c2)
        assert v == :empty

        {:ok, c2} = Pbft.Client.enq(c2, 8)

        {{:value, v}, c2} = Pbft.Client.deq(c2)
        assert v == 8
      end)

    handle = Process.monitor(proc)
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
