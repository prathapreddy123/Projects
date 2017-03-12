#Print-MultiHashTableToCSVFile -htblData $htblOuter -FilePath "D:\Prathap\DigitalAnalytics\PS\2.0\Logs\FirstScanDates.csv" -Headers "Week,Store,FirstScanDate" 
function Print-MultiHashTableToCSVFile {
 param([Parameter(Mandatory=$true)][HashTable]$htblData,[Parameter(Mandatory=$true)][string]$FilePath,[Parameter(Mandatory=$true)][string]$Headers)

  Set-Content -path $FilePath -value $Headers
  foreach($OuterKey in $htblData.keys) {
    foreach($InnerKey in $htblData[$OuterKey].Keys) {
      Add-Content -path $FilePath -value (@($OuterKey,$InnerKey,$htblData[$OuterKey][$InnerKey]) -join  ",")
    }
  }
}
