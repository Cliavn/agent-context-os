# 上下文路由

## 目标

上下文路由的目标是让 Agent 用最少 Token 读取最有用的信息，避免每次全仓扫描或全量阅读长文档。

## 分层加载策略

Agent 应按以下顺序加载上下文：

| 层级 | 内容 | 读取条件 |
|---|---|---|
| L0 | `AGENTS.md` | 每次任务必读 |
| L1 | `docs/agent/00-index.md` | 每次任务必读 |
| L2 | 任务 workflow 和 checklist | 按任务类型读取 |
| L3 | 相关模块卡片 | 修改模块前读取 |
| L4 | 业务语义摘要 | 涉及业务规则时读取 |
| L5 | 历史问题和长文档 | 复杂 bug、冲突或回归风险时读取 |

## 任务路由示例

| 任务类型 | 必读上下文 |
|---|---|
| 修复 Bug | bug-fix workflow、bug checklist、相关模块卡片、历史问题库 |
| 新增功能 | new-feature workflow、模块卡片、业务规则、验收口径 |
| 重构 | refactor workflow、架构边界、模块依赖、现有测试 |
| 字段规则变更 | 字段规则文档、业务流程、状态机、回归用例 |
| UI 改造 | UI workflow、设计规则、相关页面模块卡片 |
| 数据库变更 | storage 模块卡片、migration 规则、回滚方案 |
| 发布或提交 | version-control workflow、发布 checklist |

## 过期文档处理

文档应包含元信息：

```md
状态：current / supplement / history / deprecated
最后校验日期：<YYYY-MM-DD>
关联代码路径：
关联测试：
适用范围：
过期风险：
```

规则：

- `current` 可作为主上下文。
- `history` 只用于回溯，不作为当前实现依据。
- 超过项目约定期限未校验的文档，必须对照代码确认。
- 文档和代码冲突时，以代码和测试为准，并报告文档过期。

## Token 控制原则

- 先读摘要，不读全文。
- 先读 current，不读 history。
- 先读模块卡片，再读长文档。
- 只有出现冲突、复杂 bug 或高风险变更时才深读。
- 多 Agent 必须有明确触发条件和任务包。

