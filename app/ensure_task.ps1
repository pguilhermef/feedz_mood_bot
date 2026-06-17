param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $true)]
    [string]$TaskScript,

    [Parameter(Mandatory = $false)]
    [string]$TaskTime = "08:30"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $TaskScript)) {
    throw "TaskScript nao encontrado: $TaskScript"
}

$userId = "$env:USERDOMAIN\$env:USERNAME"

$start = (Get-Date).Date
$parts = $TaskTime.Split(":")
if ($parts.Count -eq 2) {
    $start = $start.AddHours([int]$parts[0]).AddMinutes([int]$parts[1])
}
else {
    $start = $start.AddHours(8).AddMinutes(30)
}

if ($start -lt (Get-Date)) {
    $start = $start.AddDays(1)
}

$startBoundary = $start.ToString("s")
$args = '/c ""' + $TaskScript + '"" --scheduled'
$workingDir = Split-Path -Parent $TaskScript

$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>$userId</Author>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>$startBoundary</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$userId</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$env:ComSpec</Command>
      <Arguments>$args</Arguments>
      <WorkingDirectory>$workingDir</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@

$tmpXml = Join-Path $env:TEMP ("feedz_task_" + $TaskName + ".xml")
$xml | Out-File -FilePath $tmpXml -Encoding Unicode -Force

try {
    & schtasks /create /tn $TaskName /xml $tmpXml /f | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "schtasks /create retornou codigo $LASTEXITCODE"
    }

    $service = New-Object -ComObject "Schedule.Service"
    $service.Connect()
    $root = $service.GetFolder("\")
    $def = $root.GetTask($TaskName).Definition

    if (-not $def.Settings.StartWhenAvailable) {
        throw "StartWhenAvailable=False"
    }

    if ($def.Settings.DisallowStartIfOnBatteries) {
        throw "DisallowStartIfOnBatteries=True"
    }

    if ($def.Settings.StopIfGoingOnBatteries) {
        throw "StopIfGoingOnBatteries=True"
    }

    $triggerTypes = @()
    foreach ($trigger in $def.Triggers) {
        $triggerTypes += [string]$trigger.Type
    }

    if ($triggerTypes.Count -ne 1 -or $triggerTypes[0] -ne "2") {
      throw "A tarefa deve ter apenas CalendarTrigger diario"
    }
}
finally {
    Remove-Item -Path $tmpXml -Force -ErrorAction SilentlyContinue
}
