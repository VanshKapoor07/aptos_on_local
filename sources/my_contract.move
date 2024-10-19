address 0x61dbdabc048aa3b85609e916624f46597ff9ada018a57824cd9eb5dcebe931f5 {
    module c1 {

        use std::signer;
        use aptos_framework::table::{Self, Table};
        use aptos_framework::coin;
        use aptos_framework::aptos_account;
        use aptos_framework::aptos_coin;
        use std::vector;

        const E_NOT_INITIALIZED: u64 = 1;
        const E_ALREADY_INITIALIZED: u64 = 2;
        const E_INSUFFICIENT_BALANCE: u64 = 3;
        const E_TARGET_NOT_REACHED: u64 = 4;
        const E_NOT_AUTHORIZED: u64 = 5;

        struct InvestmentData has key {
            version: u64,
            startup_address: address,
            target_amount: u64,
            total_investment: u64,
            is_active: bool,
            investments: Table<address, u64>,
            investors: vector<address>,
        }

        public entry fun initialize(startup: &signer, target_amount: u64) {
            let startup_address = signer::address_of(startup);
            assert!(!exists<InvestmentData>(startup_address), E_ALREADY_INITIALIZED);

            move_to(startup, InvestmentData {
                version: 1,
                startup_address,
                target_amount,
                total_investment: 0,
                is_active: true,
                investments: table::new(),
                investors: vector::empty(),
            });
        }
        
        public entry fun invest(investor: &signer, startup_address: address, amount: u64) acquires InvestmentData {
            let investor_address = signer::address_of(investor);
            assert!(exists<InvestmentData>(startup_address), E_NOT_INITIALIZED);
            
            let investment_data = borrow_global_mut<InvestmentData>(startup_address);
            assert!(investment_data.is_active, E_TARGET_NOT_REACHED);

            // Perform the coin transfer
            //aptos_framework::coin::transfer<AptosCoin>(investor, startup_address, amount);
            //let sender_coin_store = aptos_framework::coin::withdraw<aptos_coin::AptosCoin>(investor, amount);
            aptos_framework::coin::deposit<aptos_coin::AptosCoin>(
            startup_address,
            aptos_framework::coin::withdraw<aptos_coin::AptosCoin>(investor, amount)
        );
            if (!table::contains(&investment_data.investments, investor_address)) {
                table::add(&mut investment_data.investments, investor_address, amount);
                vector::push_back(&mut investment_data.investors, investor_address);
            } else {
                let investor_amount = table::borrow_mut(&mut investment_data.investments, investor_address);
                *investor_amount = *investor_amount + amount;
            };

            investment_data.total_investment = investment_data.total_investment + amount;

            if (investment_data.total_investment >= investment_data.target_amount) {
                investment_data.is_active = false;
            };
        }
        
        public entry fun withdraww(startup: &signer) acquires InvestmentData {
            let startup_address = signer::address_of(startup);
            let investment_data = borrow_global_mut<InvestmentData>(startup_address);
            investment_data.is_active = false;
            investment_data.total_investment = 0;
        }
    
        public fun is_initialized(address: address): bool {
            exists<InvestmentData>(address)
        }
        
        public entry fun reset(startup: &signer, new_target_amount: u64) acquires InvestmentData {
            let startup_address = signer::address_of(startup);
            assert!(exists<InvestmentData>(startup_address), E_NOT_INITIALIZED);

            let investment_data = borrow_global_mut<InvestmentData>(startup_address);
            assert!(startup_address == investment_data.startup_address, E_NOT_AUTHORIZED);

            investment_data.target_amount = new_target_amount;
            investment_data.total_investment = 0;
            investment_data.is_active = true;

            clear_investments(&mut investment_data.investments, &mut investment_data.investors);
        }
        
        #[view]
        public fun get_investment_data(startup_address: address): (u64, u64, bool) acquires InvestmentData {
            assert!(exists<InvestmentData>(startup_address), E_NOT_INITIALIZED);
            let investment_data = borrow_global<InvestmentData>(startup_address);
            (investment_data.target_amount, investment_data.total_investment, investment_data.is_active)
        }
      
        #[view]
        public fun get_investor_investment(startup_address: address, investor_address: address): u64 acquires InvestmentData {
            assert!(exists<InvestmentData>(startup_address), E_NOT_INITIALIZED);
            let investment_data = borrow_global<InvestmentData>(startup_address);
            if (table::contains(&investment_data.investments, investor_address)) {
                *table::borrow(&investment_data.investments, investor_address)
            } else {
                0
            }
        }
        
        fun clear_investments(investments: &mut Table<address, u64>, investors: &mut vector<address>) {
            let num_investors = vector::length(investors);
            let i = 0;
            while (i < num_investors) {
                let investor = vector::borrow(investors, i);
                table::remove(investments, *investor);
                i = i + 1;
            };
            *investors = vector::empty();
        }
    }
}
