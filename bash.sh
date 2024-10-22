#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_status() {
    echo -e "${YELLOW}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_error() {
    echo -e "${RED}[-] $1${NC}"
}

if [[ ! "$OSTYPE" == "msys"* ]] && [[ ! "$OSTYPE" == "cygwin"* ]]; then
    print_error "This script is designed for Windows systems only."
    exit 1
fi

print_status "Installing Chocolatey package manager..."
if ! command_exists choco; then
    powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
    export PATH="$PATH:/c/ProgramData/chocolatey/bin"
else
    print_success "Chocolatey already installed"
fi

print_status "Installing Git..."
if ! command_exists git; then
    choco install git -y
    export PATH="$PATH:/c/Program Files/Git/bin"
else
    print_success "Git already installed"
fi

print_status "Installing Node.js and npm..."
if ! command_exists node; then
    choco install nodejs -y
    export PATH="$PATH:/c/Program Files/nodejs"
else
    print_success "Node.js already installed"
fi

print_status "Installing Rust..."
if ! command_exists rustc; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
else
    print_success "Rust already installed"
fi

print_status "Installing Aptos CLI..."
if ! command_exists aptos; then
    cargo install aptos
else
    print_success "Aptos CLI already installed"
fi

if ! command_exists docker; then
    print_error "Docker Desktop is not installed. Please:"
    echo "1. Download and install Docker Desktop from: https://docs.docker.com/desktop/install/windows-install/"
    echo "2. After installation, open Docker Desktop"
    echo "3. Go to Settings (gear icon) and enable WSL 2"
    echo "4. Restart your computer"
    echo "5. Run this script again"
    exit 1
else
    print_success "Docker is installed"
fi

print_status "Starting local Aptos node..."
docker ps -q --filter "name=aptos-validator" | grep -q . && docker stop aptos-validator
docker pull aptoslabs/validator:devnet
docker run -d --rm -p 8080:8080 --name aptos-validator aptoslabs/validator:devnet

print_status "Waiting for Aptos node to start (30 seconds)..."
sleep 30

print_status "Initializing Aptos wallet..."
cat > init_wallet.exp << EOF
#!/usr/bin/expect -f
spawn aptos init
expect "Choose network"
send "1\r"
expect "Enter your private key as a hex literal"
send "\r"
expect eof
EOF

chmod +x init_wallet.exp
./init_wallet.exp
rm init_wallet.exp

print_status "Setting up Move project..."
rm -rf my_move_contract
mkdir -p my_move_contract
cd my_move_contract
aptos move init --name my_move_contract

mkdir -p sources
print_status "Downloading contract..."
curl -o sources/my_contract.move https://raw.githubusercontent.com/VanshKapoor07/aptos_on_local/main/sources/my_contract.move

ACCOUNT_ADDR=$(grep "account:" ~/.aptos/config.yaml | awk '{print $2}')

print_status "Updating Move.toml..."
sed -i "s/my_move_contract = \"_\"/my_move_contract = \"$ACCOUNT_ADDR\"/" Move.toml

print_status "Compiling Move contract..."
aptos move compile --named-addresses my_move_contract=$ACCOUNT_ADDR

print_status "Publishing Move contract..."
aptos move publish --named-addresses my_move_contract=$ACCOUNT_ADDR

print_status "Setting up ABI extraction..."
npm init -y > /dev/null 2>&1
npm install @aptos-labs/ts-sdk > /dev/null 2>&1

curl -o get_abi.js https://raw.githubusercontent.com/VanshKapoor07/aptos_on_local/main/get_abi.js

print_status "Extracting contract ABI..."
node get_abi.js

print_success "Setup completed successfully!"
echo "Environment is ready and contract is deployed!"
echo "Contract Address: $ACCOUNT_ADDR"
echo "Contract ABI has been saved to module_info.json"

cleanup() {
    print_status "Cleaning up..."
    docker stop aptos-validator >/dev/null 2>&1
}

trap cleanup EXIT