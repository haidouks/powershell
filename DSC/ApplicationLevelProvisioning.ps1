Configuration ProvisionAppEnv
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration -ModuleVersion "1.15.0.0"

    Node "localhost"
    {
        # Create a Web Application Pool
        $appPoolName = $OctopusParameters['DSC__WebSite__ApplicationPool']
        $webSiteName = $OctopusParameters['DSC__WebSite__Name']
      xWebAppPool "CreateAppPool__$appPoolName"
        {
            Name   = $appPoolName
            Ensure = "Present"
            State  = "Started"
        }

     #Create physical path website
       File "CreateWebSitePath__$webSiteName"
        {
            DestinationPath = $OctopusParameters['DSC__WebSite__PhysicalPath']
            Type = "Directory"
            Ensure = "Present"
        }
        
        xWebSite "CreateWebSite__$webSiteName"
        {
            Name   = $webSiteName
            Ensure = "Present"
            ApplicationPool = $appPoolName
            BindingInfo = MSFT_xWebBindingInformation
            {
                Protocol = "http"
                Port = 84
            }

            PhysicalPath = $OctopusParameters['DSC__WebSite__PhysicalPath']
            State = "Started"
            DependsOn = @("[xWebAppPool]CreateAppPool__$appPoolName","[File]CreateWebSitePath__$webSiteName")
        }
        
        File "EnsureConfig-$webSiteName"
        {
             DestinationPath = $OctopusParameters['DSC__WebSite__PhysicalPath'] + "\web.config"
             Contents = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
                            <configuration>
                            </configuration>"
                    Ensure = "Present"
            DependsOn = @("[File]CreateWebSitePath__$webSiteName")
        }
        
        foreach($configKey in ($OctopusParameters.keys | ? {$_ -like "DSC__WebSite__Config*"} ))
        {
        write-verbose -Message "Setting state for configuration ($configKey)-($webSiteName)" -Verbose:$true
        
        
        xWebConfigKeyValue "ModifyConfigKey-$webSiteName-$configKey"
        {
            Ensure = "Present"
            ConfigSection = $configKey.Split("__")[-3]
            Key = $configKey.Split('__')[-1]
            Value = $OctopusParameters[$configKey]
            IsAttribute = $false
            WebsitePath = "IIS:\sites\" +$webSiteName
            DependsOn = @("[File]EnsureConfig-$webSiteName")
        }
        }
        
        foreach($key in ($OctopusParameters.keys | ? {$_ -like "DSC__Application__Name*"} )) 
        {
        $application = $OctopusParameters[$key]
        $id = $key.Split('__')[-1]
        
        $pathParam = "DSC__Application__PhysicalPath__"+$id
        
        $appPath = $OctopusParameters[$pathParam]
        write-verbose -Message "Setting state for application (key: $key)-(application: $application)-(id: $id) - (appPath: $appPath) - (pathParam: $pathParam)" -Verbose:$true
        xWebAppPool "CreateAppPool__$application"
        {
            Name   = $application
            Ensure = "Present"
            State  = "Started"
        }
        #Create physical path web application
        File "NewApplicationPath__$application"
        {
            DestinationPath = $appPath
            Type = "Directory"
            Ensure = "Present"
        }
        xWebApplication "NewWebApplication__$application" 
        {
            Name = $application
            Website = $webSiteName
            WebAppPool =  $application
            PhysicalPath = $appPath
            Ensure = "Present"
            DependsOn = @("[xWebSite]CreateWebSite__$webSiteName","[File]NewApplicationPath__$application","[xWebAppPool]CreateAppPool__$application")
        }
        $configPath = $appPath + "\web.config"
        File "EnsureConfig-$application"
        {
             DestinationPath = $configPath
             Contents = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
                            <configuration>
                            </configuration>"
                    Ensure = "Present"
            DependsOn = @("[File]NewApplicationPath__$application")
        }
        
        
        
        foreach($configKey in ($OctopusParameters.keys | ? {$_ -like "DSC__Application__Config*" -and $_.Split('__')[-1] -eq $id} ))
        {
        write-verbose -Message "Setting state for configuration ($configKey)-($application)" -Verbose:$true
        
        
        xWebConfigKeyValue "ModifyConfigKey-$application-$configKey"
        {
            Ensure = "Present"
            ConfigSection = $configKey.Split("__")[-5]
            Key = $configKey.Split('__')[-3]
            Value = $OctopusParameters[$configKey]
            IsAttribute = $false
            WebsitePath = "IIS:\sites\" +$webSiteName +"\"+$application
            DependsOn = @("[File]EnsureConfig-$application","[xWebApplication]NewWebApplication__$application")
        }
        }
        
        
        
        
        
       }
        
        
        
        
#        foreach($key in ($OctopusParameters.keys | ? {$_ -contains "DSC-VirtualDirectory-Name"} )) 
#        {
#        $virDir = ($OctopusParameters['$key']).Split('#')[1]
#        #Ensure physical path virtual directory
#        File NewVirtualDirectoryPath
#        {
#            DestinationPath = $Node.PhysicalPathVirtualDir
#            Type = "Directory"
#            Ensure = "Present"
#        }

        
        #Create a new virtual Directory
#        xWebVirtualDirectory NewVirtualDir
#        {
#            Name = $virDir
#            Website = $Node.WebSiteName
#            WebApplication =  $Node.WebApplicationName
#            PhysicalPath = $OctopusParameters['DSC-VirtualDirectory-PhysicalPath#$virDir']
#            Ensure = "Present"
#            DependsOn = @("[xWebApplication]NewWebApplication","[File]NewVirtualDirectoryPath")
#        }
#        }
#        #Create an empty web.config file
        
       
    }
}

ProvisionAppEnv 
Start-DscConfiguration .\ProvisionAppEnv -wait -Verbose -Force 
