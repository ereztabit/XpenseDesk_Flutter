Run a clean Flutter launch for this workspace.

Steps:
1. If there is an active VS Code debug session or active Flutter run for this workspace, stop it cleanly first (use the VS Code "Stop Debugging" command via the extension API, or send a SIGTERM to any running `flutter` process targeting this workspace).
2. Launch the app **without debugging** using the VS Code extension API (`workbench.action.debug.run` or `flutter.runWithoutDebugging`).
3. Do not run `flutter pub get` explicitly — the selected launch configuration already handles it via `preLaunchTask` in [.vscode/launch.json](.vscode/launch.json).
4. Use the launch configuration name passed as the argument (`$ARGUMENTS`) when provided.
5. If no argument is provided, use the currently active Flutter launch configuration. If that cannot be determined, default to **Flutter Dev (Chrome)**.
6. Available configurations (from [.vscode/launch.json](.vscode/launch.json)):
   - `Flutter Dev (Chrome)` — Chrome, ENV=dev, port 8080 (default)
   - `Flutter Prod (Chrome)` — Chrome, ENV=prod, port 8080
   - `Flutter Dev (Web Server - External)` — web-server 0.0.0.0:8080, ENV=dev
7. If any step fails, stop immediately and report the failure. Do not continue.
8. Keep output minimal. Do not narrate the plan or explain reasoning. Only report failures or a brief completion status.
