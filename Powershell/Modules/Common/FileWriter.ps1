function Get-SupportedFileOutputTyes {
  return @("CSV","TSV","PSV","SSV","EXCEL")
}

function Get-ContentDelimiter{
Param([Parameter(Mandatory=$true)][string] $FileType)
  switch($FileType){
    "CSV" {return ","}
	"TSV" {return "`t"}
    "PSV" {return "|"}
    "SSV" {return ";"}
    default {throw "Unknown File Type. Supported File Types are CSV,TSV(Tab Seperated values),PSV (Pipe Seperated Values),SSV(SemiColon Seperated Values)"}
  }

}

function Get-FileExtension{
Param([Parameter(Mandatory=$true)][string] $FileType)
  switch($FileType){
    "CSV" {return ".csv"}
	"EXCEL" {return ".xlsx"}
	"TSV" {return ".txt"}
    "PSV" {return ".txt"}
    "SSV" {return ".txt"}
    default {throw "Unknown File Type. Supported File Types are CSV,Excel,TSV(Tab Seperated values),PSV (Pipe Seperated Values),SSV(SemiColon Seperated Values)"}
  }
}

function Get-Alphabet{
Param([Parameter(Mandatory=$true)][int] $Position)
   [string[]]$ColValues = @("A","B","C","D","E","F","G","H","I","J","K")
   return $ColValues[$Position-1]
}

function New-FileDetails {
  Param([string]$Name,[string]$Path,[string]$Type,[string]$Header)
  $FileDetails = New-Object -TypeName PSObject
  $FileDetails | Add-member -NotePropertyMembers @{Name=$Name;Path=$Path;Type=$Type;Header=$Header;HeaderDelimiter="|";NumericValueASTextColPositions = @()}
  return $FileDetails
}

function SaveTo-File {
Param([Parameter(Mandatory=$true)][PSCustomObject]$FileDetails,[Parameter(Mandatory=$true)][System.Data.DataTable]$Data)
    
    if($FileDetails.Type -ne "EXCEL") {
        [string]$ContentDelimiter =  Get-ContentDelimiter $FileDetails.Type
        ExportTo-DelimitedFile -Data $Data -FilePath $FileDetails.Path -Delimiter $ContentDelimiter -Header $FileDetails.Header.Replace($FileDetails.HeaderDelimiter,$ContentDelimiter)
     } else  {
       $Ret = ExportTo-Excel -Data $Data -FilePath $FileDetails.Path -SheetName $FileDetails.Name  -Header $FileDetails.Header -NumericValueASTextColPositions $FileDetails.NumericValueASTextColPositions
    }
}

function ExportTo-DelimitedFile{
Param([Parameter(Mandatory=$true)][Alias("Data")][System.Data.Datatable]$dtblData,[Parameter(Mandatory=$true)][string]$FilePath,[Parameter(Mandatory=$true)][string]$Delimiter,[string]$Header)

 if($Header.Length -gt 0){
     Set-content -path $FilePath -Encoding UTF8 $Header -Force
	 $dtblData | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -skip 1 | Add-Content -Path $FilePath 
   } else {
     $dtblData | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Add-Content -Path $FilePath -Encoding UTF8
   }
}

function Replace-NullValue {
  Param([Parameter(Mandatory=$true,ValueFromPipeline=$true)][System.Data.DataRow]$Row,[Parameter(Mandatory=$true)][object]$NullReplacementValue)
 
    Process {
             [PSObject]$NewObject = New-Object -TypeName PSObject
             $ExportableProperties |  ForEach-Object {   If($Row[$_] -ne [System.DBNull]::Value) {
                                                            $NewObject | Add-member -NotePropertyName $_ -NotePropertyValue $Row[$_]
                                                         } else {
                                                           $NewObject | Add-member -NotePropertyName $_ -NotePropertyValue $NullReplacementValue
                                                         }
                                                     }
             
             return $NewObject
          }
 }

function ExportTo-DelimitedFileReplacingNull{
Param([Parameter(Mandatory=$true)][Alias("Data")][System.Data.Datatable]$dtblData,[Parameter(Mandatory=$true)][string]$FilePath,[Parameter(Mandatory=$true)][string]$Delimiter,[Parameter(Mandatory=$true)][Object]$NullReplacementValue,[string]$Header,[string[]]$ExcludeFields)

 [int]$skiprows = 0
 [string[]]$ExportableProperties = $dtblData.columns | where-object { $ExcludeFields -notcontains $_.ColumnName  } | ForEach-Object { $_.ColumnName }
 
 if($Header.Length -gt 0){
     Set-content -path $FilePath -Encoding UTF8 $Header -Force
     $skiprows = 1
   } 

  $dtblData | Replace-NullValue -NullReplacementValue $NullReplacementValue | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -skip $skiprows | Add-Content -Path $FilePath -Encoding UTF8
}

