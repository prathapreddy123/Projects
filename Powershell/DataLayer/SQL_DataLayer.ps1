
function Create-SQLConnection {
 	 Param([Parameter(Mandatory=$true)][string] $server,[Parameter(Mandatory=$true)][string] $dbName,[string] $UserID = "",[string] $Password= "")
	if($UserID.length -eq 0){
     $SQLConnection = new-object System.Data.SqlClient.SqlConnection "Server=$server;Database=$dbname;Integrated Security=SSPI;"  
	} else {
	  $SQLConnection = new-object System.Data.SqlClient.SqlConnection "Server=$server;Database=$dbname;User ID=$UserID;Password=$Password;"
	}
	Add-Member -InputObject $SQLConnection -MemberType ScriptMethod -Name OpenConnection -Value {
	  if($this.state -ne [System.Data.ConnectionState]::Open)
	   {
		$this.Open();
	   }
	}

	Add-Member -InputObject $SQLConnection -MemberType ScriptMethod -Name CloseConnection -Value {
	  if($this.state -eq [System.Data.ConnectionState]::Open)
	   {
		$this.Close();
	   }
	}
 return $SQLConnection
}

 function Get-ResultSet {
   Param([Parameter(Mandatory=$true)][String]$server,[Parameter(Mandatory=$true)][String]$dbName,[Parameter(Mandatory=$true)][String]$sqlQuery,[System.Data.CommandType]$QueryType = [System.Data.CommandType]::Text)
   try{
	    [System.Data.SqlClient.SqlConnection]$SQLConnection = Create-SQLConnection $server $dbName
		$sqlCmd = $SQLConnection.CreateCommand()
		$sqlCmd.CommandText = $sqlQuery     
        $sqlCmd.CommandType = $QueryType 
		$adapter = New-Object System.Data.SqlClient.sqlDataAdapter
		$adapter.SelectCommand = $sqlCmd
		[System.Data.Datatable]$dtblResultSet = New-Object System.Data.DataTable
		$adapter.Fill($dtblResultSet) | Out-Null
		$sqlCmd.Dispose()
	    return ,$dtblResultSet
   }catch [Exception]{
    throw   
  }finally {
	if($SQLConnection -ne $null) {$SQLConnection.CloseConnection() }
  }
 }
 

 function Get-ResultSet {
   Param([Parameter(Mandatory=$true)][String]$server,[Parameter(Mandatory=$true)][String]$dbName,[Parameter(Mandatory=$true)][String] $sqlQuery
        ,[string[]]$ParameterNames,[string[]]$ParameterTypes,[string[]]$Parametervalues,[System.Data.CommandType]$QueryType = [System.Data.CommandType]::Text)
   try{
	    [System.Data.SqlClient.SqlConnection]$SQLConnection = Create-SQLConnection $server $dbName
		$sqlCmd = $SQLConnection.CreateCommand()
		$sqlCmd.CommandText = $sqlQuery     
        $sqlCmd.CommandType = $QueryType 
        for ([int]$index = 0; $index -lt $ParameterNames.Length; $index++)
        {
          [SqlParameter] $parameter = New-Object System.Data.SqlClient.SqlParameter($ParameterNames[$index],(Get-SqlDbType $ParameterTypes[$index]),(Get-SqlParamLength $ParameterTypes[$index]))
          $parameter.Value = $Parametervalues[$index];
          [void]$sqlCmd.Parameters.Add($parameter);
        }
		$adapter = New-Object System.Data.SqlClient.sqlDataAdapter
		$adapter.SelectCommand = $sqlCmd
		[System.Data.Datatable]$dtblResultSet = New-Object System.Data.DataTable
		$adapter.Fill($dtblResultSet) | Out-Null
		$sqlCmd.Dispose()
	    return ,$dtblResultSet
   }catch [Exception]{
    throw   
  }finally {
	if($SQLConnection -ne $null) {$SQLConnection.CloseConnection() }
  }
 }
 
 function Get-ScalarValue{
    Param([Parameter(Mandatory=$true)][String]$server,[Parameter(Mandatory=$true)][String]$dbName,[Parameter(Mandatory=$true)][String] $sqlQuery)
    try{
	    [System.Data.SqlClient.SqlConnection]$SQLConnection = Create-SQLConnection $server $dbName  
        $SQLConnection.OpenConnection()  
		$sqlCmd = $SQLConnection.CreateCommand()
		$sqlCmd.CommandText = $sqlQuery     
		$ScalarValue = $sqlCmd.ExecuteScalar()
		$sqlCmd.Dispose()
		return $ScalarValue
	   }catch [Exception]{
    	throw   
       } finally {
		if($SQLConnection -ne $null) {$SQLConnection.CloseConnection() }
	   }
 }
 
