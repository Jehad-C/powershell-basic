param(
    [Parameter(Mandatory=$true)]
    [string]$Name,

    [Parameter(Mandatory=$true)]
    [string]$Description,

    [Parameter(Mandatory=$true)]
    [string]$TargetFile,

    [Parameter(Mandatory=$true)]
    [ValidatePattern("^(0?[0-9]|1[0-2]):[0-5][0-9](AM|PM)$")]
    [string]$Time,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$Frequency = "Daily",

    [Parameter(Mandatory=$true)]
    [ValidateSet("Create", "Update", "Delete")]
    [string]$TaskAction = "Create"
)

function Create {
    if (Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue) {
        throw "Task: $Name already exists"
    }

    $trigger = switch($Frequency) {
        "Daily" { New-ScheduledTaskTrigger -At $Time -Daily }
        "Weekly" { New-ScheduledTaskTrigger -At $Time -Weekly }
        "Monthly" { New-ScheduledTaskTrigger -At $Time -Monthly }
    }

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $TargetFile"
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun

    try {
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $Name -Description $Description `
        -TaskPath "workspace" -Settings $settings -User "<User>" -RunLevel "Highest" -Force
    } catch {
        throw "Failed to register scheduled task: $Name. Details: $_"
    }
}

function Remove {
    try {
        Unregister-ScheduledTask -TaskName $Name -Confirm:$false
    } catch {
        throw "Failed to unregister scheduled task: $Name. Details: $_"
    }
}

switch($TaskAction) {
    "Create" {
        Create
        Write-Output "Successfully created scheduled task: $Name"
    }

    "Update" {
        Remove
        Create
        Write-Output "Successfully updated scheduled task: $Name"
    }

    "Delete" {
        Remove
        Write-Output "Successfully deleted scheduled task: $Name"
    }

    default { throw "Invalid action: $TaskAction. Use Create, Update or Delete" }
}
