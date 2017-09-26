Param(
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        HelpMessage="Give me fqdn of remote agent !")]
    $fqdn
  )

$ScriptPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
write-verbose -Message "Setting Script Path : $ScriptPath"
$ScriptDestination = "$env:USERPROFILE\AppData\Local\Temp\RAAgentInstallation"
write-verbose -Message "Setting Destination Script Path : $($ScriptDestination.Replace("C:\","\\$fqdn\c$\"))"
function Start-Installation{
    <#
  .SYNOPSIS
  sets execution server
  .DESCRIPTION
  This function sets execution server
  .EXAMPLE
  Set-ExecutionServer -ExecutionServer asd
  .PARAMETER ExecutionServer
  Specify the name of the execution server
  #>
  [CmdletBinding()]
  Param()
  DynamicParam
  {     
        $ParamName = "ExecutionServer" 
        
        $ParamAttrib  = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttrib.Mandatory  = $true
        $ParamAttrib.Position = 1
        $ParamAttrib.HelpMessage = "Please select one of Execution Servers for $($fqdn)"
        $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]


        $AttribColl.Add($ParamAttrib)
        $confPath = "$ScriptPath\Configuration\ExecutionServers.json"
        Write-Verbose -Message "Configuration path is $confPath"
        $ExecutionServers  = Get-Content -Path "$ScriptPath\Configuration\ExecutionServers.json" | out-string | ConvertFrom-Json
        if($ExecutionServers -eq $null)
        {
            Write-Error -Message "There is no ExecutionServers, please check ExecutionServers.json file " -Verbose
        }
        $agentIP = (Test-NetConnection -ComputerName $fqdn -Port 5985 -ErrorAction Stop -WarningAction Stop -Verbose).RemoteAddress
        Write-Verbose -Message "This script will install agent to $fqdn - $agentIP" -Verbose
        $AvailableExecutionServer = $ExecutionServers | Where-Object {$agentIP -match $_.IPBlock}
        
        if($AvailableExecutionServer -eq $null)
        {
            Write-Error -Message "There is no AvailableExecutionServer, please check IPBlock filter " -Verbose
        }
        $AttribColl.Add((New-Object  System.Management.Automation.ValidateSetAttribute($AvailableExecutionServer.IP)))
        $RuntimeParam  = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName,  [string], $AttribColl)
        $RuntimeParamDic  = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add($ParamName,  $RuntimeParam)
        return  $RuntimeParamDic
       
  }
  Begin
  {
        $ErrorActionPreference = "Stop"
  }
  Process {
    try
    {
        Copy-Item -Path $ScriptPath -Destination $ScriptDestination.Replace("C:\","\\$fqdn\c$\") -Force -Recurse -errorAction Stop -Verbose
    }
    catch
    {
        Write-Error -Message "Please check access to path($($ScriptDestination.Replace("C:\","\\$fqdn\c$\"))) for user($env:USERNAME@$env:USERDNSDOMAIN) "
    }
        $s = New-PSSession -ComputerName $fqdn
        $executionServer = $PSBoundParameters[$ParamName]
        Invoke-Command -ScriptBlock {
        Param($path,$executionServer)
        
        Unblock-File -Path "$path\AgentDSc.ps1" -Confirm:$false
        Set-ExecutionPolicy bypass
        . "$path\AgentDSc.ps1" -Confirm:$false
        
        
        Start-AgentInstallationNow -ExecutionServer $executionServer -verbose
        } -ArgumentList $ScriptDestination.Replace("C:\","\\$fqdn\c$\"),$executionServer -ComputerName $fqdn -Verbose
        Remove-Item -Path $ScriptDestination.Replace("C:\","\\$fqdn\c$\") -Force -Verbose -Recurse -Confirm:$false
    
    
    
    #Remove-Item -Path $($ScriptDestination.Replace("C:\","\\$fqdn\c$\")) -Force -Confirm:$false -Recurse
  }  
}