function FetchDBData-AsHashTable{
  Param([Parameter(Mandatory=$true)][String]$DBServer,[Parameter(Mandatory=$true)][String]$DBName,[Parameter(Mandatory=$true)][String]$SqlQuery)
   return (ConvertTo-HashTable -Values (Get-ResultSet -server $DBServer -dbName $DBName -sqlQuery $SqlQuery))
 }

function FetchDBData-AsGroupTable{
  Param([Parameter(Mandatory=$true)][String]$DBServer,[Parameter(Mandatory=$true)][String]$DBName,[Parameter(Mandatory=$true)][String]$SqlQuery)
   return (ConvertTo-GroupTable -Values (Get-ResultSet -server $DBServer -dbName $DBName -sqlQuery $SqlQuery))
 }

 function Create-Command {
   Param([Parameter(Mandatory=$true)][String]$sqlQuery,[Parameter(Mandatory=$true)][System.Data.SqlClient.SqlConnection]$SQLConnection,[Parameter(Mandatory=$false)][System.Data.SqlClient.SqlTransaction]$sqlTransaction)
   
   if($sqlTransaction -eq $null) {
     [System.Data.SqlClient.SqlCommand]$sqlCmd = New-Object System.Data.SqlClient.SqlCommand($sqlQuery,$SQLConnection)	
   } else {
     [System.Data.SqlClient.SqlCommand]$sqlCmd = New-Object System.Data.SqlClient.SqlCommand($sqlQuery,$SQLConnection,$sqlTransaction) 
   }
   $sqlCmd.CommandTimeout = 600
   return $sqlCmd
 }


 function Execute-Query{
 Param([Parameter(Mandatory=$true,Position=0)][String]$server,[Parameter(Mandatory=$true,Position=1)][String]$dbName,[Parameter(Mandatory=$true,Position=2)][String] $sqlQuery, [Switch] $Transaction)
	 try{
	     [System.Data.SqlClient.SqlConnection]$SQLConnection = Create-SQLConnection $server $dbName
		 $SQLConnection.OpenConnection() 
        <#
		 if($Transaction -eq $false) {
		   [System.Data.SqlClient.SqlCommand]$sqlCmd = New-Object System.Data.SqlClient.SqlCommand($sqlQuery,$SQLConnection)	 						 
		 } else {
		   [System.Data.SqlClient.SqlTransaction]$sqltxn = $SQLConnection.BeginTransaction() 
		   [System.Data.SqlClient.SqlCommand]$sqlCmd = New-Object System.Data.SqlClient.SqlCommand($sqlQuery,$SQLConnection,$sqltxn)	
		 }
         #>
         if($Transaction -eq $false) {
		   [System.Data.SqlClient.SqlCommand]$sqlCmd = Create-Command -sqlQuery $sqlQuery -SQLConnection $SQLConnection					 
		 } else {
		   [System.Data.SqlClient.SqlTransaction]$sqltxn = $SQLConnection.BeginTransaction() 
		   [System.Data.SqlClient.SqlCommand]$sqlCmd = Create-Command -sqlQuery $sqlQuery -SQLConnection $SQLConnection	 -sqlTransaction $sqltxn	
		 }
		 $sqlCmd.ExecuteNonQuery() | Out-Null
		 if($sqltxn -ne $null) {  $sqltxn.Commit(); }
		 $sqlCmd.Dispose()
	} catch [Exception]{	 
	   if($sqltxn -ne $null) {
	    $sqltxn.Rollback();
	   }
	 throw;
	} finally {
	   if($SQLConnection -ne $null) {$SQLConnection.CloseConnection() }
    }
 }

  
 function Execute-QueryUsingConnection{
 Param([Parameter(Mandatory=$true)][System.Data.SqlClient.SqlConnection]$SQLConnection,[Parameter(Mandatory=$true)][String] $sqlQuery, [System.Data.SqlClient.SqlTransaction]$sqltxn)
       if($sqltxn -ne $null) {
		   [System.Data.SqlClient.SqlCommand]$sqlCmd = New-Object System.Data.SqlClient.SqlCommand($sqlQuery,$SQLConnection,$sqltxn)	
		 } else {
		   [System.Data.SqlClient.SqlCommand]$sqlCmd = New-Object System.Data.SqlClient.SqlCommand($sqlQuery,$SQLConnection)	 						 
		 } 						 
	   $sqlCmd.ExecuteNonQuery() | Out-Null
	   $sqlCmd.Dispose()
 }
 
 function Get-SqlDbType{
  Param([Parameter(Mandatory=$true)][String]$DataType)
   switch($DataType){
     "string" {return [System.Data.SqlDbType]::VARCHAR }
	 "int" {return [System.Data.SqlDbType]::INT }
	 "float" {return [System.Data.SqlDbType]::FLOAT }
	 "double" {return [System.Data.SqlDbType]::DECIMAL }
	 "DateTime" { return [System.Data.SqlDbType]::DATETIME}
     "int16" { return [System.Data.SqlDbType]::SMALLINT}
   }
}

