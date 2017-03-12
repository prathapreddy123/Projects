<#
.Synopsis
   Compare two sql tables or two result sets from sql queries
.DESCRIPTION
   Compare two sql tables or two result sets from sql queries
.EXAMPLE
   Compare-QueryResult -SourceServer . -SourceDB MSSQLTips -SourceQuery 'select * from dbo.s order by id' -TargetQuery 'select * from dbo.t' 

.EXAMPLE
   #we compare value only between the two query resultsets.
   Compare-QueryResult -SourceServer . -SourceDB MSSQLTips -SourceQuery 'select * from dbo.s order by id' -TargetQuery 'select * from dbo.t' -ValueOnly

.INPUTS
   -SourceServer: A sql server instance name, default to local computer name
   -SourceDB: A sql database on $SourceServer, default to 'TempDB'
   -SourceQuery: A query against SourceServer\SourceDB (mandatory)

   -TargetServer: A sql server instance name, default to $SourceServer
   -TargetDB: A sql database on $TargetServer, default to $TargetDB
   -TargetQuery: A query against TargetServer\TargetDB (mandatory)

   -ValueOnly: compare value only, so if $SourceQuery get a value of 10 from column with datatype [int], and $TargetQuery get a value of 10 from a colum with datatype [bigint], the value are the same.
   -TempFolder: this is a folder where we need to put temporary files, default to c:\temp\. If you do not have this folder created, an error will occur.

.OUTPUTS
   A string value of either 'Match' or 'UnMatch';
#>

#Requires -Version 3.0

function Compare-QueryResult
{
    [CmdletBinding()]
    [OutputType([string])]
    
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false, 
                   Position=0)]
        [string] $SourceServer = $env:ComputerName ,

        [Parameter(Mandatory=$false)]
        [String] $SourceDB='tempdb', 

        [Parameter(Mandatory=$true)]
        [String] $SourceQuery, 

        [Parameter(Mandatory=$false)]
        [String] $TargetServer='',

        [Parameter(Mandatory=$false)]
        [String] $TargetDB='',

        [Parameter(Mandatory=$true)]
        [String] $TargetQuery,

        [Parameter(Mandatory=$false)]
        [switch] $ValueOnly, 
         
        [Parameter(Mandatory=$false)]
        [String] $TempFolder='c:\temp\'

    )
    begin 
    {
        [string]$src_result='';
        [string]$dest_result='';
    }
    Process
    {
      if (-not (test-path -Path $TempFolder) )
      {
        Write-Error "`$TempFolder=[$TempFolder] does not exist, please check !";
        return;
      }

      #prepare the necessary variables
        [string]$source_bcp_file = "$TempFolder\src_bcp_out.dat"; # the output file is hard-coded here, but you can change it to your own needs
        [string]$target_bcp_file = "$TempFolder\dest_bcp_out.dat";



        if ($TargetServer -eq '')   { $TargetServer = $SourceServer;}

        if($TargetDB -eq '')     {$TargetDB = $SourceDB;}

      #bcp data out to files
      if ($ValueOnly)
      {  
        bcp "$SourceQuery"  queryout "$source_bcp_file" -T -S "$SourceServer" -d $SourceDB -t "|" -c |  out-null;
        bcp "$TargetQuery"  queryout "$target_bcp_file" -T -S "$TargetServer" -d $TargetDB -t "|" -c |  out-null;
      }
      
      else
      {  
        bcp "$SourceQuery"  queryout "$source_bcp_file" -T -S "$SourceServer" -d $SourceDB -t "|" -n |  out-null;
        bcp "$TargetQuery"  queryout "$target_bcp_file" -T -S "$TargetServer" -d $TargetDB -t "|" -n |  out-null;
      }


      #create MD5
      [System.Security.Cryptography.MD5] $md5 = [System.Security.Cryptography.MD5]::Create();


      #read source file
      [System.IO.FileStream] $f = [System.IO.File]::OpenRead("$source_bcp_file");

      #hash the src file
      [byte[]] $hash_src = $md5.ComputeHash($f);
      $f.Close();


      #read the target file
      [System.IO.FileStream] $f = [System.IO.File]::OpenRead("$target_bcp_file");

      #hash the target file
      [byte[]] $hash_dest = $md5.ComputeHash($f);

      $src_result=[System.BitConverter]::ToString($hash_src);
      $dest_result=[System.BitConverter]::ToString($hash_dest);


      #cleanup 

      $f.Close();
      $f.Dispose();
      $md5.Dispose();


      del -Path $source_bcp_file, $target_bcp_file;
      

      #compare the hash value


    }
    End
    {
        if ($src_result -eq $dest_result)
        { write-output 'Match'}
        else
        { Write-Output 'UnMatch'; }

    }
} #Compare-QueryResult