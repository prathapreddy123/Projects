param([Parameter(Mandatory=$true,Position=0)] [string]$SourceFilePath, [Parameter(Mandatory=$true,Position=1)] [string]$TargetFilepath,[Parameter(Mandatory=$true,Position=2)][ValidateSet("Upload","Download")]$OperationType)

try
{
	 
		$Username = "temp-account"
		$Password = "xxxxx"
		$serverUri = "ftp://ftp2.retailsolutions.com/TestFolder/GPAC_WAG_AngelSoft_ScanDetails_052020141454.zip"      #
		$SourceFile = "D:\Prathap\FTP_WorkingDirectory\GPAC_WAG_AngelSoft_ScanDetails_052020141454.zip"    #"D:\Prathap\FTP_WorkingDirectory\FTPConfig.txt" #
		$TargetFile = "D:\Prathap\Temp\GPAC_WAG_AngelSoft_ScanDetails_052020141454.zip" #"D:\Prathap\Temp\GPAC_WAG_AngelSoft_ScanDetails_052020141454.zip"
		[System.Net.FtpWebRequest] $FTPrequest  =  [System.Net.FtpWebRequest]::Create($serverUri)
		$FTPRequest.Credentials = new-object System.Net.NetworkCredential($Username, $Password)
		$FTPRequest.Timeout = 10000  #Time out in Milliseconds
		#$FTPRequest.ReadWriteTimeout  = 40000 
		$FTPRequest.UsePassive = $true
		$FTPRequest.UseBinary = $false
		$FTPRequest.KeepAlive = $false   #This is important property 
		 
	if($OperationType -eq "Upload")
	{
	
		$FTPrequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile

		Write-host "Uploading File..."   
		#Create a request Stream
		[System.IO.Stream] $requestStream = $FTPRequest.GetRequestStream()
		
		if($requestStream -ne $null)
		{
		    #Read File to be uploaded
		    $FileContents = Get-Content -path $SourceFile -encoding byte
			#Write File
			$requestStream.write($FileContents, 0, $FileContents.Length)
			$requestStream.Close()   
			$requestStream.dispose()

			#Validating Status of Upload
			[System.Net.FtpWebResponse] $response = $FTPrequest.GetResponse();
			Write-host "File Upload Status $($response.StatusDescription)"    
			$response.Close()
			$response.dispose()
		}
		else
		{
		   [System.Net.FtpWebResponse] $response = $FTPrequest.GetResponse();
			Write-host "File Upload Status $($response.StatusDescription)"    
		}
	}
	elseif($OperationType -eq "Download")
	{
	   Write-host "Downloading File..." 
	   $FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile; 
	  
	   #Get the response object
		[System.Net.FtpWebResponse] $FTPResponse = $FTPRequest.GetResponse()
		if($FTPResponse -ne $null)
		{
		 [System.IO.Stream] $responseStream = $FTPResponse.GetResponseStream()
		 <#
		 [System.IO.StreamReader] $readStream = New-object System.IO.StreamReader($responseStream);  #,[System.Text.Encoding]::ASCII
		 
		if ($readStream -ne $null)
		  {
		 	   $readStream.ReadToEnd() | out-file $TargetFile
		  }
		  $readStream.close()
		  $readStream.dispose()
		 #
		  #>
		  [System.IO.FileStream]$FileStream = New-Object System.IO.FileStream($TargetFile,[System.IO.FileMode]::Create) 
		  [byte[]]$ReadBuffer = New-Object byte[] 1024
		  
		  do { 
		        $ReadLength = $ResponseStream.Read($ReadBuffer,0,1024) 
				$FileStream.Write($ReadBuffer,0,$ReadLength) 
              } 
			while ($ReadLength -ne 0)
		  
		  Write-host "File Download Status $($FTPResponse.StatusDescription)"
		  
		  $FileStream.Close()
		  $FileStream.dispose()
	      $responseStream.Close()   
		  $responseStream.dispose()
		}
	}
}
 catch [Exception]
  {
    if($requestStream -ne $null)
	{
	  $requestStream.Close()   
	  $requestStream.dispose()
	}
	
	if($responseStream -ne $null)
	{
	  $responseStream.Close()   
	  $responseStream.dispose()
	}
	
	if($FileStream -ne $null)
	{
	  $FileStream.Close()   
	  $FileStream.dispose()
	}	
	
    Write-host "$(Get-Date):Error in Main Block: Exception Type: $($_.Exception.GetType().FullName);`n
    Exception Code: $($_.Exception.ErrorCode);Exception Message: $($_.Exception.Message) "  
  }

