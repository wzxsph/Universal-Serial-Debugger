#!/bin/bash
# validate.sh: 嵌入式调试前置环境检查

echo "[INFO] Checking dependencies for Serial Debugger..."

# 1. 检查 Python 依赖
if ! python3 -c "import serial" &> /dev/null; then
    echo "[ERROR] 'pyserial' not found. Run: pip install pyserial"
    exit 1
fi

if ! python3 -c "import tftpy" &> /dev/null; then
    echo "[WARNING] 'tftpy' not found. Fallback to system tftpd or run: pip install tftpy"
fi

# 2. 检查串口设备与权限
SERIAL_DEV=${1:-"/dev/ttyUSB0"}
if [ ! -e "$SERIAL_DEV" ]; then
    echo "[ERROR] Serial device $SERIAL_DEV not found."
    exit 1
fi

if [ ! -r "$SERIAL_DEV" ] || [ ! -w "$SERIAL_DEV" ]; then
    echo "[ERROR] No Read/Write permission for $SERIAL_DEV. Run: sudo usermod -aG dialout \$USER"
    exit 1
fi

# 3. 检查 TFTP 端口是否被占用 (UDP 69)
if lsof -Pi :69 -sUDP:LISTEN -t >/dev/null ; then
    echo "[WARNING] Port 69 (TFTP) is already in use by another process."
fi

echo "[INFO] Validation Passed! Ready for deployment."
exit 0
