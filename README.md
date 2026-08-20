#  Orange Pi 4 Pro (4GB) - AI Integration Project

> **Status:** Work In Progress (WIP)  
> **Last Updated:** August 2026

## 📋 Overview

This repository documents the practical experience of integrating local AI capabilities on **Orange Pi 4 Pro** (Allwinner A733, 4GB LPDDR5 RAM). The project focuses on running lightweight language models locally without cloud dependencies, optimized for the hardware constraints of a budget single-board computer.

**Current Focus:** Setting up Ollama runtime with Qwen 2.5 models and preparing the foundation for a local voice assistant.

---

## ✅ What Works (v0.1)

- [x] **Base System:** Optimized Armbian/Debian setup for Allwinner A733
- [x] **Storage:** System + 4GB swap migrated to NVMe M.2 SSD (critical for performance)
- [x] **Ollama Runtime:** Successfully installed and running
- [x] **LLM Models:** Qwen 2.5 (1.5B / 0.5B) tested and responding
- [x] **SSH Access:** Headless operation via mobile hotspot + Termux

---

## 🛠️ Roadmap

### Phase 1: Core Infrastructure ✅
- [x] Hardware selection (Orange Pi 4 Pro 4GB)
- [x] NVMe SSD integration for swap and system
- [x] Ollama installation
- [x] Qwen 2.5 model deployment

### Phase 2: Voice Input (In Progress)
- [ ] Local speech recognition (Vosk / Whisper.cpp)
- [ ] USB microphone integration (built-in 3.5mm jack has OMTP/CTIA compatibility issues)
- [ ] Wake-word detection ("Hey Orange" / custom trigger)

### Phase 3: System Control Agent (Planned)
- [ ] Python agent to convert LLM output to safe shell commands
- [ ] Whitelist-based command execution with confirmation
- [ ] Hardware button integration (from "Znatok" electronics kit)

### Phase 4: Advanced Features (Future)
- [ ] Fine-tuning Qwen 2.5 for system administration tasks
- [ ] RAG (Retrieval-Augmented Generation) for documentation lookup
- [ ] Multi-modal capabilities (camera integration)

---

## 🚀 Quick Start

### Prerequisites
- Orange Pi 4 Pro (4GB RAM recommended)
- NVMe M.2 SSD (128GB+, e.g., SmartBuy/Netac/Kingston NV2)
- Armbian or compatible Debian-based OS
- Stable power supply (5V/3A)

### Installation

1. **Clone this repository:**
git clone https://github.com/kalle-smo/orangepi4pro_4gb_ai-project.git
cd orangepi4pro_4gb_ai-project
```

2. **Run the setup script:**
chmod +x setup-ollama.sh
sudo ./setup-ollama.sh
```

This will:
- Update system packages
- Install Ollama
- Download Qwen 2.5 (1.5B) model
- Enable Ollama service on boot

3. **Test the model:**
ollama run qwen2.5:1.5b
```

Or use the quick test script:
chmod +x test-qwen.sh
./test-qwen.sh "What command reboots Linux?"
```

---

## ⚙️ Hardware Notes

### Orange Pi 4 Pro Specifications
- **SoC:** Allwinner A733 (2× Cortex-A76 + 6× Cortex-A55)
- **RAM:** 4GB LPDDR5
- **NPU:** 3 TOPS (not yet utilized in this project)
- **Storage:** NVMe M.2 M-Key slot (PCIe 3.0)
- **Audio:** 3.5mm jack (OMTP standard - requires adapter for modern CTIA headsets)

### Critical: NVMe SSD
The 4GB RAM limitation makes swap essential. Running swap on microSD will:
- Kill the card within weeks
- Cause severe performance degradation

**Solution:** Use NVMe SSD for system + swap. Tested models:
- SmartBuy 128GB NVMe (budget, works fine)
- Netac 128GB NVMe (similar performance)
- Kingston NV2 250GB (recommended for reliability)

### Audio Input
Built-in 3.5mm jack uses outdated **OMTP** standard. Modern headsets use **CTIA**. Options:
1. Buy OMTP→CTIA adapter (~$2-3)
2. Use USB microphone (easier, plug-and-play)
3. Use USB sound card + any microphone

---

## 📊 Performance Expectations

With 4GB RAM and Qwen 2.5 (1.5B):
- **Model size:** ~1GB RAM
- **Response time:** 5-15 seconds (CPU inference)
- **Swap usage:** Minimal with swappiness=10
- **Stable operation:** Yes, with NVMe swap

For better performance, consider:
- Using `qwen2.5:0.5b` (faster, less capable)
- Upgrading to 8GB/12GB RAM version of the board
- Utilizing NPU when drivers mature

---

## 🔗 Resources & Acknowledgments

This project builds upon:
- [Armbian](https://armbian.com) - Optimized Linux for ARM boards
- [Ollama](https://ollama.com) - Local LLM runtime
- [Qwen 2.5](https://github.com/QwenLM) - Alibaba's language models
- [Orange Pi](http://www.orangepi.org) - Hardware manufacturer

---

## 📜 License

This project is licensed under **GNU General Public License v2.0** - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

This is a learning project and work in progress. Issues, suggestions, and pull requests are welcome!

**Current focus areas:**
- Voice recognition integration
- Safe command execution framework
- Documentation improvements

---

## 📝 Author

**kalle-smo** - Documenting the journey of running local AI on low hardware.

---

*Last tested: August 2026 on Orange Pi 4 Pro 4GB with Armbian*
