function Out-DataTable{ 
    [CmdletBinding()] 
    param([Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)][PSObject[]]$InputObject,[string[]]$Int16Columns,[string[]]$DoubleColumns,[string[]]$DateTimeColumns) 
 
    Begin 
    { 
        $dt = new-object Data.datatable   
        $First = $true  
    } 
    Process 
    { 
	   foreach ($object in $InputObject) 
        { 
            $DR = $DT.NewRow()   
            foreach($property in $object.PsObject.get_properties()) 
            {   
                if ($first) 
                {  
                    $Col =  new-object Data.DataColumn   
                    $Col.ColumnName = $property.Name.ToString()   
                    if($Int16Columns -contains $property.Name.ToString())
					{
					  $Col.DataType = [System.Type]::GetType('System.Int16')
					} elseif( $DoubleColumns -contains $property.Name.ToString()) {
                      $Col.DataType = [System.Type]::GetType('System.Double')
                    } elseif( $DateTimeColumns -contains $property.Name.ToString()) {
                      $Col.DataType = [System.Type]::GetType('System.DateTime')
                    } else {
                      $Col.DataType = [System.Type]::GetType('System.String')
					}
                    $DT.Columns.Add($Col) 
                }   
                if ($property.Gettype().IsArray) { 
                    $DR.Item($property.Name) =$property.value | ConvertTo-XML -AS String -NoTypeInformation -Depth 1 
                }   
               else { 
				   if($property.value -ne $null -and $property.value.length -gt 0)
					   {
	                     $DR.Item($property.Name) = $property.value 
					   } else {
	   				     $DR.Item($property.Name) = [System.DBNULL]::Value
					   }
                } 
            }   
            $DT.Rows.Add($DR)   
            $First = $false 
        } 
    }  
      
    End 
    { 
        Write-Output @(,($dt)) 
    } 
 
}