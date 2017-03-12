function Get-IniContent{ 
    <# 
      Gets the content of an INI file 
      Example: $FileContent = Get-IniContent "C:\myinifile.ini" 
   #> 
     
    Param([string]$FilePath = ".\Configurations\Properties.ini" ) 
             
     if (!(Test-Path $FilePath))
     {
       throw "Properties file not found. Check the availability of file in Path $FilePath"
     }
   
        $ini = @{} 
        switch -regex -file $FilePath 
        { 
            "^\[(.+)\]$" # Section 
            { 
                $section = $matches[1] 
                $ini[$section] = @{} 
                $CommentCount = 0 
            } 
            "^(;.*)$" # Comment 
            { 
                if (!($section)) 
                { 
                    $section = "No-Section" 
                    $ini[$section] = @{} 
                } 
                $value = $matches[1] 
                $CommentCount = $CommentCount + 1 
                $name = "Comment" + $CommentCount 
                $ini[$section][$name] = $value 
            }  
            "(.+?)=(.*)" # Key 
            { 
                if (!($section)) 
                { 
                    $section = "No-Section" 
                    $ini[$section] = @{} 
                } 
				#write-host $matches[1..2]
                $name,$value = $matches[1..2] 
				#write-host "$name;$value"
                $ini[$section][$name] = $value 
            } 
        } 
        return $ini 
   } 