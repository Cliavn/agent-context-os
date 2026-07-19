# Checklist：多任务并行 Git worktree

- [ ] 已判断变更等级：`S0 / S1 / S2 / S3`。
- [ ] 已判断是否存在多个 Codex 任务并行。
- [ ] 已确认本次使用主工作区还是独立 Git worktree。
- [ ] 如使用主工作区，已确认是 S0/S1 小改动、工作区干净且修改范围清晰。
- [ ] 如使用独立 Git worktree，已在项目目录外创建临时工作树。
- [ ] 已为临时工作树创建独立 branch。
- [ ] 已在 `docs/agent/runtime/current-task.md` 记录 `workspace_mode`、`worktree_path`、`worktree_branch` 和 `worktree_cleanup`。
- [ ] 所有修改、验证和本地提交均在正确工作区完成。
- [ ] 只暂存并提交本次任务相关文件。
- [ ] 集成阶段已合并临时分支或记录废弃原因。
- [ ] 已执行 `git worktree remove <worktree路径>` 或说明不能清理的原因。
- [ ] 已执行 `git worktree prune` 或说明不能执行的原因。
- [ ] 如临时分支已合并，已删除分支或说明保留原因。
- [ ] 已运行 `scripts/check-agent-worktrees.ps1` 或说明无法运行原因。
- [ ] 最终报告包含工作区模式、工作树路径、分支、合并状态和清理状态。
