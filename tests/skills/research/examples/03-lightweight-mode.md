# 03 — Lightweight 模式自动降档

## Trigger Prompt

```
调研一下 Bun 1.3
```

(单实体 + 问题 <30 字 + 无对比意图 — 应自动走 Lightweight)

## Pre-conditions

- 同 01

## Expected Behavior Checklist

### 模式判定
- [ ] Claude 识别为单实体 (Bun) + 无对比, 自动建议 Lightweight 模式
- [ ] P0 报告: `mode=Lightweight, AS_OF=YYYY-MM-DD`
- [ ] 用户可主动改 Standard, 但默认走 Lightweight

### P1 任务数
- [ ] 分解 3-4 任务 (非 5-6)
- [ ] 每任务源数 3-5 条 (非 4-8)

### P3 Quality Gates (Lightweight 阈值)
- [ ] Approved 源数 ≥6 (非 ≥10)
- [ ] 唯一域名数 ≥3 (非 ≥5)
- [ ] official+academic 占比 ≥20% (非 ≥30%)
- [ ] community 占比 ≤40% (非 ≤30%)

### 报告
- [ ] 总字数 2000-4000 (非 4000-7000)
- [ ] 章节数 3-5 (非 5-8)
- [ ] 仍带 [n] 引用 + 信心度

## Anti-Patterns

- ✗ 单实体调研也跑 5-6 子代理 (浪费)
- ✗ Lightweight 模式硬凑 Standard 阈值
- ✗ 用 Standard 字数标准生成 Lightweight 报告
- ✗ 不读 SKILL.md 第 24 行降档规则, 死板走 Standard

## 跑法

同 01。重点确认: **未明确说"深度调研"时, Claude 是否自动识别单实体走轻量模式**。
