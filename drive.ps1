
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Drive
)

#log directory
if ($PSVersionTable.Platform -eq 'Unix') {
    $logPath = '/tmp'
}
else{
    $logPath = 'C:\Logs'
}

$logFile = "$logPath\driveCheck.log"

#verify if log directory exist
try{
    if(-not(Test-Path -Path $logPath -ErrorAction Stop)){
        New-Item -ItemType Directory -Path $logPath -ErrorAction Stop | Out-Null
        New-Item -ItemType File -Path $logFile -ErrorAction Stop | Out-Null
    }
}
catch{
    throw
}

Add-Content -Path $logFile -Value "[INFO] Running $PSCommandPath"

#verify that PoshGram is installed
if(-not (Get-Module -Name PoshGram -ListAvailable)){
    Add-Content -Path $logFile -Value "[ERROR] PoshGram is not installed"
    throw
}
else{
    Add-Content -Path $logFile -Value "[INFO] PoshGram is installed"
}

#get hard drive information
try {
    if ($PSVersionTable.Platform -eq 'Unix') {
        $volume = Get-PSDrive -Name $Drive -ErrorAction Stop
        if($volume){
            $total = $volume.Used + $volume.Free
            $percentFree = [int](($volume.Free / $total) * 100)
            Add-Content -Path $logFile -Value "[INFO] Percent Free: $percentFree%"
        } 
        else{
            Add-Content -Path $logFile -Value "[ERROR] $Drive is not found"
            throw
        }
    }
    else{
        $volume = Get-Volume -ErrorAction Stop | Where-Object {$_.DriveLetter -eq $Drive}
        if($volume){
            $total = $volume.Size
            $percentFree = [int](($volume.SizeRemaining / $total) * 100)
            Add-Content -Path $logFile -Value "[INFO] Percent Free: $percentFree%"
        } 
        else{
            Add-Content -Path $logFile -Value "[ERROR] $Drive is not found"
            throw
        }
    }
}
catch {
    Add-Content -Path $logFile -Value "[ERROR] Unable to retrieve volume information"
    Add-Content -Path $logFile -Value $_
    throw
}


#send information if drive is low
if ($percentFree -le 70) {
    try {
        Import-Module -Name PoshGram -ErrorAction Stop
        Add-Content -Path $logFile -Value "[INFO] Imported PoshGram successfully"
    }
    catch {
        Add-Content -Path $logFile -Value "[ERROR] Poshgram cound not be imported"
        Add-Content -Path $logFile -Value $_
    }

    Add-Content -Path $logFile -Value "[INFO] Sending Telegram notification"

    $sendTelegramSplat = @{
        BotToken =  "BOT_TOKEN" # change to your bot token
        ChatID = "CHAT_ID"  # change to your chat id
        Message = "[LOW SPACE] Drive at $percentFree"
        ErrorAction = "Stop"
    }

    try {
        Send-TelegramTextMessage @sendTelegramSplat
        Add-Content -Path $logFile -Value "[INFO] Message sent successfully"
    }
    catch {
        Add-Content -Path $logFile -Value "[ERROR] Error encountered sending message"
        Add-Content -Path $logFile -Value $_
        throw
    }

 
}
