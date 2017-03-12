function Initialize-Environment {
Param([Parameter(Mandatory=$true)][string]$RootDirectory)
  [HashTable]$htblEnvironmentDetails = Get-CustomHashTable #Adds Get-Value method to HashTable. Function defined in GenericFunctions.ps1
  
  (Get-Content (Resolve-path "${RootDirectory}\Configurations\EnvironmentDetails.ini")) |
                foreach-object {
                                 [string[]]$KvPair = $_.split("=")
                                 if($KvPair.length -eq 2){
                                   $htblEnvironmentDetails.Add($KvPair[0].Trim(),$KvPair[1].Trim())
                                 }
                               }
 
 #$global:Environment = $htblEnvironmentDetails.GetValue("Environment","Missing")
 $global:DBServer = $htblEnvironmentDetails.GetValue("DBServer","Missing") 
 $global:DBName = $htblEnvironmentDetails.GetValue("DBName","Missing") 
 $global:StrSvcSchema = $htblEnvironmentDetails.GetValue("StrSvcSchema","Missing") 
 $global:SharedSchema = $htblEnvironmentDetails.GetValue("SharedSchema","Missing")
 $global:LogDirectoryPath = $htblEnvironmentDetails.GetValue("LogDirectoryPath","Missing") 
 $global:ArchiveDirectoryPath = $htblEnvironmentDetails.GetValue("ArchiveDirectoryPath","Missing") 
 Validate-Values -ErrorPrefix "Missing Environment Value(s)" -Names @("DB Server","DB Name","Store Service Schema","Shared Schema","Log Directory Path","Archive Directory Path") -Values @($global:DBServer,$global:DBName,$global:StrSvcSchema,$global:SharedSchema,$global:LogDirectoryPath,$global:ArchiveDirectoryPath)
 $global:LogDirectoryPath = (Resolve-Path -Path (join-path $RootDirectory $global:LogDirectoryPath))
 $global:ArchiveDirectoryPath = (Resolve-Path -Path (join-path $RootDirectory $global:ArchiveDirectoryPath))
}

function Fetch-Configurations {
 
    [System.Data.DataTable]$dtblConfig = Get-ResultSet $global:DBServer $global:DBName "SELECT * FROM [$global:StrSvcSchema].[vwConfigurations]" 

    #Add a method to get the Configuration Value
    Add-Member -InputObject $dtblConfig -MemberType ScriptMethod -Name GetValue -Value {
	 param([string]$ConfigName, [string]$DefaultValue=$null,[string]$Environment = "All")
    
     [System.Data.DataRow[]]$Configurations = $this.Select("Environment= '$Environment' AND (Identifier='NA' OR Identifier='ALL') AND ConfigName='$ConfigName'")
	 if($Configurations.Count -gt 0) {
	   return $Configurations[0]["ConfigValue"]
	  } 
		
     return $DefaultValue
    }


   #Add a method to get the Configuration Value for one or more customers
   Add-Member -InputObject $dtblConfig -MemberType ScriptMethod -Name GetCustomersValue -Value {
     param([Parameter(Mandatory=$true)][string]$ConfigName,[string[]]$Customers,[string]$Environment = "All")
 
     [string]$Filter = "Environment= '$Environment' AND ConfigType = 'Customer' AND ConfigName='$ConfigName'"
     if($Customers.Length -gt 0) {
        $Filter += " AND (identifier = '" +  ($Customers -join ",").Replace(",","' OR identifier = '") + "')"  #creates filter as (identifier='MXP' OR identifier='VAL' OR identifier='EVD')
     }   
 
    [HashTable]$htblConfigValues =  Get-CustomHashTable
    $this.Select($Filter) | ForEach-Object { $htblConfigValues.Add($_["identifier"],$_["ConfigValue"])   }
    return $htblConfigValues 
 
   }

   return ,$dtblConfig
}

function Parse-Configurations {
   param([Parameter(Mandatory=$true)][System.Data.DataTable]$dtblConfigurations,[string]$Environment,[string[]]$ConfigTypes,[string[]]$Identifiersets,[string]$Delimiter = '|')
   
   [string]$EnvironmentFilter = "Environment='All'"
   [string]$LogMessage = "Loading Global Configurations for Environments:All"

   if($Environment.length -gt 0) {
      $LogMessage += ",$Environment"
     [string]$EnvironmentFilter += " OR Environment='" + $Environment +  "'"
   }

   Log-Message $LogMessage
   [System.Data.DataRow []]$Configurations = $dtblConfigurations.Select("(Identifier='ALL' OR Identifier='NA') AND (${EnvironmentFilter})")
   
   [HashTable]$htblConfig = Get-CustomHashTable 
   
   foreach($Configuration in $Configurations) {
	   $htblConfig.Add($Configuration["ConfigName"],$Configuration["ConfigValue"])
	 } 
     
   for($index = 0;$index -lt $ConfigTypes.length;$index++){  
      [string]$ConfigType = $ConfigTypes[$index]
      #[string]$IdentiferFilter = ""
      Log-Message  "Loading Configurations for ConfigType:$ConfigType"
	  [string]$identifier = $Identifiersets[$index]
	  [System.Data.DataRow []]$Configurations = $dtblConfigurations.Select("ConfigType='$ConfigType' AND Identifier = '$identifier' AND (${EnvironmentFilter})")
      foreach($Configuration in $Configurations) {
       if($htblConfig[$Configuration["ConfigName"]] -eq $null) {
         $htblConfig.Add($Configuration["ConfigName"],$Configuration["ConfigValue"])
       } else {
         $htblConfig[$Configuration["ConfigName"]] = $Configuration["ConfigValue"]
       }
      }  #end of foreach Configurations 
   } #end of foreach configTypes
   
    return $htblConfig
}

function Validate-Values {
<#
.SYNOPSIS
  Checks if Configuration Values are available or missing

.DESCRIPTION
  Checks if Configuration Values are available or missing

.PARAMETER ErrorPrefix
  Message to Prefix error

.PARAMETER Names
  Configuration Names

.PARAMETER Values
  Configuration Values
#>
Param([string] $ErrorPrefix="Missing Configuration Value(s)",[Parameter(Mandatory=$true)][Alias("Names")][string[]]$ColNames,[Parameter(Mandatory=$true)][Alias("Values")][string[]]$ColValues)
     
    [string]$ErrorMessage =""
	for($index=0;$index -lt $ColNames.length;$index++){
	   if($ColValues[$index] -eq "Missing" -or $ColValues[$index].Length -eq 0) { 
          $ErrorMessage +=  "," + $ColNames[$index] 
       }
	}

 	if($ErrorMessage.length -gt 0) { 
       throw "$ErrorPrefix - $($ErrorMessage.substring(1,$ErrorMessage.Length-1))" 
    }
}

function Get-ConfigValueAsArray {
 param([Parameter(Mandatory=$true)][string]$ConfigName,[Parameter(Mandatory=$true)][string]$ConfigValue,[string]$Delimiter = '|',[string]$MissingValue = "Missing")

 if($ConfigValue -eq $MissingValue) {
    throw "$ConfigName Configuration is not available in Configurations table" 
 }
 return @($ConfigValue.split($Delimiter))
}