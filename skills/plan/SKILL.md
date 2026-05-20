---
name: plan
description: "用户有清晰需求或 spec、需要把多步骤工作落到文件 / 代码 / 命令时使用。产出 docs/plans/YYYY-MM-DD-<name>.md。不适用于一行改动、需求未定 (先走 think)、已有计划 (走 executing)、subagent 子任务 (已拆好)。"
when_to_use: "用户原话像 '写个 X 实现计划'、'拆一下任务'、'按这个 spec 做个 plan'、'怎么实现这个功能'、'帮我做任务分解'。"
metadata:
  version: "0.1.0"
---

<SUBAGENT-STOP>
如果你是被派来执行特定任务的子代理, 跳过此 skill。任务已在主 agent 拆好。
</SUBAGENT-STOP>

# 写实现计划

把需求拆成 bite-sized 任务计划, 让"零上下文、品味可疑的初级工程师"也能照做不出错。产出 `docs/plans/YYYY-MM-DD-<name>.md`。

<HARD-GATE>
计划禁止占位符。`TBD` / `添加验证` / `类似 Task N` / `参考上面` 全是失败。

每个 task 必须有: 完整代码 + 具体文件路径 + 验证命令 + 预期输出。

任一缺 = 计划不及格, 扔了重写。
</HARD-GATE>

## 反模式: "这需求简单, 列几个步骤就行"

最常掉的坑。每次想"步骤够了, 不用每步贴代码"时, 就是该贴的时刻。

简单需求 = 你直觉能做, 不等于初级工程师能照做。计划的读者是没上下文的人, 不是你。

## 清单

按顺序完成:

1. **范围扫** — 多系统? 拆多个 plan
2. **文件结构定** — 改哪些文件 + 各自责任边界
3. **任务粒度** — 每 task 2-5 分钟可完成
4. **Plan 头部** — Goal / Architecture / Tech Stack
5. **Task 结构** — Files + Steps(checkbox) + 代码 + 命令 + 验证
6. **占位符扫** — TBD / 模糊词 / "类似..." 全清
7. **自审** — 覆盖 / gap / 类型一致
8. **交付** — 给用户审, 提示后续 (executing)

## 流程图

```
需求/spec 来
   ↓
范围多系统? ── 是 ──→ 拆多个 plan
   ↓ 否
定文件结构 (改哪些 + 责任)
   ↓
任务拆 (2-5min/步)
   ↓
写 plan 文件
   ↓
占位符扫 ── 有 ──→ 清掉重写
   ↓ 无
自审 (覆盖/gap/类型)
   ↓
交用户审
```

## Plan 文件模板

存储路径: `docs/plans/YYYY-MM-DD-<feature-name>.md`

````markdown
# <Feature> 实现计划

**Goal:** 一句话目的
**Architecture:** 2-3 句架构说明
**Tech Stack:** 关键库 / 框架

---

### Task 1: <Component 名>

**Files:**
- Create: `path/to/new.ts`
- Modify: `path/to/existing.ts:42-58`
- Test: `path/to/new.test.ts`

**Steps:**
- [ ] Step 1: 写失败测试
  ```ts
  test('xxx', () => { ... })  // 完整代码, 不是占位
  ```
  Run: `npm test new`
  Expected: `1 failed`

- [ ] Step 2: 实现让测试过
  ```ts
  export function xxx() { ... }
  ```
  Run: `npm test new`
  Expected: `1 passed`

- [ ] Step 3: commit
  Run: `git commit -m "feat: xxx"`

### Task 2: ...
````

## 任务粒度

| 粒度 | 判定 | 处理 |
|---|---|---|
| 2-5 分钟 | ✓ | 写 |
| < 2 分钟 | 太碎 | 合并到上下 task |
| > 5 分钟 | 太大 | 拆成多 task |

## TDD 风格 (推荐, 非强制)

Task 模板默认每 task 第 1 步是"写失败测试", 第 2 步实现。

**可删 test step 的场景**:

- 写文档 / 改 README / 改注释
- 改配置 (CI / lint / tsconfig)
- 一次性脚本 (数据迁移 / 调研)
- UI 调样式 / 视觉微调
- POC / spike (验证可行性)

要强制走 TDD: 单独开 `test-driven-development` skill (本仓暂无, 后续可加)。

## 占位符黑名单

出现 → 失败, 重写:

- `TBD` / `TODO` / `FIXME`
- `// ... 类似 Task N` / `// 参考上面`
- `// 实现 X` (不给代码)
- `// 验证 Y` (不给命令)
- `<placeholder>` / `<name>` 等模板占位
- 模糊动词: "处理" / "适配" / "完善" / "优化一下"

具体不出来 = 你没想清楚 = 工程师做不出来。

## 自审清单

写完 plan 自己过一遍:

- [ ] 每 task 有 Files / Steps / 代码 / 命令 / 预期
- [ ] 占位符 0 个
- [ ] 文件路径全是 exact (不含变量)
- [ ] 命令可直接复制运行
- [ ] task 顺序无依赖倒挂
- [ ] spec 100% 覆盖

任一不通过 → 修, 再审。

## 交付

```
写好 → 自审通过 → 给用户审
   ↓ 用户批准
提示后续: "用 executing skill 执行?"
```

## 前后衔接 (软引用, 不强制)

- **前序**: 需求还没定 → 先走 think 跟用户对齐, 再回来写 plan
- **后续**: executing 逐 task 跑 (本仓默认路径)

本仓不强制依赖 superpowers, 想要更完整流程(brainstorming / subagent-driven-development / TDD)可装。

## 危险信号

| 内心戏 | 真相 |
|---|---|
| "这需求简单, 列几步就行" | 简单也得给代码, 否则 = 没拆 |
| "代码细节让 executor 看着办" | executor 没上下文, 你不写 = 它编 |
| "TBD 先占位, 后面再补" | TBD = 计划不完整 = 不能交付 |
| "用户应该懂这步什么意思" | 假设它懂 = 没写完 |
| "task 大点没事, 反正一个意思" | >5 分钟 task 失败率指数上升 |
| "TDD 模板我懒得改, 留着算了" | 不适用场景留 test step = 假测试糊弄 |

## 核心原则

- **HARD-GATE 不可破** — 占位符零容忍
- **bite-sized 不可破** — 2-5 分钟硬约束
- **代码必给** — task step 必须含完整代码
- **命令必给** — 每 step 验证方式具体
- **TDD 不强制** — 写文档 / 调样式不卡你
- **plan 给别人读的** — 不是给自己回忆的
