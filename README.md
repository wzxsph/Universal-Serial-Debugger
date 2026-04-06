<p align="center">
  <a href="./README_zh_cn.md">中文</a> | English
</p>

<div align="center">

# 🤖 AutoEmbedDebugger
### *Universal Serial Automation Debugger for Embedded Systems*

**⚠️ Status: [Testing Phase / Beta] - Stability Not Guaranteed**

[![Phase: Testing](https://img.shields.io/badge/Phase-Testing-orange)](https://github.com/yourusername/AutoEmbedDebugger)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-lightgrey)]()

</div>

---

## 📋 Project Overview

**AutoEmbedDebugger** is an AI-powered autonomous debugging agent designed for embedded systems development. It automates the complete firmware deployment and debugging workflow through serial port communication, TFTP network transfer, and U-boot bootloader interaction.

This project implements a **closed-loop debugging system**: deploying firmware → monitoring execution logs → autonomously proposing source code fixes for crashes.

> **⚠️ Important Notice**: This project is currently in the **testing phase**. While core functionality has been implemented, stability across different hardware platforms and edge cases has not been fully verified. Use with caution in production environments.

---

## ✨ Key Features

- 🚀 **Automated Firmware Deployment**
  - TFTP server auto-startup with PID management
  - Network configuration via U-boot commands
  - Firmware download and boot execution

- 🔌 **Intelligent Serial Communication**
  - Auto-detection of board state (U-boot / OS running / No response)
  - Non-blocking I/O with strict timeout constraints
  - Real-time log streaming and crash detection

- 🐛 **Autonomous Crash Analysis**
  - Automatic capture of crash logs (Data Abort, Kernel Panic, Hard Fault, etc.)
  - Source code location using `addr2line` and symbol tables
  - AI-generated root cause analysis and fix proposals

- 🔄 **Closed-Loop Remediation**
  - Crash → Analyze → Propose Fix → Recompile → Redeploy
  - Template-based reporting for consistent output quality

- 🛡️ **Safety Mechanisms**
  - OS state detection to prevent accidental interference
  - Resource cleanup (TFTP server termination)
  - Timeout protection on all blocking operations

---

## 🏗️ Project Structure

```
AutoEmbedDebugger/
├── SKILL.md                    # Core instruction set & workflow state machine
├── template.md                 # Crash analysis report template
├── examples/
│   └── sample.md               # Few-shot learning example
└── scripts/
    └── validate.sh             # Environment pre-check script
```

### Component Details

| Component | Description |
|-----------|-------------|
| `SKILL.md` | System prompt defining the 4-phase workflow and safety constraints |
| `template.md` | Standardized template for crash analysis reports |
| `examples/sample.md` | Example output demonstrating expected analysis quality |
| `scripts/validate.sh` | Pre-flight check for dependencies, permissions, and ports |

---

## 🔄 Workflow Phases

The agent operates through a sequential 4-phase state machine:

### Phase 1: Environment Setup & TFTP Server
1. Verify firmware directory and binary existence
2. Launch background TFTP server bound to firmware directory
3. **Critical**: Capture TFTP server PID for cleanup

### Phase 2: Serial Connection & U-boot Verification
1. Send `\r\n` to serial port and read response
2. **State Detection**:
   - ✅ `=>` or `U-Boot>` detected → Proceed to Phase 3
   - ⚠️ Login prompt or OS shell → **STOP** & request manual reset
   - ❌ No response → Check connections and reset board

### Phase 3: Network Config & Firmware Deployment
1. Configure network (`setenv ipaddr`, `setenv serverip`)
2. Verify connectivity with `ping`
3. Download firmware via `tftpboot <LOAD_ADDR> <BINARY_NAME>`
4. Execute boot command `<BOOT_CMD>`

### Phase 4: Runtime Monitoring & Auto-Remediation
1. Continuously monitor serial output for 5-15 seconds
2. **Log Analysis**:
   - ✅ Normal execution → Report success, kill TFTP, terminate
   - ❌ Crash detected → Capture logs, analyze source, propose fix, ask user for recompilation

---

## 📖 Usage Guide

### Prerequisites

- Python 3.7+
- pyserial library: `pip install pyserial`
- tftpy library (optional): `pip install tftpy`
- Serial port access (e.g., `/dev/ttyUSB0`, `COM3`)
- TFTP client on target hardware (U-boot)

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/AutoEmbedDebugger.git
   cd AutoEmbedDebugger
   ```

2. **Run environment validation**:
   ```bash
   chmod +x scripts/validate.sh
   ./scripts/validate.sh /dev/ttyUSB0
   ```

3. **Invoke the skill** (in Claude Code or compatible AI assistant):
   ```
   Run the universal-serial-debugger skill.
   Firmware is at ./build/app.bin,
   load address is 0x80000000,
   serial port is /dev/ttyUSB0.
   ```

4. **Agent executes automatically** through all 4 phases

### Core Parameters

Before deployment, ensure these variables are configured:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `FIRMWARE_DIR` | Directory containing compiled binary | `./build` |
| `BINARY_NAME` | Filename to transfer | `zImage`, `app.bin` |
| `LOAD_ADDR` | Target RAM address for TFTP | `0x80000000` |
| `BOOT_CMD` | Command to execute binary | `bootm 0x80000000` |
| `SERIAL_PORT` | Serial device path + baud rate | `/dev/ttyUSB0@115200` |

---

## 🛡️ Safety Constraints

- **Timeout Protection**: All serial reads use non-blocking I/O with configurable timeouts (default: 2s)
- **Read-Only Mode After Boot**: Once `<BOOT_CMD>` is issued, interaction switches to monitoring only
- **Resource Cleanup**: TFTP server process is always killed on task completion (success or failure)
- **OS State Guard**: Detects if target OS is running and halts to prevent data corruption

---

## 🧪 Testing Status

### Current Capabilities ✅
- [x] Environment validation script
- [x] TFTP server lifecycle management
- [x] Serial port state detection
- [x] U-boot command execution framework
- [x] Crash log capture and parsing
- [x] Template-based report generation

### Known Limitations ⚠️
- [ ] Tested primarily on ARM Cortex-A/M platforms
- [ ] Limited testing with RTOS environments (FreeRTOS, RT-Thread)
- [ ] Symbol table resolution requires `.elf` or `.map` files
- [ ] Windows COM port support needs additional testing
- [ ] Multi-board concurrent debugging not supported
- [ ] Error recovery after partial failure may be incomplete

### Platform Compatibility
| Platform | Status | Notes |
|----------|--------|-------|
| Linux (Ubuntu 20.04+) | ✅ Verified | Primary development platform |
| macOS (Monterey+) | ⚠️ Partial | TFTP server may need adjustment |
| Windows 10/11 | ⚠️ Experimental | COM port handling differs |

---

## 📊 Example Output

When a crash is detected, the agent generates a structured report:

```markdown
🐛 Crash Analysis Report

1. Exception Overview
   - Trigger Phase: OS Runtime (Application Init)
   - Error Type: Data Abort (Memory Access Violation)
   - PC Address: 0x30005abc

2. Log Snippet
   [0.130] **Data Abort Exception**
   [0.130] PC = 0x30005abc, LR = 0x30005a98

3. Root Cause Analysis
   Suspect File: src/drivers/gpio.c (Line 45)
   Reason: NULL pointer dereference after failed ioremap()

4. Proposed Fix
   diff --git a/src/drivers/gpio.c b/src/drivers/gpio.c
   @@ -27,6 +27,10 @@
    gpio_base = ioremap(GPIO_BASE_ADDR, 0x1000);
   +
   + if (gpio_base == NULL) {
   +     return -ENOMEM;
   + }
```

See [examples/sample.md](./examples/sample.md) for complete example.

---

## 🔧 Technical Architecture

### Cross-Language Collaboration
```
┌─────────────────────────────────────┐
│           LLM Agent (SKILL.md)      │ ← Task Planner
│         Generates dynamic scripts    │
└─────────────┬───────────────────────┘
              │
    ┌─────────┴─────────┐
    ▼                   ▼
┌────────┐        ┌──────────┐
│  Bash  │        │  Python  │
│        │        │          │
│ • TFTP │        │ • Serial │
│ • PID  │        │ • Log    │
│ • Kill │        │ • Parse  │
└────────┘        └──────────┘
Scheduler           Executor
```

### Deadlock Defense
All dynamically generated Python scripts enforce:
- Non-blocking reads with `ser.in_waiting` checks
- Timeout loops using `time.time()` comparison
- Graceful degradation on communication failures

---

## 🤝 Contributing

Contributions are welcome! Please note this is an **experimental project**:

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Test thoroughly on your hardware platform
4. Submit pull request with test results

### Areas Needing Help
- Windows platform testing and bug fixes
- Additional RTOS environment support
- Extended crash pattern recognition
- Documentation improvements

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

**THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.**

Use at your own risk. The authors are not responsible for:
- Hardware damage from incorrect commands
- Data loss during debugging sessions
- Unexpected behavior on untested platforms
- Production environment failures

Always validate automated suggestions before applying them to critical systems.

---

## 🙏 Acknowledgments

- Inspired by modern AI-assisted development workflows
- Built for embedded developers tired of repetitive manual debugging
- Designed to bridge the gap between code editors and hardware terminals

---

<div align="center">

**⭐ Star this repository if you find it useful!**

*Questions? Issues? Feel free to open an issue or discussion.*

[Report Bug](../../issues/new?labels=bug&template=bug_report.md) ·
[Request Feature](../../issues/new?label=enhancement&template=feature_request.md) ·
[View Examples](./examples/sample.md)

</div>
