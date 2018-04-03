$VerbosePreference = "SilentlyContinue"
$listener = New-Object System.Net.HttpListener
$port="8080"
$listener.Prefixes.Add("http://+:$port/") 
$listener.Start()
write-host "Listening On Port: $port"
$req = $null
 
while ($true) {
    $context = $listener.GetContext() 
 
    $request = $context.Request
 
    $response = $context.Response
   
    if ($request.Url -match '/end$') { 
        break 
    }
    else {
        $req = $request
        $requestvars = ([String]$request.Url).split("/");
        Write-Verbose -Message "Received request: $($request.Url)"
        Write-Verbose -Message "Request Details:`n $($request | fl * -force | Out-String -Stream)"
        $folders = (Get-ChildItem -Path $PSScriptRoot -Directory | Select-Object BaseName).BaseName
        $application = @{
            name = $requestvars[3]
            subname = $requestvars[4]
            exists = $false
        }
        Write-Verbose -Message "Looking for application $($application.Name)"
        Write-Verbose -Message "Current application list:$folders"
        foreach($folder in $folders)
        {
            if ($application.name -eq $folder)
            {
                $subfolders = (Get-ChildItem -Path $(Join-Path -Path $PSScriptRoot -ChildPath $application.name) -Directory | Select-Object BaseName).BaseName
                foreach($subfolder in $subfolders)
                {
                    if ($application.subname -eq $subfolder)
                    {
                        Write-Verbose -Message "Found $($application.name)\$($application.subname)"
                        $application.exists = $true
                        break;
                    }
                }
            }
        }
        if ($application.exists) {
            $body = $request.InputStream
            $QueryStrings = New-Object System.Collections.ArrayList
            foreach($queryKey in $request.QueryString.Keys) {
                Write-Verbose -Message "Adding queryString $queryKey --> $($request.QueryString.GetValues($queryKey))"
                $queryString = @{
                    $queryKey = $($request.QueryString.GetValues($queryKey))
                }
                $null=$QueryStrings.Add($queryString)
            }
            $parameters = @{
                queryStrings = $QueryStrings
                body = $body
            }
            Write-Verbose -Message "Executing $PSScriptRoot\$($application.name)\$($application.subname)\index.ps1"
            $result = & "$PSScriptRoot\$($application.name)\$($application.subname)\index.ps1" @parameters 
            $message = $result.output | Out-String
            $response.ContentType = $result.contentType;
        } 
        else {
            $message = "The page you're looking for does not exists!";
            $response.ContentType = 'text/html' ;
       }
        
       [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
       $response.ContentLength64 = $buffer.length
       $output = $response.OutputStream
       $output.Write($buffer, 0, $buffer.length)
       $output.Close()
   }    
}
$listener.Stop()
