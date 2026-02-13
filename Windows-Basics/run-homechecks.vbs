' this is needed to prevent a flickering window
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

currentScriptPath = WScript.ScriptFullName
currentScriptDir = objFSO.GetParentFolderName(currentScriptPath)
powershellScriptPath = objFSO.BuildPath(currentScriptDir, "run-homechecks.ps1")

objShell.Run "pwsh.exe -NoProfile -ExecutionPolicy Bypass -File """ & powershellScriptPath & """", 0, False
