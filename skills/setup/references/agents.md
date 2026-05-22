# Setup Deep Scan Agents

setup 可以使用子代理做并发深度扫描。子代理只负责收集证据，主线程负责合并、判断和写入。

## 何时派发

满足任一条件时可以派发：

- 候选领域超过 3 个；
- 项目已有多份 `.claude/rules/`，需要核对真实代码；
- 需要同时扫描配置命令、编码习惯、多个业务领域；
- 用户明确要求深入 setup 或使用 agent。

小项目不要默认派发；主线程直接完成扫描。

## 推荐分工

| Agent | 扫描范围 | 返回重点 |
|---|---|---|
| `setup-config` | package、workspace、CI、scripts、构建脚本 | commands rule / commands skill / 验证方式 |
| `setup-style` | 组件、页面、API、store、hook、service 等代表文件 | habits 矩阵、style rule、领域 examples |
| `setup-domain` | 某个候选领域，例如 api、store、components、platform | 是否需要领域 skill、代表文件、执行顺序 |
| `setup-rules` | `.claude/rules/*.md` 与真实代码 | 已有 rules 是否可引用、是否需要补 rule |

显式派发时使用这些 agent 名称；不要临时编造新的 setup agent 名称。

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
6. 最终建议用表格输出：类型、名称 / 路径、作用、内容概要、依据。
