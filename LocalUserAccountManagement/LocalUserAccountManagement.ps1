param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Create", "Modify", "Delete", "Show-Users")]
    [string]$Action,
    [string]$Username,
    [string]$Password,
    [string]$FullName,
    [string]$Description
)

function Create {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Username,
        [string]$Password,
        [string]$FullName,
        [string]$Description
    )

    $existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
    if ($existingUser) {
        throw "User: $Username already exists"
    }

    $userParams = @{
        Name = $Username
        FullName = $FullName
        Description = $Description
    }

    if ($Password) {
        $securePassword = (ConvertTo-SecureString $Password -AsPlainText -Force)
        $userParams.Add("Password", $securePassword)
    } else {
        $userParams.Add("NoPassword", $true)        
    }

    $user = New-LocalUser @userParams
    Add-LocalGroupMember -Group "Users" -Member $user

    Write-Output "Successfully created user: $Username"
}

function Modify {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Username,
        [string]$Password,
        [string]$FullName,
        [string]$Description
    )

    $existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
    if (-not $existingUser) {
        throw "User: $Username not found"
    }

    $userParams = @{ Name = $Username }

    if ($FullName) {
        $userParams.Add("FullName", $FullName)
    }

    if ($Description) {
        $userParams.Add("Description", $Description)
    }

    if ($Password) {
        $securePassword = (ConvertTo-SecureString $Password -AsPlainText -Force)
        $userParams.Add("Password", $securePassword)
    }

    Set-LocalUser @userParams

    Write-Output "Successfully modified user: $Username"
}

function Delete {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Username
    )

    $existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
    if (-not $existingUser) {
        throw "User: $Username not found"
    }

    Remove-LocalUser -Name $Username

    Write-Output "Successfully deleted user: $Username"
}

function Show-Users {
    Get-LocalUser | Select-Object Name, FullName, Description, Enabled | Format-Table -AutoSize
}

$params = @{
    Username = $Username
    Password = $Password
    FullName = $FullName
    Description = $Description
}

foreach ($param in $params.Keys.Clone()) {
    if (-not $params.Item($param)) {
        $params.Remove($param)
    }
}

switch ($Action) {
    "Create" { Create @params }
    "Modify" { Modify @params }
    "Delete" { Delete @params }
    "Show-Users" { Show-Users }
}
