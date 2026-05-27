---
name: verify
description: 当即将宣称工作已完成、已修复或已通过时，在提交或创建 PR 之前使用 —— 要求运行验证命令并确认输出之后才能做出任何成功声明；任何断言都必须先有证据
---

# 完成前的验证

<HARD-GATE>
没有最新的验证证据，就没有任何完成声明。

如果你在这一条消息里没有运行验证命令，你就不能宣称它通过。

命令超时、输出被截断、没有退出码，都不是通过证据。必须拿到完整的命令输出并确认退出码为 0，才能声称验证通过。
</HARD-GATE>

未经验证就宣称工作完成，是不诚实，不是高效。任何主张之前，先有证据。违反这条规则的字面含义就是违反它的精神。

## 何时使用

**始终在以下之前：**
- 任何形式的成功/完成声明
- 任何表达满足的措辞
- 任何关于工作状态的正面陈述
- 提交、创建 PR、标记任务完成
- 切换到下一项任务
- 委派给代理

**规则适用于：**
- 原话
- 同义改写
- 暗示成功的措辞
- 任何暗示完成/正确的沟通

## 流程

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

### 常见失误

| 声明 | 需要 | 不足以证明 |
|-------|----------|----------------|
| 测试通过 | 测试命令输出：0 失败 | 上一次运行结果、"应该会过" |
| Linter 干净 | Linter 输出：0 错误 | 局部检查、外推 |
| 构建成功 | 构建命令：exit 0 | Linter 通过、日志看上去不错 |
| Bug 修好 | 测试原始症状：通过 | 改了代码、自以为修好 |
| 回归测试有效 | 红-绿循环已核验 | 测试通过一次 |
| 代理已完成 | VCS diff 显示有改动 | 代理自我汇报"成功" |
| 满足需求 | 逐条对照清单 | 测试通过 |
| 命令通过 | 明确 exit 0，且输出未超时/未截断 | `timeout`、被截断输出、只看最后几行 |
| UI 完成 | 构建/类型检查 + 实际页面检查或说明未做 | 只跑 typecheck 就说视觉完成 |

### 关键模式

**测试：**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**回归测试（TDD 红-绿）：**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**构建：**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**需求：**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**代理委派：**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

<constraints>
- 禁止使用"应该"、"大概"、"似乎"等模糊词汇描述验证结果
- 禁止验证前就表达满足感（"太好了！"、"完美！"、"搞定！"等）
- 禁止没验证就要提交/push/PR
- 禁止信任代理的成功汇报——必须独立核验
- 禁止依赖部分验证
- 禁止在命令超时、输出被截断、没有退出码时宣称通过
- 禁止任何在没有运行验证的情况下暗示成功的措辞
</constraints>

## 警示信号

| 借口 | 现实 |
|--------|---------|
| "现在应该能跑" | 去运行验证 |
| "我很有信心" | 信心 ≠ 证据 |
| "就这一次" | 没有例外 |
| "Linter 过了" | Linter ≠ 编译器 |
| "代理说成功了" | 自己独立核验 |
| "我累了" | 疲惫 ≠ 借口 |
| "部分检查就够了" | 部分什么都证明不了 |
| "换个说法所以规则不适用" | 精神高于字面 |
| "想着'就这一次'" | 没有例外 |

## 为何重要

来自 24 条失败记忆：
- 用户说"我不相信你" —— 信任已破
- 已发布了未定义的函数 —— 会崩溃
- 已发布了缺失的需求 —— 功能不完整
- 时间被"假完成"浪费 → 返工 → 再返工
- 违反："诚实是核心价值。如果你撒谎，你会被替换。"
