$execPolicy = Get-ExecutionPolicy
Set-ExecutionPolicy Unrestricted
Remove-Item -Recurse -Force -Path "$env:LOCALAPPDATA\Microsoft\IdentityCache"
Remove-Item -Recurse -Force -Path "$env:LOCALAPPDATA\Microsoft\OneAuth"
Set-ExecutionPolicy $execPolicy