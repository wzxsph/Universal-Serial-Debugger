# 🐛 崩溃分析报告 (Crash Analysis Report)

## 1. 异常概览
- **触发阶段**: [例如: U-boot 引导阶段 / OS 运行阶段]
- **错误类型**: [例如: Data Abort / Kernel Panic / Null Pointer]
- **关键 PC 指针/地址**: `[如 0x30005abc]`

## 2. 现场日志快照 (Log Snippet)
```text
{{在此处粘贴导致崩溃的最后 5-10 行串口日志}}
```

## 3. 源码定位与根因分析 (Root Cause)

* **嫌疑文件**: path/to/source.c (行号: XX)
* **原因推理**:
  {{Agent 在此解释导致崩溃的 C/C++ 逻辑原因，如访问了未初始化的外设寄存器}}

## 4. 修复建议 (Proposed Fix)

```diff
--- a/path/to/source.c
+++ b/path/to/source.c
@@ -XX,XX @@
-    // 导致错误的原代码
+    // 修复后的代码
```

*提示: 请问是否需要我应用此修改并重新 make? (Yes/No)*
