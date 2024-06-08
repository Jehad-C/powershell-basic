param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Create", "Update", "Delete")]
    [string]$Action,          # Action

    [string]$TaskName,        # Task name
    [string]$TaskDescription, # Task description
    [string]$TaskTime,        # Task time
    [string]$TaskFrequency,   # Task frequency
    [string]$FilePath         # File path
)

# Function to create scheduled task
function Create-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,        # Task name

        [Parameter(Mandatory=$true)]
        [string]$TaskDescription, # Task description

        [Parameter(Mandatory=$true)]
        [ValidatePattern("^(0?[0-9]|1[0-2]):[0-5][0-9][ ](AM|PM)$")]
        [string]$TaskTime,        # Task time

        [Parameter(Mandatory=$true)]
        [ValidateSet("Daily", "Weekly", "Monthly")]
        [string]$TaskFrequency,   # Task frequency

        [Parameter(Mandatory=$true)]
        [string]$FilePath         # File path
    )

    $scheduledTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($scheduledTask) {
        throw "Task name: $TaskName already exists"
    }

    $trigger = switch ($TaskFrequency) {
        "Daily"   { New-ScheduledTaskTrigger -At $TaskTime -Daily }
        "Weekly"  { New-ScheduledTaskTrigger -At $TaskTime -Weekly }
        "Monthly" { New-ScheduledTaskTrigger -At $TaskTime -Monthly }
    }

    $argument = "-File $FilePath"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argument
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun

    try {
        # Create scheduled task
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $TaskName -Description $TaskDescription `
        -TaskPath "workspace" -Settings $settings -User "Lenovo-T460" -RunLevel "Highest" -Force
    } catch {
        # Handle potential errors during scheduled task creation
        throw "Failed to register scheduled task"
    }
}

# Function to delete scheduled task
function Delete-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName # Task name
    )

    try {
        # Delete scheduled task
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    } catch {
        # Handle potential errors during scheduled task deletion
        throw "Failed to unregister scheduled task"
    }    
}

function Update-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,        # Task name

        [string]$TaskDescription, # Task description

        [ValidatePattern("^(0?[0-9]|1[0-2]):[0-5][0-9][ ](AM|PM)$")]
        [string]$TaskTime,        # Task time

        [ValidateSet("Daily", "Weekly", "Monthly")]
        [string]$TaskFrequency,   # Task frequency

        [string]$FilePath         # File path
    )

    # Retrieve scheduled task information
    $scheduledTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue | Select Actions, Description, Triggers
    if (-not $scheduledTask) {
        throw "Task name: $TaskName not found"
    }

    $previousTaskDescription = $scheduledTask.Description
    $trigger = $scheduledTask.Triggers[0]
    $previousTaskTime = [DateTime]::Parse($trigger.StartBoundary).ToString("hh:mm tt")
    $previousTaskFrequency = switch ($trigger) {
        "MSFT_TaskDailyTrigger"   { "Daily" }
        "MSFT_TaskWeeklyTrigger"  { "Weekly" }
        "MSFT_TaskMonthlyTrigger" { "Monthly" }
    }

    $actions = $scheduledTask.Actions[0] | Select Arguments
    $previousFilePath = $actions.Arguments.Substring(6)

    $newTaskDescription = if ($TaskDescription) { $TaskDescription } else { $previousTaskDescription }
    $newTaskTime = if ($TaskTime) { $TaskTime } else { $previousTaskTime }
    $newTaskFrequency = if ($TaskFrequency) { $TaskFrequency } else { $previousTaskFrequency }
    $newFilePath = if ($FilePath) { $FilePath } else { $previousFilePath }

    # Delete scheduled task
    Delete-ScheduledTask -TaskName $TaskName

    # Create scheduled task
    Create-ScheduledTask -TaskName $TaskName -TaskDescription $newTaskDescription -TaskTime $newTaskTime `
    -TaskFrequency $newTaskFrequency -FilePath $newFilePath
}

switch($Action) {
    "Create" {
        Create-ScheduledTask -TaskName $TaskName -TaskDescription $TaskDescription -TaskTime $TaskTime `
        -TaskFrequency $TaskFrequency -FilePath $FilePath
        Write-Output "Successfully created scheduled task: $TaskName"
    }

    "Update" {
        Update-ScheduledTask -TaskName $TaskName -TaskDescription $TaskDescription -TaskTime $TaskTime `
        -TaskFrequency $TaskFrequency -FilePath $FilePath
        Write-Output "Successfully updated scheduled task: $TaskName"
    }

    "Delete" {
        Delete-ScheduledTask -TaskName $TaskName
        Write-Output "Successfully deleted scheduled task: $TaskName"
    }
}
