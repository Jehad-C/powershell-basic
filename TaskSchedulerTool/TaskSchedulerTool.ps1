param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Create", "Update", "Delete")]
    [string]$Action,          # Action to be performed

    [string]$TaskName,        # Name of the task
    [string]$TaskDescription, # Description of the task
    [string]$TaskTime,        # Time the task is scheduled to run
    [string]$TaskFrequency,   # Frequency of the task
    [string]$FilePath,        # Path to the file to be executed by the task
    [string]$User             # User under which the task will run
)

# Function to create a scheduled task
function Create-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,        # Name of the task

        [Parameter(Mandatory=$true)]
        [string]$TaskDescription, # Description of the task

        [Parameter(Mandatory=$true)]
        [ValidatePattern("^(0?[0-9]|1[0-2]):[0-5][0-9][ ](AM|PM)$")]
        [string]$TaskTime,        # Time the task is scheduled to run

        [Parameter(Mandatory=$true)]
        [ValidateSet("Daily", "Weekly", "Monthly")]
        [string]$TaskFrequency,   # Frequency of the task

        [Parameter(Mandatory=$true)]
        [string]$FilePath,        # Path to the file to be executed by the task

        [Parameter(Mandatory=$true)]
        [string]$User             # User under which the task will run
    )

    # Check if the task already exists
    $scheduledTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($scheduledTask) {
        throw "Task name: $TaskName already exists"
    }

    # Create the task trigger based on the specified frequency
    $trigger = switch ($TaskFrequency) {
        "Daily"   { New-ScheduledTaskTrigger -At $TaskTime -Daily }
        "Weekly"  { New-ScheduledTaskTrigger -At $TaskTime -Weekly }
        "Monthly" { New-ScheduledTaskTrigger -At $TaskTime -Monthly }
    }

    # Define the action to be performed by the task
    $argument = "-File $FilePath"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argument

    # Configure task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun

    try {
        # Register the scheduled task
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $TaskName -Description $TaskDescription `
        -TaskPath "workspace" -Settings $settings -User $User -RunLevel "Highest" -Force
    } catch {
        # Handle potential errors during scheduled task registration
        throw "Failed to register scheduled task"
    }
}

# Function to delete a scheduled task
function Delete-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName # Name of the task
    )

    try {
        # Unregister the scheduled task
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    } catch {
        # Handle potential errors during scheduled task unregistration
        throw "Failed to unregister scheduled task"
    }    
}

# Function to update a scheduled task
function Update-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,        # Name of the task

        [string]$TaskDescription, # Description of the task

        [ValidatePattern("^(0?[0-9]|1[0-2]):[0-5][0-9][ ](AM|PM)$")]
        [string]$TaskTime,        # Time the task is scheduled to run

        [ValidateSet("Daily", "Weekly", "Monthly")]
        [string]$TaskFrequency,   # Frequency of the task

        [string]$FilePath,        # Path to the file to be executed by the task

        [string]$User             # User under which the task will run
    )

    # Retrieve existing task information
    $scheduledTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue | Select Actions, Description, Triggers
    if (-not $scheduledTask) {
        throw "Task name: $TaskName not found"
    }

    # Extract previous task details
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

    # Apply new task details if specified otherwise retain existing values
    $newTaskDescription = if ($TaskDescription) { $TaskDescription } else { $previousTaskDescription }
    $newTaskTime = if ($TaskTime) { $TaskTime } else { $previousTaskTime }
    $newTaskFrequency = if ($TaskFrequency) { $TaskFrequency } else { $previousTaskFrequency }
    $newFilePath = if ($FilePath) { $FilePath } else { $previousFilePath }

    # Register a new scheduled task with updated properties
    Delete-ScheduledTask -TaskName $TaskName
    Create-ScheduledTask -TaskName $TaskName -TaskDescription $newTaskDescription -TaskTime $newTaskTime `
    -TaskFrequency $newTaskFrequency -FilePath $newFilePath -User $User
}

# Main script execution
# Perform the specified action
switch($Action) {
    "Create" {
        Create-ScheduledTask -TaskName $TaskName -TaskDescription $TaskDescription -TaskTime $TaskTime `
        -TaskFrequency $TaskFrequency -FilePath $FilePath -User $User
        Write-Output "Successfully created scheduled task: $TaskName"
    }

    "Update" {
        Update-ScheduledTask -TaskName $TaskName -TaskDescription $TaskDescription -TaskTime $TaskTime `
        -TaskFrequency $TaskFrequency -FilePath $FilePath -User $User
        Write-Output "Successfully updated scheduled task: $TaskName"
    }

    "Delete" {
        Delete-ScheduledTask -TaskName $TaskName
        Write-Output "Successfully deleted scheduled task: $TaskName"
    }
}
