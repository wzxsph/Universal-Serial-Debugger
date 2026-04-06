# **技术方案：Universal Serial Debugger (通用串口自动化调试 Agent)**

## **1\. 方案概述**

**Universal Serial Debugger** 是一个专为嵌入式开发者设计的自动化 AI Agent Skill（适用于 Claude Code 等本地 AI 编程助手）。该方案通过大语言模型的任务规划能力，结合本地宿主机的 Bash 和 Python 执行环境，实现了\*\*“固件编译 \-\> TFTP网络下发 \-\> U-boot引导启动 \-\> 串口日志监控 \-\> 源码级崩溃分析与修复”\*\*的全链路闭环调试能力。

本方案有效解决了嵌入式开发中频繁手动复位、敲击繁琐 U-boot 命令以及跨终端（代码编辑器与串口终端）比对报错日志的痛点。

## **2\. 工程目录架构设计**

该 Skill 作为一个独立的模块，遵循标准的结构化设计：

universal-serial-debugger/  
├── SKILL.md           \# 核心指令集：定义 Agent 的角色、工作流状态机和安全约束  
├── template.md        \# 模板文件：规范 Agent 输出崩溃分析报告和修复建议的格式  
├── examples/  
│   └── sample.md      \# 示例输出：提供一个 few-shot 示例，约束 AI 的输出质量  
└── scripts/  
    └── validate.sh    \# 预检脚本：Agent 在启动 Phase 1 前执行的环境依赖检查

### **2.1 组件功能详解**

#### **2.1.1 SKILL.md (大脑 & 状态机)**

作为 Agent 的 System Prompt，采用四阶段状态机（Phase 1\~4）严格控制操作流。通过明确的 If-Else 条件（如遇到 root@ 立即挂起等待人工干预），确保硬件操作的安全性。

#### **2.1.2 scripts/validate.sh (环境预检)**

为了防止运行时报错，AI 在执行主流程前应首先调用此脚本。它负责检查宿主机环境。

**设计实现：**

\#\!/bin/bash  
\# validate.sh: 嵌入式调试前置环境检查

echo "\[INFO\] Checking dependencies for Serial Debugger..."

\# 1\. 检查 Python 依赖  
if \! python3 \-c "import serial" &\> /dev/null; then  
    echo "\[ERROR\] 'pyserial' not found. Run: pip install pyserial"  
    exit 1  
fi

if \! python3 \-c "import tftpy" &\> /dev/null; then  
    echo "\[WARNING\] 'tftpy' not found. Fallback to system tftpd or run: pip install tftpy"  
fi

\# 2\. 检查串口设备与权限  
SERIAL\_DEV=${1:-"/dev/ttyUSB0"}  
if \[ \! \-e "$SERIAL\_DEV" \]; then  
    echo "\[ERROR\] Serial device $SERIAL\_DEV not found."  
    exit 1  
fi

if \[ \! \-r "$SERIAL\_DEV" \] || \[ \! \-w "$SERIAL\_DEV" \]; then  
    echo "\[ERROR\] No Read/Write permission for $SERIAL\_DEV. Run: sudo usermod \-aG dialout \\$USER"  
    exit 1  
fi

\# 3\. 检查 TFTP 端口是否被占用 (UDP 69\)  
if lsof \-Pi :69 \-sUDP:LISTEN \-t \>/dev/null ; then  
    echo "\[WARNING\] Port 69 (TFTP) is already in use by another process."  
fi

echo "\[INFO\] Validation Passed\! Ready for deployment."  
exit 0

#### **2.1.3 template.md (报告格式化约束)**

在 Phase 4 中，当 Agent 捕获到内核崩溃或应用 Error 时，强制要求其将抓取到的日志与本地代码关联，并填充至此模板中输出给用户。

**设计实现：**

\# 🐛 崩溃分析报告 (Crash Analysis Report)

