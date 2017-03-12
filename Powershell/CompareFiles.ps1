function md5hash($path) {
    $fullPath = Resolve-Path $path
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $encoding = New-Object System.Text.ASCIIEncoding
    [System.BitConverter]::ToString($md5.ComputeHash($encoding.GetBytes((gc $fullPath))))
}

function Compare-Files($file1, $file2) {
   write-output "Comparing $file1 with file $file2"
   if((md5hash $file1) -eq (md5hash $file2)) { write-host -f Green "Identical"; return }
   write-host -f Red "$file1 does not match with $file2"
}

Compare-Files "D:\Prathap\DigitalAnalytics\PS\Scripts\DBBackupConfig.json" "D:\Prathap\DigitalAnalytics\PS\Scripts\DBBackupConfig2.json"