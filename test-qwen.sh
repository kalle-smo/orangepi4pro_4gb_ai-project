#!/bin/bash
# Quick test script for Qwen 2.5 on Orange Pi 4 Pro

if [ -z "$1" ]; then
    echo "Usage: ./test-qwen.sh \"Your question\""
    echo ""
    echo "Example:"
    echo "  ./test-qwen.sh \"What is the command to reboot Linux?\""
    echo "  ./test-qwen.sh \"List all files in current directory\""
    exit 1
fi

echo " Asking Qwen 2.5: $1"
echo "=========================================="
echo ""

# Send request to local Ollama API
response=$(curl -s http://localhost:11434/api/generate -d '{
  "model": "qwen2.5:1.5b",
  "prompt": "You are a helpful Linux assistant for Orange Pi 4 Pro. Answer concisely and practically. Question: '"$1"'",
  "stream": false
}')

# Extract and display response
if [ $? -eq 0 ]; then
    echo "$response" | grep -o '"response":"[^"]*"' | sed 's/"response":"//;s/"$//' | sed 's/\\n/\n/g'
    echo ""
    echo "=========================================="
    echo "✅ Done"
else
    echo "❌ Error: Failed to get response from Ollama"
    echo "💡 Make sure Ollama is running: sudo systemctl status ollama"
    exit 1
fi
