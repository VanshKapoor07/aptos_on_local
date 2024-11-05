address 0x4d13cf1bee31d1a31d0f783c48ac3979cc643fd8b169fd735ee57160a9c717a7 {
    module contract {
        use std::string;
    use std::signer;
    
    struct HelloMessage has key, store {
        message: string::String
    }

    public entry fun init(account: &signer) {
        // Initialize the HelloMessage resource under the account
        move_to(account, HelloMessage {
            message: string::utf8(b"Hello, World!")
        });
    }

    #[view]
    public fun get_message(account_address: address): string::String acquires HelloMessage {
        // Get the message from the HelloMessage resource
        borrow_global<HelloMessage>(account_address).message
    }

    public entry fun update_message(account: &signer, new_message: string::String) acquires HelloMessage {
        // Update the message in the HelloMessage resource
        let signer_address = signer::address_of(account);
        let hello_msg = borrow_global_mut<HelloMessage>(signer_address);
        hello_msg.message = new_message;
    }
    }
}
