const { AptosClient } = require('aptos');
const fs = require('fs');

const client = new AptosClient('https://fullnode.devnet.aptoslabs.com');

async function getLatestModuleAddress(accountAddress, moduleName) {
    try {
        // Get account's transactions, most recent first
        const transactions = await client.getAccountTransactions(accountAddress, {
            limit: 100
        });

        // Find the most recent successful module publishing transaction
        const publishTx = transactions.find(tx => 
            tx.type === 'user_transaction' &&
            tx.success &&
            tx.payload?.function === '0x1::code::publish_package_txn'
        );

        if (!publishTx) {
            throw new Error('No recent module publishing transaction found');
        }

        return accountAddress;
    } catch (error) {
        console.error("Error fetching latest module address:", error);
        throw error;
    }
}

async function getModuleInfo(accountAddress, moduleName) {
    try {
        // First, get the latest module address
        const moduleAddress = await getLatestModuleAddress(accountAddress, moduleName);
        console.log('Found module at address:', moduleAddress);

        // Add delay to ensure transaction is processed
        await new Promise(resolve => setTimeout(resolve, 5000));

        // 1. Get module's address
        console.log('1. Module Address:', moduleAddress);

        // 2. Get module's name
        console.log('2. Module Name:', moduleName);

        // 3. Get functions available in the module
        const moduleData = await client.getAccountModule(moduleAddress, moduleName);
        const functionsInfo = [];
        console.log('3. Available Functions:');
        for (const [funcName, funcData] of Object.entries(moduleData.abi.exposed_functions)) {
            console.log(`   - ${funcName}`);
            console.log(`     Visibility: ${funcData.visibility}`);
            console.log(`     Entry: ${funcData.is_entry}`);
            console.log(`     Generic Type Parameters: ${funcData.generic_type_params.length}`);
            console.log(`     Parameters: ${funcData.params}`);

            functionsInfo.push({
                name: funcName,
                visibility: funcData.visibility,
                is_entry: funcData.is_entry,
                generic_type_params: funcData.generic_type_params.length,
                parameters: funcData.params
            });
        }

        // Save output
        const outputData = {
            moduleAddress,
            moduleName,
            availableFunctions: functionsInfo,
            timestamp: new Date().toISOString()
        };

        const outputFilePath = './module_info.json';
        fs.writeFileSync(outputFilePath, JSON.stringify(outputData, null, 2), 'utf-8');
        console.log(`Module information saved to ${outputFilePath}`);

    } catch (error) {
        console.error("Error fetching module info:", error);
        throw error;
    }
}

async function getAccountAddressFromConfig() {
    try {
        const configPath = './.aptos/config.yaml';
        if (fs.existsSync(configPath)) {
            const config = fs.readFileSync(configPath, 'utf8');
            const match = config.match(/account:\s*([a-fA-F0-9x]+)/);
            if (match && match[1]) {
                return match[1];
            }
        }
        throw new Error('Account address not found in config');
    } catch (error) {
        console.error("Error reading account address from config:", error);
        throw error;
    }
}

async function main() {
    try {
        const accountAddress = await getAccountAddressFromConfig();
        // Updated module name to match the Move contract
        const moduleName = 'hello_world';  // Changed from 'message' to 'hello_world'

        console.log('Using account address:', accountAddress);
        await getModuleInfo(accountAddress, moduleName);
    } catch (error) {
        console.error("Main execution error:", error);
    }
}

main();