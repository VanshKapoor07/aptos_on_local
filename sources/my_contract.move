module hello_world::message {
    use std::string;
    use aptos_framework::account;
    use aptos_framework::event;
    
    struct MessageHolder has key {
        message: string::String,
        message_change_events: event::EventHandle<MessageChangeEvent>,
    }

    struct MessageChangeEvent has drop, store {
        from_message: string::String,
        to_message: string::String,
    }

    public entry fun say_hello(account: &signer) {
        let addr = account::get_signer_capability_address(account);
        
        if (!exists<MessageHolder>(addr)) {
            let holder = MessageHolder {
                message: string::utf8(b"Hello World!"),
                message_change_events: account::new_event_handle<MessageChangeEvent>(account),
            };
            move_to(account, holder);
        }
    }
}
