# 检索式项目记忆存储

## 目标

检索式项目记忆存储用于把项目协作过程中形成的业务场景、前端交互、后端实现、历史问题和决策依据，沉淀为可检索、可验证、可迁移的结构化记忆。

它不是替代项目文档，而是为 Agent 提供快速召回层：

```text
代码和测试 > 当前文档 > 决策记录 > 检索记忆 > 对话摘要
```

当检索记忆与代码、测试或当前文档冲突时，必须以代码、测试和当前文档为准，并把记忆标记为 `stale` 或 `deprecated`。

## 适用场景

- 项目业务规则较多，`memory.md` 已经变成长表。
- 前端交互、后端实现、权限、接口和数据流之间存在大量隐含约束。
- 多个 Agent 或多人长期协作，需要共享可追溯上下文。
- 旧项目文档较多，需要先建立索引，再按任务召回。
- 任务开始时需要快速定位相关事实，而不是全量阅读文档。

## 分层职责

| 层级 | 职责 | 推荐介质 |
|---|---|---|
| 稳定事实层 | 人类可审查的当前事实、架构边界、业务规则 | `docs/agent/*.md`、业务文档、ADR |
| 检索记忆层 | Agent 快速召回的事实片段、坑点、交互约束、实现约束 | JSONL、关系数据库、向量数据库、全文索引 |
| 证据层 | 代码、测试、提交、任务报告、Issue、PR | 仓库、测试报告、版本控制系统 |
| 运行层 | 当前任务状态、召回结果、待确认问题 | `docs/agent/runtime/current-task.md` |

## 最小数据模型

每条记忆必须包含可追溯来源和可信度，不得只保存一段孤立文本。

```json
{
  "id": "mem-YYYYMMDD-001",
  "status": "current",
  "type": "business_rule",
  "scope": ["order", "checkout"],
  "summary": "下单时必须先锁定库存，再创建支付单。",
  "content": "适用于普通商品下单流程。库存锁定失败时不得创建支付单。",
  "source": {
    "kind": "user_confirmed",
    "ref": "docs/agent/modules/order.md",
    "date": "YYYY-MM-DD"
  },
  "evidence": [
    "src/order/OrderService.ts",
    "tests/order/checkout.test.ts"
  ],
  "confidence": "high",
  "last_verified": "YYYY-MM-DD",
  "tags": ["backend", "inventory", "payment"]
}
```

## 字段规则

| 字段 | 必填 | 说明 |
|---|---|---|
| `id` | 是 | 稳定唯一标识，推荐 `mem-YYYYMMDD-序号` |
| `status` | 是 | `current`、`draft`、`assumption`、`deprecated`、`stale` |
| `type` | 是 | `project_fact`、`business_rule`、`interaction_rule`、`architecture_rule`、`implementation_note`、`known_issue`、`decision`、`open_question` |
| `scope` | 是 | 适用模块、流程、接口、页面或业务对象 |
| `summary` | 是 | 适合检索结果展示的一句话摘要 |
| `content` | 是 | 可执行的完整记忆内容 |
| `source` | 是 | 用户说明、文档、代码、任务报告或决策来源 |
| `evidence` | 否 | 支撑该记忆的代码、测试、文档或报告路径 |
| `confidence` | 是 | `high`、`medium`、`low` |
| `last_verified` | 是 | 最近一次对照代码、测试、文档或用户确认的日期 |
| `tags` | 否 | 检索辅助标签 |

## 检索策略

检索应采用混合策略，而不是只依赖向量相似度：

1. 关键词检索：匹配模块名、接口名、字段名、页面名、业务对象和错误码。
2. 结构化过滤：按 `status`、`type`、`scope`、`tags`、`last_verified` 筛选。
3. 向量检索：召回语义相近的业务场景、历史坑和决策背景。
4. 新鲜度排序：优先使用最近校验且仍为 `current` 的记忆。
5. 来源优先级：用户确认、当前文档、代码和测试优先于对话摘要。

默认召回规则：

| 任务 | 默认召回 |
|---|---|
| 新增功能 | `business_rule`、`interaction_rule`、`architecture_rule`、`decision` |
| 修复 Bug | `known_issue`、`implementation_note`、相关 `business_rule` |
| UI 改造 | `interaction_rule`、风格事实、相关业务规则 |
| 数据库或接口变更 | `architecture_rule`、`implementation_note`、字段和接口相关记忆 |
| 方案摄取 | `decision`、`open_question`、冲突范围内的当前事实 |

## 写入流程

1. 从对话、任务报告、代码变更、文档变更或用户确认中识别可复用事实。
2. 判断是否应写入稳定文档；如果是当前事实，优先更新对应文档。
3. 同步写入检索记忆，记录来源、证据、可信度和最后校验日期。
4. 如果信息不完整，写为 `draft` 或 `open_question`，不得标为 `current`。
5. 如果只是 Agent 推测，最多写为 `assumption`，并设置低可信度。
6. 后续发现冲突时，不删除历史记录；标记为 `stale` 或 `deprecated` 并指向新事实。

## 读取流程

任务开始时，Agent 应先判断是否需要检索记忆：

- `S0` 微小变更默认不检索，除非用户补充业务背景或涉及风险点。
- `S1` 按模块、文件路径、任务类型做小范围检索。
- `S2` 必须检索相关业务、架构、实现和历史问题记忆。
- `S3` 必须检索决策、旧文档索引、历史问题、开放问题和冲突事实。

召回后必须做三件事：

1. 只采用与当前任务相关的记忆。
2. 对高风险或过期记忆回到代码、测试或当前文档验证。
3. 在任务报告中说明使用了哪些记忆，以及是否发现过期或冲突。

## 推荐存储形态

轻量项目可以只使用模板内的 JSONL 文件：

```text
docs/agent/memory-store/
├── README.md
├── memory-schema.json
├── memories.jsonl
└── retrieval-config.json
```

中大型项目可以把同一数据模型同步到数据库：

| 能力 | 推荐实现 |
|---|---|
| 结构化查询 | PostgreSQL |
| 向量检索 | pgvector、Qdrant、Weaviate、Milvus |
| 全文搜索 | PostgreSQL FTS、OpenSearch、Elasticsearch |
| 证据回链 | Git 路径、Issue、PR、任务报告路径 |

无论采用哪种数据库，都必须保留可导出的 JSONL 形态，避免项目记忆被单一工具锁定。

## 隐私和安全

- 不得写入账号、密钥、token、cookie 或真实隐私数据。
- 不得写入无法脱敏的客户数据、生产数据或安全凭据。
- 对外部系统中的 Issue、PR 或任务链接，只记录必要引用，不复制敏感正文。
- 记忆内容应按最小必要原则记录，避免把一次性对话完整存档。

## 质量门禁

启用检索式项目记忆后，任务完成前必须回答：

- 本次是否新增、更新、废弃或校验了检索记忆。
- 召回记忆是否影响实现方案。
- 是否发现过期、冲突或低可信记忆。
- 是否已把当前事实同步到人类可审查的文档。
- 是否需要更新 `memory-schema.json`、检索配置或导入脚本。
