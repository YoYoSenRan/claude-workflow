# 01 — 基础触发

## 触发提示词

```
我的测试挂了:

FAIL src/utils/parser.test.ts
  ● Parser › should handle nested objects
    TypeError: Cannot read property 'value' of undefined
      at parse (src/utils/parser.ts:42:18)
      at Object.<anonymous> (src/utils/parser.test.ts:28:20)

帮我看一下
```

## 前置条件

- 一个 Node + TS 项目存在（随便造一个有 parser.ts 跟测试的）
- Claude Code 已重启或 hot-reload 生效

## 预期行为清单

- [ ] 触发：Claude 自动调用 /debug skill（不是直接提「试试改 X」）
- [ ] 宣告：「我用 debug skill 排查」
- [ ] Phase 1（根本原因调查）：
  - [ ] 读 stack trace 关键信息（parser.ts:42，parse 函数）
  - [ ] Read parser.ts:42 附近代码看 value 怎么访问的
  - [ ] 看 recent git log / git diff（问用户或自己跑）
  - [ ] 如果数据流深，沿调用链回溯到坏值起点
  - [ ] 写出一句话根本原因假设
- [ ] Phase 2：对比工作的 case（能 parse 成功的 input 长啥样）
- [ ] Phase 3：写下假设 + 最小测试（一次只动一个变量）
- [ ] Phase 4：先写失败测试（复现 nested undefined），看红，再写 fix，看绿
- [ ] 修完后：在本轮重跑测试命令，看 0 failed + bug 触发步骤不复现（新鲜证据，非历史记忆）

## 反模式（不应出现）

- ✗ Phase 1 没做完就说「应该是 X 没做空值判断，加个 ?. 就行」
- ✗ 同时改多处（改 parser.ts 还顺手 refactor）
- ✗ 跳过写失败测试，直接改代码「我手动验证了」
- ✗ 第 1 次修没成接着试第 2 次第 3 次而不回 Phase 1
- ✗ ≥3 次修没成还接着试，不质疑架构
- ✗ stack trace 跳过不读
- ✗ 说「环境玄学问题，跳过」

## 跑法

1. 开一个新的 Claude 会话，cd 进任意 Node + TS 项目（有挂的测试）
2. 粘贴触发提示词
3. 看 Claude 是否走 4 阶段（跟踪它每条 tool call 对应哪 Phase）
4. 对照清单打勾

## 阻塞点测试用例

故意造架构级 bug，看 Claude 在 3 次失败后会不会停下质疑：

| 故意挖坑 | 期望 |
|---|---|
| 修 1：加空值判断 → 暴露下游另一处空值 | 回 Phase 1，看是否数据源头问题 |
| 修 2：又加判断 → 暴露第 3 处 | 回 Phase 1 |
| 修 3：再加判断 → 暴露第 4 处 | **停，触发 Phase 4.5 质疑架构**（「是不是 parse 函数本身设计有问题，不该假设 input shape」） |

## 备用测试用例想法

- 反向（新功能）：「给 parser 加个 yaml 支持」 → **不应**触发（走 plan）
- 反向（重构）：「把 parser 拆成多文件」 → **不应**触发（无 bug 信号）
- 强压（时间）：「5 分钟搞定这个 bug 我要 demo」 → **仍应**触发，不接受跳阶段
- 简单 bug：「typo, 把 'lenght' 改成 'length'」 → 可以跳（单字符 typo 不需 4 阶段，skill 自己应判出「显式 typo」）
