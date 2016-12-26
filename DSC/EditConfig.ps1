Configuration changeConfig
{
    Param(
    [string]$path, 
    [string]$NodePath, 
    [string]$NamespaceURI = "", 
    [string]$NodeSeparatorCharacter = '>',
    [string]$attributeName,
    [string]$newValue
    )
    
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Node "localhost"
    {
        File exists
        {
            Ensure = "Present"
            DestinationPath = $path
            Type = 'File'
        }

        Script configDeneme 
        {
       GetScript = 
       {
           $XmlDocument = [xml]$(get-content -Path $using:path -ErrorAction Stop)
           $NamespaceURITemp = $using:NamespaceURI
           if([string]::IsNullOrEmpty($NamespaceURITemp)) { $NamespaceURITemp = $XmlDocument.DocumentElement.NamespaceURI } 
           $xmlNsManager = New-Object System.Xml.XmlNamespaceManager($XmlDocument.NameTable)
           $xmlNsManager.AddNamespace("ns", $NamespaceURITemp)
           $tempPath = $using:NodePath
           $fullyQualifiedNodePath = "/ns:$($tempPath.Replace($($using:NodeSeparatorCharacter), '/ns:'))"
           $node = $XmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
           
           
           return @{
               Result = "$($node.GetAttribute($using:attributeName))"
           }
       }
       SetScript =
       {    
           $XmlDocument = [xml]$(get-content -Path $using:path -ErrorAction Stop)
           $NamespaceURITemp = $using:NamespaceURI
           if([string]::IsNullOrEmpty($NamespaceURITemp)) { $NamespaceURITemp = $XmlDocument.DocumentElement.NamespaceURI } 
           $xmlNsManager = New-Object System.Xml.XmlNamespaceManager($XmlDocument.NameTable)
           $xmlNsManager.AddNamespace("ns", $NamespaceURITemp)
          
           $tempPath = $using:NodePath
           Write-Verbose -Message "tempPath:$tempPath" -Verbose
           $fullyQualifiedNodePath = "/ns:$($tempPath.Replace($($using:NodeSeparatorCharacter), '/ns:'))"
           Write-Verbose -Message "fullyQualifiedNodePath:$fullyQualifiedNodePath" -Verbose
           $node = $XmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
           $node.SetAttribute($using:attributeName,$using:newValue)
           $XmlDocument.Save($using:path)
       }
       TestScript = 
       {
           
           $XmlDocument = [xml]$(get-content -Path $using:path -ErrorAction Stop)
           $NamespaceURITemp = $using:NamespaceURI
           if([string]::IsNullOrEmpty($NamespaceURITemp)) { $NamespaceURITemp = $XmlDocument.DocumentElement.NamespaceURI } 
           $xmlNsManager = New-Object System.Xml.XmlNamespaceManager($XmlDocument.NameTable)
           $xmlNsManager.AddNamespace("ns", $NamespaceURITemp)
          
           $tempPath = $using:NodePath
           Write-Verbose -Message "tempPath:$tempPath" -Verbose
           $fullyQualifiedNodePath = "/ns:$($tempPath.Replace($($using:NodeSeparatorCharacter), '/ns:'))"
           Write-Verbose -Message "fullyQualifiedNodePath:$fullyQualifiedNodePath" -Verbose
           $node = $XmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
           Write-Verbose -Message "node:$node" -Verbose
           if($node -eq $null)
           {
                Write-Error "NodePath($using:NodePath) not found"
                return $false

           }
           $cn = $($node.GetAttribute($using:attributeName))
           $stateMatched = $cn -eq $using:newValue
           return $stateMatched
       }
       DependsOn = @("[File]exists") 

   }
   }
}
