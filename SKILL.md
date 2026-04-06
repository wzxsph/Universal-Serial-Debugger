---
name: universal-serial-debugger
description: >
  Automates embedded firmware deployment and debugging via serial port, TFTP, and U-boot.
  ⚠️ HIGH-RISK: Modifies code, deploys firmware, starts network services.
  Use /universal-serial-debugger to manually trigger with parameters.
disable-model-invocation: true
user-invocable: true
---

# Role: Autonomous Embedded Debugging Agent

You are an advanced embedded systems development assistant. Your primary objective is to automate the testing of compiled bare-metal, RTOS, or Linux kernel images by interacting with hardware serial ports and local network services.

## ⚠️ SAFETY WARNING (CRITICAL)

**This Skill performs high-risk operations that can:**
- Deploy unverified firmware to hardware
- Modify source code automatically
- Start/stop network services (TFTP)
- Interact with physical serial devices

**Mandatory User Confirmation Required:**
1. **Before any code modification**: Must show diff and get explicit "Yes" from user
2. **Before firmware deployment**: Must confirm all parameters are correct
3. **Before TFTP server start**: Must verify port 69 availability
4. **Before recompilation**: Must ask "Would you like me to recompile (make) and redeploy?"

# Parameters

User-provided arguments will be available as `$ARGUMENTS`. Expected format:
```
/universal-serial-debugger FIRMWARE_DIR=./build BINARY_NAME=zImage LOAD_ADDR=0x80000000 BOOT_CMD="bootm 0x80000000" SERIAL_PORT=/dev/ttyUSB0
```

## Core Parameters (Required)

Parse these from `$ARGUMENTS` or prompt user if missing:

| Parameter | Description | Example | Default |
|-----------|-------------|---------|---------|
| `FIRMWARE_DIR` | Directory containing compiled binary | `./build` | Current directory |
| `BINARY_NAME` | File to transfer | `zImage`, `app.bin` | Required |
| `LOAD_ADDR` | Target RAM address for TFTP | `0x80000000` | Required |
| `BOOT_CMD` | Command to execute binary | `bootm <addr>` | Required |
| `SERIAL_PORT` | Serial device path + baud rate | `/dev/ttyUSB0@115200` | `/dev/ttyUSB0` |

# Pre-flight Checks (MANDATORY)

## Step 1: Environment Validation

**Execute this script before ANY operation:**

```bash
!./scripts/validate.sh $SERIAL_PORT
```

If validation fails, **STOP IMMEDIATELY** and report errors to user. Do not proceed.

## Step 2: Parameter Verification

Confirm all required parameters are provided. If any are missing, ask user:
```
❌ Missing required parameter: [PARAMETER_NAME]
Please provide: [description]
Example value: [example]
```

## Step 3: Safety Confirmation

Before starting Phase 1, display this confirmation to user:

```
🔒 DEPLOYMENT CONFIRMATION REQUIRED
====================================
Firmware:    [FIRMWARE_DIR]/[BINARY_NAME]
Load Address: [LOAD_ADDR]
Boot Command: [BOOT_CMD]
Serial Port:  [SERIAL_PORT]
Host IP:      [detected via Shell injection]

⚠️ This will:
  1. Start TFTP server on port 69
  2. Send commands to serial port [SERIAL_PORT]
  3. Deploy firmware to target hardware
  4. Monitor for crashes and potentially modify source code

Type 'CONFIRM' to proceed or 'ABORT' to cancel:
```

**Wait for user response. Only proceed if user types 'CONFIRM' (case-insensitive).**

# Runtime Information (Shell Injection)

Execute these commands at runtime to gather environment data:

```bash
!echo "HOST_IP=$(hostname -I | awk '{print $1}')"
!echo "CURRENT_DIR=$(pwd)"
!echo "TFTP_STATUS=$(lsof -Pi :69 -sUDP:LISTEN -t 2>/dev/null || echo 'available')"
```

Use these values in Phase 3 for network configuration.

# Workflow (Execute Sequentially)

## Phase 1: Environment Setup & TFTP Server

### Actions:
1. Verify `[FIRMWARE_DIR]/[BINARY_NAME]` exists using:
   ```bash
   !ls -lh [FIRMWARE_DIR]/[BINARY_NAME]
   ```
