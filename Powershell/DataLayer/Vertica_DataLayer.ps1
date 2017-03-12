
function PBEWithMD5AndDES {
	PARAM([Parameter(Mandatory=$true)][String] $key,[Parameter(Mandatory=$true)] [byte[]]$salt,[Parameter(Mandatory=$true)] [int] $iterations)   
	$des = new-object -TypeName System.Security.Cryptography.DESCryptoServiceProvider
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	
	$enc    = [system.Text.Encoding]::ASCII
	$result = $enc.GetBytes($key) + $salt
	
	for($i = 0; $i -lt $iterations; $i++) {
		$result = $md5.ComputeHash($result);
	}

	[byte[]] $okey = $result[0..7]
	[byte[]] $iv   = $result[8..16]
    
	return $des.CreateDecryptor($okey, $iv)
}

function Decrypt {
	PARAM([Parameter(Mandatory=$true)][String] $code)
	
	# The encrypted string is stored in base64
	[Byte[]]$inputBytes = [System.Convert]::FromBase64String($code)
	[Byte[]]$salt       = 0xA9,  0x9B,  0xC8,  0x32, 0x56,  0x35,  0xE3,  0x03
	
	$dec = PBEWithMD5AndDES "cfgmgmt" $salt 10 #"Decrypt"

	$memStream   = New-Object System.IO.MemoryStream 
	$cryptStream = New-Object Security.Cryptography.CryptoStream $memStream, $dec, "write"  #[System.Security.Cryptography.CryptoStreamMode]::Write
	$cryptStream.Write($inputBytes, 0, $inputBytes.length)
	$cryptStream.close()
	$output = $memStream.ToArray()
	return [System.Text.Encoding]::ASCII.GetString($output)
}


function Create-VerticaConnection {
 	PARAM([String] $server, [String] $dbName, [String] $username, [String] $EncryptedPassword)
 
  if([String]::IsNullorEmpty($server))
  {
    #Load Properties from Ini File into Variables
    $server = $Properties["DBInfo"]["Vertica_ServerName"]
	$dbName  = $Properties["DBInfo"]["Vertica_Database"]
	$username = $Properties["DBInfo"]["Vertica_userName"]
	$EncryptedPassword = $Properties["DBInfo"]["Vertica_Password"]
  }
     
$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Vertica.Data")
$Connbuilder = New-Object Vertica.Data.VerticaClient.VerticaConnectionStringBuilder
$Connbuilder.Host = $server
$Connbuilder.Database = $dbName
$Connbuilder.User = $username
$Connbuilder.password = (Decrypt $EncryptedPassword)
#$Connbuilder.ConnectionLoadBalance = $true;

$Conn = $Connbuilder.Tostring()  

$verticaConnection = New-Object Vertica.Data.VerticaClient.VerticaConnection $Connbuilder.Tostring()

Add-Member -InputObject $verticaConnection -MemberType ScriptMethod -Name OpenConnection -Value {
  if($this.state -ne [System.Data.ConnectionState]::Open)
   {
    $this.Open();
   }
}

Add-Member -InputObject $verticaConnection -MemberType ScriptMethod -Name CloseConnection -Value {
  if($this.state -eq [System.Data.ConnectionState]::Open)
   {
    $this.Close();
   }
}
<#
#$password = Decrypt $EncryptedPassword
#$verticaConnection.ConnectionString = "database=$dbName;host=$server;user=$username;password=$password;ConnectionLoadBalance=$true

# Returns the results of a query (can be multiple rows)
  Add-Member -InputObject $verticaConnection -MemberType ScriptMethod -Name GetResultSet -Value {
		Param([String]$sqlQuery)
		$this.Open()
		$sqlCmd    = $this.CreateCommand()
		$sqlCmd.CommandText    = $sqlQuery     
		$adapter = New-Object Vertica.Data.VerticaClient.VerticaDataAdapter
		$adapter.SelectCommand = $sqlCmd
		$dtblResultSet = New-Object System.Data.DataTable
		$adapter.Fill($dtblResultSet) | Out-Null
		$sqlCmd.Dispose()
		#$this.close();
		return ,[System.Data.Datatable]$dtblResultSet
 }
#>
return $verticaConnection
}

function GetResultSet {
   Param([Parameter(Mandatory=$true)][Vertica.Data.VerticaClient.VerticaConnection]$verticaConnection,[Parameter(Mandatory=$true)][String] $sqlQuery)
        
		#$verticaConnection.OpenConnection()
		$sqlCmd    = $verticaConnection.CreateCommand()
		$sqlCmd.CommandText    = $sqlQuery     
		$adapter = New-Object Vertica.Data.VerticaClient.VerticaDataAdapter
		$adapter.SelectCommand = $sqlCmd
		[System.Data.Datatable]$dtblResultSet = New-Object System.Data.DataTable
		$adapter.Fill($dtblResultSet) | Out-Null
		$sqlCmd.Dispose()
	#	$verticaConnection.CloseConnection();
		return ,$dtblResultSet
 }

 function ExecuteQuery{
 Param([Parameter(Mandatory=$true)][Vertica.Data.VerticaClient.VerticaConnection]$verticaConnection,[Parameter(Mandatory=$true)][String] $sqlQuery, [Switch] $Transaction)
	 try
	 {
		 #$verticaConnection.OpenConnection()
		 if($Transaction -eq $true) { [Vertica.Data.VerticaClient.VerticaTransaction]$txn = $verticaConnection.BeginTransaction() }
		 $sqlCmd  = $verticaConnection.CreateCommand()
		 $sqlCmd.CommandText = $sqlQuery 
		 $sqlCmd.ExecuteNonQuery() | Out-Null
		 if($txn -ne $null) {  $txn.Commit(); }
		 $sqlCmd.Dispose()
		 #$verticaConnection.CloseConnection();
	 }
     catch [Exception]
    {	 
	  if($txn -ne $null)
	  {
	   $txn.Rollback();
	  }
	 throw;
	}
 }



