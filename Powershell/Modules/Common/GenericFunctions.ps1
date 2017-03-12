function Get-LogPath{
  Param([Parameter(Mandatory=$true)][string]$LogFileName)
  return [System.IO.Path]::Combine($global:LogDirectoryPath,$LogFileName.Replace(".ps1",".log"))
}

function Get-ErrorLogPath{
  Param([Parameter(Mandatory=$true)][string]$LogFileName)
  return [System.IO.Path]::Combine($global:LogDirectoryPath,($LogFileName.Replace(".ps1","") + "_Errors.log"))
}

function Log-Message{
   Param([Parameter(Mandatory=$true)][string]$Message = "No Message",[Boolean]$OverWrite = $False)
   
   if($OverWrite) {
    "$(Get-Date) - $Message " > $global:LogFilePath
   } else {
    "$(Get-Date) - $Message " >> $global:LogFilePath
  }
}
 
function Log-Error{
   Param([Parameter(Mandatory=$true)][string]$Error)
  
   "$(Get-Date) - Error:$Error " >> $global:ErrorLogPath
 }
 
 
function Get-UTCTime{
  $DateTime = [DateTime]::SpecifyKind((Get-Date), [DateTimeKind]::Local)
  $DateTime.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
}

function ArchiveandPurge{
   Param([Parameter(Mandatory=$true)][string]$SourceFilePath,[Parameter(Mandatory=$true)][string]$ArchiveFilePath,[int]$PurgeDays) 
 
   Move-Item $SourceFilePath $ArchiveFilePath -force
 
   if($PurgeDays -gt 0) {
     Get-Childitem $ArchiveFilePath\*.* | foreach-object{ if((New-TimeSpan $_.LastWriteTime (Get-Date)).TotalDays -ge $PurgeDays) { $_.Delete()} }
   }
 
 }

function Get-DayNumberOFWeek{
 Param([Parameter(Mandatory=$true)][string]$DayofWeek)
  Switch($DayofWeek.TOUPPER().SUBSTRING(0,3))    
  {
	  "MON" { return 1 }
	  "TUE" { return 2 }
	  "WED" { return 3 }
	  "THU" { return 4 }
	  "FRI" { return 5 }
	  "SAT" { return 6 }
	  "SUN" { return 7 } 
	  Default { return -1 }
  }
}

function Get-NextRunDate{
      Param([Parameter(Mandatory=$true)][DateTime]$SourceDate,[Parameter(Mandatory=$true)][string]$RunDaysofWeek)
	  [int[] ]$RunDaysofWeek_DayNumbers=@()
	  $RunDaysofWeek.split("|")|ForEach-object{$RunDaysofWeek_DayNumbers += Get-DayNumberOFWeek $_}
	  if($RunDaysofWeek_DayNumbers -Contains -1){
	    throw "Get-NextRunDate:Invalid Day of Week. Day of week should be MON,TUE,WED,THU,FRI,SAT,SUN"
	  }
	  [int]$CurrentDayNumberofWeek = Get-DayNumberOFWeek $SourceDate.DayOfWeek
	  [int]$NextDay = $CurrentDayNumberofWeek 
	  [int]$AddDays = 0 
	  [int]$index = 0
	 while($true)
	 {
	   if($RunDaysofWeek_DayNumbers -Contains $NextDay)   #if the Day is available in list of days specified in schedule
	   {
	     #if next run day of week (say Thursday)is ahead of current day of week(Say Tuesday), adddays is next run day of week - current day of week
		 #if next run day of week (say Tuesday)is same of current day of week(Say Tuesday) i.e adddays is 0
		 #if next run day of week (say Monday)is ahead of current day of week(Say Friday), adddays is 7 + (next run day of week - current day of week)
		 if($NextDay -gt $CurrentDayNumberofWeek) {$AddDays =  $NextDay - $CurrentDayNumberofWeek }  
		 elseif($NextDay -eq $CurrentDayNumberofWeek) { $AddDays = 0 }
		 else { $AddDays = 7 + ($NextDay - $CurrentDayNumberofWeek) }
		 break
	   }
	   elseif($NextDay -eq 7) #if sunday Initialize to zero and start over the week
	   {
		 $NextDay = 0
	   }
	   $NextDay++ #Move forward by each day
	   #This block is for Safety and can be removed after few runs
	   $index++
	   if($index -gt 8){
	    throw  "Infinite loop in Get-NextRunDate function"
		break
	   }
	 }
	  return ( "{0:MM/dd/yyyy}" -f ($SourceDate).AddDays($AddDays))
} 

