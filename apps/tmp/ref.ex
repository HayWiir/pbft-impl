x = :enacl.sign_keypair()
sig = :enacl.sign_detached(inspect(message), x.secret)
:enacl.sign_verify_detached(sig, inspect(message), x.public)

{pub, priv} = :crypto.generate_key(:eddsa, :ed25519)
signature = :crypto.sign(:eddsa, :none, inspect(message), [priv, :ed25519])
:crypto.verify(:eddsa, :none, inspect(message), signature, [pub, :ed25519])
