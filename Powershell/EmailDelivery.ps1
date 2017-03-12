Function Mailer ([string] $SMTPServer,[string] $emailFrom,[string] $emailTo,[string] $emailSubject,[string] $emailbody) 
<# 
  This is a simple function that that sends a message. The variables defined above can be passed as parameters by taking them out and putting then in the parentheseis above. 
#> 
{ 
$smtpServer 
$emailFrom 
$emailTo
$emailSubject
$emailbody
#$smtp=new-object System.Net.Mail.SmtpClient($SMTPServer) 
#$smtp.Send($emailFrom, $emailTo, $emailSubject, $emailbody) 
} 

Function MailerUsingMessageObject ([string] $SMTPServer,[string] $emailFrom,[string] $emailTo,[string] $emailSubject,[string] $emailbody) 
<# 
  This is a simple function that that sends a message. The variables defined above can be passed as parameters by taking them out and putting then in the parentheseis above. 
#> 
{ 
 
 #Creating a Mail object
 $objmsg = new-object system.Net.Mail.MailMessage
 
 #Creating SMTP server object
 $smtp=new-object system.Net.Mail.SmtpClient($SMTPServer) 
 
 #Email structure 
 $objmsg.From = $emailFrom
 $objmsg.ReplyTo = "replyto@xxxx.com"
 $objmsg.To.Add($emailTo)
 $objmsg.subject = $emailSubject
 $objmsg.body = $emailbody
 
  #Sending email 
  $smtp.Send($objmsg)
 } 


$message = @" 
                                 
Some stuff that is meaningful  
 
Thank you, 
IT Department 
Cotendo Corporation 
it@cotendo.com 
"@        

Mailer -SMTPServer "<your mailhost>.<yourdomain>.com" -emailFrom "noreply@<yourdomain>.com"  -emailTo "prathap@abc.com" -emailSubject "<Your Text Here>" -emailbody $message

<#
#You can also call in the below form but last one will not have new line character in each string
Mailer "<your mailhost>.<yourdomain>.com" "noreply@<yourdomain>.com"   "prathap@abc.com" "<Your Subject Here>" $message
Mailer("<your mailhost>.<yourdomain>.com","noreply@<yourdomain>.com","prathap@cdecom","<Your new Subject Here>",$message)
#>

######################### Using the PowerShell Send-MailMessage cmdlet #############################################
<#
Two issues with version 2.0 is this cmdlet does not accept SMTP port number and assumes port number as default port (i.e 25)
Second issue is if Exchange Server requires credentials, this can be handled with -credentials parameter but this could pose
a problem if you are trying to use Send-MailMessage in an unattended setting where there is no way to enter a password.In those 
situations, try to run the command in a process or task that is already running under the proper credentials.

The cmdlet will also look to the variable $PSEmailServer for a SMTPServer value. If the variable is defined, then you don’t 
need to specify –SMTPServer. Defining $PSEmailServer can be done in your profile.
#>
Send-MailMessage -To jhicks@jdhitsolutions.com -from jhicks@jdhitsolutions.com -Subject Test –body "This is body"  -SmtpServer xyz.jdhit.com

#Sending body as variable.  Note if out-string is not used the command fails since body paramter expects string
$body= Get-process | out-string
Send-MailMessage -To jhicks@jdhitsolutions.com -from jhicks@jdhitsolutions.com -Subject Test –body $body  -SmtpServer xyz.jdhit.com

#Sending as an attachment
$Message | out-file c:\work\dailyprocs.txt –encoding ASCII
send-mailmessage -to jhicks@jdhitsolutions.com -from jhicks@jdhitsolutions.com -subject "Daily Process Report" -body "Attached is the daily report" -Attachments C:\work\dailyprocs.txt -Port 587

#Sending HTML output
Param([string]$Computername = $env:COMPUTERNAME)
$head = @"
<Title>Process Report: $($computername.ToUpper())</Title>
<style>
Body {
font-family: "Tahoma", "Arial", "Helvetica", sans-serif;
background-color:#F0E68C;
}
table {
border-collapse:collapse;
width:60%
}
td {
font-size:12pt;
border:1px #0000FF solid;
padding:5px 5px 5px 5px;
}
th {
font-size:14pt;
text-align:left;
padding-top:5px;
padding-bottom:4px;
background-color:#0000FF;
color:#FFFFFF;
}
tr{
color:#000000;
background-color:#0000FF;
}
</style>
"@
 
#convert output to html as a string
$html = Get-Process -ComputerName $Computername | Select Handles,NPM,PM,WS,VM,ID,Name | 
ConvertTo-Html -Head $head -precontent "<h2>Process Report for $($Computername.ToUpper())</h2>" -PostContent "<h6> report run $(Get-Date)</h6>" |
Out-String
 
#send as mail body
$paramHash = @{
 To = "Jhicks@jdhitsolutions.com"
 from = "jhicks@jdhitsolutions.com"
 BodyAsHtml = $True
 Body = $html
 Port = 587
 Subject = "Daily Process Report for $Computername"
}
 
Send-MailMessage @paramHash