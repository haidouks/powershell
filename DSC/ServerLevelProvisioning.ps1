configuration InstallWebServer
    {
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'    
    node "localhost"
    {
        
        WindowsFeature IIS 
        { 
            Ensure = "Present" 
            Name = "Web-Server"
            IncludeAllSubFeature = $true
        } 
        
        WindowsFeature AppServer 
        { 
            Ensure = "Present" 
            Name = "Application-Server"
            IncludeAllSubFeature = $true
        } 
 
        WindowsFeature WAS 
        { 
            Ensure = "Present" 
            Name = "WAS" 
            IncludeAllSubFeature = $true
        }
        
        
        WindowsFeature TelnetClient 
        { 
            Ensure = "Present" 
            Name = "Telnet-Client" 
            IncludeAllSubFeature = $true
        }
        
        
        }
    }
InstallWebServer
Start-DscConfiguration .\InstallWebServer -wait -Verbose -Force
