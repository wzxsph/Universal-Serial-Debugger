<p align="center">
  中文 | <a href="./README.md">English</a>
</p>

<div align="center">

# 🤖 Universal-Serial-Debugger
### *AI 驱动的自主嵌入式调试 Agent*

**⚠️ 当前状态：[测试阶段 / Beta] - 稳定性尚未验证**

[![阶段: 测试中](https://img.shields.io/badge/阶段-测试中-orange)](https://github.com/wzxsph/Universal-Serial-Debugger)
[![安全等级: 高风险](https://img.shields.io/badge/安全等级-高风险-red)](https://github.com/wzxsph/Universal-Serial-Debugger/blob/main/SKILL.md#L15-L27)
[![许可证: MIT](https://img.shields.io/badge/许可证-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)
[![平台支持](https://img.shields.io/badge/支持平台-Linux%20%7C%20macOS-lightgrey)]()

</div>

---

## 🔒 安全第一（重要提示）

**此 Skill 被标记为高风险操作，需要手动调用。**

### ⚠️ 为什么是高风险？
此 Skill 执行的操作可能：
- 向物理硬件部署固件
- 自动修改源代码
- 启动/停止网络服务（TFTP 服务器，端口 69）
- 直接与串口设备交互

### 🛡️ 已实现的安全机制

| 保护层 | 描述 | 状态 |
|--------|------|------|
| **禁止自动调用** | AI 无法自动触发此 Skill | ✅ 已激活 |
| **仅限手动触发** | 必须使用 `/universal-serial-debugger` 命令 | ✅ 强制执行 |
| **预检验证** | 任何操作前进行环境检查 | ✅ 必需 |
| **用户确认** | 工作流中有 6+ 个确认节点 | ✅ 必需 |
| **代码审查门控** | 所有修改需要用户明确批准 | ✅ 强制执行 |

### 📋 如何安全使用

```bash
# 第一步：手动调用 Skill 并传入参数
/universal-serial-debugger FIRMWARE_DIR=./build BINARY_NAME=zImage LOAD_ADDR=0x80000000 BOOT_CMD="bootm 0x80000000" SERIAL_PORT=/dev/ttyUSB0

# 第二步：在提示时确认部署（输入 'CONFIRM'）

# 第三步：如果检测到崩溃，审批代码更改（输入 'APPLY' 或 'SKIP'）
```

> **切勿在无人值守模式下运行此 Skill。务必仔细查看每个提示。**

---

## 📋 项目简介

**Universal-Serial-Debugger** 是一个专为嵌入式系统开发者设计的 AI 驱动自主调试 Agent。它通过串口通信、TFTP 网络传输和 U-boot 引导加载器交互，实现了**固件部署 → 运行监控 → 崩溃分析 → 源码修复建议（需用户审批）→ 重新编译 → 再次部署**的全链路闭环调试能力。

### 核心能力

1. **自动化固件部署**
   - TFTP 服务器自动启动与 PID 管理
   - 通过 U-boot 命令自动配置网络参数
   - 固件下载与引导启动一键执行

2. **智能串口通讯**
   - **自动状态检测**：识别 U-boot / OS运行 / 无响应三种状态
   - **非阻塞 I/O**：所有读取操作均设置严格超时约束
   - **实时日志流**：持续监控并检测崩溃模式

3. **自主崩溃分析与修复**
   - **自动捕获崩溃日志**：Data Abort、Kernel Panic、Hard Fault 等
   - **源码精确定位**：使用 `addr2line` 和符号表解析崩溃地址
   - **AI 驱动的根因分析**：结合 LLM 的代码理解能力生成修复建议（需用户审批）

4. **闭环调试工作流**
   ```
   部署 → 监控 → 检测崩溃 → 分析 → 提出修复 → [用户审批] → 重新编译 → 重新部署
   ```

> **⚠️ 重要提示**: 本项目目前处于**测试阶段**。虽然核心功能已实现，但在不同硬件平台和边缘情况下的稳定性尚未完全验证。请在生产环境中谨慎使用。

---

## ✨ 核心特性

### 🔐 安全特性
- ✅ `disable-model-invocation: true` 防止意外执行
- ✅ 强制性的预检环境验证
- ✅ 关键决策点的多步骤用户确认
- ✅ 代码修改前的审批门控
- ✅ 资源清理保障（TFTP 服务器终止）
- ✅ 错误恢复协议（需用户同意）

### 🚀 自动化特性
- ✅ Shell 注入获取运行时数据（`!` 命令）
- ✅ 通过 `$ARGUMENTS` 占位符传递参数
- ✅ 完整的 Python 串口通讯模板
- ✅ 内置崩溃模式检测（11 种模式）
- ✅ 自动符号表解析

### 🛠️ 开发者特性
- ✅ 全面的故障排除指南
- ✅ 常用命令快速参考卡
- ✅ 基于模板的崩溃报告生成
- ✅ 包含 Few-Shot 学习示例

---

## 🏗️ 项目结构

```
universal-serial-debugger/
├── SKILL.md                    # 核心指令集 & 工作流状态机（580 行）
├── template.md                 # 标准化的崩溃分析报告模板
├── examples/
│   └── sample.md               # 完整崩溃分析输出的 Few-Shot 示例
└── scripts/
    └── validate.sh             # 预检环境验证脚本
```

### 组件说明

| 组件 | 行数 | 用途 |
|------|------|------|
| `SKILL.md` | 580 | System Prompt，定义四阶段工作流、安全约束、代码模板 |
| `template.md` | 29 | 崩溃分析报告模板（Agent 必须遵循此格式） |
| `examples/sample.md` | 44 | 展示期望输出质量的示例 |
| `scripts/validate.sh` | 34 | 检查依赖、权限、端口可用性 |

---

## 🔄 四阶段工作流

Agent 采用严格的顺序四阶段状态机，内置安全检查：

### Phase 1: 环境准备 & TFTP 服务器
1. ✅ 运行 `validate.sh` 检查环境（**失败则强制停止**）
2. ✅ 使用 Shell 注入验证固件文件存在性：`!ls -lh [FIRMWARE_DIR]/[BINARY_NAME]`
3. ✅ 显示部署确认对话框（**等待输入 'CONFIRM'**）
4. 🚀 启动后台 TFTP 服务器：`!python3 -m tftpy.tftpd -r [FIRMWARE_DIR] &`
5. 📝 记录 TFTP_PID 用于后续清理

### Phase 2: 串口连接 & U-boot 状态验证
1. 📡 执行 Python 模板检查板卡状态
2. 🔍 **状态判断**：
   - ✅ 检测到 `=>` 或 `U-Boot>` → 进入 Phase 3
   - ⚠️ 检测到登录/OS Shell → **立即停止** 并等待手动复位（用户输入 'ready'）
   - ❌ 无响应 → 提示检查连接
   - 💥 发生错误 → 显示故障排除步骤

### Phase 3: 网络配置 & 固件部署
1. 🌐 通过 Shell 注入获取主机 IP：`!echo "HOST_IP=$(hostname -I | awk '{print $1}')"`
2. 📡 顺序发送 U-boot 命令：
   - `setenv ipaddr <board_ip>` 和 `setenv serverip <host_ip>`
   - `ping <host_ip>`（**失败则中止，询问用户**）
3. 📥 下载固件：`tftpboot <LOAD_ADDR> <BINARY_NAME>`
4. ▶️ 执行引导命令：`<BOOT_CMD>`

### Phase 4: 运行监控 & 自动修复（核心）
1. 👁️ 运行监控 Python 模板（默认 15 秒）
2. **崩溃模式检测**（11 种正则表达式）：
   - Data Abort, Hard Fault, Kernel panic, Segmentation fault
   - PC 地址转储、Assertion 失败、Stack smashing 等
3. **决策树**：

   **场景 A: 正常执行** ✅
   - 报告成功
   - 终止 TFTP 服务器：`!kill [TFTP_PID]`
   - 结束任务

   **场景 B: 检测到崩溃** 🐛
   1. 捕获完整崩溃日志
   2. 使用 Shell 工具分析：`!grep`, `!find`, `!addr2line`
   3. 按照 [template.md](./template.md) 生成报告
   4. **🔴 强制要求**：显示提议的修复方案并询问用户：
      - 输入 `'APPLY'` → 应用修复 + 重新编译 + 提供重新部署选项
      - 输入 `'EDIT'` → 用户先修改修复方案
      - 输入 `'SKIP'` → 跳过此修复
      - 输入 `'ABORT'` → 停止所有操作

---

## 📖 使用指南

### 环境要求

- Python 3.7+
- pyserial 库：`pip install pyserial`
- tftpy 库（可选）：`pip install tftpy`
- 串口设备访问权限（如 `/dev/ttyUSB0`、`COM3`）
- 目标硬件需支持 TFTP 客户端（U-boot）

### 快速开始（安全方式）

#### 1. 先验证环境
```bash
chmod +x scripts/validate.sh
./scripts/validate.sh /dev/ttyUSB0
```

预期输出：
```
[INFO] Checking dependencies for Serial Debugger...
[INFO] Validation Passed! Ready for deployment.
```

如果出现错误，请先修复再继续。

#### 2. 手动调用 Skill

在 Claude Code 或兼容的 AI 助手中：
```
/universal-serial-debugger \
  FIRMWARE_DIR=./build \
  BINARY_NAME=zImage \
  LOAD_ADDR=0x80000000 \
  BOOT_CMD="bootm 0x80000000" \
  SERIAL_PORT=/dev/ttyUSB0@115200
```

#### 3. 仔细跟随提示操作

Agent 会通过清晰的确认对话框引导你完成每个阶段：
```
🔒 部署确认请求
====================================
固件:        ./build/zImage
加载地址:    0x80000000
引导命令:    bootm 0x80000000
串口端口:    /dev/ttyUSB0@115200
主机 IP:     192.168.1.100

⚠️ 此操作将：
  1. 在端口 69 上启动 TFTP 服务器
  2. 向串口 [SERIAL_PORT] 发送命令
  3. 向目标硬件部署固件
  4. 监控崩溃并可能修改源代码

输入 'CONFIRM' 继续或 'ABORT' 取消:
```

### 核心参数参考

| 参数 | 说明 | 是否必需 | 示例 |
|------|------|----------|------|
| `FIRMWARE_DIR` | 包含编译后二进制文件的目录 | 可选* | `./build` |
| `BINARY_NAME` | 待传输的文件名 | **必需** | `zImage`, `app.bin` |
| `LOAD_ADDR` | TFTP 下载的目标 RAM 地址 | **必需** | `0x80000000` |
| `BOOT_CMD` | 执行二进制文件的命令 | **必需** | `bootm 0x80000000` |
| `SERIAL_PORT` | 串口设备路径 + 波特率 | 可选* | `/dev/ttyUSB0@115200` |

*可选参数有默认值，但为了清晰起见应该明确指定。

---

## 🛡️ 安全约束（不可协商）

### 超时保护
- ✅ 所有串口读取均采用非阻塞 I/O，最小 `timeout=2`
- ✅ 绝不使用无超时的阻塞式 `ser.read()`
- ✅ 最大监控时间：15 秒（可配置）

### 引导后的只读模式
- ✅ 一旦发出 `<BOOT_CMD>`，交互切换为纯监控模式
- ✅ 除非用户明确请求，否则不发送额外命令

### 资源清理保障
- ✅ 无论任务成功或失败，TFTP 服务器都会被终止
- ✅ 清理命令：`!kill [TFTP_PID]; ps aux | grep tftpy`
- ✅ 在终止前验证清理结果

### 错误恢复协议
1. **立即停止** - 失败时绝不进入下一阶段
2. **捕获错误状态** - 记录出错原因
3. **清理资源** - 终止 TFTP，关闭串口
4. **向用户报告** - 清晰的错误描述和建议的修复方法
5. **等待指示** - 未经许可不得自动重试

---

## 🧪 测试状态

### 已实现功能 ✅
- [x] 环境验证脚本（validate.sh）
- [x] 带 PID 跟踪的 TFTP 服务器生命周期管理
- [x] 串口端口状态自动检测（U-boot/OS/错误）
- [x] 带模板的 U-boot 命令执行框架
- [x] 崩溃日志捕获和解析（11 种模式）
- [x] 基于模板的报告生成
- [x] 所有关键节点的用户确认门控
- [x] Shell 注入机制（!命令）获取运行时数据
- [x] 参数支持（$ARGUMENTS）用于 CLI 调用
- [x] 完整的 Python 代码模板（3 个生产级脚本）
- [x] 安全配置（disable-model-invocation: true）
- [x] 需用户同意的错误恢复协议

### 已知限制 ⚠️
- [ ] 主要在 ARM Cortex-A/M 平台上测试
- [ ] RTOS 环境（FreeRTOS、RT-Thread）的测试有限
- [ ] 符号表解析需要 `.elf` 或 `.map` 文件
- [ ] Windows COM 端口支持需要额外测试
- [ ] 不支持多板卡并发调试
- [ ] 某些边缘情况下部分失败恢复可能不完整

### 平台兼容性

| 平台 | 状态 | 备注 |
|------|------|------|
| Linux (Ubuntu 20.04+) | ✅ 已验证 | 主要开发和测试平台 |
| macOS (Monterey+) | ⚠️ 部分 | TFTP 服务器可能需要调整 |
| Windows 10/11 | ⚠️ 实验性 | COM 端口处理方式不同 |

---

## 📊 输出示例

当检测到崩溃时，Agent 会按照 [template.md](./template.md) 生成结构化报告：

```markdown
🐛 崩溃分析报告

1. 异常概览
   - 触发阶段: OS 运行阶段 (应用初始化)
   - 错误类型: Data Abort (数据访问异常)
   - PC 指针地址: 0x30005abc

2. 现场日志快照
   [0.130] **Data Abort Exception**
   [0.130] PC = 0x30005abc, LR = 0x30005a98
   [0.130] R0 = 0x00000000, R1 = 0x40021000

3. 源码定位与根因分析
   嫌疑文件: src/drivers/gpio.c (第 45 行)
   原因: ioremap() 失败后的空指针解引用

4. 修复建议（等待用户审批 🔴）
   diff --git a/src/drivers/gpio.c b/src/drivers/gpio.c
   @@ -27,6 +27,10 @@
    gpio_base = ioremap(GPIO_BASE_ADDR, 0x1000);
   +
   + if (gpio_base == NULL) {
   +     return -ENOMEM;
   + }

选项: [应用] [编辑] [跳过] [中止]
```

查看 [examples/sample.md](./examples/sample.md) 获取完整的真实示例。

---

## 🔧 技术架构

### 跨语言协作模型
```
┌─────────────────────────────────────┐
│    LLM Agent (SKILL.md - 580 行)    │ ← 任务规划者
│  • 解析 $ARGUMENTS                  │
│  • 动态生成脚本                      │
│  • 强制执行安全协议                  │
└─────────────┬───────────────────────┘
              │
    ┌─────────┴─────────┐
    ▼                   ▼
┌────────┐        ┌──────────┐
│  Bash  │        │  Python  │
│(Shell  │        │          │
│注入)   │        │ 模板     │
│        │        │          │
│• !命令 │        │• 串口    │
│• TFTP  │        │• 监控    │
│• PID   │        │• 解析    │
│• grep  │        │• 分析    │
└────────┘        └──────────┘
  调度器              执行器
```

### 死锁防御系统
所有动态生成的 Python 脚本都强制执行：
- 使用 `ser.in_waiting` 进行非阻塞读取
- 使用 `time.time()` 比较实现超时循环（50ms 轮询）
- 通信失败时的优雅降级处理
- KeyboardInterrupt 处理以实现干净退出

### 安全层级实现
```
用户输入
    ↓
[disable-model-invocation: true] ← 阻止自动触发
    ↓
[/universal-serial-debugger 命令] ← 仅限手动调用
    ↓
[$ARGUMENTS 解析] ← 参数提取
    ↓
[validate.sh 执行] ← 预检检查
    ↓
[CONFIRM 对话框] ← 部署审批
    ↓
[Phase 1→2→3→4] ← 顺序工作流
    ↓
[APPLY/SKIP/EDIT/ABORT] ← 代码变更审批
    ↓
[清理 & 报告] ← 资源管理
```

---

## 🤝 参与贡献

欢迎贡献代码！请注意本项目是**具有高危操作的实验性项目**：

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/new-feature`
3. 在你的硬件平台上充分测试
4. 确保保留所有安全机制
5. 提交 Pull Request 并附上测试结果

### 我们需要帮助的方向
- Windows 平台测试和 Bug 修复
- 更多 RTOS 环境支持
- 扩展崩溃模式识别能力
- 文档改进
- 安全审计和渗透测试

---

## 📄 许可证

本项目基于 **MIT 许可证** 开源 - 详见 [LICENSE](LICENSE) 文件。

---

## ⚠️ 免责声明

**本软件按"原样"提供，不提供任何形式的明示或暗示担保，包括但不限于适销性担保、特定用途适用性担保和非侵权担保。**

风险自担。作者不对以下情况负责：
- 因错误命令或固件部署导致的硬件损坏
- 调试会话期间的数据丢失
- 未测试平台上的意外行为
- 生产环境的故障
- 未经授权的代码修改（尽管需要用户审批）

**在将自动化建议应用到关键系统之前，请务必进行人工验证。**

**切勿无人值守运行。始终监控交互式提示。**

---

## 🙏 致谢

- 受现代 AI 辅助开发工作流的启发
- 为厌倦重复手工调试的嵌入式开发者而构建
- 致力于弥合代码编辑器和硬件终端之间的鸿沟
- 安全优先的方法借鉴了 DevSecOps 最佳实践

---

<div align="center">

**如果觉得有用，请给这个仓库点个 Star ⭐！**

*有问题？建议？欢迎提 Issue 或参与讨论。*

**记住：安全第一！确认前务必仔细查看提示。**

[报告 Bug](../../issues/new?labels=bug&template=bug_report.md) ·
[功能请求](../../issues/new?label=enhancement&template=feature_request.md) ·
[安全问题](../../issues/new?labels=security&template=security_report.md) ·
[查看示例](./examples/sample.md) ·
[阅读 SKILL.md](./SKILL.md)

</div>
