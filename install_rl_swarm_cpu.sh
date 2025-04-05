#!/bin/bash

# === Logging Function with Emojis ===
log() {
    echo -e "\n\033[1;32m[INFO] $1\033[0m"
}

# === Starting Installation ===
log "🚀 Starting RL Swarm CPU-only installation..."

# === Step 1: System Update & Installing Dependencies ===
log "🔧 Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  python3.10 python3.10-venv python3.10-dev \
  build-essential git curl screen

# === Step 2: Installing pip (Latest Version) ===
log "📦 Installing latest pip..."
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10
python3.10 -m pip install --upgrade pip setuptools wheel

# === Step 3: Cloning RL Swarm Repository ===
log "📁 Cloning the RL Swarm repository from GitHub..."
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm || { log "❌ Failed to enter the directory!"; exit 1; }

# === Step 4: Set up Virtual Environment ===
log "🐍 Creating and activating Python virtual environment..."
python3.10 -m venv .venv
source .venv/bin/activate

# === Step 5: Installing Python Dependencies (CPU-only) ===
log "📦 Installing Python dependencies (CPU-only)..."
pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cpu

# === Step 6: Making Script Executable ===
log "🔑 Making the run script executable..."
chmod +x run_rl_swarm.sh

# === Step 7: Running RL Swarm ===
log "🚀 Starting RL Swarm process..."
./run_rl_swarm.sh

# === Final Message ===
log "🎉 RL Swarm installation completed successfully! 🚀"

# End of script

