function Get-FileEncoding {
    <#
  .SYNOPSIS
  Gets the encoding of a file
  .DESCRIPTION
  This function finds out the encoding of a file by converting it byte. Created by Cansin Aldanmaz - 30-06-2017
  .EXAMPLE
  Get-FileEncoding -Path c:\Users\Cansin.txt
  .EXAMPLE
  "c:\Users\Cansin.txt" | Get-FileEncoding
  .PARAMETER Path
  Specify the path of a file
  #>
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='The path of file which you want to find out the encoding')]
			[ValidateNotNullOrEmpty()]
			[String]$Path)
	$bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4 -ErrorAction Stop -ErrorVariable Err)
	Write-Verbose -Message "Checking encoding type for file:$Path"
	$result = $null 
	    if ($bytes -ne $null) {
            if ($bytes.Count -ge 4) {
                if ( $bytes[0] -eq 0xef -and $bytes[1] -eq 0xbb -and $bytes[2] -eq 0xbf ) {
                    $result = 'UTF8' 
                } elseif ($bytes[0] -eq 0xfe -and $bytes[1] -eq 0xff) {
                    $result = 'Unicode'
                } elseif ($bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 0xfe -and $bytes[3] -eq 0xff) {
                    $result = 'UTF32'
                } elseif ($bytes[0] -eq 0x2b -and $bytes[1] -eq 0x2f -and $bytes[2] -eq 0x76) {
                    $result = 'UTF7'
                } else {
                    $result = 'ASCII'
                }
				Write-Verbose -Message "Found encoding type: $result"
            } 
			else {
                Write-Error -Message ($Path + " is only " + $byte.Count + " bytes in size, unable to determine file encoding") -Category InvalidData -ErrorAction Stop -ErrorVariable Error
            }
        } 
		else {
			$Err = ($Path + " is zero byte(s) in size")
            Write-Error -Message $Err -Category InvalidData -ErrorAction Stop 
			}
		return $result	
}
function Update-ContentOfFile {
	<#
  .SYNOPSIS
  Change the content of a file
  .DESCRIPTION
  This function replaces the keywords in a file and|or let's you to keep/specify the encoding and take a backup of file. Created by Cansin Aldanmaz - 30-06-2017
  .EXAMPLE
  Replace-Content -Path "C:\Users\Cansin Aldanmaz\Desktop\vpn\successfull.txt" -To "MSI file" -From "Cansin File" -Encoding "UTF8"  
  .EXAMPLE
  Replace-Content -Path "C:\Users\Cansin Aldanmaz\Desktop\successfull.txt" -To "MSI file" -From "Cansin File" -TakeBackup -Verbose
  .PARAMETER Path
  Specify the path of the file
  .PARAMETER From
  Specify the keyword you want to change from
  .PARAMETER To
  Specify the keyword you want to change to
  .PARAMETER Encoding
  Specify the Encoding that you want to set for the file. If you don't specify, current encoding of file value will be saved.
  .PARAMETER TakeBackup
  If you want to take a backup of the file before you make changes, enable this switch.
  #>
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='The path of file which you want change content')]
			[ValidateNotNullOrEmpty()]
			[String]$Path,
		
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$False,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='The keyword that will be replaced from')]
			[String]$From,
		
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$False,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='The keyword that will be replaced to')]
			[String]$To,

		[Parameter(Mandatory=$False,
			ValueFromPipeline=$False,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='The keyword that will be replaced to')]
			[String]$Encoding,
		
		[Parameter(Mandatory=$False,
			ValueFromPipeline=$False,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Want to take a backup of file before changing it?')]
			[Switch]$TakeBackup = $False
	)
	$Error = $null
	$Item  = $null
	$Date  = $(Get-Date -Format 'yyyyMMddHHmm')
	Write-Host "Take backup value: $TakeBackup"
	try {
		Write-Verbose -Message "$(Get-Date)-Getting file: $Path"
		$Item = Get-Item -Path $Path -ErrorAction Stop -ErrorVariable Error
		if($TakeBackup)
		{
			$Destination = "$($Item.FullName)__$Date.backup"
			Write-Verbose -Message "$(Get-Date)-Taking a backup: $Destination"
			Copy-Item -Path $Item.FullName -Destination $Destination -ErrorAction Stop -ErrorVariable Error
		}
		Write-Verbose -Message "$(Get-Date)-Getting encoding"
		$CurrentEncoding = $(Get-FileEncoding -Path $Item.FullName -ErrorAction Stop -ErrorVariable Error)
		Write-Verbose -Message "$(Get-Date)-Encoding:$CurrentEncoding"
		Write-Verbose -Message "$(Get-Date)-Getting content and replacing from '$from' to '$to'"
		$Content = $(Get-Content -Path $Item.FullName -Raw -Encoding $CurrentEncoding -ErrorAction Stop -ErrorVariable Error).Replace($from,$to)
		Write-Verbose -Message "$(Get-Date)-Setting new content"
		If( (-not [String]::IsNullOrEmpty($Encoding)) -and ($Encoding -ne $CurrentEncoding))
		{
			Write-Verbose -Message "$(Get-Date)-Setting new Encoding:$Encoding"
		}
		else
		{
			$Encoding = $CurrentEncoding
			Write-Verbose -Message "$(Get-Date)-Encoding will not change:$Encoding"
		}
		Set-Content -Value $Content -Path $Item.FullName -Force -ErrorAction Stop -ErrorVariable Error -Encoding $Encoding
	}
	catch {
			throw $Error
		}
	}
