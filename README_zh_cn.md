<p align="center">
  中文 | <a href="./README.md">English</a>
</p>

<div align="center">

# 🤖 AutoEmbedDebugger
### *通用串口自动化嵌入式调试 Agent*

**⚠️ 当前状态：[测试阶段 / Beta] - 稳定性尚未验证**

[![阶段: 测试中](https://img.shields.io/badge/阶段-测试中-orange)](https://github.com/yourusername/AutoEmbedDebugger)
[![许可证: MIT](https://img.shields.io/badge/许可证-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)
[![平台支持](https://img.shields.io/badge/支持平台-Linux%20%7C%20macOS-lightgrey)]()

</div>

---

## 📋 项目简介

**AutoEmbedDebugger** 是一个专为嵌入式系统开发者设计的 AI 驱动自主调试 Agent。它通过串口通信、TFTP 网络传输和 U-boot 引导加载器交互，实现了**固件部署 → 运行监控 → 崩溃分析 → 源码修复建议**的全链路闭环调试能力。

本项目有效解决了嵌入式开发中的痛点：
- ❌ 频繁手动复位开发板
- ❌ 敲击繁琐的 U-boot 命令
- ❌ 跨终端（代码编辑器 ↔ 串口终端）比对报错日志
- ❌ 手动定位崩溃原因耗时耗力

> **⚠️ 重要提示**: 本项目目前处于**测试阶段**。虽然核心功能已实现，但在不同硬件平台和边缘情况下的稳定性尚未完全验证。请在生产环境中谨慎使用。

---

## ✨ 核心特性

### 🚀 自动化固件部署
- TFTP 服务器自动启动与 PID 管理
- 通过 U-boot 命令自动配置网络参数
- 固件下载与引导启动一键执行

### 🔌 智能串口通讯
- **自动状态检测**：识别 U-boot / OS运行 / 无响应三种状态
- **非阻塞 I/O**：所有读取操作均设置严格超时约束
- **实时日志流**：持续监控并检测崩溃模式

### 🐛 自主崩溃分析
- **自动捕获崩溃日志**：Data Abort、Kernel Panic、Hard Fault 等
- **源码精确定位**：使用 `addr2line` 和符号表解析崩溃地址
- **AI 驱动的根因分析**：结合 LLM 的代码理解能力生成修复建议

### 🔄 闭环修复流程
```
崩溃发生 → 日志捕获 → 源码定位 → 根因分析 → 提出修复方案 → 用户确认 → 重新编译 → 再次部署
```
基于模板的报告输出确保一致性和专业性。

### 🛡️ 安全机制
- **OS 状态保护**：检测到目标 OS 运行时立即停止，防止误操作
- **资源清理保障**：任务结束时自动终止 TFTP 服务进程
- **超时死锁防御**：所有阻塞操作均配置超时保护

---

## 🏗️ 项目结构

```
AutoEmbedDebugger/
├── SKILL.md                    # 核心指令集 & 工作流状态机
├── template.md                 # 崩溃分析报告模板
├── examples/
│   └── sample.md               # Few-Shot 学习示例
└── scripts/
    └── validate.sh             # 环境预检脚本
```

### 组件说明

| 组件 | 功能描述 |
|------|----------|
| `SKILL.md` | Agent 的 System Prompt，定义四阶段工作流和安全约束 |
| `template.md` | 标准化的崩溃分析报告模板（强制 Agent 遵循） |
| `examples/sample.md` | 完整的输出示例，展示期望的分析质量 |
| `scripts/validate.sh` | 部署前环境检查（依赖、权限、端口） |

---

## 🔄 四阶段工作流

Agent 采用严格的顺序状态机执行：

### Phase 1: 环境准备 & TFTP 服务器
1. ✅ 验证固件目录和二进制文件存在性
2. 🚀 启动后台 TFTP 服务器并绑定到固件目录
3. ⚠️ **关键**：必须捕获 TFTP 进程 PID 用于后续清理

### Phase 2: 串口连接 & U-boot 状态验证
1. 📡 向串口发送 `\r\n` 并读取响应
2. 🔍 **状态判断**：
   - ✅ 检测到 `=>` 或 `U-Boot>` → 进入 Phase 3
   - ⚠️ 检测到登录提示或 OS Shell → **立即停止**，请求手动复位
   - ❌ 无响应 → 提示检查连接并复位板卡

### Phase 3: 网络配置 & 固件部署
1. 🌐 配置网络参数：`setenv ipaddr`, `setenv serverip`
2. ✅ 执行 `ping` 验证连通性
3. 📥 通过 `tftpboot <LOAD_ADDR> <BINARY_NAME>` 下载固件
4. ▶️ 执行引导命令 `<BOOT_CMD>`

### Phase 4: 运行监控 & 自动修复（核心）
1. 👁️ 持续监控串口输出 5-15 秒
2. **智能分析**：
   - ✅ 正常执行 → 报告成功，终止 TFTP，结束任务
   - ❌ 检测到崩溃 → 
     1. 捕获完整崩溃日志（寄存器堆栈、PC 地址、调用栈）
     2. 使用工具搜索本地 C/C++/Rust 代码库定位问题
     3. 解释根因并提出代码修改建议
     4. 询问用户："是否重新编译 (`make`) 并再次运行？"

---

## 📖 使用指南

### 环境要求

- Python 3.7+
- pyserial 库：`pip install pyserial`
- tftpy 库（可选）：`pip install tftpy`
- 串口设备访问权限（如 `/dev/ttyUSB0`、`COM3`）
- 目标硬件需支持 TFTP 客户端（U-boot）

### 快速开始

1. **克隆仓库**：
   ```bash
   git clone https://github.com/yourusername/AutoEmbedDebugger.git
   cd AutoEmbedDebugger
   ```

2. **运行环境检查**：
   ```bash
   chmod +x scripts/validate.sh
   ./scripts/validate.sh /dev/ttyUSB0
   ```

3. **调用 Skill**（在 Claude Code 或兼容的 AI 助手中）：
   ```
   Run the universal-serial-debugger skill.
   Firmware is at ./build/app.bin,
   load address is 0x80000000,
   serial port is /dev/ttyUSB0.
   ```

4. **Agent 将自动完成**全部四个阶段的操作

### 核心参数说明

部署前请确保以下变量已正确配置：

| 参数 | 说明 | 示例 |
|------|------|------|
| `FIRMWARE_DIR` | 包含编译后二进制文件的目录 | `./build` |
| `BINARY_NAME` | 待传输的文件名 | `zImage`, `app.bin` |
| `LOAD_ADDR` | TFTP 下载的目标 RAM 地址 | `0x80000000` |
| `BOOT_CMD` | 执行二进制文件的命令 | `bootm 0x80000000` |
| `SERIAL_PORT` | 串口设备路径 + 波特率 | `/dev/ttyUSB0@115200` |

---

## 🛡️ 安全约束

- **超时保护**：所有串口读取均采用非阻塞 I/O，默认超时 2 秒
- **只读模式**：一旦发出 `<BOOT_CMD>`，交互切换为纯监控模式
- **资源清理**：无论任务成功或失败，TFTP 服务器进程都会被终止
- **OS 状态守护**：检测到目标 OS 运行时立即挂起，防止数据损坏

---

## 🧪 测试状态

### 已实现功能 ✅
- [x] 环境依赖验证脚本
- [x] TFTP 服务器生命周期管理
- [x] 串口端口状态自动检测
- [x] U-boot 命令执行框架
- [x] 崩溃日志捕获与解析
- [x] 基于模板的报告生成

### 已知限制 ⚠️
- [ ] 主要在 ARM Cortex-A/M 平台测试
- [ ] RTOS 环境（FreeRTOS、RT-Thread）的测试有限
- [ ] 符号表解析需要 `.elf` 或 `.map` 文件
- [ ] Windows COM 端口支持需要额外测试
- [ ] 不支持多板卡并发调试
- [ ] 部分失败后的错误恢复可能不完整

### 平台兼容性

| 平台 | 状态 | 备注 |
|------|------|------|
| Linux (Ubuntu 20.04+) | ✅ 已验证 | 主要开发和测试平台 |
| macOS (Monterey+) | ⚠️ 部分 | TFTP 服务器可能需要调整 |
| Windows 10/11 | ⚠️ 实验性 | COM 端口处理方式不同 |

---

## 📊 输出示例

当检测到崩溃时，Agent 会生成结构化报告：

```markdown
🐛 崩溃分析报告

1. 异常概览
   - 触发阶段: OS 运行阶段 (应用初始化)
   - 错误类型: Data Abort (数据访问异常)
   - PC 指针地址: 0x30005abc

2. 现场日志快照
   [0.130] **Data Abort Exception**
   [0.130] PC = 0x30005abc, LR = 0x30005a98

3. 源码定位与根因分析
   嫌疑文件: src/drivers/gpio.c (第 45 行)
   原因: ioremap() 失败后的空指针解引用

4. 修复建议
   diff --git a/src/drivers/gpio.c b/src/drivers/gpio.c
   @@ -27,6 +27,10 @@
    gpio_base = ioremap(GPIO_BASE_ADDR, 0x1000);
   +
   + if (gpio_base == NULL) {
   +     return -ENOMEM;
   + }
```

查看 [examples/sample.md](./examples/sample.md) 获取完整示例。

---

## 🔧 技术架构

### 跨语言协作机制
```
┌─────────────────────────────────────┐
│         LLM Agent (SKILL.md)        │ ← 任务规划者
│       动态生成临时脚本               │
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
  调度器              执行器
```

### 死锁防御机制
所有动态生成的 Python 脚本都强制执行：
- 使用 `ser.in_waiting` 进行非阻塞读取
- 使用 `time.time()` 比较实现超时循环
- 通信失败时的优雅降级处理

---

## 🤝 参与贡献

欢迎贡献代码！请注意本项目是**实验性项目**：

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/new-feature`
3. 在你的硬件平台上充分测试
4. 提交 Pull Request 并附上测试结果

### 我们需要帮助的方向
- Windows 平台测试和 Bug 修复
- 更多 RTOS 环境支持
- 扩展崩溃模式识别能力
- 文档改进和翻译

---

## 📄 许可证

本项目基于 **MIT 许可证** 开源 - 详见 [LICENSE](LICENSE) 文件。

---

## ⚠️ 免责声明

**本软件按"原样"提供，不提供任何形式的明示或暗示担保，包括但不限于适销性担保、特定用途适用性担保和非侵权担保。**

风险自担。作者不对以下情况负责：
- 因错误命令导致的硬件损坏
- 调试会话期间的数据丢失
- 未测试平台上的意外行为
- 生产环境的故障

在将自动化建议应用到关键系统之前，请务必进行人工验证。

---

## 🙏 致谢

- 受现代 AI 辅助开发工作流的启发
- 为厌倦重复手工调试的嵌入式开发者而构建
- 致力于弥合代码编辑器和硬件终端之间的鸿沟

---

<div align="center">

**如果觉得有用，请给这个仓库点个 Star ⭐！**

*有问题？建议？欢迎提 Issue 或参与讨论。*

[报告 Bug](../../issues/new?labels=bug&template=bug_report.md) ·
[功能请求](../../issues/new?label=enhancement&template=feature_request.md) ·
[查看示例](./examples/sample.md)

</div>
