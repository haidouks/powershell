function Wait-WebSite
{
    <#
  .SYNOPSIS
  Waits for no IIS website request
  .DESCRIPTION
  This function waits for no web request for a specified IIS website for a specified duration.
  .EXAMPLE
  Wait-NoReqForWebSite -siteName CnSn_Website -maxSec 45 
  .PARAMETER siteName
  Specify the name of the IIS website
  #>
  
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$True,
          ValueFromPipeline=$True,
          ValueFromPipelineByPropertyName=$True,
          HelpMessage='Maximum waiting time for no request')]
    [ValidateRange(0,600)]
    [Int]$maxSec = 30         
  )
  DynamicParam
  {          
        $ParamName = "siteName" 
        $ParamAttrib  = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttrib.Mandatory  = $true
        $ParamAttrib.HelpMessage = "Please select one of the websites on the IIS server $($env:COMPUTERNAME)"
        #$ParamAttrib.ParameterSetName = '__AllParameterSets'
          
        $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add($ParamAttrib)

        Import-Module -Name WebAdministration -ErrorAction Stop
        $webSiteNames  = Get-Website -ErrorAction Stop| Select-Object -ExpandProperty Name
        $AttribColl.Add((New-Object  System.Management.Automation.ValidateSetAttribute($webSiteNames)))

        $RuntimeParam  = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName,  [string], $AttribColl)
        $RuntimeParamDic  = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add($ParamName,  $RuntimeParam)
        return  $RuntimeParamDic
        }
  Begin
  {
        $ErrorActionPreference = "Stop"
  }
  Process
  {
        $siteName = $PSBoundParameters[$ParamName]
        $secCounter = 0
        Write-Verbose "Waiting for no current connection, max wait time:$maxSec seconds"
        $con = 1
        do
        {
            $secCounter ++
            Write-Verbose "Getting current connection count for site:$siteName"
            $con=(Get-Website | Get-WebRequest| Where-Object {$_.hostName -eq $siteName}).Count
            Write-Verbose "$secCounter.sec connection count:$con"
            Start-Sleep -Seconds 1
        } while(($secCounter -le $maxSec) -and ($con -ne 0))
        if($con -eq $null)
        {
            Write-Verbose "There is no requests in $secCounter seconds"
        }
        if($secCounter -ge $maxSec)
        {
            Write-Warning -Message "Maximum waiting time($maxSec seconds) reached but $siteName still has requests!"
        }
    }       
}

function Stop-AppPool
{
    <#
  .SYNOPSIS
  Stops or kills application pool
  .DESCRIPTION
  This function waits for a duration to application pool if application pool doesnt stop in desired duration, in case of kill switch is on, script kills related process for the application pool.
  .EXAMPLE
  Stop-AppPool -siteName CnSn_Website -maxSec 45 
  .PARAMETER AppPoolName
  Please specify the name of the IIS application pool
  #>
    [CmdletBinding()]
    Param (
    [Parameter(Mandatory=$True,
          ValueFromPipeline=$True,
          ValueFromPipelineByPropertyName=$True,
          HelpMessage='Maximum waiting time for no request')]
    [ValidateRange(0,600)]
    [Int]$maxSec = 30,
    [Parameter(Mandatory=$False,
          ValueFromPipeline=$True,
          ValueFromPipelineByPropertyName=$True,
          HelpMessage='Kill Application pool at the end of time out')]
    [switch]$Kill = $false        
  )
    DynamicParam
    {          
        $ParamName = "AppPoolName" 
        $ParamAttrib  = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttrib.Mandatory  = $true
        $ParamAttrib.HelpMessage = "Please select one of the application pools on the IIS server $($env:COMPUTERNAME)"
        #$ParamAttrib.ParameterSetName = '__AllParameterSets'
          
        $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add($ParamAttrib)

        Import-Module -Name WebAdministration -ErrorAction Stop
        $AppPoolNames  = Get-ChildItem IIS:\AppPools -ErrorAction Stop| Select-Object -ExpandProperty Name
        $AttribColl.Add((New-Object  System.Management.Automation.ValidateSetAttribute($AppPoolNames)))

        $RuntimeParam  = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName,  [string], $AttribColl)
        $RuntimeParamDic  = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add($ParamName,  $RuntimeParam)
        return  $RuntimeParamDic
    }
    Begin 
    {
        $ErrorActionPreference = "SilentlyContinue"
    } 
    Process
    {
        $AppPoolName = $PSBoundParameters[$ParamName]
        write-verbose -message "Stopping application pool($AppPoolName)"
        write-verbose -message "Setting time out:$maxSec seconds"
        Stop-WebAppPool -Name $AppPoolName -ErrorAction SilentlyContinue
        while((Get-WebAppPoolState -Name $AppPoolName).Value -ne "Stopped" -and $maxSec -ge 0)
        {
            Start-sleep -Seconds 1
            write-verbose -message "Waiting for Application Pool($AppPoolName) to be stopped. Remaining seconds: $maxSec , Current state: $((Get-WebAppPoolState -Name $AppPoolName).Value)"
            $maxSec -= 1
        }
        if((Get-WebAppPoolState -Name $AppPoolName).Value -ne "Stopped")
        {
            Write-Warning -Message "Couldn't stop application Pool($AppPoolName) in soft mode !"
            if($Kill)
            {
                $pId = Get-ChildItem -Path "IIS:\AppPools\$AppPoolName\WorkerProcesses\" -ErrorAction Stop | Select-Object -ExpandProperty ProcessId
                write-verbose -message "Killing worker process ($pId) for Application Pool($AppPoolName) ." 
                Stop-Process -Id $pId -Force
            }
            if((Get-WebAppPoolState -Name $AppPoolName).Value -ne "Stopped")
            {
                Write-Error "Couldn't stop application pool($AppPoolName) in $maxSec"
            }
            else
            {
                write-verbose -message "Succesfully Stopped Application Pool($AppPoolName) !" 
            }

        }
        else
        {
            write-verbose -message "Succesfully Stopped Application Pool($AppPoolName) !" 
        }
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
