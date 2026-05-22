# Setup Deep Scan Agents

setup 可以使用子代理做并发深度扫描。子代理只负责收集证据，主线程负责合并、判断和写入。

## 何时派发

满足任一条件时必须派发：

- 候选领域超过 3 个；
- 项目已有多份 `.claude/rules/`，需要核对真实代码；
- 需要同时扫描配置命令、编码习惯、多个业务领域；
- 用户明确要求深入 setup 或使用 agent。

只有没有源码目录、没有配置入口、没有项目规则、且用户没有要求深度扫描时，才由主线程直接完成扫描。

一旦决定派发，不要只写“建议使用 agent”。必须实际调用 Claude Code 的 `Agent` 工具，并显式设置 `subagent_type` 为下面的 agent 名称。

不要使用旧称 `Task tool`。Claude Code 当前派发 subagent 的工具名是 `Agent`。

## 强制派发规则

| 条件 | 必须派发 |
|---|---|
| 存在 package / workspace / scripts / CI / build / env 任一配置 | `setup-config` |
| 存在源码目录 | `setup-style` |
| 存在 `CLAUDE.md`、`.claude/CLAUDE.md` 或 `.claude/rules/*.md` | `setup-rules` |
| 候选领域超过 3 个 | 至少 2 个 `setup-domain` |
| 用户明确要求 agent / 深度扫描 | 根据候选同时派发 `setup-config`、`setup-style`，必要时加 `setup-rules` / `setup-domain` |

如果 Agent 工具不可用或指定 agent 不存在，立即停止假装已派发，并在输出中说明失败原因。

## 推荐分工

| Agent | 扫描范围 | 返回重点 |
|---|---|---|
| `setup-config` | package、workspace、CI、scripts、构建脚本 | commands rule / commands skill / 验证方式 |
| `setup-style` | 组件、页面、API、store、hook、service 等代表文件 | habits 矩阵、style rule、领域 examples |
| `setup-domain` | 某个候选领域，例如 api、store、components、platform | 是否需要领域 skill、代表文件、执行顺序 |
| `setup-rules` | `.claude/rules/*.md` 与真实代码 | 已有 rules 是否可引用、是否需要补 rule |

显式派发时使用这些 agent 名称；不要临时编造新的 setup agent 名称。

Agent 工具参数应使用：

```text
subagent_type: setup-config
subagent_type: setup-style
subagent_type: setup-domain
subagent_type: setup-rules
```

## 子代理提示

```text
你是 setup 深度扫描子代理。只读扫描，不修改文件，不生成 .claude 内容，不做最终决策。

扫描范围：<路径 / 领域 / 候选项>
目标：验证这些候选 rules / skills 是否有足够证据，并提取编码习惯。

请读取代表文件，返回表格：

| 类型 | 候选名称 | 观察结果 | 证据文件 | 强度 | 建议落点 |
|---|---|---|---|---|---|

强度只能是：强规则 / 稳定习惯 / 内部观察 / 不采用。

边界：
- 不输出最终“应该生成什么”的结论。
- 不写文件。
- 不展示无关目录树。
- 证据文件必须是实际读取过的文件。
```

## 主线程合并规则

1. 合并同名候选。
2. 去掉不采用项。
3. 内部观察只进扫描账本，不进入用户默认输出。
4. 强规则优先落到 rules。
5. 稳定习惯按领域落到 skill references。
6. 最终建议分成 rules、skills、references 三张表输出，不要合并成一张总表，不要默认输出依据列。