function Get-SqlParamLength{
  Param([Parameter(Mandatory=$true)][String]$DataType)
   if($DataType -eq "string"){
     return -1
   }
   return 0
}

function Batch-Insert {
    Param([Parameter(Mandatory=$true)][String]$server,[Parameter(Mandatory=$true)][String]$dbName,[Parameter(Mandatory=$true)][String]$InsertQuery,[Parameter(Mandatory=$true)][System.Data.DataTable]$dtblValues,[Parameter(Mandatory=$true)][String[]]$ParameterNames
          ,[String[]]$ParameterDataTypes,[String[]]$SourceColumnNames,[String]$DeleteQuery,[String]$UpdateQuery,[String]$OperationOrder="I")
     try{
           if($ParameterDataTypes.Count -eq 0)  {
             $ParameterNames | ForEach-Object { $ParameterDataTypes += $dtblValues.Columns[$_.Replace("@","")].DataType }
           }

           if($SourceColumnNames.Count -eq 0)  {
             $ParameterNames | ForEach-Object { $SourceColumnNames += $_.Replace("@","") }
           }

	       [System.Data.SqlClient.SqlConnection]$SQLConnection = Create-SQLConnection $server $dbName
		   $SQLConnection.OpenConnection() 
		   [System.Data.SqlClient.SqlTransaction]$sqltxn = $SQLConnection.BeginTransaction() 
		   for($index=0;$index -lt $OperationOrder.length;$index++) {
			   switch($OperationOrder.substring($index,1)){
			     "I" {
				       [System.Data.SqlClient.SqlDataAdapter]$ObjDataAdapter   = new-object System.Data.SqlClient.SqlDataAdapter
					   $ObjDataAdapter.InsertCommand = new-object System.Data.SqlClient.SqlCommand($InsertQuery,$SQLConnection,$sqltxn)
					   for($i = 0; $i -lt $ParameterNames.length;$i++){
					   [void]$ObjDataAdapter.InsertCommand.Parameters.Add($ParameterNames[$i],(Get-SqlDbType $ParameterDataTypes[$i]), (Get-SqlParamLength $ParameterDataTypes[$i]),$SourceColumnNames[$i])
			      	   }
			           $ObjDataAdapter.InsertCommand.UpdatedRowSource = [System.Data.UpdateRowSource]::None 
					   $ObjDataAdapter.Update($dtblValues) | Out-Null
				     }
			     "U" {
				       [System.Data.SqlClient.SqlCommand]$sqlCmd = new-object System.Data.SqlClient.SqlCommand($UpdateQuery,$SQLConnection,$sqltxn)
              		   $sqlCmd.ExecuteNonQuery() | Out-Null
				     }
				 "D" {
				       [System.Data.SqlClient.SqlCommand]$sqlCmd = new-object System.Data.SqlClient.SqlCommand($DeleteQuery,$SQLConnection,$sqltxn)
              		   $sqlCmd.ExecuteNonQuery() | Out-Null
				     }
			   }
			}
			$sqltxn.Commit()
      } catch [Exception]{	 
	    if($sqltxn -ne $null) {
	      $sqltxn.Rollback();
	    }
	    throw
	  } finally {
	   if($SQLConnection -ne $null) {$SQLConnection.CloseConnection() }
      }
 }
	