const { AptosClient } = require('aptos');
const fs = require('fs'); // Import the fs module

const client = new AptosClient('https://fullnode.testnet.aptoslabs.com');

async function getModuleInfo(moduleAddress, moduleName) {
    try {
        // 1. Get module's address (already known)
        console.log('1. Module Address:', moduleAddress);

        // 2. Get module's name (already known)
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

            // Store function info for JSON output
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

        // 5. Get account resources (as in your original code)
        const accountResources = await client.getAccountResources(moduleAddress);
        const moduleResources = accountResources.filter((resource) =>
            resource.type.includes(moduleName)
        );
        console.log('5. Module Resources:');
        console.log(JSON.stringify(moduleResources, null, 2));

        // Prepare the data to save as JSON
        const outputData = {
            moduleAddress,
            moduleName,
            availableFunctions: functionsInfo,
            resourceStructures: structsInfo,
            moduleResources
            
        };

        // Save the data as a JSON file
        const outputFilePath = './module_info.json';
        fs.writeFileSync(outputFilePath, JSON.stringify(outputData, null, 2), 'utf-8');
        console.log("Module information saved to ${outputFilePath}");

    } catch (error) {
        console.error("Error fetching module info:", error);
    }
}

const moduleAddress = '0x4d13cf1bee31d1a31d0f783c48ac3979cc643fd8b169fd735ee57160a9c717a7'; // Replace with your contract address
const moduleName = 'c'; // Replace with your module name

getModuleInfo(moduleAddress, moduleName);