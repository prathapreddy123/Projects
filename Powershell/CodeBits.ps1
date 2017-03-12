######################################################## Menu Creation #######################################################################################
$caption = "Choose Action";
 $message = "What do you want to do?";
 $reportmigration = new-Object System.Management.Automation.Host.ChoiceDescription "&ReportMigration","ReportMigration";
 $rollback = new-Object System.Management.Automation.Host.ChoiceDescription "&Rollback","Rollback";
 $choices = [System.Management.Automation.Host.ChoiceDescription[]]($reportmigration,$rollback);
 $answer = $host.ui.PromptForChoice($caption,$message,$choices,0)
 
 switch($answer)
 {
    0{Invoke-Expression -Command ".\ReportMigration.ps1"; break}
    1{Invoke-Expression -Command ".\Rollback.ps1"; break}
 }

"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')   $message" | out-file -Append -filepath "$currentPath/$logFile"   #Writing to file
Start-Sleep -Milliseconds 200

[Object[]]$currentJobs = @(Get-Job);       #Represents an array of object

$DirectoryofCurrentScript = Split-Path -Parent $MyInvocation.MyCommand.Path
$CurrentScriptName = (Split-Path -Leaf $MyInvocation.MyCommand.Path)   #.Replace(".Tests.", ".")

#Formatting strings
Get-WmiObject Win32_Service | ForEach-Object { if ($_.Started) { "{0}({1}) = {2}" -f $_.Caption, $_.Name, $_.Description } }

#List objects which are older than 30 days (720 hours)
Get-Childitem c:\myfiles\junk\*.* | Where-object{ (New-TimeSpan $_.LastWriteTime (Get-Date)).TotalHours -gt 720 } | Select-object -property Name,LastWriteTime

#Delete objects which are older than 30 days (720 hours)
Get-Childitem c:\myfiles\junk\Createabc.txt | foreach-object{ if((New-TimeSpan $_.LastWriteTime (Get-Date)).TotalHours -gt 720) { $_.Delete()} }

######################################################## Reading Config from XML #######################################################################################
 $hash = @{}
 
 [xml]$tokenConfig = Get-Content "$environments_dir\$environment\tokens.xml"
 $tokenConfig.tokens.token | ForEach-Object { $hash += @{$_.key = $_.value} }

######################################################## Convert Time To UTC #######################################################################################
 $DateTime = [DateTime]::SpecifyKind((Get-Date), [DateTimeKind]::Local)
 $DateTime = $DateTime.ToUniversalTime()
 $DateTime.ToString("yyyy-MM-dd hh:mm:ss")
 $DateTime.ToString("yyyy-MM-dd hh:mm:ss.fffzzz")

########################################################  Menu Design  #######################################################################################
$yes = ([System.Management.Automation.Host.ChoiceDescription]"&yes")
$no = ([System.Management.Automation.Host.ChoiceDescription]"&no")
$selection = [System.Management.Automation.Host.ChoiceDescription[]] ($yes,$no)
$answer = $host.ui.PromptForChoice('Reboot','May the system now be rebooted?',$selection,1)
$selection[$answer]
if ($selection -eq 0) {
"Reboot"
} else {
"OK, then not"
}

########################################################  SSAS Helper   ###########################################################################################
SSAS Helper DLL: http://ssas-info.com/analysis-services-tools/1745-ssas-helper							

[Reflection.Assembly]::LoadFile("$thisFolder\SSASHelper.dll")
$ssasHelper = New-Object SSASHelper.SSASHelper($cubeServerName, $cubeDBName, $logDir)
$mdx = $ssasHelper.GetLogicCubeMDX($mainCube.Name, $hubServerName, $hubDBName, $metadataGroupName)
$mdx = $mainCube.MdxScripts.FindByName('MdxScript').Commands[0].Text

#Powershell Analysis Services command reference :http://technet.microsoft.com/en-us/library/hh758425.aspx
#Invoke-Sqlcmd   -   http://technet.microsoft.com/en-us/library/cc281720.aspx

#############################################   Usage of Invoke-Command to invoke script block  ##################################################################
#Invoke-Command Runs commands or expressions on the local computer.  valid from poweshell 2.0

