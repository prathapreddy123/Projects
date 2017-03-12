#FileCompression.ps1 -SourceFile "C:\Projects\wsubi" -zip_to "C:\Users\Bryan\Desktop\wsubi" [-compression fast] [-timestamp] [-confirm]

Param( [Parameter(Mandatory=$true,Position=0)] [string]$SourceFile, [Parameter(Mandatory=$true,Position=1)] [string]$zip_to,
      ,[Parameter(Mandatory=$false,Position=2)][ValidateSet("fast","small","none")][string]$compression,[Parameter(Mandatory=$false,Position=3)][bool]$timestamp
)

function DeleteFileOrFolder
{ Param([string]$PathToItem)

  if (Test-Path $PathToItem)
  {
    Remove-Item ($PathToItem) -Force -Recurse;
  }
}

function DetermineCompressionLevel
{
  $CompressionToUse = $null;

  switch($compression)
  {
    "fast" {$CompressionToUse = [System.IO.Compression.CompressionLevel]::Fastest}
    "small" {$CompressionToUse = [System.IO.Compression.CompressionLevel]::Optimal}
    "none" {$CompressionToUse = [System.IO.Compression.CompressionLevel]::NoCompression}
    default {$CompressionToUse = [System.IO.Compression.CompressionLevel]::Fastest}
  }

  return $CompressionToUse;
}

if ((Get-Item $SourceFile).PSIsContainer)   #Check whether SourceFile parameter is a directory or file. PsIScontainer is true if the input is directory
{
  $zip_to = ($zip_to + "\" + (Split-Path $SourceFile -Leaf) + ".zip");   #In this example provides C:\Users\Bryan\Desktop\wsubi\wsubi.zip
}
else{

  #So, the CreateFromDirectory function below will only operate on a $target
  #that's a Folder, which means some additional steps are needed to create a
  #new folder and move the target file into it before attempting the zip process. 
  $FileName = [System.IO.Path]::GetFileNameWithoutExtension($SourceFile);
  $NewFolderName = ($zip_to + "\" + $FileName)

  DeleteFileOrFolder($NewFolderName);

  md -Path $NewFolderName;
  Copy-Item ($SourceFile) $NewFolderName;

  $SourceFile = $NewFolderName;
  $zip_to = $NewFolderName + ".zip";
}

DeleteFileOrFolder($zip_to);

if ($timestamp)
{
  $TimeInfo = New-Object System.Globalization.DateTimeFormatInfo;
  $CurrentTimestamp = Get-Date -Format $TimeInfo.SortableDateTimePattern;
  $CurrentTimestamp = $CurrentTimestamp.Replace(":", "-");
  $zip_to = $zip_to.Replace(".zip", ("-" + $CurrentTimestamp + ".zip"));
}

$Compression_Level = (DetermineCompressionLevel);
$IncludeBaseFolder = $false;

[Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" );
[System.IO.Compression.ZipFile]::CreateFromDirectory($target, $zip_to, $Compression_Level, $IncludeBaseFolder);

Write-Output "Zip process complete.";