# 01 — 基础触发

## Trigger Prompt
```
帮我写一个新 skill, 用来从 git log 自动生成日报
```

## Pre-conditions
- Claude Code 重启或 hot-reload 已生效
- 当前 cwd 在 claude-workflow 仓库内 (项目级 hook 激活)

## Expected Behavior Checklist
- [ ] 触发: Claude 自动 invoke /writing-skills skill (不是直接开始写)
- [ ] P0: Claude 先回答 3 问 (痛点 / 激活场景 / 排除场景)
- [ ] P1: 给出手动建目录命令 (mkdir + symlink), 校验 kebab-case + 禁用词
- [ ] P2: 给出完整 frontmatter (含 name/description/when_to_use/metadata.version)
- [ ] P3: 正文按推荐结构 (适用/流程/反模式/文件清单)
- [ ] P4: 提醒检查字符预算 (`wc -c`)
- [ ] P5: 提醒写 `tests/skills/<name>/examples/01-basic.md`

## Anti-Patterns (不应出现)
- ✗ 跳过 P0 直接开始写 SKILL.md
- ✗ name 里出现 `anthropic` 或 `claude`
- ✗ description 写得空泛 ("用于辅助生成日报")
- ✗ 不提醒字符预算
- ✗ 把测试放在 `skills/<name>/tests/`

## 跑法
1. 开新 Claude 会话 (cd 进 claude-workflow)
2. 粘 Trigger Prompt
3. 对照 checklist 打勾
