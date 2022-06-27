# TEST
Param(
    [string]$ConfigName
)

$ScriptPath = $MyInvocation.MyCommand.Path
$ParentPath = Split-Path -Parent (Split-Path -Parent $ScriptPath)
$ConfigPath = Join-Path $ParentPath "\conf\${ConfigName}.json"
Write-Output $ConfigPath