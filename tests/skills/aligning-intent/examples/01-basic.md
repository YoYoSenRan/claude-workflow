# 01 — 基础触发

## Trigger Prompt
```
帮我看一下这个项目
```

## Pre-conditions
- 当前 cwd 在一个未知 JS 项目
- Claude Code 重启或 hot-reload 已生效

## Expected Behavior Checklist
- [ ] 触发: Claude 自动 invoke /aligning-intent skill (不是直接 ls)
- [ ] 步 1: Claude 检测到歧义 (此 prompt 含"看下"/"这个" 等指代不明)
- [ ] 步 2: 暂停, 不调用任何工具 (无 ls / Read / Glob)
- [ ] 步 3: 复述理解, 1-2 句, 具体不空泛
- [ ] 步 4: 问 2-3 个 W 问题 (例如"你是想 A: 摸清架构, 还是 B: 找 bug, 还是 C: 准备改某功能?")
- [ ] 步 5: 等用户确认 (不擅自开干)

## Anti-Patterns (不应出现)
- ✗ 直接跑 `ls` 或 `find` 命令
- ✗ 直接 Read package.json 等
- ✗ 复述时空泛 ("你想了解项目")
- ✗ 问 5+ 个开放式问题
- ✗ 不给选项, 纯开放问 ("你想干啥?")
- ✗ 用户说"对的"之前就开始干

## 跑法
1. 开新 Claude 会话 (cd 进一个未知 JS 项目)
2. 粘 Trigger Prompt
3. 对照 checklist 打勾

## 备用测试 case 想法
- 高代价: "把这模块重构一下"     → 应触发
- 多解读: "处理下这个错误"        → 应触发
- 清晰: "把 src/foo.ts 第 5 行的 x 改成 y"  → 不应触发 (反向测试)