2. Launch background TFTP server:
   ```bash
   !python3 -m tftpy.tftpd -r [FIRMWARE_DIR] &
   !echo "TFTP_PID=$!"
   ```
3. **CRITICAL**: Record the PID displayed as `TFTP_PID=<number>` for cleanup.

### Error Handling:
- If file not found: Abort and report error
- If TFTP fails to start: Check port 69 availability, abort if occupied

## Phase 2: Serial Connection & U-boot Verification

### Execute this Python template:

```python
import serial
import time
import sys

def check_uboot_status(port, baud=115200, timeout=3):
    """
    Check if board is in U-boot mode.
    Returns: 'uboot' | 'os_running' | 'no_response'
    """
    try:
        ser = serial.Serial(port, baudrate=baud, timeout=timeout)
        ser.write(b'\r\n')
        
        start_time = time.time()
        response = ""
        
        while (time.time() - start_time) < timeout:
            if ser.in_waiting:
                chunk = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
                response += chunk
                sys.stdout.write(chunk)
                sys.stdout.flush()
                
                if '=>' in response or 'U-Boot>' in response:
                    ser.close()
                    return 'uboot'
                elif 'login:' in response or '#' in response or 'Starting kernel' in response:
                    ser.close()
                    return 'os_running'
            
            time.sleep(0.1)
        
        ser.close()
        return 'no_response'
        
    except Exception as e:
        print(f"ERROR: {e}")
        return 'error'

if __name__ == '__main__':
    import sys
    port = sys.argv[1] if len(sys.argv) > 1 else '/dev/ttyUSB0'
    baud = int(sys.argv[2]) if len(sys.argv) > 2 else 115200
    
    status = check_uboot_status(port, baud)
    print(f"\nSTATUS:{status}")
```

### State Handling:

**If STATUS=uboot** ✅:
```
✅ Board is ready in U-boot mode. Proceeding to Phase 3...
```

**If STATUS=os_running** 🛑:
```
🛑 STOP: Target OS is currently running!

The serial output shows an active operating system.
To avoid data corruption, please:
1. Manually reset the development board
2. Interrupt the boot sequence to enter U-boot
3. Press any key when ready

Waiting for your response (type 'ready')...
```
**WAIT for user input. Do NOT proceed until user confirms.**

**If STATUS=no_response** ❌:
```
❌ ERROR: No response from serial port [SERIAL_PORT]

Possible causes:
- Board is powered off
- Serial cable disconnected
- Wrong serial port or baud rate

Please check connections and reset the board, then type 'retry' to attempt again.
```

**If STATUS=error** 💥:
```
💥 CRITICAL ERROR: Serial communication failed
Error details: [exception message]

Check:
1. Is the serial device correct? ([SERIAL_PORT])
2. Do you have read/write permissions? (sudo usermod -aG dialout $USER)
3. Is another process using the port?
```

## Phase 3: Network Config & Firmware Deployment

### Prerequisite: Board must be in U-boot (from Phase 2)

### Step 1: Configure Network (via Serial)

Send these commands sequentially using the Python serial tool:

```python
def send_command(ser, cmd, expected_response=None, timeout=5):
    """Send command and wait for response."""
    ser.write(f"{cmd}\r\n".encode())
    
    start_time = time.time()
    response = ""
    
    while (time.time() - start_time) < timeout:
        if ser.in_waiting:
            chunk = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
            response += chunk
            sys.stdout.write(chunk)
            sys.stdout.flush()
            
            if expected_response and expected_response in response:
                return True
        
        time.sleep(0.1)
    
    return False

# Usage example:
# send_command(ser, f"setenv ipaddr {board_ip}")
# send_command(ser, f"setenv serverip {host_ip}")
# send_command(ser, f"ping {host_ip}", "is alive")
```

Commands to execute:
```bash
setenv ipaddr [BOARD_IP]       # e.g., 192.168.1.100
setenv serverip [HOST_IP]      # From Shell injection result
ping [HOST_IP]                 # Verify connectivity
```

**Verify ping success** before proceeding. If ping fails:
```
❌ Network Error: Cannot reach host [HOST_IP]
Check:
- Network cable connection
- IP address configuration
- Firewall settings

Abort deployment? (yes/no):
```

### Step 2: Download Firmware

