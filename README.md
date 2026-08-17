# ⚡ power-mode

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-orange.svg)]()
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero%20(Pure%20Python)-brightgreen.svg)]()
[![Hardware: Intel | AMD | NVIDIA](https://img.shields.io/badge/Hardware-Intel%20%7C%20AMD%20%7C%20NVIDIA-green.svg)]()

> **Universal Linux Dynamic CPU/GPU Power Profiler, Package Power Orchestrator & Telemetry Manager.**

`power-mode` is a lightweight, zero-dependency Linux tool that synchronously controls **Intel RAPL (PL1/PL2) sustained wattages**, **CPU Energy Performance Preferences (EPP)**, **ACPI Platform Profiles**, and **NVIDIA Discrete GPU TGP** from a unified Terminal UI (TUI), CLI, or desktop top-bar widget.

---

## 🌟 Key Features

* **🔬 Zero Dependencies**: Built entirely using Python's standard library (`curses`, `sysfs`, `subprocess`). Runs out of the box on any Linux distribution (Arch, Fedora, Ubuntu, Debian, CachyOS, Void, NixOS).
* **🧠 Adaptive Hardware Probing**:
  * **GPU Detected**: Generates specialized high-performance GPU profiles (`GPU Max`, `Balanced`, `CPU Compute`, `Eco`).
  * **No GPU (Integrated / Headless / CPU Machines)**: Automatically detects GPU absence and generates **CPU ML Training / High-Compute Modes** (uncapped sustained PL1/PL2, performance governor, all cores max boost).
  * **CachyOS Kernel Detection**: Detects CachyOS kernels (`BORE`/`EEVDF` schedulers) and generates ultra-low-latency high-throughput scheduler profiles.
* **🎮 Simulation / Dry-Run Mode (`--simulate` / `--dry-run`)**:
  * Test hardware detection, probe RAPL limits, and preview profile adjustments without requiring root permissions or altering system state.
* **⚙️ Interactive Custom Tuner**:
  * Live `$ \leftarrow / \rightarrow $` wattage sliders in 5W increments to dial in exact CPU sustained (PL1) and GPU TGP limits.
* **🖥️ Desktop Widget Extensions**:
  * Includes ready-to-use plugins for **Omarchy / Quickshell** popup panels and **Waybar**.

---

## 📋 Profile Matrix

### 1. Devices with Dedicated NVIDIA GPU
| Profile | CPU PL1 (Sustained) | CPU PL2 (Burst) | GPU Power Limit (TGP) | CPU Governor (EPP) | ACPI Profile | Target Workload |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **GPU** | 35 W | 55 W | **MAX (e.g. 95-100W)** | `performance` | `performance` | 3D Gaming, CUDA, Blender, Unreal Engine |
| **CACHYOS** *(if detected)* | 85 W | 162 W | **MAX (e.g. 95-100W)** | `performance` | `performance` | CachyOS Gaming / Max Multi-Threaded Throughput |
| **BALANCED** | 25 W | 45 W | ~60 W | `balance_performance` | `balanced` | Daily browsing, media, moderate multitasking |
| **CPU** | 85 W | 162 W | ~40 W | `performance` | `performance` | Code compilation (Rust/C++), CPU rendering, physics simulation |
| **ECO** | 15 W | 25 W | **MIN (e.g. 5-35W)** | `power` | `low-power` | Maximum battery conservation, silent fans |

### 2. Devices without Dedicated GPU (Integrated / CPU-Only)
| Profile | CPU PL1 (Sustained) | CPU PL2 (Burst) | CPU Governor (EPP) | ACPI Profile | Target Workload |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **ML_TRAIN** | **95 W** | **165 W** | `performance` | `performance` | Local LLMs, PyTorch/TensorFlow CPU training, data science |
| **CACHYOS** *(if detected)* | **85 W** | **140 W** | `performance` | `performance` | All-core low-latency task scheduling on CachyOS |
| **BALANCED** | 45 W | 75 W | `balance_performance` | `balanced` | General development and multitasking |
| **ECO** | 15 W | 25 W | `power` | `low-power` | Battery conservation, silent operation |

---

## 🚀 Installation

```bash
git clone https://github.com/b47m4n/power-mode.git
cd power-mode
chmod +x install.sh
./install.sh
```

Or install manually:
```bash
sudo cp bin/power-mode /usr/local/bin/power-mode
sudo chmod +x /usr/local/bin/power-mode
```

---

## 💻 CLI Usage

```bash
# Launch interactive Curses TUI
power-mode

# Run in simulation / dry-run mode (no root needed)
power-mode --simulate

# View live telemetry in JSON format (ideal for status bars)
power-mode --json

# View live hardware status
power-mode --status

# Switch profiles directly from terminal / keybindings
power-mode --gpu
power-mode --cachy
power-mode --balanced
power-mode --cpu
power-mode --ml_train
power-mode --eco

# Apply custom wattages directly (CPU PL1 in Watts, GPU TGP in Watts)
power-mode --custom 65 80
```

---

## 🧩 Desktop Integrations

### Omarchy / Quickshell
The repository includes a mouse-interactive popup panel extension under `extensions/omarchy-quickshell/`.
To install:
```bash
mkdir -p ~/.config/omarchy/plugins/local.power-mode
cp -r extensions/omarchy-quickshell/* ~/.config/omarchy/plugins/local.power-mode/
```
Add `"local.power-mode"` to your `~/.config/omarchy/shell.json` inside `bar.layout.right`.

### Waybar
Add the custom module snippet from `extensions/waybar/config.jsonc` to your `~/.config/waybar/config.jsonc`.

---

## ⚠️ Safety Disclaimer & Thermal Limits

* `power-mode` interacts with Linux kernel sysfs interfaces (`intel-rapl`, `cpufreq`) and NVIDIA driver power management.
* Always ensure your laptop or PC has adequate cooling and is connected to a power supply with sufficient wattage capacity when utilizing high-power profiles.
* Hardware safety guards (thermal throttling trips and OEM firmware ceilings) remain active in the hardware controller.

---

## 📄 License

MIT © [b47m4n](https://github.com/b47m4n)
