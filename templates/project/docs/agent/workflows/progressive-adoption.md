# Workflow：渐进式接入

## 目标

将已有项目低成本接入 Agent Context Engine，安装最小协作规则，并避免首次接入阶段全量分析旧文档或消耗过多 Token。

## 步骤

1. 检查项目根目录是否存在 `AGENTS.md`、`Agent.md`、`docs/agent/` 和旧文档目录。
2. 向用户说明将创建或合并协作入口文件，并明确不会全量分析旧文档。
3. 等待用户确认。
4. 创建或合并 `AGENTS.md`，保留已有用户规则。
5. 创建最小 `docs/agent/` 文件：`00-index.md`、`adoption.md`、`style-profile.md`、`memory.md`、`legacy-docs.md`、`quality.md`。
6. 创建必要 workflow、checklist 和任务报告模板。
7. 轻量记录旧文档路径和主题，不读取全文。
8. 将接入状态记录为 `progressive`。
9. 运行结构检查。
10. 告诉用户可以直接开始开发任务。

## 合并规则

- 不得静默覆盖已有 `AGENTS.md` 或 `Agent.md`。
- 已有规则必须保留。
- 新规则应写入明确标记的 Agent Context Engine 区块。
- 发现冲突时，必须报告冲突并等待用户确认。

推荐标记：

```md
<!-- BEGIN Agent Context Engine -->
<协作规则>
<!-- END Agent Context Engine -->
```

## 旧文档规则

- 首次接入只建立索引，不总结全文。
- 旧文档默认状态为 `indexed`，可信度为 `unknown`。
- 只有任务需要时才读取旧文档全文。
- 读取后只迁移已确认、仍然有效、与当前任务相关的事实。

## 禁止事项

- 不允许首次接入阶段全量阅读所有旧文档。
- 不允许把旧文档直接视为当前事实。
- 不允许要求用户先补齐完整文档结构。
- 不允许为了文档完整性扩大接入范围。
