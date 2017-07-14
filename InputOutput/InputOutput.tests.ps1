$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module $ModulePath -Verbose -Force
Describe "Get-FileEncoding" {
	Context "If file is there" {
		$file = "$ModulePath\Tests\UTF8.txt"
		$result = Get-FileEncoding -Path $file
		It "Encoding for the file($file) Should Be UTF8" {
			$result | Should be "UTF8"
		}

		$file = "$ModulePath\Tests\ASCII.txt"
		$result = Get-FileEncoding -Path $file
		It "Encoding for the file($file) Should Be ASCII" {
			$result | Should be "ASCII"
		}
	}
}
Describe "Search-BigFiles" {
	Context "If file is there" {

		$folder = "$ModulePath\Tests"
		$keyword = 'CnSn','Me'
		$result = Get-ChildItem -Path $folder -File|ForEach-Object{Search-BigFiles $_.FullName -Keywords $keyword -Highlight}
		$lineNumber = $result.LineNumber
		$content = $result.Content
		It "LineNumber for the folder($folder) Should Be 2 and Content should be 'search*Me* search*Me* search *Me* *CnSn*'" {
			$lineNumber | Should be 2 
			$content | Should be 'search*Me* search*Me* search *Me* *CnSn*'
		}

		$file = "$ModulePath\Tests\fast-search.txt"
		$keyword = 'SeArchMe'
		$result = (Search-Fast -Path $file -Keywords $keyword)
		

		It "Check result length and content of third item for keyword 'searchMe'. Case insensitive" {
			$result.Length | Should be 3
			$result[2].Content | Should be 'searchMe search Me searchMe'
		}
	}
}
Describe "Handle specific tests"{
	Context "Find-Handle function tests"{
		It "There should be more than 100 handles on the operating system" {
			(Find-Handle).Count | Should BeGreaterThan 10
		}
		It "There should be some handles for svchost process" {
			(Find-Handle -Process svchost).Count | Should BeGreaterThan 0
		}
		It "There should be no handle for test file" {
			$file = "$ModulePath\Tests\UTF8.txt"
			(Find-Handle -Path $file).Count | Should Be 0
		}
	}
}