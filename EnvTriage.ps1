. .\HTTPClientWrapper.ps1

function New-PortObj([string]$Protocol, [int]$Port) {
    $protocolList = @("TCP", "HTTP") # anything else to add here? 

    if (-not ($Protocol -in $protocolList)) {
        Write-Host "Protocol must be one of $($protocolList -join ", ")." 
    }
    elseif (-not ($Port -gt 0 -and $Port -lt 65536)) {
        Write-Host "Port must be between 1 and 65535 inclusive."
    }
    else {
        return [PSCustomObject]@{
            Protocol = $Protocol
            Port     = $Port
        }
    }
}

function New-HostObj([string]$Target = "0.0.0.0", [string]$Type = "Server") {
    $typeList = @("Server", "Network Switch") # anything else to add here? 

    if (-not ($Type -in $typeList)) {
        Write-Host "Type must be one of $($typeList -join ", ")."
    }
    else {
        return [PSCustomObject]@{
            Target      = $Target
            Type        = $Type 
            PortNumbers = @() 
        }
    }
}

function Test-Ping([Parameter(Mandatory)][string]$Target, [int]$Timeout = 100) {
    try {
        $icmpClient = [System.Net.NetworkInformation.Ping]::new()
    }
    catch {
        throw [System.Management.Automation.RuntimeException]::new("Unable to create ICMP client.")
    }

    if (-not ($Timeout -gt 0)) {
        throw [System.ArgumentOutOfRangeException]::new("Timeout must be more than 0.")
    }

    $reply = $icmpClient.Send($Target, $Timeout)

    if ($reply.Status -eq "Success") {
        return "Ping success to $($Target) (RTT: $($reply.RoundTripTime) ms)."
    }
    else {
        return "Ping failed to $($Target)."
    }
}

function Test-HTTPService([Parameter(Mandatory)][string]$Target, [int]$Port = 443, [string]$Path = "/") {
    try {
        $httpClient = [HTTPClientWrapper]::new("https://$($Target):$($Port)")
    }
    catch {
        throw "Unable to create HTTP client wrapper."
    }

    $result = $httpClient.Get($Path)

    # if unsuccessful status code
    if (-not $result.IsSuccessStatusCode) {
        return "HTTP request failed to $($Target): $($result.StatusCode)."
    }
    # if it's a success status code
    else {
        return "HTTP request successful to $($Target): $($result.StatusCode)."
    }
}

function Test-TCPService([Parameter(Mandatory)][string]$Target, [int]$Timeout = 100, [Parameter(Mandatory)][int]$Port) {
    if (-not ($Port -gt 0 -and $Port -lt 65536)) {
        throw [System.ArgumentOutOfRangeException]::new("Port number must be between 1 and 65535 inclusive.")
    }
    elseif (-not ($Timeout -gt 0)) {
        throw [System.ArgumentOutOfRangeException]::new("Timeout must be more than 0.")
    }
 
    try {
        $tcpClient = [System.Net.Sockets.TcpClient]::new()
    }
    catch {
        throw [System.Management.Automation.RuntimeException]::new("Unable to create TCP client.")
    }

    $connection = $tcpClient.BeginConnect($Target, $Port, $null, $null)
    $wait = $connection.AsyncWaitHandle.WaitOne($Timeout, $false)    
    $tcpClient.Close()

    if (-not $wait) {
        return "$($Target) port $($Port) - Closed (Timeout)"
    }
    else {
        return "$($Target) port $($Port) - Open"
    }
}

# do something here to consume an IP file for ping test
# do something here to consume an IP + service port file for service port test
