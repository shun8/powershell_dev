# Sub 3
Param (
    [string]$S3FileName,
    [string]$S3AccumYMD,
    [string]$AccumYMD,
    [string]$BaseYMD,
    [string]$DeleteYMD,
    [string]$DBName,
    [string]$Warehouse,
    [switch]$NoDelete
)

# Path
$ParentDir = Split-Path -Parent "$PSScriptRoot"
$ConfigPath = Join-Path "$ParentDir" "\conf\load_mappings_conf.json"

# import
. (Join-Path "$PSScriptRoot" "logging.ps1")
$logger = [Logging]::new("C:\tmp", "TEST", "20220801")

# Required
if (! $S3FileName) {
    $logger.Info("test", @("1rep", "2rep"))
}
