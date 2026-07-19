# Agent Context OS

**AI Agent 协助开发通用蓝图。**

Agent Context OS is a universal blueprint for AI-agent-assisted software development.

它帮助任意软件项目建立一套可渐进接入、可继承、可路由、可记忆、可验证、可控成本的协作体系，让 Agent 在更少上下文成本下，更准确地理解项目、业务和质量要求，并随着协作持续完善项目理解。

## 定位

Agent Context OS 不是某个项目的文档库，也不是某种技术栈的开发规范。它是一套通用蓝图，用于帮助项目沉淀：

- 项目上下文继承
- 老项目渐进式接入
- 项目记忆沉淀
- 项目风格画像与端侧习惯
- 方案理解与摄取
- 方案落实台账
- 变更分级与执行门禁
- 业务语义建模
- 架构边界约束
- 开发实现说明
- 质量门禁
- 历史问题防复发
- Token 成本控制
- 单 Agent / 多 Agent 协作策略
- 多 Codex 任务并行开发隔离

## 设计原则

1. **通用优先**：核心蓝图不绑定具体项目、技术栈或行业业务。
2. **按需加载**：Agent 先读入口和路由，再读取最小必要上下文。
3. **渐进接入**：老项目首次接入只安装协作规则，不全量分析旧文档。
4. **主动记忆**：用户补充的可复用项目事实必须评估是否写回，而不是只停留在当前对话。
5. **方案先理解**：完整方案必须先识别初衷、业务意义和系统影响；仍处于讨论阶段时不得写回当前协作文档，必须等用户明确确认定版、执行或写回后再拆解和写回。
6. **落地可追踪**：多轮讨论后的方案必须通过草稿、定稿和任务状态台账承接，避免实现时遗漏确认细节。
7. **变更分级**：微小变更走轻量模式，高风险变更走完整门禁。
8. **事实分级**：代码和测试优先于文档；文档过期时必须报告并修正。
9. **业务可建模**：不同项目的业务不同，但都可以按对象、流程、字段、状态、异常和验收拆解。
10. **质量可执行**：每类任务都应有 workflow、checklist、验证命令和报告模板。
11. **成本可控制**：默认不全量读文档，不无脑启用多 Agent。
12. **并行可隔离**：小改动可在主工作区轻量完成；大改造、长期任务或多个 Codex 任务并行时，必须使用独立 Git worktree（工作树）和独立 branch（分支），并在任务结束后清理临时工作树。

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
│  ├─ 08-multi-agent-policy.md
│  ├─ 09-project-memory.md
│  ├─ 10-progressive-adoption.md
│  ├─ 11-plan-intake.md
│  ├─ 12-execution-gates.md
│  ├─ 13-project-style-profile.md
│  ├─ 14-retrieval-memory-store.md
│  ├─ 15-release-readiness-review.md
│  └─ 16-plan-execution-ledger.md
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

## 快速接入：新项目

1. 复制 `templates/project/` 到你的项目根目录。
2. 确认复制结果包含 `AGENTS.md`、`docs/agent/`、`scripts/`、`.gitattributes` 和 `.gitignore`。
3. 替换模板中的 `<项目名>`、`<技术栈>`、`<模块名>` 和 `<验证命令>`。
4. 按真实项目补齐 `docs/agent/modules/`、`docs/agent/memory.md` 和业务语义文档。
5. 执行 `scripts/check-agent-strong.ps1`；如果项目尚未启用完整脚本，再分别执行 `scripts/check-project-memory-store.ps1`、`scripts/check-agent-worktrees.ps1` 和 `scripts/check-agent-drift.ps1`。
6. 后续所有 Agent 任务从项目根目录的 `AGENTS.md` 和 `docs/agent/00-index.md` 开始。

## 快速接入：老项目

老项目、文档散乱项目或已有旧文档结构的项目，默认使用渐进式接入：

1. 在项目根目录请求 Agent 应用 Agent Context Engine。
2. Agent 只创建或合并最小协作入口，不全量分析旧文档。
3. 旧文档只建立索引，默认不作为当前事实。
4. 后续开发任务中，Agent 按需读取旧文档、迁移有效事实并写回项目记忆。

## 核心收益

| 目标 | 机制 |
|---|---|
| 提高代码通过率 | workflow、checklist、质量门禁、验证矩阵 |
| 减少 Bug 产出 | 实现说明、历史问题库、防复发规则 |
| 降低接入成本 | 渐进式接入、旧文档索引、按需迁移 |
| 降低 Token 消耗 | 上下文路由、摘要优先、按需深读 |
| 沉淀项目记忆 | 用户补充背景、业务事实、开放问题和回写规则 |
| 沉淀项目风格 | 前端、后端、客户端等端侧的风格、交互和工程习惯 |
| 吸收完整方案 | 方案意图、业务意义、系统影响和融合更新 |
| 防止方案遗漏 | 方案落实台账、开发顺序、任务状态和完成核对 |
| 控制小改成本 | S0-S3 变更分级、轻量模式、执行门禁 |
| 提升开发速度 | Agent 直接进入正确上下文，减少重复搜索 |
| 支持多项目复用 | 通用模板 + 项目事实填充 |
| 支持多 Agent | 按复杂度和收益触发，不默认增加成本 |
| 支持多任务并行 | 按变更等级和冲突风险选择主工作区或独立 Git worktree，并要求完成后清理 |

## License

MIT