function Get-DateExcludingWeekends([Parameter(Mandatory=$true)][DateTime]$SourceDate,[Parameter(Mandatory=$true)][int]$NumberofDays) {
   [int]$Multiplier = 1
   
   if($NumberofDays -eq 0) {
     return $SourceDate
   } elseif($NumberofDays -lt 0){
      $Multiplier = -1
   }
  
    [int]$index = 1  
	[int]$AddDays = 1
   while($index -le [System.Math]::Abs($NumberofDays)){
     [string]$WeekDay = $SourceDate.AddDays($AddDays *  $Multiplier).DayOfWeek
	  $AddDays++
	 if($WeekDay -eq "Saturday" -or $WeekDay -eq "Sunday"){
	  continue
	 }
	  $index++
   }
   
   #Reduce one day as adddays moves one day ahead before exiting loop
   $AddDays--
   
  return $SourceDate.AddDays(($AddDays * $Multiplier))

}

#Add GetValue method to HashTable with ability to provide defaultvalue
function Get-CustomHashTable {
 param()

 [HashTable]$htblObject = @{}

  #Add a method to get the Values	  	
  Add-Member -InputObject $htblObject -MemberType ScriptMethod -Name GetValue -Value {
	param([string] $name, [string] $defaultValue=$null)
	if($this.ContainsKey($name) -and (![string]::IsNullOrEmpty($this.Get_Item($name)))) {
	   return $this.Get_Item($name)
	 } else {
	   return $defaultValue
	 }
  }

  return $htblObject
}

#Converts DataTable to HashTable
function ConvertTo-HashTable {
  param([Parameter(Mandatory=$true)][Alias("Values")][System.Data.DataTable]$dtblValues)

  if($dtblValues.Columns.Count -ne 2) {
     throw "Invalid Argument: DataTable should contain 2 columns to be converted to Hash Table"
   }

  [HashTable]$htblValues = Get-CustomHashTable
  $dtblValues.rows | ForEach-Object { $htblValues.Add($_[0],$_[1]) }
  return $htblValues
}

#Converts DataTable to GroupTable (i.e HashTable with string as key and another HashTable as Value) 
function ConvertTo-GroupTable {
Param([Parameter(Mandatory=$true)][Alias("Values")][System.Data.DataTable]$dtblValues)

   if($dtblValues.Columns.Count -ne 3) {
     throw "Invalid Argument: DataTable should contain 3 columns to be converted to Group Table"
   }

   [HashTable]$GroupTable = @{}
   $dtblValues.rows | ForEach-Object { 	
                        if($GroupTable[$_[0]] -ne $null) { 
			              [void] $($GroupTable[$_[0]]).Add($_[1],$_[2])
			            } else  {
				          $GroupTable.Add($_[0], @{$_[1] = $_[2]})  #New Group
			            } #end of checking whether new Group or not
                      }
  	 		 
 #Add a method to get the Values	  	
  Add-Member -InputObject $GroupTable -MemberType ScriptMethod -Name GetMemberValue -Value {
	param([string]$GroupKey,[string]$name, [string]$defaultValue=$null)
    	if($this.ContainsKey($GroupKey) -and (![string]::IsNullOrEmpty($($this[$GroupKey])[$name]))) {
				return $($this[$GroupKey]).Get_Item($name)
		} else {
				return $defaultValue
		}
  }

  return $GroupTable
}

