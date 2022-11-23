x = :enacl.sign_keypair      
sig = :enacl.sign_detached(inspect(message), x.secret)  
:enacl.sign_verify_detached(sig, inspect(message), x.public)