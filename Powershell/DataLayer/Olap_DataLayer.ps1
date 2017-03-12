<#
Function Get-OlapServerDetails{
Param([Parameter(Mandatory=$true)][String]$HubServer,[Parameter(Mandatory=$true)][String]$HubDB,[Parameter(Mandatory=$true)][String]$SqlQuery)
   $dtblResults = Get-ResultSet $HubServer $HubDB $SqlQuery
   $CubeDetails=""
	if($dtblResults.rows.count -gt 0) {
		$CubeDetails  = $dtblResults.Rows[0]["CubeServer"] + "|" + $dtblResults.Rows[0]["Cube_DBName"] + "|" + $dtblResults.Rows[0]["Cube_Name"]
      }
	 else {
       $CubeDetails = $null
	 }
	 return $CubeDetails
}
#>

function Create-OlapConnection {
 	Param([Parameter(Mandatory=$true)][string]$OlapServer,[Parameter(Mandatory=$true)][string]$OlapDatabase,[string]$IISApp,[string]$UserId,[string]$Password)

    if($IISApp -eq 'NA') {
     [string]$ConnectionString = "data source=$OlapServer;initial catalog=$OlapDatabase;Connect Timeout=$global:Olap_ConnectionTimeOut_Seconds" #;ReturnCellProperties=True
	} else {
     [string]$ConnectionString = "data source=http://${OlapServer}/${IISApp}/msmdpump.dll;initial catalog=$OlapDatabase;User ID=$UserId;Password=$Password;Connect Timeout=$global:Olap_ConnectionTimeOut_Seconds"
    }

	$OlapConnection = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection $ConnectionString
    
	Add-Member -InputObject $OlapConnection -MemberType ScriptMethod -Name OpenConnection -Value {
	  if($this.state -ne [System.Data.ConnectionState]::Open)
	   {
		$this.Open();
	   }
	}

	Add-Member -InputObject $OlapConnection -MemberType ScriptMethod -Name CloseConnection -Value {
	  if($this.state -eq [System.Data.ConnectionState]::Open)
	   {
		$this.Close();
	   }
	}

    Add-Member -InputObject $OlapConnection -MemberType ScriptMethod -Name IsOpenConnection -Value {
	  if($this.state -eq [System.Data.ConnectionState]::Open) {
		 return $true
	   } else {
         return $false
       }
	}
   Add-Member -InputObject $OlapConnection -MemberType Noteproperty -Name ConnectionType -Value "OLAP"

   return $OlapConnection
}


Function Retrieve-OlapData {
    Param([Parameter(Mandatory=$true)][Microsoft.AnalysisServices.AdomdClient.AdomdConnection]$OlapConnection,[Parameter(Mandatory=$true)][string]$MDXQuery)
    #Reset-OlapDataTable 
   try{
   		
		#$OlapConnection = Create-OlapConnection  $OlapServer $OlapDatabase 
        [bool]$CloseConnection = $false 
        #Check if connection is already opened 
        if($OlapConnection.IsOpenConnection -eq $false) {
		   $OlapConnection.OpenConnection()    
           $CloseConnection = $true     
        }
		$MDXCmd = $OlapConnection.CreateCommand()
		$MDXCmd.CommandText = $MDXQuery  
	    $MDXCmd.CommandTimeout = $Olap_CommandTimeOut_Seconds 
		$adapter = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter
		$adapter.SelectCommand = $MDXCmd
		[System.Data.DataTable] $dtblResults = New-Object System.Data.DataTable 
	    $adapter.Fill($dtblResults) | Out-Null
		$MDXCmd.Dispose()
		return ,$dtblResults 
      } catch [Exception] {
	    throw 
	  } finally {
       if($CloseConnection){
	     $OlapConnection.CloseConnection()
        }
      }	
}