\#\# 1\. 异常概览  
\- \*\*触发阶段\*\*: \[例如: U-boot 引导阶段 / OS 运行阶段\]  
\- \*\*错误类型\*\*: \[例如: Data Abort / Kernel Panic / Null Pointer\]  
\- \*\*关键 PC 指针/地址\*\*: \`\[如 0x30005abc\]\`

\#\# 2\. 现场日志快照 (Log Snippet)  
\`\`\`text  
{{在此处粘贴导致崩溃的最后 5-10 行串口日志}}

## **3\. 源码定位与根因分析 (Root Cause)**

* **嫌疑文件**: path/to/source.c (行号: XX)  
* **原因推理**:  
  {{Agent 在此解释导致崩溃的 C/C++ 逻辑原因，如访问了未初始化的外设寄存器}}

## **4\. 修复建议 (Proposed Fix)**

\--- a/path/to/source.c  
\+++ b/path/to/source.c  
@@ \-XX,XX @@  
\-    // 导致错误的原代码  
\+    // 修复后的代码

*提示: 请问是否需要我应用此修改并重新 make? (Yes/No)*

\#\#\#\# 2.1.4 \`examples/sample.md\` (Few-Shot 样本)  
向 Agent 展示一个标准的输出案例，例如遇到 \`Data Abort\` 时的完美汇报长什么样，防止其输出冗长的废话。

\---

\#\# 3\. 核心执行逻辑与技术难点

\#\#\# 3.1 跨语言协作机制  
此方案巧妙利用了 LLM 擅长编写临时代码的特性：  
1\. \*\*Bash 扮演调度者\*\*：用于启停网络服务 (\`tftp\`)，处理文件路径，以及终止后台进程 (\`kill \-9 PID\`)。  
2\. \*\*Python 扮演执行器\*\*：LLM 会根据 \`SKILL.md\` 动态生成带有 \`timeout\` 的 \`serial\_tool.py\` 脚本，用于精细控制读写时序。

\#\#\# 3.2 死锁防御机制 (Timeout Constraints)  
嵌入式设备极易无响应。方案中明确规定 \*\*"Never write blocking serial read functions"\*\*，要求动态生成的 Python 脚本必须采用非阻塞读取：  
\`\`\`python  
\# LLM 预期生成的 Python 串口通讯范例片段  
import serial  
import time  
import sys

def send\_and\_wait(ser, cmd, wait\_for="=\>", timeout=3.0):  
    ser.write(f"{cmd}\\r\\n".encode())  
    start\_time \= time.time()  
    response \= ""  
    while (time.time() \- start\_time) \< timeout:  
        if ser.in\_waiting:  
            chunk \= ser.read(ser.in\_waiting).decode('utf-8', errors='ignore')  
            response \+= chunk  
            sys.stdout.write(chunk)  
            sys.stdout.flush()  
            if wait\_for in response:  
                return True  
        time.sleep(0.1)  
    return False \# Timeout 发生，避免 Agent 永久卡死

### **3.3 闭环自动化 (Closed-loop Remediation)**

Phase 4 是该方案的灵魂。传统的脚本只能做到“把代码传下去跑”，而该 Agent 方案实现了：

1. **监听异常**：匹配正则如 Panic, Abort, Fault。  
2. **符号表解析（隐含能力）**：结合本地的 .map 或 .elf 文件（利用 addr2line 等工具的 bash 命令），将崩溃地址反编译为代码行号。  
3. **AST上下文检索**：读取错误代码的上下文，利用 LLM 的代码理解能力，指出是指针问题还是时序问题。

## **4\. 预期使用流程 (User Journey)**

1. 用户完成代码修改，执行 make 编译出二进制文件。  
2. 用户在终端唤醒 Claude Code (或其他 Agent)，并输入指令：*"Run the universal-serial-debugger skill. Firmware is at ./build/app.bin, load address is 0x80000000. Serial is on /dev/ttyUSB0."*  
3. Agent 静默调用 validate.sh 检查环境。  
4. Agent 启动后台 TFTP 服务，记录 PID。  
5. Agent 检测串口，确认处于 U-boot，发送网络和下载指令。  
6. 板卡启动，若一切正常，Agent 提示“测试通过”并杀掉 TFTP。  
7. **若发生异常**，Agent 终端立刻暂停输出硬件日志，开始分析本地 C 代码，并最终按照 template.md 打印一份包含 Diff 的修复报告，询问用户是否一键应用。