$dimSchema = {
		Param(
			[string] $tableName,
			[string] $template,
			[string] $keyColumn
		)
		$sql = "SELECT count(table_name) FROM tables where table_schema = '$schemaName' and table_name = '$tableName'"
		[int] $count = [int] $verticaConnection.QueryScalar($sql)
		if ($count -eq 0) {
			$sql = "CREATE TABLE IF NOT EXISTS $schemaName.$tableName AS SELECT * FROM $schemaName.$template ORDER BY $keyColumn UNSEGMENTED ALL NODES;"
			$verticaConnection.Execute($sql)
			echo "Added : table $schemaName.$tableName"
			$sql = "ALTER TABLE $schemaName.$tableName ADD CONSTRAINT PK_$tableName PRIMARY KEY ($keyColumn)"
			$verticaConnection.Execute($sql)	
		}
	}

# Invoke command calling function.  Function can also be called directly	
Invoke-Command -ScriptBlock {$dimSchema -ArgumentList $productTableName, "OLAP_ITEM_TEMPLATE", "ITEM_KEY" }

#Invoke command to run on remote computer and  scriptblock accepts source and Dest
Invoke-command -computername $serverName -scriptblock {param([string] $s, [string] $d) $s; Copy-Item $s $d} -ArgumentList $source,$destination


#Run the sample.ps1 script on all of the computers listed in the Servers.txt file. The command uses the FilePath parameter to specify the script file. This command allows you to run the script on the remote computers, even 
#if the script file is not accessible to the remote computers.When you submit the command, the content of the Sample.ps1 file is copied into a script block and the script block is run on each of the remote computers. This procedure is equivalent to 
#using the ScriptBlock parameter to submit the contents of the script.
invoke-command -comp (get-content servers.txt) -filepath c:\scripts\sample.ps1 -argumentlist Process, Service

#Refer:http://technet.microsoft.com/en-us/library/dd347578.aspx  for more information

#############################################   Usage of Invoke-Expression to invoke another powershell script  ##################################################################
#Invoke-Expression Runs commands or expressions on the local computer.  Valid from powershell 3.0

#All the below calls are valid
Invoke-Expression -Command "$thisScript\materialize.ps1 -serverName $serverName -dbName $dbName -schemaName $schemaName -siloID $siloID -deploy 0 -check 1"  
Invoke-Expression  "$thisScript\materialize.ps1 -serverName $serverName -dbName $dbName -schemaName $schemaName -siloID $siloID -deploy 0 -check 1"   
"$thisScript\materialize.ps1 -serverName $serverName -dbName $dbName -schemaName $schemaName -siloID $siloID -deploy 0 -check 1" | invoke-expression
& "$thisScript\materialize.ps1 -serverName $serverName -dbName $dbName -schemaName $schemaName -siloID $siloID -deploy 0 -check 1"


# Running a cmd-let stored in string variable using Invoke-Expression
$command = "Get-Process | where {$_.cpu -gt 1000} "
invoke-expression $command   #Returns all the processes 

#Refer:http://technet.microsoft.com/en-us/library/hh849893.aspx  for more information

#######################  Multi Line Code using @ so that all special characters such as " . $ are treated as literals.    ############################################
$sql=@"
CREATE VIEW $schemaName.OLAP_STORE_FACT_COMPUTED AS
	  SELECT fact.RETAILER_KEY, fact.VENDOR_KEY, fact.ITEM_KEY, fact.STORE_KEY, fact.PERIOD_KEY, fact.SUBVENDOR_ID_KEY, fact.DC_KEY, fact.DC_RETAILER_KEY
	  ,  1 as PERIOD_ID, TO_CHAR(TO_DATE(PERIOD_KEY::VARCHAR, 'YYYYMMDD') + INTEGER '364', 'YYYYMMDD')::INTEGER NY_PERIOD_KEY
	  , CASE WHEN "Total Sales Volume Units" <> 0 THEN ROUND("Total Sales Amount"/"Total Sales Volume Units",2) END "Total Price"
	  , CASE WHEN "Promoted Sales Volume Units" <> 0 THEN ROUND("Promoted Sales Amount"/"Promoted Sales Volume Units",2) END "Promoted Price"
	  , CASE WHEN "Regular Sales Volume Units" <> 0 THEN ROUND("Regular Sales Amount"/"Regular Sales Volume Units",2) END "Regular Price"
	  , CASE WHEN "Store On Hand Volume Units" is not null then case when "Store On Hand Volume Units" > 0 then 0 else 1 end end "Store Out of Stock Indicator`"
	  , CASE WHEN "Store On Hand Volume Units" < 0 then 0 else "Store On Hand Volume Units" end "Store On Hand Volume Units Non-Negative"
	  , "Total Sales Volume Units" * it.EQUIVALENT_UNIT `"Total Sales Volume Equivalent Units"
	  , "Promoted Sales Volume Units" * it.EQUIVALENT_UNIT `"Promoted Sales Volume Equivalent Units"
	  , "Regular Sales Volume Units" * it.EQUIVALENT_UNIT "Regular Sales Volume Equivalent Units"
	  , "Store On Hand Volume Units" * it.EQUIVALENT_UNIT "Store On Hand Volume Equivalent Units"
	  $equiConversion $caseConversion
	   FROM $schemaName.SPD_FACT_PIVOT fact
		join $schemaName.OLAP_ITEM it on it.ITEM_KEY = fact.ITEM_KEY;
