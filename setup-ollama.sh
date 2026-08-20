#!/bin/bash
# Orange Pi 4 Pro - Ollama & Qwen 2.5 Setup Script
# For 4GB RAM version with NVMe SSD

echo "🚀 Starting Orange Pi 4 Pro AI Setup..."
echo "=========================================="
echo ""

# Step 1: Update system
echo "[1/4] Updating system packages..."
sudo apt update && sudo apt upgrade -y
if [ $? -ne 0 ]; then
    echo "❌ System update failed!"
    exit 1
fi
echo "✅ System updated"
echo ""

# Step 2: Install Ollama
echo "[2/4] Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
if [ $? -ne 0 ]; then
    echo "❌ Ollama installation failed!"
    exit 1
fi
echo "✅ Ollama installed"
echo ""

# Step 3: Enable and start Ollama service
echo "[3/4] Enabling Ollama service..."
sudo systemctl enable ollama
sudo systemctl start ollama
sudo systemctl status ollama --no-pager
echo ""

# Step 4: Download Qwen 2.5 model
echo "[4/4] Downloading Qwen 2.5 (1.5B) model..."
echo "⏳ This may take 10-20 minutes depending on your internet speed..."
ollama pull qwen2.5:1.5b
if [ $? -ne 0 ]; then
    echo "❌ Failed to download Qwen 2.5!"
    echo "💡 Try running: ollama pull qwen2.5:0.5b (smaller model)"
    exit 1
fi
echo "✅ Qwen 2.5 downloaded successfully!"
echo ""

echo "=========================================="
echo "🎉 Setup complete!"
echo ""
echo "Test the model with:"
echo "  ollama run qwen2.5:1.5b"
echo ""
echo "Or use the test script:"
echo "  ./test-qwen.sh \"Your question\""
echo "=========================================="
