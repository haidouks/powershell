configuration install_ra_agent {
Param($ScriptPath,$ExecutionServer)
    node localhost{
        File ConfigVar{
        Type = "File"
        Ensure = "Present"
        Force = $True
        Contents = @"
nolio.hiddenport`$Boolean=false
sys.programGroupDisabled`$Boolean=false
sys.installationDir=C\:\\Program Files (x86)\\CA\\ReleaseAutomationAgent
nolio.agent.mapping.application=
sys.languageId=en
nolio.agent.mapping.servertype=
nolio.nimi.node.id=$($env:COMPUTERNAME.ToUpper())
nolio.execution.name=$ExecutionServer
nolio.service.pw=********
nolio.nimi.port=6600
sys.component.336`$Boolean=true
sys.programGroupName=CA Release Automation
nolio.nimi.supernode=$ExecutionServer\:6600
install.service.lsa`$Boolean=true
nolio.agent.mapping.environment=
nolio.nimi.secured`$Boolean=true
nolio.service.user=
sys.programGroupAllUsers`$Boolean=true
nolio.execution.port=6600
sys.adminRights`$Boolean=true
"@
        DestinationPath = "$ScriptPath\Configuration\response.varfile"
        Checksum = "SHA-256"
        
        }
        Script runinstaller{
            GetScript = {
                return  @{ 'Result' = (Get-Service -name nolioagent2 -ErrorAction SilentlyContinue)  } }
            TestScript = {
                $test1 = Test-Path -Path "C:\Program Files (x86)\CA\ReleaseAutomationAgent"
                $test2 = -not [String]::IsNullOrEmpty([scriptblock]::Create($GetScript).Invoke().Result.Name)
                write-verbose -Message "test1:$test1 , test2:$test2"
                if($test1 -and $test2){
                     return $true
                }
                else {
                    return $false
                }

            }
            SetScript = {
                $ScriptPath=$Using:ScriptPath
                cmd /c $ScriptPath\Installers\nolio_agent_windows_6_4_0_b10011.exe -varfile "$ScriptPath\Configuration\response.varfile" -console -q
            }
            DependsOn = "[File]ConfigVar"
       }
        File JKSCertificate{
        Type = "File"
        Ensure = "Present"
        SourcePath = "$ScriptPath\Configuration\Netscaler.jks"
        DestinationPath = "C:\Program Files (x86)\CA\ReleaseAutomationAgent\cert\Netscaler.jks"
        Force = $True
        DependsOn = "[Script]runinstaller"
        }
        Script WrapperUpdate{
            GetScript = {
                $file = "C:\Program Files (x86)\CA\ReleaseAutomationAgent\conf\wrapper.conf"
                return @{'Result' = Get-Content -Path $file }
            }
            TestScript = {
                $Content = [scriptblock]::Create($GetScript).Invoke().Result
                if( ($Content -contains "wrapper.java.additional.3=-Djavax.net.ssl.trustStore=cert/NetScaler.jks") -and ($Content  -contains "wrapper.java.additional.4=-Djavax.net.ssl.trustStorePassword=password")){
                    return $true
                }
                else{
                    return $false
                }
            }
            SetScript = {
                $file = "C:\Program Files (x86)\CA\ReleaseAutomationAgent\conf\wrapper.conf"
                $find1 = '# wrapper.java.additional.3=-Djavax.net.ssl.trustStore=conf/keystore.jks'
                $find2 = '# wrapper.java.additional.4=-Djavax.net.ssl.trustStorePassword=booboo17'
                $replace1 = 'wrapper.java.additional.3=-Djavax.net.ssl.trustStore=cert/NetScaler.jks'
                $replace2 ='wrapper.java.additional.4=-Djavax.net.ssl.trustStorePassword=password'
                (Get-Content $file).replace($find1, $replace1).replace($find2, $replace2) | Set-Content $file -Encoding UTF8
            }
            DependsOn = '[File]JKSCertificate'

        }
        Script RestartNolio{
        GetScript = {
            $service = get-service -Name nolioagent2
            return @{'Result' = $service}

        }
        SetScript = {
            Restart-Service -Name nolioagent2 -Force -Confirm
            #Start-Sleep -seconds 5 -Verbose
        }
        TestScript = {
            $service = [scriptblock]::Create($GetScript).Invoke().Result
            if($service.Status -eq "Running")
            {
                return $false
            }
            else
            {
                return $false
            }
        }
        DependsOn = "[Script]WrapperUpdate"
        }
        Service Nolio{
            Name = "nolioagent2"
            DependsOn = "[script]RestartNolio"
            State = "Running"
            StartupType = "Automatic"
            BuiltInAccount = "LocalSystem"        
        }  
    }
}
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

function Start-AgentInstallationNow{
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
  Param($executionServer)
  
  Begin
  {
        $ErrorActionPreference = "Stop"
  }
  Process {
    write-verbose -Message "For $env:COMPUTERNAME executionServer: $executionServer , ScriptPath: $ScriptPath will be set!"
    install_ra_agent -output C:\temp\powershell\nolioInstall -ScriptPath $ScriptPath -ExecutionServer $executionServer
    Start-DscConfiguration -Path  "C:\temp\powershell\nolioInstall"  -Wait -Force -Verbose 
  }  
}