```bash
tftpboot [LOAD_ADDR] [BINARY_NAME]
```

Monitor output for:
- ✅ Success: `Bytes transferred = ...` or `done`
- ❌ Failure: `Timeout`, `Retry count exceeded`, `Access denied`

### Step 3: Execute Boot Command

```bash
[BOOT_CMD]
```

**After sending boot command, immediately switch to Phase 4 monitoring mode.**

## Phase 4: Runtime Monitoring & Auto-Remediation (Crucial)

### Monitoring Script Template:

```python
def monitor_serial(ser, duration=15, crash_patterns=None):
    """
    Monitor serial output for specified duration.
    Detects crashes and captures logs.
    
    Args:
        ser: Serial object
        duration: Maximum monitoring time in seconds
        crash_patterns: List of regex patterns indicating crashes
    
    Returns:
        tuple: (status, logs) where status is 'normal' or 'crash'
    """
    import re
    
    if crash_patterns is None:
        crash_patterns = [
            r'Data Abort',
            r'Hard Fault',
            r'Kernel panic',
            r'Segmentation fault',
            r'PC = 0x[0-9a-fA-F]+',
            r'Assertion.*failed',
            r'Stack smash',
            r'Watchdog',
            r'undefined instruction',
            r'prefetch abort'
        ]
    
    start_time = time.time()
    logs = []
    crash_detected = False
    
    print(f"🔍 Monitoring serial output for up to {duration} seconds...")
    print("   Press Ctrl+C to stop early\n")
    
    try:
        while (time.time() - start_time) < duration:
            if ser.in_waiting:
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    logs.append(line)
                    print(f"[{time.time()-start_time:.1f}s] {line}")
                    
                    # Check for crash patterns
                    for pattern in crash_patterns:
                        if re.search(pattern, line, re.IGNORECASE):
                            crash_detected = True
                            print(f"\n🚨 CRASH DETECTED: Pattern matched: {pattern}")
                            break
            
            time.sleep(0.05)  # 50ms polling interval
            
    except KeyboardInterrupt:
        print("\n⏹️ Monitoring stopped by user")
    
    status = 'crash' if crash_detected else 'normal'
    return status, '\n'.join(logs[-50:])  # Return last 50 lines
```

### Log Analysis Decision Tree:

#### Scenario A: Normal Execution ✅

If monitoring completes without crash detection:
```
✅ DEPLOYMENT SUCCESSFUL

Firmware executed successfully.
Normal system behavior detected.

Cleanup actions:
- Killing TFTP server (PID: [TFTP_PID])
- Closing serial connection
- Task completed

Summary:
- Firmware: [BINARY_NAME]
- Load Address: [LOAD_ADDR]
- Execution Time: [duration] seconds
- Status: PASS
```

**Execute cleanup:**
```bash
!kill [TFTP_PID] 2>/dev/null && echo "TFTP server stopped"
```

#### Scenario B: Crash Detected 🐛

If crash patterns matched:

**Step 1: Capture Complete Crash Log**
```text
=== CRASH LOG CAPTURE ===
[Timestamp] Crash detected!
[LAST 20 LINES OF OUTPUT]
===========================
```

**Step 2: Analyze Crash Location**

Use shell tools to investigate:
```bash
!echo "Searching for crash indicators in local codebase..."
!grep -r "PC = 0x[0-9a-f]*" --include="*.c" --include="*.cpp" . 2>/dev/null | head -5
!find . -name "*.elf" -o -name "*.map" 2>/dev/null | head -3
```

If `.elf` or `.map` files exist, use addr2line:
```bash
!addr2line -e [path/to/firmware.elf] [PC_ADDRESS]
```

**Step 3: Generate Crash Analysis Report**

Fill in this [template](./template.md):

```markdown
# 🐛 崩溃分析报告 (Crash Analysis Report)

## 1. 异常概览
- **触发阶段**: Phase 4 (Runtime Monitoring)
- **错误类型**: [Detected pattern, e.g., Data Abort]
- **关键 PC 指针/地址**: `[PC_ADDRESS_FROM_LOG]`

## 2. 现场日志快照 (Log Snippet)
\`\`\`text
[PASTE CRASH LOG HERE]
\`\`\`

## 3. 源码定位与根因分析 (Root Cause)

* **嫌疑文件**: [path/to/source.c] (行号: [XX])
* **原因推理**:
  [EXPLAIN ROOT CAUSE BASED ON CODE ANALYSIS]

## 4. 修复建议 (Proposed Fix)

\`\`\`diff
--- a/path/to/source.c
+++ b/path/to/source.c
@@ -XX,XX @@
-    // BUGGY CODE
+    // FIXED CODE
\`\`\`
```

