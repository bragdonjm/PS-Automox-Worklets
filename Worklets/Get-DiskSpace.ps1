<#
Copyright 2020 Jeffrey Bragdon

Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

Copy to clipboard
   http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Credits:

 ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄       ▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄       ▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌     ▐░░▌▐░░░░░░░░░░░▌▐░▌     ▐░▌
▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌ ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌░▌   ▐░▐░▌▐░█▀▀▀▀▀▀▀█░▌ ▐░▌   ▐░▌ 
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌▐░▌ ▐░▌▐░▌▐░▌       ▐░▌  ▐░▌ ▐░▌  
▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌ ▐░▐░▌ ▐░▌▐░▌       ▐░▌   ▐░▐░▌   
▐░░░░░░░░░░░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌  ▐░▌  ▐░▌▐░▌       ▐░▌    ▐░▌    
▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌   ▀   ▐░▌▐░▌       ▐░▌   ▐░▌░▌   
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌  ▐░▌ ▐░▌  
▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌ ▐░▌   ▐░▌ 
▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌     ▐░▌
 ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀       ▀ 
                                                                                         

Disk Space

#>


# We set Param here so -verbose comes online.
# Make sure Mandatory is False, or this will not work as a worklet

Param(
  [
    parameter(
      Mandatory=$False,
      Position=0, 
      HelpMessage='Add an additional directory to add to the report.'
    )
  ][String]$extraDirectory='false'

)


Try {

  # Used for time spans from the start of this script
  $scriptStartTime=Get-Date
  $scriptName=$MyInvocation.MyCommand.Name
  Write-Verbose “$scriptName Initial Setup, Started running on $scriptStartTime”

  Write-Verbose "Pulling disk information..."
  $Disks = Get-WmiObject -Class Win32_logicaldisk -Filter "DriveType = '3'" | 
    Select-Object -Property DeviceID, DriveType, VolumeName, 
    @{L='FreeSpaceGB';E={"{0:N2}" -f ($_.FreeSpace /1GB)}},
    @{L="Capacity";E={"{0:N2}" -f ($_.Size/1GB)}}
  
  # We'll use this for the folder information. 
  $folderList = @()

  Write-Verbose "Getting information about all user directories..."
  $targetDirectories = $null
  $targetDirectories += Get-ChildItem C:\Users -Directory

  # Let's check if there is an additional directory and add it now. 

  if ($extraDirectory -notlike 'false') {
     Write-Verbose "Getting information from $extraDirectory"
     $targetDirectories += Get-Item $extraDirectory
  }
  
  Write-Verbose "Pulling information from all specified directories. This can take some time..."

  forEach ($targetDirectory in $targetDirectories) {
    Write-Verbose "Processing $($targetDirectory.FullName)"
    $folderSize=$null
    $folderSize = Get-Childitem `
                     -Path $targetDirectory.FullName `
                     -Recurse `
                     -Force `
                     -ErrorAction SilentlyContinue | `
                     Measure-Object `
                       -Property Length `
                       -Sum `
                       -ErrorAction SilentlyContinue  

    $folderObject = [PSCustomObject]@{
      FolderName = $targetDirectory.FullName
        'Size(Bytes)' = $folderSize.Sum
        'Size(MB)'    = $([Math]::Round($($folderSize.Sum / 1MB), 4))
        'Size(GB)'    = $([Math]::Round($($folderSize.Sum / 1GB), 4))
      }  
    $folderList+=$folderObject
  }

  $Disks | Format-Table
  $folderList | Format-Table

}

Catch {
  $ThisThrowMessage = "Failure: $scriptName threw: " + $_.Exception.Message
  Throw $ThisThrowMessage
}

Finally {
  $totalExecutionTime = $((New-TimeSpan -Start $scriptStartTime -End $(Get-Date)).Seconds).ToString() + " seconds"
  Write-Verbose “Executed in: $totalExecutionTime”
}