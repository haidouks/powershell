$TestPath = Split-Path -Parent $MyInvocation.MyCommand.Path 
$ModulePath = Split-Path -Path $TestPath -Parent
Import-Module $ModulePath -Force
Describe "Get-FileEncoding" {
	Context "If file is there" {
		$file = "$TestPath\Data\UTF8.txt"
		$result = Get-FileEncoding -Path $file
		It "Encoding for the file($file) Should Be UTF8" {
			$result | Should be "UTF8"
		}

		$file = "$TestPath\Data\ASCII.txt"
		$result = Get-FileEncoding -Path $file
		It "Encoding for the file($file) Should Be ASCII" {
			$result | Should be "ASCII"
		}
	}
}

Describe "Find-Handle" {
	Context "If the process is explorer" {
		$handles = Find-Handle -Process "Explorer"
		$result = $handles.Count
		It "Should find more than 1 handle" {
			$result | should BeGreaterThan 1
		}
	}
}

Describe "Search-BigFile" {
	Context "If file is there" {

		$folder = "$TestPath\Data"
		Write-Verbose -Message "Folder : $folder"
		$keyword = 'CnSn','Me'
		$result = Get-ChildItem -Path $folder -File|ForEach-Object{Search-BigFile $_.FullName -Keywords $keyword -Highlight}
		$lineNumber = $result.LineNumber
		$content = $result.Content
		It "LineNumber for the folder($folder) Should Be 2 and Content should be 'search*Me* search*Me* search *Me* *CnSn*'" {
			$lineNumber | Should be 2 
			$content | Should be 'search*Me* search*Me* search *Me* *CnSn*'
		}

		$file = "$TestPath\Data\fast-search.txt"
		$keyword = 'SeArchMe'
		$result = (Search-BigFile -Path $file -Keywords $keyword)
		

		It "Check result length and content of third item for keyword 'searchMe'. Case insensitive" {
			$result.Length | Should be 3
			$result[2].Content | Should be 'searchMe search Me searchMe'
		}
	}
}

