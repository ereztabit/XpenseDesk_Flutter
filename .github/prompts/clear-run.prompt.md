---
name: "clear-run"
description: "Stop an active Flutter run/debug session, then launch without debugging. Use when: /clear-run or when restarting the app cleanly."
argument-hint: "[launch configuration name]"
agent: "agent"
---

Run a clean Flutter launch for this workspace.

Steps:
1. If there is an active VS Code debug session or active Flutter run for this workspace, stop it cleanly first.
2. Launch the app without debugging.
3. Do not run `flutter pub get` explicitly. The selected launch configuration already handles it via `preLaunchTask` in [launch.json](../../.vscode/launch.json).
4. Use the launch configuration name passed as the prompt argument when provided.
5. If no argument is provided, use the currently selected Flutter launch configuration. If that cannot be determined, use `Flutter Dev (Chrome)`.
6. If any step fails, stop immediately and report the failure instead of continuing.
7. Keep chat output minimal while executing. Do not explain reasoning or narrate the plan. Only report failures or a brief completion status.

Prefer the workspace launch configurations in [launch.json](../../.vscode/launch.json) and the pre-launch task in [tasks.json](../../.vscode/tasks.json).