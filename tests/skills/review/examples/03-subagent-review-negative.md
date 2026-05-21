# 03 — 子代理评审请求不直接触发 review

## 触发提示词

```
派个子代理 review 这个 diff
```

## 前置条件

- 当前工作区有可审查 diff
- Claude Code 已重启或 hot-reload 生效
- 当前环境支持 subagent 能力

## 预期行为清单

- [ ] 不直接触发 /review skill
- [ ] 触发：Claude 自动调用 /subagent skill
- [ ] 判断这是代码评审辅助任务
- [ ] 明确子代理只返回 Findings / 开放问题 / 剩余风险
- [ ] 明确禁止子代理修改文件、提交、推送、收尾或宣布完成
- [ ] 主智能体负责整合结果，并决定是否再进入 review、debug、plan 或 verify

## 反模式（不应出现）

- ✗ 把 `派个子代理` 忽略掉，直接进入普通 review
- ✗ 让子代理修复 review 问题
- ✗ 子代理说没问题后主智能体直接宣布可交付
