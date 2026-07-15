# 发布前质量审查记录

本文记录 Agent Context OS 作为可交付蓝图对外提供前的质量审查结论、发现项、修复状态和验证方式。

## 审查范围

- 根目录协作入口、README 和系统文档。
- `templates/project/` 下游项目模板。
- `templates/business/`、`templates/modules/`、`templates/reports/` 通用模板。
- `scripts/` 根仓库检查脚本。
- 下游项目复制模板后的脚本可用性。
- 敏感信息、危险命令、JSON / JSONL 结构、换行和 Git 状态。

## 发现与修复记录

| 编号 | 问题 | 风险 | 状态 |
|---|---|---|---|
| RR-001 | `templates/project/` 未包含项目级检查脚本 | 用户复制模板后没有 memory-store 和 drift 检查，质量门禁可能落空 | 已修复：新增 `templates/project/scripts/` 并由根检查脚本校验与根脚本一致 |
| RR-002 | README 新项目接入步骤指向根仓库检查脚本 | 下游项目按文档操作时可能找不到 `scripts/check-agent-context-os.ps1` | 已修复：改为运行项目模板内的检查脚本 |
| RR-003 | README 仓库结构未列出 `docs/14-retrieval-memory-store.md` | 结构说明与实际仓库不一致，用户可能漏读检索式记忆规范 | 已修复 |
| RR-004 | drift 检查未覆盖脚本、配置和常见构建文件 | `.ps1`、JSON、YAML、Dockerfile 等高风险改动可能绕过文档同步检查 | 已修复：扩展代码/配置路径识别范围 |
| RR-005 | drift 检查在下游项目缺少 `docs/agent` 时会跳过 | 未正确接入模板的项目可能误以为检查通过 | 已修复：仅蓝图模板仓库允许跳过，下游项目缺失时失败 |
| RR-006 | memory-store 只校验字段和枚举，未校验真实日期 | `2026-99-99` 等无效日期可能进入项目记忆 | 已修复：校验 `id` 日期、`source.date` 和 `last_verified` 为真实日历日期 |
| RR-007 | `privacy_rules.forbidden_content` 未实际用于扫描记忆记录 | 账号、密钥、token、cookie 等敏感标记可能被写入 `memories.jsonl` | 已修复：按配置扫描 summary、content、source、scope、evidence 和 tags |
| RR-008 | 默认隐私标记只覆盖英文词 | 中文项目中“密码”“密钥”“凭据”等敏感词不易被拦截 | 已修复：补充中文敏感标记 |
| RR-009 | 主检查未防止模板脚本和根脚本漂移 | 根脚本修复后，模板脚本可能遗留旧逻辑 | 已修复：根检查脚本校验模板脚本内容必须一致 |
| RR-010 | `templates/project/` 未包含 `.gitattributes` 和 `.gitignore` | 用户初始化 Git 后可能出现换行噪声，或误提交环境变量、日志和构建产物 | 已修复：模板项目包含基础 Git 文件并纳入根检查 |
| RR-011 | drift 检查返回空 Git 改动集合时不稳定 | 干净项目可能误报失败，且没有清晰错误原因 | 已修复：显式返回字符串数组 |

## 剩余边界

- 检查脚本只能拦截明确的敏感标记，不能证明所有真实隐私数据都不存在。
- drift 检查只能基于 Git 工作区判断变更，无法替代项目自身测试、构建和业务验收。
- 本仓库提供 PowerShell 脚本；非 Windows 环境应确认 PowerShell 可用。

## 发版前验证清单

- 运行 `scripts/check-agent-context-os.ps1`。
- 运行 `scripts/check-project-memory-store.ps1`。
- 运行 `scripts/check-agent-drift.ps1`。
- 对 memory-store、retrieval-config、schema、drift 进行负向验证。
- 扫描敏感信息和危险命令。
- 检查 `.ps1` 换行符合 `.gitattributes`。
- 确认 Git 工作区干净。
