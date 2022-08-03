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

# ExitCode
$SuccessfulCode = 0
$ErrorCode = 127

# ID
$ScriptID = "TEST"

# Path
$ParentDir = Split-Path -Parent "$PSScriptRoot"
$ConfigPath = Join-Path "$ParentDir" "\conf\load_mappings_conf.json"

# File Check
if (!(Test-Path $ConfigPath)) {
    Write-Output "No Config File ${ConfigPath}"
    exit $ErrorCode
}

# Set Config
$Config = Get-Content -Path "${ConfigPath}" | ConvertFrom-Json
$TmpDir = $Config.tmp_dir
$Env:TMP = "$TmpDir"

# import: Logger
. (Join-Path "$PSScriptRoot" "logging.ps1")
$logger = [Logging]::new("C:\tmp", "$ScriptID", "20220801")

# Check: Required
if (! $S3FileName) {
    $logger.error("test", @("1rep", "s3filename"))
    exit($ErrorCode)
}
if (! $S3AccumYMD) {
    $logger.error("test", @("1rep", "s3accumymd"))
    exit($ErrorCode)
}
if (! $AccumYMD) {
    $logger.error("test", @("1rep", "accumymd"))
    exit($ErrorCode)
}
if (! $BaseYMD) {
    $logger.error("test", @("1rep", "baseymd"))
    exit($ErrorCode)
}
if ((! $NoDelete) -And (! $DeleteYMD)) {
    $logger.error("test", @("1rep", "deleteymd"))
    exit($ErrorCode)
}
if (! $DBName) {
    $logger.error("test", @("1rep", "dbname"))
    exit($ErrorCode)
}
if (! $Warehouse) {
    $logger.error("test", @("1rep", "warehouse"))
    exit($ErrorCode)
}

# Check: Datetime
try {
    [DateTime]::ParseExact("$S3AccumYMD","yyyyMMdd", $null)
}
catch {
    $logger.error("test", @("1rep", "s3accumymd"))
    exit($ErrorCode)
}
try {
    [DateTime]::ParseExact("$AccumYMD","yyyyMMdd", $null)
}
catch {
    $logger.error("test", @("1rep", "accumymd"))
    exit($ErrorCode)
}
try {
    [DateTime]::ParseExact("$BaseYMD","yyyyMMdd", $null)
}
catch {
    $logger.error("test", @("1rep", "baseymd"))
    exit($ErrorCode)
}
try {
    if ("$DeleteYMD") {
        [DateTime]::ParseExact("$DeleteYMD","yyyyMMdd", $null)
    }
}
catch {
    $logger.error("test", @("1rep", "deleteymd"))
    exit($ErrorCode)
}

# Read Config
foreach ($Mapping in $Config.mappings) {
    if ($S3FileName -eq $Mapping.file_name) {
        $SQLInfo = $Mapping
        break
    }
}
if (! $SQLInfo) {
    $logger.error("test", @("1rep", "2rep"))
    exit($ErrorCode)
}

# URI Pattern
$S3PathPattern = "/$S3FileName/.+/$AccumYMD/.+"

# Generate: Tmp SQL FIle
if ($NoDelete) {
    $SQLFileName = "$ScriptID" + "_load_no_delete.sql"
    $BaseSQLFile = Join-Path $Config.sql_dir "$SQLFileName"
}
else {
    $SQLFileName = "$ScriptID" + "_load.sql"
    $BaseSQLFile = Join-Path $Config.sql_dir "$SQLFileName"
}

$TmpSQLFile = New-TemporaryFile
if (! $?) {
    $logger.error("test", @("1rep", "2rep"))
    exit($ErrorCode)
}

Copy-Item -Path "$BaseSQLFile" -Destination "$TmpSQLFile"

$ENCODING = "UTF8"
(Get-Content "$TmpSQLFile" -Encoding "$ENCODING") | `
ForEach-Object {
    $_ -replace '<table_name>',$SQLInfo.table_name `
        -replace '<table_columns_order>',$SQLInfo.table_columns_order `
        -replace '<s3_filename_pattern>',"$S3PathPattern"
} | Set-Content "$TmpSQLFile" -Encoding "$ENCODING"

# Execute: SnowSQL
# TODO: SecretManager
$SnowsqlJSON = (Get-Content -Path "<forUT>" | ConvertFrom-Json)
$Env:SNOWSQL_PWD = $SnowSQLInfo.Password
$TmpErrorFile = New-TemporaryFile
snowsql -a <account>.ap-northeast-1.aws -d test -u <user> -s <schema>`
        -f ..\sql\transaction_test.sql `
        -o variable_substitution=true `
        -D table_name=h_0 -D id=00005 2>> $TmpErrorFile

if (($LASTEXITCODE -ne 0) -Or ((Get-Item $TmpErrorFile).Length -ne 0)) {
    $logger.error("test", @("1rep", "snowsqlerror"))
    Remove-Item $TmpSQLFile
    Remove-Item $TmpErrorFile
    exit($ErrorCode)
}

$logger.info("test", @("1rep", "success"))
Remove-Item $TmpSQLFile
Remove-Item $TmpErrorFile
exit($SuccessfulCode)