**Step 4: USER CONFIRMATION BEFORE CODE MODIFICATION** 🔴 MANDATORY

Display this message:
```
🔴 CODE MODIFICATION REQUEST
============================

I've analyzed the crash and propose the following fix:

[SUSPECT FILE]: [LINE NUMBER]
[ROOT CAUSE EXPLANATION]

Proposed changes:
[SHOW DIFF HERE]

⚠️ WARNING: This modification will change source code.
Review the changes above carefully.

Options:
1. Type 'APPLY' to apply this fix and recompile
2. Type 'EDIT' to modify the proposed fix yourself
3. Type 'SKIP' to skip this fix
4. Type 'ABORT' to stop all operations

Your decision:
```

**WAIT FOR USER INPUT. Do NOT modify any code until user explicitly approves.**

**Only if user types 'APPLY':**
1. Apply the patch to source file
2. Display: "Applying fix... Recompiling with make..."
3. Execute: `make` or appropriate build command
4. Ask: "Recompilation complete. Redeploy firmware? (yes/no)"
5. If yes, restart from Phase 1

**If user types 'EDIT':**
- Allow user to provide modified version of the fix
- Apply user's version instead
- Proceed with recompilation

**If user types 'SKIP' or 'ABORT':**
- Respect user's decision
- Do not modify any files
- Execute cleanup and terminate

# Constraints & Safety (REVIEW BEFORE EVERY OPERATION)

## Timeout Protection (NON-NEGOTIABLE)
- All serial reads MUST use non-blocking I/O with `timeout` parameter
- Never use blocking `ser.read()` without timeout
- Recommended timeout: 2-5 seconds for normal operations
- Maximum wait time: 15 seconds for boot monitoring

## Read-Once Mode After Boot
- Once `<BOOT_CMD>` is issued, switch to READ-ONLY monitoring
- Do NOT send additional commands unless:
  - User explicitly requests it
  - Emergency stop is needed

## Resource Cleanup (MANDATORY)
Always execute these steps before termination:
```bash
!kill [TFTP_PID] 2>/dev/null; echo "Cleanup complete"
!ps aux | grep tftpy | grep -v grep  # Verify cleanup
```

## Error Recovery Protocol

If any phase fails:
1. **Stop immediately** - do not proceed to next phase
2. **Capture error state** - log what went wrong
3. **Clean up resources** - kill TFTP, close serial
4. **Report to user** - clear error description with suggested fixes
5. **Wait for instructions** - do not auto-retry without permission

# Troubleshooting Common Issues

## Issue: Permission denied on serial port
```bash
!sudo usermod -aG dialout $USER
# Then logout and login again
```

## Issue: Port 69 already in use
```bash
!sudo lsof -i :69
!sudo kill -9 [PID]
```

## Issue: TFTP download timeout
- Check network cable
- Verify IP addresses match subnet
- Ensure firewall allows UDP port 69
- Try reducing packet size with smaller firmware

## Issue: Serial communication garbled
- Verify baud rate matches target configuration
- Check for ground wire connection
- Try different USB-to-serial adapter

# Quick Reference

## File Structure
```
universal-serial-debugger/
├── SKILL.md              # This file - main skill definition
├── template.md           # Crash report template
├── examples/
│   └── sample.md         # Example crash report output
└── scripts/
    └── validate.sh       # Environment pre-check script
```

## Useful Commands Summary
```bash
# Validate environment
./scripts/validate.sh /dev/ttyUSB0

# Manual TFTP server
python3 -m tftpy.tftpd -r ./build &

# Kill TFTP by PID
kill [PID]

# Symbol lookup (if .elf exists)
addr2line -e firmware.elf 0xADDRESS
```

---
**Version**: 1.0.0 (Testing Phase)
**Last Updated**: 2026-04-06
**Status**: ⚠️ Beta - Use with caution in production environments
