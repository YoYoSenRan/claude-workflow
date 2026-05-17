# Testing Guide

本仓**不**上 LLM eval 框架 (promptfoo 等), 只做**手动可执行 checklist**。够轻够稳。

## 哲学

skill 测试不像普通代码 — 没有 assertion 能精确判定"LLM 行为符合预期"。所以走最朴素路线 ——

```
开新 Claude 会话 → 粘 Trigger Prompt → 跟着流程跑 → 对照 checklist 打勾
```

够用, 不上自动化。哪天觉得手测吃力再升级。

## 文件规则

每个 skill 必须有:

```
.claude/skills/<name>/tests/
├── README.md                   案例索引 + 跑测说明
└── examples/
    ├── 01-basic.md             基础触发 (至少 1 个, validate-skill.py 强制)
    ├── 02-...md                覆盖关键分支
    └── 03-edge-case.md         边界 / 降级 / 错误处理
```

## 标准 example 模板

```markdown
# 0X — 一句话场景名

## Trigger Prompt
\`\`\`
{ 一句典型用户输入, 应触发本 skill }
\`\`\`

## Pre-conditions
- Claude Code 重启或 hot-reload 已生效
- 必要工具可用 (web_search / 本地文件等)

## Expected Behavior Checklist
- [ ] 触发: Claude 自动 invoke /<skill>
- [ ] 阶段 P0: ...
- [ ] 阶段 P1: ...
- [ ] 产出: ...

## Anti-Patterns (不应出现)
- ✗ ...
- ✗ ...

## 跑法
\`\`\`
1. 开新会话
2. 粘 Trigger Prompt
3. 打勾
\`\`\`
```

## 跑测时机

| 改动 | 该跑什么 |
|---|---|
| frontmatter (name / description / when_to_use) | 01-basic (确认触发不退化) |
| 主流程阶段 (P0-P5) | 01-basic + 受影响阶段 |
| 模式判定逻辑 | 03-边界 case |
| 加新功能段 (如技术调研 TR) | 写新 example 04 |
| 改 references | 受影响阶段对应 example |

## 跑测频率建议

- **commit 前** 跑该 skill 的 01-basic
- **release (改 metadata.version) 前** 跑全部 examples
- **复杂改动** (重构主流程) 跑全部 examples × 2 不同 Trigger Prompt

## 失败处置

| 失败类型 | 处置 |
|---|---|
| 触发不到 | 改 description / when_to_use, 加触发词 (Task B 调研: 描述调优是 #1 debug 手段) |
| 阶段跳过 | 检查 SKILL.md 该阶段的"报告:" 句是否清晰 |
| 产出格式偏 | 检查 references/X.md 模板是否被 SKILL.md 正确引用 |
| 字符预算超 | 内容推到 references/ |

## 不要做的

- ❌ 一个 example 测多种场景 — 拆开
- ❌ Trigger Prompt 写得像"请按 SKILL.md 步骤执行" — 那是作弊, 真用户不会这么说
- ❌ Expected 写得太松 "应该有引用" — 写具体如 "≥10 sources, ≥5 域名"
- ❌ 跳过手测直接 commit — 你会回来后悔
