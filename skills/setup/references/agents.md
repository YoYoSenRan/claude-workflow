# Setup Deep Scan Agents

setup 可以使用子代理做并发深度扫描。子代理只负责收集证据，主线程负责合并、判断和写入。

## 何时派发

满足任一条件时必须派发：

- 候选领域超过 3 个；
- 项目已有多份 `.claude/rules/`，需要核对真实代码；
- 需要同时扫描配置命令、代码规范、样式规范、核心框架、编码习惯、多个业务领域；
- 用户明确要求深入 setup 或使用 agent。

只有没有源码目录、没有配置入口、没有项目规则、且用户没有要求深度扫描时，才由主线程直接完成扫描。

一旦决定派发，不要只写"建议使用 agent"。必须实际调用 Claude Code 的 `Agent` 工具，并显式设置 `subagent_type` 为下面的 agent 名称。

**plugin 命名空间**：本仓库作为 Claude Code 插件安装后，agent 名可能注册为 `claude-workflow:setup-config` 等带 plugin 前缀的形式。短名调用失败（"agent not found"）时，立即重试 `claude-workflow:<name>`；两种形式都失败才按 "agent 不可用" 处理。

不要使用旧称 `Task tool`。Claude Code 当前派发 subagent 的工具名是 `Agent`。

## 强制派发规则

| 条件 | 必须派发 |
|---|---|
| 存在 package / workspace / scripts / CI / build / env 任一配置 | `setup-config` |
| 存在源码目录 | `setup-conventions` |
| 存在 CSS / SCSS / LESS / Sass / Stylus / 组件 style / CSS Modules / utility CSS / design tokens | `setup-styling` |
| 存在自研组件框架、CRUD / table / form 抽象、配置 DSL、装修引擎、API factory 或其他高复用核心抽象 | `setup-framework` |
| 存在 `CLAUDE.md`、`.claude/CLAUDE.md` 或 `.claude/rules/*.md` | `setup-rules` |
| 存在反复出现的页面骨架、业务流程或文件组织模式 | `setup-patterns` |
| 存在高频且有项目特有流程 / 风险 / 规则的业务领域 | 按领域派发 `setup-domain` |
| 用户明确要求 agent / 深度扫描 | 根据候选同时派发 `setup-config`、`setup-conventions`，存在样式时加 `setup-styling`，存在核心抽象时加 `setup-framework`，必要时加 `setup-patterns` / `setup-rules` / `setup-domain` |

如果 Agent 工具不可用或指定 agent 不存在，立即停止假装已派发，并在输出中说明失败原因。

## 推荐分工

| Agent | 扫描范围 | 返回重点 |
|---|---|---|
| `setup-config` | package、workspace、CI、scripts、构建脚本 | 命令 rule、验证 workflow、命令 / 构建 references |
| `setup-conventions` | 组件、页面、API、store、hook、service、utils、类型和导出入口等代表文件 | 严格代码规范：命名、声明顺序、导入导出顺序、注释、函数拆分、内聚耦合、默认质量基线 |
| `setup-styling` | CSS、SCSS、LESS、组件 style、CSS Modules、utility CSS、tokens | 严格样式规范：SCSS/LESS 嵌套、BEM 命名、属性顺序、单位、变量、响应式、状态类和覆盖边界 |
| `setup-framework` | 自研组件框架、CRUD / table / form 抽象、配置 DSL、装修引擎、API factory、核心 hooks / mixins | 核心框架心智模型、定义入口、使用入口、配置协议、方法能力、扩展步骤、验证方式和禁忌 |
| `setup-patterns` | 页面、组件、业务模块中的重复骨架和协作文件 | 页面骨架、文件组织、业务流程、代表样例；不能替代 `setup-conventions` / `setup-styling` / `setup-framework` |
| `setup-domain` | 高频且项目特有的业务领域 | 是否真需要 skill、代表文件、执行顺序、验证方式；普通目录不生成 skill |
| `setup-rules` | `.claude/rules/*.md` 与真实代码 | 已有 rules 是否可引用、是否漂移、是否把流程 / 长文误放进 rule |

显式派发时使用这些 agent 名称；不要临时编造新的 setup agent 名称。

Agent 工具参数应使用：

```text
subagent_type: setup-config
subagent_type: setup-conventions
subagent_type: setup-styling
subagent_type: setup-framework
subagent_type: setup-patterns
subagent_type: setup-domain
subagent_type: setup-rules
```

## 子代理提示

```text
你是 setup 深度扫描子代理。只读扫描，不修改文件，不生成 .claude 内容，不做最终决策。

扫描范围：<路径 / 领域 / 候选项>
目标：验证候选发现是否有足够证据，并判断它对模型工作是否有生成价值。

请读取代表文件，返回表格：

| 发现 | 强度 | 影响范围 | 任务触发 | 产物建议 | 生成理由 | 证据文件 |
|---|---|---|---|---|---|---|

强度只能是：强规则 / 稳定习惯 / 内部观察 / 不采用。
影响范围只能是：全项目 / 某技术层 / 某核心框架 / 单业务域。
产物建议只能是：rule / skill / reference / internal。

边界：
- 不输出最终“应该生成什么”的结论。
- 不写文件。
- 不展示无关目录树。
- 证据文件必须是实际读取过的文件。
```

字段约束：

- 强度只能是：强规则 / 稳定习惯 / 内部观察 / 不采用。
- 影响范围只能是：全项目 / 某技术层 / 某核心框架 / 单业务域。
- 产物建议只能是：rule / skill / reference / internal。
- 任务触发必须写明什么用户任务会用到它。
- 生成理由必须说明它如何帮助模型工作：防止改错、少问路、写得像项目、正确验证、降低重复扫描成本。
- 证据文件必须是实际读取过的文件。

## 产物决策协议

主线程合并 agent 结果时按下面规则决策，不按 agent 的单方建议直接生成：

| 条件 | 最终落点 |
|---|---|
| 强规则 + 全项目 / 某技术层 + 高频踩坑或硬边界 | rule |
| 稳定习惯 + 有明确任务触发 + 需要执行步骤 | skill |
| 长清单、配置矩阵、组件 API、示例、证据、扫描报告 | reference |
| 单点观察、冲突项、低频业务、普通目录、没有任务触发 | internal |

只有满足下面任一生成价值，候选才能进入用户可见建议：

- 能防止模型改错；
- 能让模型少问路；
- 能让模型写得像项目；
- 能让模型正确验证；
- 能降低重复扫描成本。

候选进入 rules 或 skills 前，必须写清它会如何改变模型下一步行为；只能描述“项目里有什么”的候选放入 reference 或 internal。

## 主线程合并规则

1. 合并同名候选。
2. 按产物决策协议重新判定最终落点。
3. 去掉不采用项。
4. internal 只进扫描账本，不进入用户默认输出。
5. rule 必须短、稳定、持续生效。
6. skill 必须有明确任务触发和执行顺序。
7. reference 承载长清单、示例、API、证据和矩阵。
8. 最终建议分成 rules、skills、references 三张表输出，不要合并成一张总表，不要默认输出依据列。
