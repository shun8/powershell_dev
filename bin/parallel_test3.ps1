# TEST
Param(
    [String]$ConfigName
)

# Path
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir = Split-Path -Parent $ScriptPath
$ParentDir = Split-Path -Parent $ScriptDir
$ConfigPath = Join-Path $ParentDir "\conf\${ConfigName}.json"

# File Check
if (!(Test-Path $ConfigPath)) {
    Write-Output "No Config File ${ConfigPath}"
    exit 1
}

# JSON
$Config = Get-Content -Path "${ConfigPath}" | ConvertFrom-Json


# Parallel
Workflow Test-Workflow {
    Param (
        $JobList,
        $Dir
    )
    
    InlineScript { echo $Using:JobList >> "C:\Users\shun8\OneDrive\powershell\powershell_dev\test\hoge.txt" }
    $Errors = 0
    ForEach -Parallel ($Job in $Workflow:JobList) {
        InlineScript { Write-Output $Using:Job }
        $Cmd = (Join-Path $Workflow:Dir $Workflow:Job.command) + ".ps1"
        InlineScript { Write-Host $Using:Cmd }
        $ret = InlineScript { Invoke-Expression ($Using:Cmd + ';$?') }
        InlineScript { Write-Host $Using:ret }
        if ($retnum -gt 10)
        {
            $Workflow:Errors += 1
        }
    }
}

Test-Workflow -JobList $Config.list -Dir $ScriptDir



echo $Config.list
