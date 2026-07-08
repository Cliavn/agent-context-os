# Agent Context OS

**AI Agent 协助开发通用蓝图。**

Agent Context OS is a universal blueprint for AI-agent-assisted software development.

它帮助任意软件项目建立一套可继承、可路由、可验证、可控成本的协作体系，让 Agent 在更少上下文成本下，更准确地理解项目、业务和质量要求。

## 定位

Agent Context OS 不是某个项目的文档库，也不是某种技术栈的开发规范。它是一套通用蓝图，用于帮助项目沉淀：

- 项目上下文继承
- 业务语义建模
- 架构边界约束
- 开发实现说明
- 质量门禁
- 历史问题防复发
- Token 成本控制
- 单 Agent / 多 Agent 协作策略

## 设计原则

1. **通用优先**：核心蓝图不绑定具体项目、技术栈或行业业务。
2. **按需加载**：Agent 先读入口和路由，再读取最小必要上下文。
3. **事实分级**：代码和测试优先于文档；文档过期时必须报告并修正。
4. **业务可建模**：不同项目的业务不同，但都可以按对象、流程、字段、状态、异常和验收拆解。
5. **质量可执行**：每类任务都应有 workflow、checklist、验证命令和报告模板。
6. **成本可控制**：默认不全量读文档，不无脑启用多 Agent。

## 仓库结构

```text
agent-context-os/
├─ AGENTS.md
├─ docs/
│  ├─ 00-system-overview.md
│  ├─ 01-context-routing.md
│  ├─ 02-business-modeling.md
│  ├─ 03-architecture-boundaries.md
│  ├─ 04-implementation-spec.md
│  ├─ 05-quality-gates.md
│  ├─ 06-known-issues-system.md
│  ├─ 07-token-budget.md
│  └─ 08-multi-agent-policy.md
├─ templates/
│  ├─ project/
│  ├─ business/
│  ├─ modules/
│  └─ reports/
├─ examples/
└─ scripts/
```

## 适用项目

- RPA / 自动化项目
- 桌面端应用
- Web 应用
- SaaS / 管理后台
- 数据处理工具
- 长期由人类开发者与 AI Agent 协作维护的项目

## 不适用场景

- 只需要一次性脚本的小任务
- 无需长期维护的临时实验
- 不希望沉淀项目上下文的短期演示

## 快速接入

1. 复制 `templates/project/` 到你的项目根目录。
2. 替换模板中的 `<项目名>`、`<技术栈>`、`<模块名>` 和 `<验证命令>`。
3. 按真实项目补齐 `docs/agent/modules/` 和业务语义文档。
4. 执行 `scripts/check-agent-context-os.ps1` 或项目内检查脚本。
5. 后续所有 Agent 任务从项目根目录的 `AGENTS.md` 和 `docs/agent/00-index.md` 开始。

## 核心收益

| 目标 | 机制 |
|---|---|
| 提高代码通过率 | workflow、checklist、质量门禁、验证矩阵 |
| 减少 Bug 产出 | 实现说明、历史问题库、防复发规则 |
| 降低 Token 消耗 | 上下文路由、摘要优先、按需深读 |
| 提升开发速度 | Agent 直接进入正确上下文，减少重复搜索 |
| 支持多项目复用 | 通用模板 + 项目事实填充 |
| 支持多 Agent | 按复杂度和收益触发，不默认增加成本 |

## License

MIT

