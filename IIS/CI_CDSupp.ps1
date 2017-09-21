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
    [Int]$TimeOut = 30         
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
        Write-Verbose "Waiting for no current connection, max wait time:$TimeOut seconds"
        $con = 1
        do
        {
            $secCounter ++
            Write-Verbose "Getting current connection count for site:$siteName"
            $con=(Get-Website | Get-WebRequest| Where-Object {$_.hostName -eq $siteName}).Count
            Write-Verbose "$secCounter.sec connection count:$con"
            Start-Sleep -Seconds 1
        } while(($secCounter -le $TimeOut) -and ($con -ne 0))
        if($con -eq $null)
        {
            Write-Verbose "There is no requests in $secCounter seconds"
        }
        if($secCounter -ge $TimeOut)
        {
            Write-Warning -Message "Maximum waiting time($TimeOut seconds) reached but $siteName still has requests!"
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
    [Int]$TimeOut = 30,
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
        write-verbose -message "Setting time out:$TimeOut seconds"
        Stop-WebAppPool -Name $AppPoolName -ErrorAction SilentlyContinue
        while((Get-WebAppPoolState -Name $AppPoolName).Value -ne "Stopped" -and $TimeOut -ge 0)
        {
            Start-sleep -Seconds 1
            write-verbose -message "Waiting for Application Pool($AppPoolName) to be stopped. Remaining seconds: $TimeOut , Current state: $((Get-WebAppPoolState -Name $AppPoolName).Value)"
            $TimeOut -= 1
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
                Write-Error "Couldn't stop application pool($AppPoolName) in $TimeOut"
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

function Get-HttpCode
{
    <#
  .SYNOPSIS
  Gets the Http code for the url
  .DESCRIPTION
  Gets the http code for the url. In case of not receiving a http code from remote, this function waits for a max duration specified.
  .EXAMPLE
  Get-HttpCode -url "www.powershelldunyasi.com" -maxSec 45 
  .PARAMETER url
  Please specify the url to test.
  .PARAMETER maxSec
  Please specify the max waiting duration in seconds in case of not receiving any http code from remote.
  #>
    [CmdletBinding()]
    Param (
    [Parameter(Mandatory=$False,
          ValueFromPipeline=$True,
          ValueFromPipelineByPropertyName=$True,
          HelpMessage='Maximum waiting time for no request')]
    [ValidateRange(0,600)]
    [Int]$TimeOut = 5,
    [Parameter(Mandatory=$True,
          ValueFromPipeline=$True,
          ValueFromPipelineByPropertyName=$True,
          HelpMessage="Please enter the url starting with 'http:\\' you want to test")]
    #[ValidateNotNullOrEmpty]
    [ValidatePattern('https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)')]
    [string]$url = $false        
  )
    try
    {
        return (Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeOut -DisableKeepAlive)
    }
    catch [Net.WebException]
    {
        return $_.Exception.Response
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