function Search-BigFiles {
    <#
  .SYNOPSIS
  This function searchs keyword(s) in huge files which have milions of lines in a fast way.
  .DESCRIPTION
  This function searchs keyword(s) in huge files which have milions of lines in a fast way and return a hash list which contains results. Created by Cansin Aldanmaz - 30-06-2017
  .EXAMPLE
  Search-Fast -Path c:\Users\Cansin.txt -KeyWords ('deneme','deneme2')
  .EXAMPLE
  "c:\Users\Cansin.txt","c:\Users\Cansin.txt" | Search-Fast -KeyWords 'deneme','deneme2'
  .EXAMPLE	
  Get-ChildItem -Path c:\temp -File|ForEach-Object{Search-Fast $_.FullName -Keywords 'Deneme','asd' -Highlight}
  .PARAMETER Path
  Specify the path of large file(s)
  .PARAMETER Keywords
  Specify the keyword(s) that you want to search for.
  .PARAMETER Highlight
  Specify the Highlight switch if you want to highlight your keyword(s) in the line
  #>
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='The path of file(s)')]
			[ValidateNotNullOrEmpty()]
			[String[]]$Path,
	    [Parameter(Mandatory=$True,
			ValueFromPipeline=$false,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='Create a list that contains keywords.')]
			[ValidateNotNullOrEmpty()]
			[String[]]$Keywords,
	    [Parameter(Mandatory=$False,
			ValueFromPipeline=$false,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='Highlights keyword(s) in line')]
			[switch]$Highlight
	)
	$t1 = Get-Date
	write-verbose -Message "Search will start for file:´n$Path and Keywords:´n$($Keywords|Out-String -Stream)"
	$file = [IO.File]::OpenText($Path)
	$lineNumber = 0
	$Results = New-Object Collections.ArrayList
	while ($file.Peek() -ge 0) {
		$lineNumber=$lineNumber+1 
		$line = $file.ReadLine()
		$Counter = 0
		$continueToSearch = $true
		$Result = $null
		while($continueToSearch -and ($Counter -lt $Keywords.Count))
		{
			if($line -Match $Keywords[$Counter])
			{
				if($Highlight)
				{
					$line = $line.Replace($Keywords[$Counter],"*$($Keywords[$Counter])*")
				}
				write-verbose -Message "Found keyword($($Keywords[$Counter])) on line $lineNumber"
				$Counter=$Counter+1
			}
			else
			{
				if($Counter -ne 0)
				{
					write-verbose -Message "Couldn't find keyword($($Keywords[$Counter])) on line $lineNumber"
				}
				$continueToSearch = $false
			}
		}
		if($continueToSearch)
		{
				$Result = @{
					Keywords = $Keywords
					LineNumber = $lineNumber
					Content = $line.Trim()
					Path = $Path
				}
				[Void]$Results.Add($Result)
				write-verbose -Message "All keywords matched, added result to List ´n$($($result[1]) | out-string -Stream)"
			}
		}
	$file.Dispose()
	$t2 = Get-Date
	Write-Verbose -Message "Search completed in $(($t2-$t1).TotalSeconds) seconds."
	return $Results
}
function Find-Handle {
	<#
  .SYNOPSIS
  This function searchs for handles
  .DESCRIPTION
  This function searchs for handles. You can list handles created by process(es) or the processes that makes handle for a file. If you don't specify any thing, it will list all handles in operating system .Created by Cansin Aldanmaz - 13-07-2017
  .EXAMPLE
  Find-Handle -Path c:\Users\Cansin.txt
	.EXAMPLE
  Find-Handle -Path "c:\Users\Cansin.txt","C:\Program Files (x86)\Google\Chrome\Application\59.0.3071.115\chrome_child.dll"
  .EXAMPLE
  Find-Handle -Process chrome
  .PARAMETER Path
  Specify the path of large file(s)
  .PARAMETER Process
  Specify the name(s) of processes that you want to search for.
  #>
    
Param(
		[Parameter(Mandatory=$False,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='Enter the path(s) of file(s)')]
			[String[]]$Path,
	    [Parameter(Mandatory=$False,
			ValueFromPipeline=$False,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='Enter the name(s) of process(es)')]
			[String[]]$Process)
	$ProcessName = "*"
	If($Process.Count -gt 0)
	{
		$ProcessName = $Process
	}
	$Results = New-Object Collections.ArrayList
	Write-Verbose -Message "Getting all processes named $($ProcessName | Out-String -Stream)"
	$Procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
	If($procs -ne $null)
	{
		$Procs | foreach{
			$Proc = $_
			if($Path.Count -gt 0)
			{
				$Path | foreach{
				$p = $_
				$Proc.Modules | foreach{
					if($_.FileName -eq $p)
					{
						$Result = @{
							ProcessName = $Proc.Name
							ProcessID   = $Proc.Id
							File = $p
						}
						$object = New-Object -TypeName PSObject –Prop $Result
						[Void]$Results.Add($object)
					}
				}
			}
			}
			else
			{
				$_.Modules | foreach{
					$Result = @{
							ProcessName = $Proc.Name
							ProcessID   = $Proc.Id
							File = $_.FileName
						}
					$object = New-Object -TypeName PSObject -Prop $Result
					[Void]$Results.Add($object)
					}
			}
		}
		if($Results.Count -eq 0)
		{
			Write-Verbose -Message "No handles found!"
		}
	}
	else
	{
		Write-Warning -Message "No processes found for the process $($Process | out-string) . Please check process name!"
	}
	return $Results
}
function Remove-Handle {
		<#
  .SYNOPSIS
  This function removes handles from a file
  .DESCRIPTION
  This function searchs for handles. You can list handles created by process(es) or the processes that makes handle for a file. If you don't specify any thing, it will list all handles in operating system .Created by Cansin Aldanmaz - 13-07-2017
  .EXAMPLE
  Remove-Handle -Path c:\Users\Cansin.txt -Force
	.EXAMPLE
  Remove-Handle -Path "c:\Users\Cansin.txt","C:\Program Files (x86)\Google\Chrome\Application\59.0.3071.115\chrome_child.dll"
  .EXAMPLE
  Find-Handle -Process chrome
  .PARAMETER Path
  Specify the path of large file(s)
  .PARAMETER Process
  Specify the name(s) of processes that you want to search for.
  #>
    
Param(
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='Enter the path(s) of file(s)')]
			[ValidateNotNullOrEmpty()]
			[String[]]$Path,
		[Parameter(Mandatory=$False,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
    		HelpMessage='Before killing the process confirm it')]
			[Switch]$Confirm = $False
	)
	foreach($p in $Path)
	{
		Write-Verbose -Message "Finding handles for path $p"
		$handles = Find-Handle -Path $p
		Write-Verbose -Message "$($handles.Count) handles found, removing handles"
		$handles | foreach {
			$handle = $_
			Stop-Process -Id $handle.ProcessID -Confirm:$(-not $Confirm) -Force -ErrorAction Continue
		}
	}
}