"@

########################################################    Hash Tables Creation/Set values/Get values and Accessing using keys  ########################################################

[hashtable] $dataPerm = @{}
$dataPerm.Set_Item($dataType, $values)
if ($dataPerm.ContainsKey($dataType)) 
{ 
  $values = $dataPerm.Get_Item($dataType)
} 

#Accessing using keys
foreach ( $key in $dataPerm.keys ) 
{ 
  $Strkey = [string] $key    #Type Conversion
  $Value = $dataPerm.$Strkey #Value
 }
 
 ########################################################    Parameter validation and Mandatory  ########################################################
   Param([Parameter(Mandatory=$true)] [ValidateSet("Tom","Dick","Jane")] [string]$DayofWeek)
   
   
########################################################  Create a function to invoke entire script block  using &  by passing Script block as parameter  ############################################
function Step
{
Param($msg, $stmt)
    write-host -NoNewLine "$msg "
    $space = " " *  [math]::max(70 - $msg.length,0)
    Try {
        &$stmt
        write-host -Foreground "green" "$space [done]"
    }
    Catch {
        write-host -Foreground "red" "$space [failed]"
        throw $_.Exception
    }
}

#Calling function.  Second parameter is a script block that contains all kinds of statements such as creating objects , calling functions etc
Step "Pivoting on stage table ($pivotStageTable)" {
        $sqlCmd                = $dw.CreateCommand()
        $sqlCmd.CommandText    = "select measure_name, unitsorsales from  metadata.MEASURES_CORE where retailer_name IN ('*', '$retailerName') and measuregroup_type = 'STORE' order by 1,2"
        $adapter               = New-Object Vertica.Data.VerticaClient.VerticaDataAdapter
        $adapter.SelectCommand = $sqlCmd
        $coreMeasureSet        = New-Object System.Data.DataSet
        [void] $adapter.Fill($coreMeasureSet)
        $sqlCmd.Dispose()
    }

######################################################## Delete empty Subfolders ##############################################
Get-ChildItem c:\shared -Directory -recurse | where {-NOT $_.GetFiles("*","AllDirectories")} |  del -recurse 

########################################################  Check for a word in files ##############################################
Get-ChildItem -recurse | Select-String -pattern "dummy" | group path | select name

####################################  Check for a program in Environment Variable ##############################################
($env:path | %{$_.split(';')}) | where { $_ -match ".*python.*"   }

####################################  Sorting HashTable by Value ##############################################
$hash.GetEnumerator() | Sort-Object {$_.Value.MemoryUsage} | Select Name, {$_.Value.MemoryUsage} | Format-Table -AutoSize

####################################  Check if software is installed ##############################################
#Option 1 - Using Get-WmiObject
Get-WmiObject -Class Win32_Product | ? {$_.name -match "Java*"  } | Select-Object -Property Name,version

#Remote computer
Get-WmiObject -Class Win32_Product -Computer <remote-comp-name> | Sort-object Name | select Name

#option 2 - using registry provider
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | 
Format-Table –AutoSize

Get-ItemProperty "HKLM:\Software\JavaSoft\Java Runtime Environment" | Select-Object -property currentversion

#Remote computer
Invoke-Command -cn wfe0, wfe1 -ScriptBlock {Get-ItemProperty "HKLM:\Software\JavaSoft\Java Runtime Environment" | Select-Object -property currentversion }