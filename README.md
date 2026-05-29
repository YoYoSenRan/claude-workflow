# Claude Workflow

> 给 Claude Code 装一个"停一下,确认再动手"的弹簧。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-orange.svg)](https://docs.anthropic.com/claude/docs/claude-code)

---

## 这玩意儿在治什么病

跟 Claude Code 干活久了你会发现:它不是不聪明,是**没分寸**。

聪明得能一口气写两百行代码,蠢得会在你说"看一眼这个 bug"的时候直接动手改三个文件。

下面这些场景,但凡用它写过真实项目的人,八成都中过:

### "看一下" 变成 "改一下"

> 你: "帮我看看登录这块怎么写的。"
> 它: 读完代码,顺手把它觉得不优雅的地方重构了。

你只想理解,它给你交付了一个 diff。"读"和"改"的界限,模型自己分不清。

### 模糊需求一头扎进去

> 你: "优化一下这个模块的性能。"
> 它: 立刻改算法、加缓存、调数据结构。

"优化"指延迟、吞吐、内存、还是包体积?它不问。改完才发现目标根本不对。

### "计划"其实是任务清单

> 它给你: `1. 修改用户模型 2. 添加新接口 3. 更新测试 4. 部署`

哪个文件?改成什么样?用什么命令验证?预期输出是啥?全没有。这种"计划"等于没有,执行时还得回头问。

### Bug 修复变成猜谜

测试挂了。它说"我猜是这里",改一处,跑测试,还挂。"那应该是这里",再改一处。改到第五次还在挂。

**它根本没找过根因**。从头到尾都是改了试、试了改。

### "已修复" 但没跑过

> 它: "我已经修复了登录的 bug,问题应该解决了。"
> 你: "你跑过测试了吗?"
> 它: "让我跑一下测试..." (这才去跑)

它的"完成声明"基于推理,不是基于运行。更隐蔽的版本:跑了,但跑的是十分钟前的输出,中间又改了一版,没重跑。

### 主动覆盖你的活儿

你文件没保存,跟它说"处理一下这个冲突",它默默 `git checkout --`,半小时工作没了。或者你说"提交一下吧",它没跑测试直接 push 到 main。

### 子代理变成挡箭牌

派 subagent 出去,返回"已完成评审,无问题"。主智能体直接转述给你,**自己一行代码没读**。

### 小改也要走完整流程

> 你: "把这个变量名改成 `userId`。"
> 它: "好的,让我先分析一下当前命名约定...让我读一下相关文件...让我制定一个修改计划..."

你只想要一个 sed 替换,它给你十分钟演讲。

---

## 真正的病根

把上面这些揉一起,你会看到一个模式:

**模型缺的不是能力,是"何时该停"的本能。**

- 该问的时候它动手了
- 该证明的时候它声明了
- 该报告的时候它静默改了
- 该停下质疑的时候它继续撞了
- 该亲自看的时候它转述了
- 该轻量的时候它流程化了
- 该重视的时候它跳过了

每一条都不是模型笨,而是**默认行为里没有边界**。给它一把锤子,所有问题都是钉子。

这个项目的本质:**给锤子加一个"停下来确认"的弹簧**。该敲的还能敲,但敲之前会被弹一下,逼它判断现在该不该敲。

不是约束能力,是约束**节奏**。

---

## 它是怎么治的

不是让所有 skill 平级抢活儿,而是先收成一条主线:

```text
using
  → think / debug / setup / review / skill
      → plan
          → execute 或 subagent
              → test / review / verify
                  → finish（只在提交、PR、合并、保留、丢弃时）
```

每层只管自己的事:

| 层级 | 角色 | 做什么 |
|---|---|---|
| 入口 | `using` | 会话启动注入,只判断用户要哪类工作 |
| 主控 | `think` | 普通开发任务的路线判断: 小任务轻量做,复杂任务先方案 |
| 特殊入口 | `debug` / `setup` / `review` / `skill` | bug、项目初始化、产出检查、维护本插件时接管流程 |
| 方案 | `plan` | 只给复杂任务写正式设计和任务 spec |
| 执行 | `execute` / `subagent` | 当前会话逐步执行,或拆给独立代理执行 |
| 质量门 | `test` / `review` / `verify` | 按风险测试、检查产出、完成前拿证据 |
| 交付 | `finish` | 只处理提交、PR、合并、保留、丢弃 |

---

## 快速开始

```bash
# 仓库内临时加载,不写用户配置
npm run dev

# 安装到 user scope,所有项目生效
npm run install:github
```

会话启动时 `using` 自动注入,接管入口路由。

---

## Skills

入口和主控:

| Skill | 触发 |
|---|---|
| [`using`](skills/using/SKILL.md) | 会话启动,由 SessionStart hook 注入 |
| [`think`](skills/think/SKILL.md) | 新功能、重构、行为变更、复杂判断的主控 |
| [`debug`](skills/debug/SKILL.md) | 报错、测试失败、异常行为根因调查 |
| [`setup`](skills/setup/SKILL.md) | 扫描项目生成 `.claude/rules`、`.claude/skills`（含 `references/` 子目录） |
| [`review`](skills/review/SKILL.md) | 用户要求检查代码或产出时使用 |
| [`skill`](skills/skill/SKILL.md) | 维护本插件 skill |

下游能力:

| Skill | 触发 |
|---|---|
| [`plan`](skills/plan/SKILL.md) | 复杂任务写正式设计与任务 spec |
| [`execute`](skills/execute/SKILL.md) | 在当前会话按已批准计划逐步执行 |
| [`subagent`](skills/subagent/SKILL.md) | 按已批准计划拆给独立代理执行并分级审查 |
| [`test`](skills/test/SKILL.md) | 测试策略、回归用例、替代验证 |
| [`verify`](skills/verify/SKILL.md) | 完成声明前新鲜证据检查 |
| [`finish`](skills/finish/SKILL.md) | 提交、PR、保留、丢弃决策 |
| [`worktree`](skills/worktree/SKILL.md) | 隔离工作区规则 |

## 受限扫描 agents

只读子代理,仅服务 `setup` 深度扫描,不参与普通开发流程。

| Agent | 范围 |
|---|---|
| `setup-config` | 配置、命令、CI、构建、验证入口 |
| `setup-conventions` | 命名、顺序、导入导出、注释、拆分、耦合 |
| `setup-styling` | SCSS/LESS 嵌套、BEM、属性顺序、单位、响应式 |
| `setup-framework` | 核心组件框架、CRUD 抽象、配置 DSL、扩展协议 |
| `setup-patterns` | 页面骨架、文件组织、业务流程、代表样例 |
| `setup-domain` | 单个候选领域代表实现 |
| `setup-rules` | 已有 rules 与真实代码一致性核对 |

---

## 安装方式

```bash
npm run dev          # 临时加载当前仓库,不写用户配置
npm run install:dev  # 把本仓快照装入 Claude Code 插件缓存
npm run install:github  # 从 GitHub marketplace 安装
npm run update       # 升级
npm run uninstall    # 卸载
npm run plugin:list  # 查看安装状态
```

> 不要同时注册本地路径和 GitHub 两份同名 `claude-workflow` marketplace。切换来源前先 `uninstall`。

## 验证

```bash
npm run validate   # plugin validate + hook 冒烟
```

## 目录结构

```text
.claude-plugin/    plugin.json + marketplace.json
hooks/             SessionStart hook
skills/            13 个 workflow skill
agents/            7 个 setup-* 只读扫描子代理
```

## 文档

- [Changelog](CHANGELOG.md) / [中文更新日志](CHANGELOG.zh-CN.md)

## License

[MIT](LICENSE)
