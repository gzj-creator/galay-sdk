# Agent instructions

在处理用户提出的“检查”“更新”或其他需要提交的动作时，先检查各个仓库的最新版本号，并与 `VERSION` 清单比对：

1. 若各仓库最新版本号 `<= VERSION` 清单中的对应版本，则继续执行用户请求。
2. 若任一仓库最新版本号 `> VERSION` 清单中的对应版本，则先更新 `VERSION` 清单。
3. 更新完成后，按该新版本创建并提交对应 tag。
4. 提交规则、版本号策略、`CHANGELOG.md`、`docs/release_note.md` 与 git commit 处理，统一参考 `commit_change` skill。

如用户明确说明“不要打 tag”“不要提交”或“只补某个文件”，以用户指令为准。
