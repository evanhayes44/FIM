Write-Host ""
Write-Host "What would you like to do?"
Write-Host "    A) Collect new Baseline?"
Write-Host "    B) Begin monitoring files with saved Baseline?"
Write-Host ""

$answer = Read-Host "Please enter 'A' or 'B'"
Write-Host ""

Function CalculateFileHash ($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA256
    return $filehash
}
Function EraseExistingBaseline() {
    $baselineExists = Test-Path -Path E:\VSCodePowershellFIM\baseline.txt

    if ($baselineExists) {
        # Delete previous baseline
        Remove-Item -Path E:\VSCodePowershellFIM\baseline.txt
    }
}

if ($answer -eq "A".ToUpper()) {
    # Delete the old/previous baseline
    EraseExistingBaseline

    # Calculate a hash from the selected files and store them into baseline.txt
    # Collect files within targeted folder/location
    $files = Get-ChildItem -Path E:\VSCodePowershellFIM\FIMtest

    # For each file, calculate the hash, and write to baseline.txt
    foreach ($f in $files) {
        $hash = CalculateFileHash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath E:\VSCodePowershellFIM\baseline.txt -Append
    }
    
}

elseif ($answer -eq "B".ToUpper()) {
    # Load the files & hashes from baseline.txt into a hash table
    $fileHashTable = @{}

    $filePathHash = Get-Content -Path E:\VSCodePowershellFIM\baseline.txt
    
    foreach ($f in $filePathHash) {
         $fileHashTable.add($f.Split("|")[0],$f.Split("|")[1])
    }

    # Begin continuously monitoring the files using the saved baseline
    while ($true) {
        Start-Sleep -Seconds 1
        
        $files = Get-ChildItem -Path E:\VSCodePowershellFIM\FIMtest

        # For each file, calculate the hash, and write them to baseline.txt
        foreach ($f in $files) {
            $hash = CalculateFileHash $f.FullName

            if ($fileHashTable[$hash.Path] -eq $null) {
                # Notify if a new file has been created
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Yellow
            }
            else {
                if ($fileHashTable[$hash.Path] -eq $hash.Hash) {
                    # The file hasn't been changed
                }
                else {
                    # Notify the user that the file has been changed
                    Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Red
                }
            }
        }

        foreach ($key in $fileHashTable.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                # One of the baseline files have been deleted, notify the user
                Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Cyan
            }
        }
    }
}