#Converts HashTable to DataTable
function ConvertTo-DataTable {
  param([Parameter(Mandatory=$true)][Alias("Values")][HashTable]$htblValues,[string[]]$ColumnNames = @("Col1","Col2"),[string[]]$DataTypes=@("String","String"))

  if($ColumnNames.Length -ne 2 -or $DataTypes.Length -ne 2)  {
    throw "ConvertTo-DataTable: Invalid Parameters - Only 2 values are supported for ColumnNames and DataTypes"
  }
 
  [System.Data.Datatable]$dtblValues = New-Object system.data.datatable
  $dtblValues.Columns.Add("$($ColumnNames[0])",[System.Type]::GetType("System.$($DataTypes[0])")) | out-null
  $dtblValues.Columns.Add("$($ColumnNames[1])",[System.Type]::GetType("System.$($DataTypes[1])")) | out-null

 
  $htblValues.Keys | ForEach-Object { 
                                     [System.Data.DataRow]$row = $dtblValues.NewRow()
                                     $row[0] = $_
                                     $row[1] = $htblValues[$_]
                                     $dtblValues.rows.Add($row)
                                    }
 return ,$dtblValues
}

#This function must be deprecated
function Remove-leadingCharacter{
Param([string]$InputValue="")
  return (Strip-leadingCharacter $InputValue)
}

function Strip-leadingCharacter{
 Param([string]$InputValue="")
  if($InputValue.length -eq 0){
    return $InputValue
  }
  return $InputValue.substring(1,$InputValue.Length - 1)
}

function Strip-TrailingCharacter{
  Param([string]$InputValue="")
  if($InputValue.length -eq 0){
    return $InputValue
  }
  return $InputValue.substring(0,$InputValue.Length - 2)
}

#Accepts array of values and returns first non null value. if all values are null returns null
function Coalesce {
  param([pscustomobject []]$Values)
  foreach($Value in $Values) {
     if($Value) {
       return $Value
     } 
  }
  return $null
 }
 
 function Get-LargerValue{
  Param($Value1,$Value2)

  if($Value1 -gt $Value2) {
   return $Value1
  } else {
    return $Value2
  }
}

 function Get-SmallerValue{
  Param($Value1,$Value2)

  if($Value1 -lt $Value2) {
   return $Value1
  } else {
    return $Value2
  }
}

function Exclude-ArrayElements {
 param([string[]]$OriginalArray, [string[]]$Elements)
 
 [string[]]$NewArray = @()
 $OriginalArray | Where-Object {$Elements -notcontains $_ } | ForEach-Object { $NewArray += $_ }
 return $NewArray
}

function Replicate {
  Param([Parameter(Mandatory=$true,ValueFromPipeline=$true)][Object]$Value,[Parameter(Mandatory=$true)][int]$Times)
 
   Process {
             0..($Times - 1) | ForEach-Object -Begin {[Object[]]$Values = @() } -Process { $Values += $Value } -End { return $Values }
          }
 }
 
function Delete-Files {
 param([Parameter(Mandatory=$true)][string[]]$FilePaths)

 $FilePaths | Where-Object {Test-path $_} | ForEach-Object { Remove-item -path $_ }
}

