Run a clean Flutter launch for this workspace.

Steps:
1. **Free port 8080**: Use PowerShell to find and kill any process holding port 8080:
   ```
   powershell -Command "Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }"
   ```
   Do not check whether anything was actually running — just run the kill command unconditionally.

2. **Launch**: Run Flutter in the background (use `run_in_background: true`):
   ```
   cd "c:/Projects/XpenseDesk/FrontEnd/xpensedesk_flutter/XpenseDesk_Flutter" && flutter run -d chrome --dart-define=ENV=dev --web-port=8080 --no-pub
   ```
   Do not wait for the background task to complete — it is a long-lived dev server.

3. Use the launch configuration name passed as the argument (`$ARGUMENTS`) when provided.
4. If no argument is provided, default to **Flutter Dev (Chrome)** (chrome, ENV=dev, port 8080).
5. Available configurations (from [.vscode/launch.json](.vscode/launch.json)):
   - `Flutter Dev (Chrome)` — `-d chrome --dart-define=ENV=dev --web-port=8080` (default)
   - `Flutter Prod (Chrome)` — `-d chrome --dart-define=ENV=prod --web-port=8080`
   - `Flutter Dev (Web Server - External)` — `-d web-server --web-hostname=0.0.0.0 --dart-define=ENV=dev --web-port=8080`
6. **Silent execution:** Say nothing on success. Only speak if a step fails.
