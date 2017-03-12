function PBEWithMD5AndDES {
	PARAM([String] $key, [byte[]]$salt, [int] $iterations)   
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
	PARAM([String]$code)
	# The encrypted string is stored in base64
	[Byte[]]$inputBytes = [System.Convert]::FromBase64String($code)
	[Byte[]]$salt       = 0xA9,  0x9B,  0xC8,  0x32, 0x56,  0x35,  0xE3,  0x03
	
	$dec = PBEWithMD5AndDES "MD5DES" $salt 10

	$memStream   = New-Object System.IO.MemoryStream 
	$cryptStream = New-Object Security.Cryptography.CryptoStream $memStream, $dec, "write"
	$cryptStream.Write($inputBytes, 0, $inputBytes.length)
	$cryptStream.close()
	$output = $memStream.ToArray()
	return [System.Text.Encoding]::ASCII.GetString($output)
}
