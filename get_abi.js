const { AptosClient } = require('aptos');
const fs = require('fs');

const client = new AptosClient('https://fullnode.devnet.aptoslabs.com');

async function getLatestModuleAddress(accountAddress, moduleName) {
    try {
        // Get account's transactions, most recent first
        const transactions = await client.getAccountTransactions(accountAddress, {
            limit: 100  // Adjust this number based on how far back you want to look
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

        // The module will be at the same address as the publisher
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

        // 4. Get structure of resources defined in the module
        const structsInfo = [];
        console.log('4. Resource Structures:');
        for (const struct of moduleData.abi.structs) {
            console.log(`   - ${struct.name}`);
            console.log('     Fields:');
            const fieldsInfo = struct.fields.map(field => ({
                name: field.name,
                type: field.type
            }));
            structsInfo.push({
                name: struct.name,
                fields: fieldsInfo
            });
            for (const field of struct.fields) {
                console.log(`       ${field.name}: ${field.type}`);
            }
        }

        // 5. Get account resources
        const accountResources = await client.getAccountResources(moduleAddress);
        const moduleResources = accountResources.filter((resource) =>
            resource.type.includes(moduleName)
        );
        console.log('5. Module Resources:');
        console.log(JSON.stringify(moduleResources, null, 2));

        // Prepare and save output
        const outputData = {
            moduleAddress,
            moduleName,
            availableFunctions: functionsInfo,
            resourceStructures: structsInfo,
            moduleResources,
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

// Function to get account address from local config
async function getAccountAddressFromConfig() {
    try {
        // Read the .aptos/config.yaml file from the current directory
        const configPath = './.aptos/config.yaml';
        if (fs.existsSync(configPath)) {
            const config = fs.readFileSync(configPath, 'utf8');
            // Simple YAML parsing for the account address
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

// Usage
async function main() {
    try {
        // Get the account address from config
        const accountAddress = await getAccountAddressFromConfig();
        const moduleName = 'message'; // Replace with your module name

        console.log('Using account address:', accountAddress);
        await getModuleInfo(accountAddress, moduleName);
    } catch (error) {
        console.error("Main execution error:", error);
    }
}

main();