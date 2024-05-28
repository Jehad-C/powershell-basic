param(
    [ValidateSet("Get-NetworkConfiguration", "Set-DHCP", "Set-StaticIP", "Set-DNSServer")]
    [Parameter(Mandatory=$true)]
    [string]$Action,
    [string]$AdapterName,
    [string]$IPAddress,
    [string]$SubnetMask,
    [string]$DefaultGateway,
    [string[]]$DNSServers,
    [string]$LogPath="$HOME/workspace/NetworkConfiguration.csv"
)

function Get-NetworkConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )

    $logContent = @()
    $logDir = Split-Path -Path $LogPath -Parent

    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    Remove-Item -Path $LogPath -Confirm:$false -ErrorAction SilentlyContinue

    $adapters = Get-NetAdapter
    if (-not $adapters) {
        throw "Adapter: $adapter not found"
    }

    foreach ($adapter in $adapters) {
        $ipConfiguration = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex
        $netConfiguration = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
        $networkInformation = [PSCustomObject]@{
            Adapter = "$($adapter.Name)"
            Status = "$($adapter.Status)"
            MacAddress = "$($adapter.MacAddress)"
        }

        if ($ipConfiguration) {
            $subnetMask = Get-SubnetMask -PrefixLength "$($ipConfiguration.PrefixLength[1])"
            $networkInformation | Add-Member -MemberType NoteProperty -Name 'IPAddress' -Value "$($ipConfiguration.IPAddress)"
            $networkInformation | Add-Member -MemberType NoteProperty -Name 'SubnetMask' -Value $subnetMask
        }

        if ($netConfiguration) {
            $networkInformation | Add-Member -MemberType NoteProperty -Name 'DefaultGateway' -Value "$($netConfiguration.IPv4DefaultGateway)"
            $networkInformation | Add-Member -MemberType NoteProperty -Name 'DNSServer' -Value "$($netConfiguration.DNSServer)"
        }

        $logContent += $networkInformation
    }

    $logContent | Export-Csv -Path $LogPath -NoTypeInformation

    Write-Output "Successfully logged network information"
}

function Set-DHCP {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    $adapter = Get-NetAdapter -Name $Name
    if (-not $adapter) {
        throw "Adapter: $adapter not found"
    }

    Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -Dhcp Enabled

    Write-Output "Successfully set DHCP"
}

function Set-StaticIP {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$IPAddress,
        [string]$SubnetMask,
        [string]$DefaultGateway
    )

    $adapter = Get-NetAdapter -Name $Name
    if (-not $adapter) {
        throw "Adapter: $adapter not found"
    }

    $prefixLength = Get-PrefixLength -SubnetMask $SubnetMask

    Set-NetIPInterface -InterfaceAlias $Name -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $IPAddress -PrefixLength $prefixLength -DefaultGateway $DefaultGateway

    Write-Output "Successfully set static IP address"
}

function Set-DNSServer {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string[]]$DNSServers
    )

    $adapter = Get-NetAdapter -Name $Name
    if (-not $adapter) {
        throw "Adapter: $adapter not found"
    }

    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $DNSServers

    Write-Output "Successfully set DNS servers"
}

function Get-SubnetMask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PrefixLength
    )

    $binaryMask = ('1' * $PrefixLength).PadRight(32, '0')
    $octets = @(
        [Convert]::ToInt32($binaryMask.Substring(0, 8), 2),
        [Convert]::ToInt32($binaryMask.Substring(8, 8), 2),
        [Convert]::ToInt32($binaryMask.Substring(16, 8), 2),
        [Convert]::ToInt32($binaryMask.Substring(24, 8), 2)
    )

    $subnetMask = $octets -join '.'
    return $subnetMask
}

function Get-PrefixLength {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubnetMask
    )

    $maskBytes = $SubnetMask.Split('.') | ForEach-Object { [Convert]::ToByte($_) }
    $binaryString = ($maskBytes | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(9, '0') }) -join ''
    $prefixLength = ($binaryString -split '1').Length - 1
    return $prefixLength
}

switch ($Action) {
    "Get-NetworkConfiguration" { Get-NetworkConfiguration -LogPath $LogPath }
    "Set-DHCP" { Set-DHCP -Name $AdapterName }
    "Set-StaticIP" { Set-StaticIP -Name $AdapterName -IPAddress $IPAddress -SubnetMask $SubnetMask -DefaultGateway $DefaultGateway }
    "Set-DNSServer" { Set-DNSServer -Name $AdapterName -DNSServers $DNSServers }
}