function Get-SqlType{
   Param([Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$ValueType)
  Switch($ValueType)    
  {
	  "String" { return "String" }
	  "Integer" { return "Int32" }
	  "Decimal" { return "Double" }
	  "DateTime" { return "DateTime" }
      default: { throw "Invalid value type.Cannot find corresponding Sqltype.Supported Value types are String,Integer,Decimal,DateTime" }
  }
}

 <#
function Get-EncryptedPassword
{
  return (get-content .\Configurations\engp2vtcn1.txt)
}

function WriteTo-File_Vertical{
   Param([string]$FilePath,[string]$Header,[string]$MetaData,[string]$Delimiter,[int]$GroupsCount,[int]$PrefixColumnCount,[int]$PartitionColumnCount)
  
    $Header | Out-file $FilePath -Force
	
	$index =0
	$GroupIndex=1
	While($GroupIndex -le $GroupsCount)
	{
	  foreach($Datarow in $global:dtblOlapResults.rows)
	  {
	     $PrefixColumnValues =""
		for($ColIndex=0;$ColIndex -lt $PrefixColumnCount;$ColIndex++)
        {	
       	  $PrefixColumnValues = $PrefixColumnValues + $Delimiter + $Datarow[$ColIndex]
        }
		
		$PartitionColumnValues =""
	    for($ColIndex=0;$ColIndex -lt $PartitionColumnCount;$ColIndex++)
        {		
		  $PartitionColumnValues = $PartitionColumnValues + $Delimiter + $Datarow[$PrefixColumnCount + $index + $ColIndex]
        }
		
		$MetaData + $PrefixColumnValues + $PartitionColumnValues >> $FilePath
	  }	
	   $index = $index + $PartitionColumnCount
	  
	   $GroupIndex = $GroupIndex + 1
	}
	
}  

function Set-FileConfigurationValue() {
    param([Parameter(Mandatory=$true)][string] $FilePath, [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Key
	      ,[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Value,[Switch] $ReplaceOnly)
    		
     $content = Get-Content -Path $FilePath
     $regex = '^' + [regex]::escape($key) + '\s*=.+'
	 if ( $content -match $regex ) {
        $content -replace $regex, "$key=$value" | Set-Content $FilePath 
        return 0   		
     } elseif (-not $ReplaceOnly)  {           
        Add-Content $FilePath "$key=$value"
		 return 0
     } else {
         Write-Warning "Key $Key not found in configuration file $FilePath"
		  return 1
     } 
  }
  
function Get-FileConfigurationValue() {
    param([Parameter(Mandatory=$true)][string] $FilePath, [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Key)
    		
     $content = @(Get-Content -Path $FilePath)
     $regex = '^' + [regex]::escape($key) + '\s*=.+'
	 $Value = $content -match $regex | %{ $($_.split("="))[1]}
	 return $Value 
  }

   
 
  Description: Validates whether all keys are available in the section specified in the .ini file as required
  
  Input Parameters: 
  1.SectionKeys - Keys available in a particulat section in .ini file
  2.ValidKeys  - Valid keys to be available in the corresponding Section 
    
  Return value : Message 	

   
function validate-KeysInSection(){
 param([Parameter(Mandatory=$true)][string[] ] $SectionKeys,[Parameter(Mandatory=$true)][string[] ] $ValidKeys,[Parameter(Mandatory=$true)][String] $iniFileName)
 
  [String] $ErrorMessage  = ""
  
  #Check for valid keys missing
  $ValidKeys | where-object {$SectionKeys -notcontains $_} | foreach-object {$MissingKeys =  $MissingKeys + "," + $_}
  if($MissingKeys.length -gt 0) { $MissingKeys = $MissingKeys.substring(1,$MissingKeys.Length-1); $ErrorMessage = "Missing Input Keys - $MissingKeys in $iniFileName.ini file for campaign $CampaignName`r`n"}  
   
   #Check for any Invalid keys presence
  $SectionKeys | where-object {$ValidKeys -notcontains $_} | foreach-object {$InvalidKeys =  $InvalidKeys + "," + $_}
  if($InvalidKeys.length -gt 0) {$InvalidKeys = $InvalidKeys.substring(1,$InvalidKeys.Length-1); $ErrorMessage += "Invalid Keys - $InvalidKeys found in $iniFileName.ini file for campaign $CampaignName`r`n"}  
  
  return $ErrorMessage

}   
   
   
#>

