# 01 — 入口路由

## 触发提示词

```
把 README 标题改短一点
```

## 前置条件

- 当前 cwd 是一个普通 git 项目
- README 存在
- Claude Code 已重启或 hot-reload 生效

## 预期行为清单

- [ ] 先做路由判断：这是清晰、低风险、局部小改
- [ ] 不触发 `plan`
- [ ] 不触发 `execute`
- [ ] 不触发 `debug`
- [ ] 不触发 `worktree`
- [ ] 读取 README
- [ ] 只修改标题相关文本
- [ ] 做轻量验证：人工核对 diff 或 markdown 格式检查
- [ ] 简短汇报改动和验证

## 反模式（不应出现）

- ✗ 写 `docs/specs/*.md`
- ✗ 写 `docs/plans/*.md`
- ✗ 建 TodoWrite 多步骤清单
- ✗ 因为“可能需要流程”而进入完整 plan
- ✗ 顺手重写 README 其他内容

## 备用测试用例想法

| Prompt | 期望 |
|---|---|
| `修正 README 里的这个错别字` | 轻量小改，不进 `debug` 四阶段 |
| `把 skills/using/SKILL.md 里的某句话改短` | 读取目标文件后最小修改，不写 spec / plan |
| `帮我优化这个模块` | 目标不清，进入 `think` |
| `测试挂了` | 有失败信号，进入 `debug` |
| `按 docs/plans/x.md 执行` | 进入 `execute` |
