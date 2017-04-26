function Wait-NoReqForWebSite($siteName,$maxSec,[switch]$verbose)
{
    $secCounter = 0
    write-verbose -Message "importing webadministration PSSnapin" -Verbose
    Add-PSSnapin WebAdministration -ErrorAction SilentlyContinue
    write-verbose -Message "importing webadministration Module" -Verbose
    Import-Module WebAdministration -ErrorAction SilentlyContinue
        
    Write-Verbose "Waiting for no current connection, max wait time:$maxSec seconds" -Verbose:$verbose
    $con = 1
    do
    {
        $secCounter ++
        Write-Verbose "Getting current connection count for site:$siteName" -Verbose:$verbose
        $con=(Get-Website | Get-WebRequest| where {$_.hostName -eq $siteName}).Count
        Write-Verbose "$secCounter.sec connection count:$con" -Verbose:$verbose
        Start-Sleep -Seconds 1
    }while(($secCounter -le $maxSec) -and ($con -ne 0))
    if($con -eq $null)
    {
        Write-Verbose "There is no requests in $secCounter seconds" -Verbose:$verbose
    }
    if($secCounter -ge $maxSec)
    {
        Write-Warning -Message "Maximum waiting time($maxSec seconds) reached but $siteName still has requests!" -Verbose:$true
    }
}

function Get-IISWebRoot($siteName)
{
        write-verbose -Message "importing webadministration PSSnapin" -Verbose
        Add-PSSnapin WebAdministration -ErrorAction SilentlyContinue
        write-verbose -Message "importing webadministration Module" -Verbose
        Import-Module WebAdministration -ErrorAction SilentlyContinue
        Write-Verbose "Getting physicalPath for website $siteName" -Verbose:$verbose
        $webRoot = $null
        Try{
            $webRoot = (Get-Website  | where-object{$_.Name -eq $siteName}).physicalPath
            
        } Catch [System.IO.FileNotFoundException]{
            Start-sleep -seconds 1
            $webRoot = (Get-Website  | where-object{$_.Name -eq $siteName}).physicalPath
        }
        if([String]::IsNullOrEmpty($webRoot))
        {
            Write-Host "Error:WebRoot is null"
            Exit 1
        }
        return $webRoot 
}


function checkHttpCode($url,[switch]$verbose)
{
    $start = Get-Date
    $result = $false
    try
    {
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Creating request to $url" -verbose:$verbose
        $HTTP_Request = [System.Net.WebRequest]::Create($url)
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Setting timeout to 60 seconds" -verbose:$verbose
        $HTTP_Request.Timeout = 60000
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Request created to $url" -verbose:$verbose
        $HTTP_Response = $HTTP_Request.GetResponse()
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Getting response from $url" -verbose:$verbose
        $HTTP_Status = [int]$HTTP_Response.StatusCode
    If ($HTTP_Status -eq 200) 
    { 
        $result = $true 
    }
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - HTTP code is $HTTP_Status" -verbose:$verbose
            
    }
    catch 
    {
        $result = $false
    }
    finally
    {
        if($HTTP_Response -ne $null)
        {
            $HTTP_Response.Close()
        }
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Closed connection to $url" -verbose:$verbose
        $finish = Get-Date
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Request completed in $(($finish-$start).TotalMilliseconds) ms." -verbose:$verbose
        
    }
    if($result -ne $true)
    {
        Write-Warning -Message "Http status code is not 200 for url:$url!" -Verbose:$true
    }
    return $result
}

function stop-ApplicationPool($AppPool,$maxWait=180)
{
    write-verbose -Message "importing webadministration PSSnapin" -Verbose
    Add-PSSnapin WebAdministration -ErrorAction SilentlyContinue
    write-verbose -Message "importing webadministration Module" -Verbose
    Import-Module WebAdministration -ErrorAction SilentlyContinue
    write-verbose -message "Stopping Application Pool($AppPool)" -Verbose
    write-verbose -message "Setting maxWait:$maxWait seconds" -Verbose
    Stop-WebAppPool -Name $AppPool -Verbose -ErrorAction SilentlyContinue
    while((Get-WebAppPoolState -Name $AppPool).Value -ne "Stopped" -and $maxWait -ge 0)
    {
       Start-sleep -seconds 5
       write-verbose -message "Waiting for Application Pool($AppPool) to stopped. Remaining seconds: $maxWait" -Verbose
       $maxWait -= 5
       (Get-WebAppPoolState -Name $AppPool)
    }
    if((Get-WebAppPoolState -Name $AppPool).Value -ne "Stopped")
    {
        Write-Warning -Message "Couldn't stop application Pool($AppPool) in $maxWait seconds!" -Verbose:$true
    }
    else
    {
        write-verbose -message "Succesfully Stopped Application Pool($AppPool) !" -Verbose
    }
}

function checkHttpCode($url,[switch]$verbose,$timeOut=60)
{
    $start = Get-Date
    $result = $false
    try
    {
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Creating request to $url" -verbose:$verbose
        $HTTP_Request = [System.Net.WebRequest]::Create($url)
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Setting timeout to $timeOut seconds" -verbose:$verbose
        $HTTP_Request.Timeout = $timeOut
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Request created to $url" -verbose:$verbose
        $HTTP_Response = $HTTP_Request.GetResponse()
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Getting response from $url" -verbose:$verbose
        $HTTP_Status = [int]$HTTP_Response.StatusCode
    If ($HTTP_Status -eq 200) 
    { 
        $result = $true 
    }
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - HTTP code is $HTTP_Status" -verbose:$verbose
            
    }
    catch 
    {
        $result = $false
    }
    finally
    {
        if($HTTP_Response -ne $null)
        {
            $HTTP_Response.Close()
        }
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Closed connection to $url" -verbose:$verbose
        $finish = Get-Date
        Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Request completed in $(($finish-$start).TotalMilliseconds) ms." -verbose:$verbose
        
    }
    if($result -ne $true)
    {
        Write-Warning -Message "Http status code is not 200 for url:$url!" -Verbose:$true
    }
    return $result
}
