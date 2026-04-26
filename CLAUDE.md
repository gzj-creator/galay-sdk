# Release/version workflow

当用户提出“检查”“更新”或其他需要提交的动作时，先检查各个仓库的最新版本号，并与 `VERSION` 清单比对：

1. 若各仓库最新版本号 `<= VERSION` 清单中的对应版本，只按用户当前请求继续处理。
2. 若任一仓库最新版本号 `> VERSION` 清单中的对应版本，先更新 `VERSION` 清单。
3. 更新清单后，按新的版本号创建并提交对应 tag。
4. 提交说明、版本号处理、`CHANGELOG.md`、`docs/release_note.md` 以及 git commit 规则，统一遵循 `commit_change` skill。

除非用户明确要求不要打 tag、不要提交或只修改部分文件，否则按以上流程执行。
