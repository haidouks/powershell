Configuration changeConfig
{
   
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Node "localhost"
    {
        foreach($key in ($OctopusParameters.keys | ? {$_ -like "DSC__Config__NodePath*"} )) 
        {
            $attributeName = $OctopusParameters[$key].Split('>')[-1]
            write-verbose -message "setting attributeName:$attributeName" -verbose
            $id = $key.Split('__')[-1]
            write-verbose -message "setting id:$id" -verbose
            $configPath = $OctopusParameters["DSC__Config__FilePath__"+$id]
            write-verbose -message "setting configPath:$configPath" -verbose
            $newValue = $OctopusParameters["DSC__Config__Value__"+$id]
            write-verbose -message "setting newValue:$newValue " -verbose
            $nodePath = $OctopusParameters["DSC__Config__NodePath__"+$id].Replace(">$attributeName","")
            write-verbose -message "setting nodePath:$nodePath" -verbose
            $NamespaceURI = $OctopusParameters["DSC__Config__NamespaceURITemp__"+$id]
            
            write-verbose -message "setting NamespaceURITemp:$NamespaceURITemp" -verbose
            File "FileCheck-$id"
            {
                Ensure = "Present"
                DestinationPath = $configPath
                Type = 'File'
            }
            
            Script "ChangeConfig-$id" 
            {
                GetScript = 
                {
                    write-verbose -Message "Creating XMLDocument using Path:$($using:configPath)" -verbose
                    $XmlDocument = [xml]$(get-content -Path $($using:configPath) -ErrorAction Stop)
                    write-verbose -Message "Created XMLDocument:$XmlDocument" -verbose
                    $NamespaceURITemp = $using:NamespaceURI
                    if([string]::IsNullOrEmpty($NamespaceURITemp)) { $NamespaceURITemp = $XmlDocument.DocumentElement.NamespaceURI }
                    $xmlNsManager = New-Object System.Xml.XmlNamespaceManager($XmlDocument.NameTable)
                    $xmlNsManager.AddNamespace("ns", $NamespaceURITemp)
                    $tempPath = $using:nodePath
                    $fullyQualifiedNodePath = "/ns:$($tempPath.Replace('>', '/ns:'))"
                    $node = $XmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
                    return @{Result = "$($node.GetAttribute($using:attributeName))"}
                }
                SetScript =
                {    
                write-verbose -Message "Creating XMLDocument using Path:$($using:configPath)" -verbose
                $XmlDocument = [xml]$(get-content -Path $($using:configPath) -ErrorAction Stop)
                write-verbose -Message "Created XMLDocument:$XmlDocument" -verbose
                $NamespaceURITemp = $using:NamespaceURI
                if([string]::IsNullOrEmpty($NamespaceURITemp)) { $NamespaceURITemp = $XmlDocument.DocumentElement.NamespaceURI }
                $xmlNsManager = New-Object System.Xml.XmlNamespaceManager($XmlDocument.NameTable)
                $xmlNsManager.AddNamespace("ns", $NamespaceURITemp)
                $tempPath = $using:nodePath
                $fullyQualifiedNodePath = "/ns:$($tempPath.Replace('>', '/ns:'))"
                $node = $XmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
                $node.SetAttribute($using:attributeName,$using:newValue)
                $XmlDocument.Save($($using:configPath))
        }
                TestScript = 
                {
                write-verbose -Message "Creating XMLDocument using Path:$($using:configPath)" -verbose
                $XmlDocument = [xml]$(get-content -Path $($using:configPath) -ErrorAction Stop)
                write-verbose -Message "Created XMLDocument:$XmlDocument" -verbose
                $NamespaceURITemp = $using:NamespaceURI
                if([string]::IsNullOrEmpty($NamespaceURITemp)) { $NamespaceURITemp = $XmlDocument.DocumentElement.NamespaceURI }
                $xmlNsManager = New-Object System.Xml.XmlNamespaceManager($XmlDocument.NameTable)
                $xmlNsManager.AddNamespace("ns", $NamespaceURITemp)
                $tempPath = $using:nodePath
                $fullyQualifiedNodePath = "/ns:$($tempPath.Replace('>', '/ns:'))"
                $node = $XmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
                Write-Verbose -Message "node:$node" -Verbose
                if($node -eq $null)
                {
                    Write-Error "NodePath($using:NodePath) not found"
                    return $false
                }
                $cn = $($node.GetAttribute($attributeName))
                $stateMatched = $cn -eq $newValue
                return $stateMatched
            }
            
                DependsOn = @("[File]FileCheck-$id")
            }
        }
   }
}

changeConfig -Verbose
Start-DscConfiguration .\changeConfig -Wait -Force -ComputerName localhost -verbose
