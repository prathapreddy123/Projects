function Strip-EndDelimiter
{
   [CmdletBinding()]  
  param([Parameter(Mandatory=$true)][string]$StringValue,[Parameter(Mandatory=$true)][string]$Delimiter)
  if($StringValue.EndsWith($Delimiter)) {
    return $StringValue.Substring(0,($StringValue.Length - 1))
  }
  return $StringValue
}

function Parse-EmailList
{
 [CmdletBinding()]  
  param([string]$Emaillist,[string]$AddressTypeDelimiter = ",",[string]$EmailIDDelimiter=";")
  [HashTable]$EmailAddresses = @{}
  $Emaillist.split($AddressTypeDelimiter) | where-object { $_ -Match "^TO:+" -or $_ -Match "^CC:+" -or $_ -Match "^BCC:+"} | foreach-object { [string[]]$MailAddresses =  $_.split(":"); $EmailAddresses.Add($MailAddresses[0],$MailAddresses[1]); }
  if($EmailAddresses.keys.count -eq 0 -or $EmailAddresses["TO"] -eq $null) {
    throw "Invalid Emaillist. Emaillist should have TO addresses and can contain optional CC and BCC addresses as per below rules: `r`n
           1.Each AddressType(TO,CC,BCC) should be seperated by AddressTypeDelimiter (Default ,) from other address type `r`n
           2.AddressType (TO,CC,BCC) and emaillist should be seperated by :.  `r`n
           3.Each emailid should be seperated by EmailIDDelimiter (Default ;) from other emailid. `r`n
           Example - TO:email1@domain1.com;email2@domain2.com,CC:email3@domain2.com;email4@domain2.com,BCC:email5@domainx.com"
  }

  return $EmailAddresses

}

function Send-Mail 
{
  param([Parameter(Mandatory=$true)][string]$SMTPServer,[Parameter(Mandatory=$true)][int]$SMTPPort,[Parameter(Mandatory=$true)][string]$From,[Parameter(Mandatory=$true)][string]$ReceiversEmailList,[Parameter(Mandatory=$true)][string]$Subject,[Parameter(Mandatory=$true)][string]$Body,[switch]$TextFormat)
 
  #Creating a Mail object
  [system.Net.Mail.MailMessage]$EmailMessage = new-object System.Net.Mail.MailMessage
 
  #Creating SMTP server object
  [system.Net.Mail.SmtpClient]$smtp=new-object System.Net.Mail.SmtpClient($SMTPServer,$SMTPPort) 
  [HashTable]$EmailAddresses = Parse-EmailList $ReceiversEmailList
  
  [string]$EmailIDSeperator = ";"

 #Email structure 
 $EmailMessage.From = new-object System.Net.Mail.MailAddress($From);
 foreach($addresstype in $EmailAddresses.keys)
 {
    $addresslist =  (Strip-EndDelimiter $EmailAddresses[$addresstype] $EmailIDSeperator)
    switch($addresstype)
    {
      "TO" {
             $addresslist.split($EmailIDSeperator) | foreach-object { $EmailMessage.To.Add($_) }
           }
      "CC" {
             $addresslist.split($EmailIDSeperator) | foreach-object { $EmailMessage.CC.Add($_) }  
           }
      "BCC"{
             $addresslist.split($EmailIDSeperator) | foreach-object { $EmailMessage.BCC.Add($_) }
           }
    }
 }
 #$objmsg.ReplyTo = "replyto@xxxx.com"
 $EmailMessage.subject = $Subject
 $EmailMessage.body = $Body
 $EmailMessage.IsBodyHtml = $true 

 #Sending email 
 $smtp.Send($EmailMessage)
  if($Host.Name -eq "ConsoleHost"){
   #$Host.UI.KeyAvailable = $false
   #$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
 }
} 

function Get-EmailTableFormat
{
  return @"
    <Title>MyTitle</Title>
    <style>
    Body {
    font-family: "Tahoma", "Arial", "Helvetica", sans-serif;
    background-color:#fffff;
    }
    table {
    border-collapse:collapse;
    width:100%
    }
    td {
    font-size:10pt;
    border:1px Black solid;
    padding:5px 5px 5px 5px;
    }
    th {
    font-size:12pt;
    text-align:left;
    padding:5px 5px 5px 5px;
    background-color:#00aaFF;
    border:1px Black solid;
    color:#FFFFFF;
    }
    tr{
    color:#000000;
    background-color:#ffee99;
    }
    </style>
"@
}
