#!/bin/bash

# --- Step 1: Set up color and bold formatting ---
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
PINK='\033[1;35m'

# Show function for colored and bold output messages
show() {
    case $2 in
        "error")
            echo -e "${PINK}${BOLD}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${PINK}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${PINK}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

# --- Step 2: Install sudo ---
echo "🔄 Installing sudo..."
apt update && apt install -y sudo

# --- Step 3: Install necessary dependencies ---
echo "📦 Installing required dependencies..."
sudo apt update && sudo apt install -y python3 python3-venv python3-pip curl wget screen git lsof

# --- Step 4: Install Yarn ---
echo "📦 Installing Yarn..."
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install -y yarn

# --- Step 5: Install Node.js if not installed ---
# Check if curl is installed 
if ! command -v curl &> /dev/null; then
    show "curl is not installed. Installing curl..." "progress"
    sudo apt-get update
    sudo apt-get install -y curl
    if [ $? -ne 0 ]; then
        show "Failed to install curl. Please install it manually and rerun the script." "error"
        exit 1
    fi
fi

# Check for existing Node.js installations
EXISTING_NODE=$(which node)
if [ -n "$EXISTING_NODE" ]; then
    show "Existing Node.js found at $EXISTING_NODE. The script will install the latest version system-wide."
fi

# Fetch the latest Node.js version dynamically
show "Fetching latest Node.js version..." "progress"
LATEST_VERSION=$(curl -s https://nodejs.org/dist/latest/ | grep -oP 'node-v\K\d+\.\d+\.\d+' | head -1)
if [ -z "$LATEST_VERSION" ]; then
    show "Failed to fetch latest Node.js version. Please check your internet connection." "error"
    exit 1
fi
show "Latest Node.js version is $LATEST_VERSION"

# Extract the major version for NodeSource setup
MAJOR_VERSION=$(echo $LATEST_VERSION | cut -d. -f1)

# Set up the NodeSource repository for the latest major version
show "Setting up NodeSource repository for Node.js $MAJOR_VERSION.x..." "progress"
curl -sL https://deb.nodesource.com/setup_${MAJOR_VERSION}.x | sudo -E bash -
if [ $? -ne 0 ]; then
    show "Failed to set up NodeSource repository." "error"
    exit 1
fi

# Install Node.js and npm
show "Installing Node.js and npm..." "progress"
sudo apt-get install -y nodejs
if [ $? -ne 0 ]; then
    show "Failed to install Node.js and npm." "error"
    exit 1
fi

# Verify installation and PATH availability
show "Verifying installation..." "progress"
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    NODE_VERSION=$(node -v)
    NPM_VERSION=$(npm -v)
    INSTALLED_NODE=$(which node)
    if [ "$INSTALLED_NODE" = "/usr/bin/node" ]; then
        show "Node.js $NODE_VERSION and npm $NPM_VERSION installed successfully at /usr/bin."
    else
        show "Node.js $NODE_VERSION and npm $NPM_VERSION installed, but another node executable is in PATH at $INSTALLED_NODE."
        show "The system-wide installation is at /usr/bin/node. To prioritize it, ensure /usr/bin is before other paths in your PATH variable."
    fi
else
    show "Installation completed, but node or npm not found in PATH." "error"
    show "This is unusual as /usr/bin should be in PATH. Please ensure /usr/bin is in your PATH variable (e.g., export PATH=/usr/bin:$PATH) and restart your shell."
    exit 1
fi

# --- Step 6: Clone the RL Swarm repository from gensyn-ai ---
echo "🔄 Cloning RL Swarm repository from gensyn-ai..."
cd $HOME && [ -d rl-swarm ] && rm -rf rl-swarm
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm

# --- Step 7: Create a Python virtual environment ---
echo "🛠️ Creating Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate

# --- Step 8: Install Python dependencies ---
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# --- Step 9: Create a screen session for RL Swarm ---
echo "🎥 Creating a screen session named 'gensyn'..."
screen -S gensyn -d -m

# --- Step 10: Run the RL Swarm in the background ---
echo "🚀 Running RL Swarm..."
screen -S gensyn -X stuff "python3 -m venv .venv && . .venv/bin/activate && ./run_rl_swarm.sh\n"

# --- Step 11: Auto-answer the prompts ---
echo "🔑 Answering the prompts automatically..."
sleep 3
screen -S gensyn -X stuff "Y\n"  # Automatically answer 'Y' to connect to the Testnet
screen -S gensyn -X stuff "N\n"  # Automatically answer 'N' for pushing models to Hugging Face

# --- Step 12: Detach from the screen session ---
echo "📱 Detaching from the screen session (Ctrl+A, D)..."
screen -S gensyn -X detach

# --- Step 13: Final confirmation ---
echo "✅ RL Swarm setup is now complete. The RL Swarm is running in a detached screen session."
echo "You can reconnect to the session anytime using 'screen -r gensyn'."

# --- Step 14: Instructions for Manual Login ---
echo "📝 Manual Login Instructions:"
echo "   If you're running on a VM, open a browser and navigate to http://localhost:3000/."
echo "   Log in with your preferred method (Hugging Face or Alchemy)."
echo "   After logging in, you can check the RL Swarm progress."

# --- Step 15: Troubleshooting Notes ---
echo "🔧 Troubleshooting: If you face issues, you can check the following common problems:"
echo "1. OOM Errors (Out of Memory) on MacBooks or limited machines? Try setting:"
echo "   export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0 && ./run_rl_swarm.sh"
echo "2. If the login screen doesn't open, ensure port forwarding is set for VM users."
echo "   Use: gcloud compute ssh --zone 'your-zone' --project 'your-project-id' -- -L 3000:localhost:3000"

# --- Step 16: Automatic Exit ---
echo "🛑 Script execution complete. RL Swarm setup has been successfully automated! 🎉"
