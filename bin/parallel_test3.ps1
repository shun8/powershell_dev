# TEST
Param(
    [string]$Target,
    [switch]$Rerun,
    [string]$AccumYMD,
    [string]$DeleteYMD
)

# ExitCode
$SuccessfulCode = 0
$ErrorCode = 128

# Check: Required
if (! $Target) {
    $logger.error("test", @("1rep", "target"))
    exit($ErrorCode)
}

# Path
$ParentDir = Split-Path -Parent "$PSScriptRoot"
$ConfigPath = Join-Path $ParentDir "\conf\${Target}_conf.json"

# File Check
if (!(Test-Path $ConfigPath)) {
    Write-Output "No Config File ${ConfigPath}"
    exit $ErrorCode
}

# Config
$Config = Get-Content -Path "${ConfigPath}" | ConvertFrom-Json
$TmpDir = $Config.tmp_dir
$Env:TMP = "$TmpDir"

# import: Logger
. (Join-Path "$PSScriptRoot" "logging.ps1")
$logger = [Logging]::new("C:\tmp", "$ScriptID", "20220801")

# Def: Parallel Workflow
Workflow Test-Workflow {
    Param (
        [object]$JobList,
        [string]$Dir,
        [string]$AccumYMD,
        [string]$BaseYMD,
        [string]$DeleteYMD,
        [switch]$Rerun
    )
    
    $Errors = 0
    ForEach -Parallel ($Job in $Workflow:JobList) {
        if (! $Workflow:DeleteYMD) {
            if ($Rerun) {
                $Workflow:DeleteYMD = $Workflow:BaseYMD
            }
            elseif ($Job.delete_term -eq "D") {
                $GenerationNum = [int]($Job.generation_num)
                $DeleteYMD = [DateTime]::ParseExact( `
                        "$Workflow:BaseYMD","yyyyMMdd", $null)
                $DeleteYMD = $DeleteYMD.AddDays( `
                        -1 * $GenerationNum).ToString("yyyyMMdd")
                $Workflow:DeleteYMD = $DeleteYMD
            }
            elseif ($Job.delete_term -eq "M") {
                $GenerationNum = [int]($Job.generation_num)
                $DeleteYMD = [DateTime]::ParseExact( `
                        "$Workflow:BaseYMD","yyyyMMdd", $null)
                $DeleteYMD = $DeleteYMD.AddMonths( `
                        -1 * $GenerationNum).ToString("yyyyMMdd")
                $Workflow:DeleteYMD = $DeleteYMD
            }
        }

        if (($Job.delete_term -eq "M") `
                -And ($Job.delete_day -ne $AccumYMD.Substring(6, 2))) {
            $NoDelete = True
        }
        else {
            $NoDelete = False
        }

        $Cmd = (Join-Path $Workflow:Dir $Workflow:Job.command) + ".ps1" `
                + " -AccumYMD $Workflow:AccumYMD" `
                + " -BaseYMD $Workflow:BaseYMD" `
                + " -DeleteYMD $Workflow:DeleteYMD" `
                + " -NoDelete $NoDelete"

        $result = InlineScript {
            (Invoke-Expression ($Using:Cmd + ";`$?"))
        }
        if (! $result[-1])
        {
            #log
            $Workflow:Errors += 1
        }
        else {
            #Log
        }
    }
    Write-Output $Errors
}

# Get AccumYMD
if (! $AccumYMD) {
    $TmpAccumYMDFile = New-TemporaryFile
    $TmpAccumYMDFilePath = Join-Path "$TmpDir" $TmpAccumYMDFile.Name
    aws s3 cp $Config.accum_ymd_path "$TmpAccumYMDFilePath"
    if ($LASTEXITCODE -ne 0) {
        $logger.error("test", @("1rep", "s3error"))
        Remove-Item $TmpAccumYMDFile
        exit($ErrorCode)
    }
    $AccumYMDJSON = (Get-Content -Path "$TmpAccumYMDFilePath" | ConvertFrom-Json)
    $AccumYMD = $AccumYMDJSON.accum_ymd
    Remove-Item $TmpAccumYMDFile
}

# Set BaseYMD
$BaseYMD = [DateTime]::ParseExact("$AccumYMD","yyyyMMdd", $null)
$BaseYMD.AddDays(-1)
$BaseYMD = $BaseYMD.ToString("yyyyMMdd")

$ErrorCount = (Test-Workflow -JobList $Config.scripts -Dir $ScriptDir `
        -AccumYMD "$AccumYMD" -BaseYMD "$BaseYMD" -DeleteYMD "$DeleteYMD" `
        -Rerun $Rerun)

if ($ErrorCount -ne 0) {
    $logger.error("test", @("1rep", "snowsqlerror"))
    exit($ErrorCode)
}

$logger.info("test", @("1rep", "success"))
exit($SuccessfulCode)
