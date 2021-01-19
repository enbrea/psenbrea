# Copyright (c) STÜBER SYSTEMS GmbH. All rights reserved.
# Licensed under the MIT License.

BeforeAll {
	# Get the path of our module 
	$modulePath = $PSCommandPath.Replace('.tests.ps1','.psm1')
	# Import the module for testing
	Import-Module $modulePath -Force
	# Import assemblies
	Add-Type -Path .\_Dependencies\NuGet.Versioning.dll
}

Describe -name "Tests" {
	Context "Module interface" {
		It "Module should export 6 commands in alphabetical order." {
			$commands = Get-Command -Module PsEnbrea
			$commands.Count | Should -BeExactly 6
			$commands[0].Name | Should -Be "Initialize-EnbreaExport"
			$commands[1].Name | Should -Be "Initialize-EnbreaImport"
			$commands[2].Name | Should -Be "Install-EcfTools"
			$commands[3].Name | Should -Be "Start-EnbreaExport"
			$commands[4].Name | Should -Be "Start-EnbreaImport"
			$commands[5].Name | Should -Be "Update-EcfTools"
		}
	}
	Context "GetFullConfigPath" {
		It "[.\config] should return [.\config.json]" {
			InModuleScope PsEnbrea {
				$fileName = GetFullConfigPath .\config
				$fileName | Should -Be '.\config.json'
			}
		}
		It "[.\config.json] should return [.\config.json]" {
			InModuleScope PsEnbrea {
				$fileName = GetFullConfigPath .\config.json
				$fileName | Should -Be '.\config.json'
			}
		}
		It "[.\config.txt] should return [.\config.txt]" {
			InModuleScope PsEnbrea {
				$fileName = GetFullConfigPath .\config.txt
				$fileName | Should -Be '.\config.txt'
			}
		}
		It "[config] should return [($location)\config.json]" {
			InModuleScope PsEnbrea {
				$location = Get-Location
				$fileName = GetFullConfigPath config
				$fileName | Should -Be "$($location)\config.json"
			}
		}
		It "[config.json] should return [($location)\config.json]" {
			InModuleScope PsEnbrea {
				$location = Get-Location
				$fileName = GetFullConfigPath config.json
				$fileName | Should -Be "$($location)\config.json"
			}
		}
		It "[config.txt] should return [($location)\config.txt]" {
			InModuleScope PsEnbrea {
				$location = Get-Location
				$fileName = GetFullConfigPath config.txt
				$fileName | Should -Be "$($location)\config.txt"
			}
		}
	}
	Context "GetSemVersion" {
		It "[0.0.1] should be ok" {
			InModuleScope PsEnbrea {
				$semVersion = GetSemVersion "0.0.1"
				$semVersion.Major | Should -Be 0
				$semVersion.Minor | Should -Be 0
				$semVersion.Patch | Should -Be 1
				$semVersion.Release | Should -Be ""
			}
		}
		It "[1.0.0] should be ok" {
			InModuleScope PsEnbrea {
				$semVersion = GetSemVersion "1.0.0"
				$semVersion.Major | Should -Be 1
				$semVersion.Minor | Should -Be 0
				$semVersion.Patch | Should -Be 0
				$semVersion.Release | Should -Be ""
			}
		}
		It "[1.3.5] should be ok" {
			InModuleScope PsEnbrea {
				$semVersion = GetSemVersion "1.3.5"
				$semVersion.Major | Should -Be 1
				$semVersion.Minor | Should -Be 3
				$semVersion.Patch | Should -Be 5
				$semVersion.Release | Should -Be ""
			}
		}
		It "[1.3.5-alpha1] should be ok" {
			InModuleScope PsEnbrea {
				$semVersion = GetSemVersion "1.3.5-alpha1"
				$semVersion.Major | Should -Be 1
				$semVersion.Minor | Should -Be 3
				$semVersion.Patch | Should -Be 5
				$semVersion.Release | Should -Be "alpha1"
			}
		}
		It "[2.3.5-alpha1] should be ok" {
			InModuleScope PsEnbrea {
				$semVersion = GetSemVersion "2.3.5-beta"
				$semVersion.Major | Should -Be 2
				$semVersion.Minor | Should -Be 3
				$semVersion.Patch | Should -Be 5
				$semVersion.Release | Should -Be "beta"
			}
		}
		It "[v-0.0.1] should be ok" {
			InModuleScope PsEnbrea {
				$semVersion = GetSemVersion "v-0.0.1"
				$semVersion.Major | Should -Be 0
				$semVersion.Minor | Should -Be 0
				$semVersion.Patch | Should -Be 1
				$semVersion.Release | Should -Be ""
			}
		}
		It "[v-0.0.2] should be greater than [v-0.0.1]" {
			InModuleScope PsEnbrea {
				$semVersion1 = GetSemVersion "v-0.0.1"
				$semVersion2 = GetSemVersion "v-0.0.2"
				$semVersion2 -gt $semVersion1 | Should -Be True
			}
		}
		It "[v-0.0.2] should be greater than [v-0.0.2-alpha]" {
			InModuleScope PsEnbrea {
				$semVersion1 = GetSemVersion "v-0.0.2-alpha"
				$semVersion2 = GetSemVersion "v-0.0.2"
				$semVersion2 -gt $semVersion1 | Should -Be True
			}
		}
		It "[System.Version] should be ok" {
			InModuleScope PsEnbrea {
				$semVersion = GetSemVersion (New-Object System.Version(0, 0, 1)).ToString()
				$semVersion.Major | Should -Be 0
				$semVersion.Minor | Should -Be 0
				$semVersion.Patch | Should -Be 1
				$semVersion.Release | Should -Be ""
			}
		}
	}
}