function ExportTo-Excel{
Param([Parameter(Mandatory=$true)][Alias("Data")][System.Data.Datatable]$dtblData,[Parameter(Mandatory=$true)][string]$FilePath,[Parameter(Mandatory=$true)][string]$SheetName,[string]$Header,[string[]]$NumericValueASTextColPositions)
try{
     # load excel, and create a new workbook  #XlWBATemplate::xlWBATWorksheet
     $excelApp = New-Object -ComObject Excel.Application
	 #$excelApp.visible = $true
	 $excelApp.ScreenUpdating = $false
	 $workbook = $excelApp.workbooks.add() 
    	  
	 # Update workook properties 
     $workbook.author = "RSI" 
	 #$workbook.title = "Item Discovery File" 
	 $workbook.subject = "Digital Analytics" 	

      # The default workbook has three sheets, remove 2  $S2 =
      $workbook.sheets | foreach-object {if($_.name -ne "Sheet1") {$_.delete()} }   
	  $workSheet = $excelApp.ActiveSheet;
	  $workSheet.name = $SheetName
	  
	  #Convert column format to Text as numeric data such as UPC, StoreID should preserve leading and trailing zeros
	  foreach($Position in $NumericValueASTextColPositions){
	     $ColAlpahabet = Get-Alphabet $Position 
		 $workSheet.range("${ColAlpahabet}:${ColAlpahabet}").NumberFormat = "@"
	  }
	  
      $TotalRows = $dtblData.Rows.Count + 1
      $TotalColumns  =  $dtblData.Columns.Count

     #column headings
     if($Header.length -ne 0) {
        [string[]]$HeaderColumns = $Header.split("|")
     } else {
        [string[]]$HeaderColumns = (0..($TotalColumns - 1) ) | ForEach-Object { $dtblData.Columns[$_].ColumnName  }
	 }
    
     if($HeaderColumns.Count -ne $TotalColumns) {
      throw "ExportTo-Excel:  Number of Header Columns do not match with columns in Data Table"
     }

     (0..($HeaderColumns.Count - 1)) | ForEach-Object { 
                                        $workSheet.Cells.item(1, ($_ + 1)) = $HeaderColumns[$_];    #Excel colIndex starts from 1                
                                        $workSheet.Cells.item(1, ($_ + 1)).font.bold = $true;
                                      }
	 
     #Build DataRange
	 [string[,]]$DataValues = new-object 'string[,]' $TotalRows,$TotalColumns
	 $DataRange =  $workSheet.Range($workSheet.Cells.item(2, 1),$workSheet.Cells.item($TotalRows + 1, $TotalColumns))

     #Writing to an array and assigning to range object is performance efficient than writing cell by cell value
	 for ($Rowindex = 0; $Rowindex -lt $dtblData.Rows.Count; $Rowindex++) {
          for ($Colindex = 0; $Colindex -lt $dtblData.Columns.Count; $Colindex++){
					#$workSheet.Cells.item(($Rowindex + 2), ($Colindex + 1)) = $dtblData.Rows[$Rowindex][$Colindex];
					$DataValues[$Rowindex,$Colindex] = $dtblData.Rows[$Rowindex][$Colindex]
                }
            } 	
      
	  $DataRange.Value2  = 	$DataValues
	  
      ## - Adjusting columns in the Excel sheet:
	  #$xlsRng = $workSheet.usedRange;
	  $DataRange.EntireColumn.AutoFit();

	if(Test-path $FilePath) {
         Remove-item $FilePath -Force 
      }	 		
     
	 $workbook.SaveAs($FilePath) 
	 $workbook.Close($true)
	 $excelApp.ScreenUpdating = $true
 } catch [Exception] {
    if($workbook -ne $null)
	{
	 $workbook.Close($false)
	}	
   if(Test-path $FilePath) {
         Remove-item $FilePath -Force 
      }	 
    
   throw;
 } finally {
    
   if($excelApp -ne $null) { 
	  	$excelApp.Quit()
		[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelApp)
	 }	  
 }
}


