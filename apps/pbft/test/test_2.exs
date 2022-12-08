defmodule Test1 do
  use ExUnit.Case
  doctest Pbft
  import Emulation, only: [spawn: 2, send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  # test "Leader elected in midst of operations and multiple failures" do
  #   Emulation.init()
  #   Emulation.append_fuzzers([Fuzzers.delay(0)])

  #   {a_public, a_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {b_public, b_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {c_public, c_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {d_public, d_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {e_public, e_private} = :crypto.generate_key(:eddsa, :ed25519)

  #   {client_public, client_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {c2_public, c2_private} = :crypto.generate_key(:eddsa, :ed25519)

  #   cluster_pub_keys = %{:a => a_public, :b => b_public, :c => c_public, :d => d_public, :e => e_public}
  #   client_pub_keys = %{:client => client_public, :c2 => c2_public}

  #   cluster = {:a, :b, :c, :d, :e}

  #   a_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       a_private,
  #       100_000
  #     )

  #   b_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       b_private,
  #       1_000
  #     )

  #   c_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       c_private,
  #       1_000
  #     )

  #   d_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       d_private,
  #       1_000
  #     )
    
  #   e_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       e_private,
  #       1_000
  #     )  

  #   spawn(:a, fn -> Pbft.become_primary(a_config) end)
  #   spawn(:b, fn -> Pbft.become_replica(b_config) end)
  #   spawn(:c, fn -> Pbft.become_replica(c_config) end)
  #   spawn(:d, fn -> Pbft.become_replica(d_config) end)
  #   spawn(:e, fn -> Pbft.become_replica(e_config) end)

  #   proc =
  #     spawn(:c2, fn ->
  #       c2 = Pbft.Client.new_client(:e, c2_private, cluster_pub_keys, cluster)

  #       # receive do
  #       # after
  #       #   5_000 -> :ok
  #       # end

  #       {:ok, c2} = Pbft.Client.enq(c2, 5)
  #       {:ok, c2} = Pbft.Client.enq(c2, 10)
  #       send(:a, :die)

  #       # receive do
  #       # after
  #       #   400 -> :ok
  #       # end

  #       # Process.sleep(1000)
        
  #       {{:value, v}, c2} = Pbft.Client.deq(c2)
  #       assert v == 5
  #       {{:value, x}, c2} = Pbft.Client.deq(c2)
  #       assert x == 10
  #       {:empty, c2} = Pbft.Client.deq(c2)
  #       send(:b, :die)

  #       {:ok, c2} = Pbft.Client.enq(c2, 8)

  #       {{:value, v}, c2} = Pbft.Client.deq(c2)
  #       assert v == 8
        



  #       # {{:value, v}, c2} = Pbft.Client.deq(c2)
  #       # assert v == 5
  #       # {v, c2} = Pbft.Client.deq(c2)
  #       # assert v == :empty

  #       # {:ok, c2} = Pbft.Client.enq(c2, 8)

        
  #     end)
    
  #   # proc2 =   spawn(:client, fn ->
  #   #   client = Pbft.Client.new_client(:b, client_private, cluster_pub_keys, cluster)

  #   #   # receive do
  #   #   # after
  #   #   #   5_000 -> :ok
  #   #   # end

  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 5)
  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 10)
  #   #   # send(:a, :die)

  #   #   receive do
  #   #   after
  #   #     5_000 -> :ok
  #   #   end

  #   #   # Process.sleep(1000)
      
  #   #   {{:value, v}, client} = Pbft.Client.deq(client)
  #   #   assert v == 10
  #   #   {{:value, x}, client} = Pbft.Client.deq(client)
  #   #   assert x == 5
  #   #   {:empty, client} = Pbft.Client.deq(client)

  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 8)

  #   #   # {{:value, v}, c2} = Pbft.Client.deq(c2)
  #   #   # assert v == 8
      



  #   #   # {{:value, v}, c2} = Pbft.Client.deq(c2)
  #   #   # assert v == 5
  #   #   # {v, c2} = Pbft.Client.deq(c2)
  #   #   # assert v == :empty

  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 8)

      
  #   # end)

  #   handle = Process.monitor(proc)
  #   # Timeout.
  #   receive do
  #     {:DOWN, ^handle, _, _, _} -> true
  #   after
  #     30_000 -> assert false
  #   end
  # after
  #   Emulation.terminate()
  # end

  # test "Byzantine Leader - Wrong Message" do
  #   Emulation.init()
  #   Emulation.append_fuzzers([Fuzzers.delay(0)])

  #   {a_public, a_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {b_public, b_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {c_public, c_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {d_public, d_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {e_public, e_private} = :crypto.generate_key(:eddsa, :ed25519)

  #   {client_public, client_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {c2_public, c2_private} = :crypto.generate_key(:eddsa, :ed25519)

  #   cluster_pub_keys = %{:a => a_public, :b => b_public, :c => c_public, :d => d_public, :e => e_public}
  #   client_pub_keys = %{:client => client_public, :c2 => c2_public}

  #   cluster = {:a, :b, :c, :d, :e}

  #   a_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       a_private,
  #       100_000
  #     )

  #   b_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       b_private,
  #       1_000
  #     )

  #   c_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       c_private,
  #       1_000
  #     )

  #   d_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       d_private,
  #       1_000
  #     )
    
  #   e_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       e_private,
  #       1_000
  #     )  

  #   spawn(:a, fn -> Pbft.become_primary(a_config) end)
  #   spawn(:b, fn -> Pbft.become_replica(b_config) end)
  #   spawn(:c, fn -> Pbft.become_replica(c_config) end)
  #   spawn(:d, fn -> Pbft.become_replica(d_config) end)
  #   spawn(:e, fn -> Pbft.become_replica(e_config) end)

  #   proc =
  #     spawn(:c2, fn ->
  #       c2 = Pbft.Client.new_client(:e, c2_private, cluster_pub_keys, cluster)

  #       # receive do
  #       # after
  #       #   5_000 -> :ok
  #       # end

  #       {:ok, c2} = Pbft.Client.enq(c2, 5)
  #       {:ok, c2} = Pbft.Client.enq(c2, 10)
  #       send(:a, :byzantine_mssg)

  #       # receive do
  #       # after
  #       #   400 -> :ok
  #       # end

  #       # Process.sleep(1000)
        
  #       {{:value, v}, c2} = Pbft.Client.deq(c2)
  #       assert v == 5
  #       {{:value, x}, c2} = Pbft.Client.deq(c2)
  #       assert x == 10
  #       {:empty, c2} = Pbft.Client.deq(c2)
  #       send(:b, :die)

  #       {:ok, c2} = Pbft.Client.enq(c2, 8)

  #       {{:value, v}, c2} = Pbft.Client.deq(c2)
  #       assert v == 8
        



  #       # {{:value, v}, c2} = Pbft.Client.deq(c2)
  #       # assert v == 5
  #       # {v, c2} = Pbft.Client.deq(c2)
  #       # assert v == :empty

  #       # {:ok, c2} = Pbft.Client.enq(c2, 8)

        
  #     end)
    
  #   # proc2 =   spawn(:client, fn ->
  #   #   client = Pbft.Client.new_client(:b, client_private, cluster_pub_keys, cluster)

  #   #   # receive do
  #   #   # after
  #   #   #   5_000 -> :ok
  #   #   # end

  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 5)
  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 10)
  #   #   # send(:a, :die)

  #   #   receive do
  #   #   after
  #   #     5_000 -> :ok
  #   #   end

  #   #   # Process.sleep(1000)
      
  #   #   {{:value, v}, client} = Pbft.Client.deq(client)
  #   #   assert v == 10
  #   #   {{:value, x}, client} = Pbft.Client.deq(client)
  #   #   assert x == 5
  #   #   {:empty, client} = Pbft.Client.deq(client)

  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 8)

  #   #   # {{:value, v}, c2} = Pbft.Client.deq(c2)
  #   #   # assert v == 8
      



  #   #   # {{:value, v}, c2} = Pbft.Client.deq(c2)
  #   #   # assert v == 5
  #   #   # {v, c2} = Pbft.Client.deq(c2)
  #   #   # assert v == :empty

  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 8)

      
  #   # end)

  #   handle = Process.monitor(proc)
  #   # Timeout.
  #   receive do
  #     {:DOWN, ^handle, _, _, _} -> true
  #   after
  #     30_000 -> assert false
  #   end
  # after
  #   Emulation.terminate()
  # end

  # test "Byzantine Leader - Wrong Sequence" do
  #   Emulation.init()
  #   Emulation.append_fuzzers([Fuzzers.delay(0)])

  #   {a_public, a_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {b_public, b_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {c_public, c_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {d_public, d_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {e_public, e_private} = :crypto.generate_key(:eddsa, :ed25519)

  #   {client_public, client_private} = :crypto.generate_key(:eddsa, :ed25519)
  #   {c2_public, c2_private} = :crypto.generate_key(:eddsa, :ed25519)

  #   cluster_pub_keys = %{:a => a_public, :b => b_public, :c => c_public, :d => d_public, :e => e_public}
  #   client_pub_keys = %{:client => client_public, :c2 => c2_public}

  #   cluster = {:a, :b, :c, :d, :e}

  #   a_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       a_private,
  #       100_000
  #     )

  #   b_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       b_private,
  #       1_000
  #     )

  #   c_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       c_private,
  #       1_000
  #     )

  #   d_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       d_private,
  #       1_000
  #     )
    
  #   e_config =
  #     Pbft.new_configuration(
  #       cluster,
  #       cluster_pub_keys,
  #       client_pub_keys,
  #       e_private,
  #       1_000
  #     )  

  #   spawn(:a, fn -> Pbft.become_primary(a_config) end)
  #   spawn(:b, fn -> Pbft.become_replica(b_config) end)
  #   spawn(:c, fn -> Pbft.become_replica(c_config) end)
  #   spawn(:d, fn -> Pbft.become_replica(d_config) end)
  #   spawn(:e, fn -> Pbft.become_replica(e_config) end)

  #   proc =
  #     spawn(:c2, fn ->
  #       c2 = Pbft.Client.new_client(:e, c2_private, cluster_pub_keys, cluster)

  #       # receive do
  #       # after
  #       #   5_000 -> :ok
  #       # end

  #       {:ok, c2} = Pbft.Client.enq(c2, 5)
  #       {:ok, c2} = Pbft.Client.enq(c2, 10)
  #       send(:a, :byzantine_seq)

  #       # receive do
  #       # after
  #       #   400 -> :ok
  #       # end

  #       # Process.sleep(1000)
        
  #       {{:value, v}, c2} = Pbft.Client.deq(c2)
  #       assert v == 5
  #       {{:value, x}, c2} = Pbft.Client.deq(c2)
  #       assert x == 10
  #       {:empty, c2} = Pbft.Client.deq(c2)
  #       send(:b, :die)

  #       {:ok, c2} = Pbft.Client.enq(c2, 8)

  #       {{:value, v}, c2} = Pbft.Client.deq(c2)
  #       assert v == 8
        



  #       # {{:value, v}, c2} = Pbft.Client.deq(c2)
  #       # assert v == 5
  #       # {v, c2} = Pbft.Client.deq(c2)
  #       # assert v == :empty

  #       # {:ok, c2} = Pbft.Client.enq(c2, 8)

        
  #     end)
    
  #   # proc2 =   spawn(:client, fn ->
  #   #   client = Pbft.Client.new_client(:b, client_private, cluster_pub_keys, cluster)

  #   #   # receive do
  #   #   # after
  #   #   #   5_000 -> :ok
  #   #   # end

  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 5)
  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 10)
  #   #   # send(:a, :die)

  #   #   receive do
  #   #   after
  #   #     5_000 -> :ok
  #   #   end

  #   #   # Process.sleep(1000)
      
  #   #   {{:value, v}, client} = Pbft.Client.deq(client)
  #   #   assert v == 10
  #   #   {{:value, x}, client} = Pbft.Client.deq(client)
  #   #   assert x == 5
  #   #   {:empty, client} = Pbft.Client.deq(client)

  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 8)

  #   #   # {{:value, v}, c2} = Pbft.Client.deq(c2)
  #   #   # assert v == 8
      



  #   #   # {{:value, v}, c2} = Pbft.Client.deq(c2)
  #   #   # assert v == 5
  #   #   # {v, c2} = Pbft.Client.deq(c2)
  #   #   # assert v == :empty

  #   #   # {:ok, c2} = Pbft.Client.enq(c2, 8)

      
  #   # end)

  #   handle = Process.monitor(proc)
  #   # Timeout.
  #   receive do
  #     {:DOWN, ^handle, _, _, _} -> true
  #   after
  #     30_000 -> assert false
  #   end
  # after
  #   Emulation.terminate()
  # end

  test "Byzantine Leader - Exclude" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(0)])

    {a_public, a_private} = :crypto.generate_key(:eddsa, :ed25519)
    {b_public, b_private} = :crypto.generate_key(:eddsa, :ed25519)
    {c_public, c_private} = :crypto.generate_key(:eddsa, :ed25519)
    {d_public, d_private} = :crypto.generate_key(:eddsa, :ed25519)
    {e_public, e_private} = :crypto.generate_key(:eddsa, :ed25519)

    {client_public, client_private} = :crypto.generate_key(:eddsa, :ed25519)
    {c2_public, c2_private} = :crypto.generate_key(:eddsa, :ed25519)

    cluster_pub_keys = %{:a => a_public, :b => b_public, :c => c_public, :d => d_public, :e => e_public}
    client_pub_keys = %{:client => client_public, :c2 => c2_public}

    cluster = {:a, :b, :c, :d, :e}

    a_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        a_private,
        100_000
      )

    b_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        b_private,
        1000
      )

    c_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        c_private,
        100_000
      )

    d_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        d_private,
        100_000
      )
    
    e_config =
      Pbft.new_configuration(
        cluster,
        cluster_pub_keys,
        client_pub_keys,
        e_private,
        100_000
      )  

    spawn(:a, fn -> Pbft.become_primary(a_config) end)
    spawn(:b, fn -> Pbft.become_replica(b_config) end)
    spawn(:c, fn -> Pbft.become_replica(c_config) end)
    spawn(:d, fn -> Pbft.become_replica(d_config) end)
    spawn(:e, fn -> Pbft.become_replica(e_config) end)

    proc =
      spawn(:c2, fn ->
        c2 = Pbft.Client.new_client(:b, c2_private, cluster_pub_keys, cluster)

        # receive do
        # after
        #   5_000 -> :ok
        # end

        send(:a, {:byzantine_exclude, {:a, :c, :d, :e}})

        {:ok, c2} = Pbft.Client.enq(c2, 5)
        {:ok, c2} = Pbft.Client.enq(c2, 10)
        

        # receive do
        # after
        #   400 -> :ok
        # end

        # Process.sleep(1000)
        
        {{:value, v}, c2} = Pbft.Client.deq(c2)
        assert v == 5
        {{:value, x}, c2} = Pbft.Client.deq(c2)
        assert x == 10
        {:empty, c2} = Pbft.Client.deq(c2)
        send(:b, :die)

        {:ok, c2} = Pbft.Client.enq(c2, 8)

        {{:value, v}, c2} = Pbft.Client.deq(c2)
        assert v == 8
        



        # {{:value, v}, c2} = Pbft.Client.deq(c2)
        # assert v == 5
        # {v, c2} = Pbft.Client.deq(c2)
        # assert v == :empty

        # {:ok, c2} = Pbft.Client.enq(c2, 8)

        
      end)
    
    # proc2 =   spawn(:client, fn ->
    #   client = Pbft.Client.new_client(:b, client_private, cluster_pub_keys, cluster)

    #   # receive do
    #   # after
    #   #   5_000 -> :ok
    #   # end

    #   # {:ok, c2} = Pbft.Client.enq(c2, 5)
    #   # {:ok, c2} = Pbft.Client.enq(c2, 10)
    #   # send(:a, :die)

    #   receive do
    #   after
    #     5_000 -> :ok
    #   end

    #   # Process.sleep(1000)
      
    #   {{:value, v}, client} = Pbft.Client.deq(client)
    #   assert v == 10
    #   {{:value, x}, client} = Pbft.Client.deq(client)
    #   assert x == 5
    #   {:empty, client} = Pbft.Client.deq(client)

    #   # {:ok, c2} = Pbft.Client.enq(c2, 8)

    #   # {{:value, v}, c2} = Pbft.Client.deq(c2)
    #   # assert v == 8
      



    #   # {{:value, v}, c2} = Pbft.Client.deq(c2)
    #   # assert v == 5
    #   # {v, c2} = Pbft.Client.deq(c2)
    #   # assert v == :empty

    #   # {:ok, c2} = Pbft.Client.enq(c2, 8)

      
    # end)

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
