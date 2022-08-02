Class Logging {
    [string]$LogFormat = "{0} {1,-5} {2}"
    [string]$LogFilePath
    [object]$MessageList
    [string]$ScriptID

    Logging() {
        $this.ScriptID = "TEST"
        $this.SetLogFilePath("C:\tmp\", $this.ScriptID + "_%(xx).log")
        $this.SetMessageList()
        New-Item $this.LogFilePath
    }

    Logging(
        [string]$LogFilePath,
        [string]$ScriptID
    ) {
        $this.LogFilePath = $LogFilePath
        $this.SetMessageList()
        $this.ScriptID = $ScriptID
        New-Item $this.LogFilePath
    }

    Logging(
        [string]$LogFileDir,
        [string]$ScriptID,
        [string]$YMD
    ) {
        $this.SetLogFilePath($LogFileDir, "$ScriptID" + "_" + "$YMD" + "_%(xx).log")
        $this.SetMessageList()
        $this.ScriptID = $ScriptID
        New-Item $this.LogFilePath
    }

    [void] SetLogFilePath(
        [string]$LogFileDir,
        [string]$LogFileName
    ) {
        $LogFileNamePattern = $LogFileName.Replace("%(xx)", "*")
        $LogFIlePathPattern = Join-Path "$LogFileDir" "$LogFileNamePattern"
        $FileCount = (Get-ChildItem "$LogFilePathPattern" | Measure-Object).Count
        
        $FileCount += 1
        $LogFileName = $LogFileName.Replace("%(xx)", $FileCount.ToString("00"))
        $this.LogFilePath = Join-Path "$LogFileDir" "$LogFileName"
    }

    [void] SetMessageList() {
        $ParentDir = Split-Path -Parent "$PSScriptRoot"
        $MessageListFile = Join-Path "$ParentDir" "\conf\message_list.json"

        $this.MessageList = (Get-Content -Path "$MessageListFile" | ConvertFrom-Json).messages
    }

    [void] WriteLog(
        [string]$Level,
        [string]$Message
    ) {
        $TimeStamp = (Get-Date -UFormat "%Y-%m-%dT%H:%M:%S")
        $Content = ($this.LogFormat -f "$TimeStamp", "$Level", "$Message")
        Write-Host "$Content"
        Add-Content -Path $this.LogFilePath -Value "$Content" -Encoding UTF8
    }

    [void] Info(
        [string]$MessageID,
        [array]$ReplacementStrings
    ) {
        $Message = $this.GetMessageString($MessageID)
        $Message = $this.ReplacePlaceHolders($Message, $ReplacementStrings)

        $this.WriteLog("INFO", "$Message")
    }

    [void] Error(
        [string]$MessageID,
        [array]$ReplacementStrings
    ) {
        $Message = $this.GetMessageString($MessageID)
        $Message = $this.ReplacePlaceHolders($Message, $ReplacementStrings)

        $this.WriteLog("ERROR", "$Message")
    }

    [string] GetMessageString(
        [string]$MessageID
    ) {
        foreach ($Message in $this.MessageList) {
            if ($Message.id -eq $MessageID) {
                return $Message.message
            }
        }
        return "NO MESSAGE by ID: $MessageID"
    }

    [string] ReplacePlaceHolders(
        [string]$Message,
        [array]$ReplacementStrings
    ) {
        $ReplaceCount = 0
        foreach ($ReplacementString in $ReplacementStrings) {
            $PlaceHolder = "{" + $ReplaceCount.ToString() + "}"
            $Message = $Message.Replace($PlaceHolder, $ReplacementString)
            $ReplaceCount += 1
        }
        return $Message
    }
}
