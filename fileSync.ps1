$shareFolder = ""
$localFolder = ""

$shareFolderFiles = Get-ChildItem -Path $shareFolder
$localFolderFiles = Get-ChildItem -Path $localFolder


function syncDir {
    # This part of the script simply checks for file existence in both locations. Once I know each folder at least a version 
    $fileDiffs = Compare-Object -ReferenceObject $shareFolderFiles -DifferenceObject $localFolderFiles -IncludeEqual
    Foreach($fileComparison in $fileDiffs){
        #get -path 
        $copyParams = @{
            'Path' = $fileComparison.InputObject.FullName
        }
        if($fileComparison.SideIndicator -eq '<='){
            $copyParams.Destination = $localFolder
            Copy-Item @copyParams
            echo $fileComparison.InputObject.FullName copied to $localFolder
        }elseif ($fileComparison.SideIndicator -eq '=>'){
            $copyParams.Destination = $shareFolder
            Copy-Item @copyParams
            echo $fileComparison.InputObject.FullName copied to $ShareFolder
        }
    }

    # Once the file exists in both places, get accurate listing 
    $shareFolderFiles = Get-ChildItem -Path $shareFolder
    # Version Checking
    Foreach($file in $shareFolderFiles){
        #show me the file name
        $file.name 
        #if(!(Test-Path -Path (join-path $localFolder $file.name))){    echo false    }  #test if exists in both another way, not used because it doesn't accurately get all files.
        #determine hash of both sides.  if same, skip regardless of last write time. If different, overwrite based on last write time. 
        if((Get-FileHash (join-path $localFolder $file)).Hash -eq (Get-FileHash (join-path $shareFolder $file)).Hash){
            $file.name
            echo same hash 
        }else{
            #hashes are different, select newest write time and copy that file both places. 
            if((join-path $shareFolder $file).LastWriteTime -gt (join-path $localFolder $file).LastWriteTime){
                Copy-Item -path (join-path $localFolder $file) -Destination $shareFolder -Force
            }else{
                Copy-Item -path (join-path $shareFolder $file) -Destination $localFolder -Force
            }
        }
    }
}

syncDir
