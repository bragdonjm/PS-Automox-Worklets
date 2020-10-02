  <# 
   Copyright 2020 Jeffrey Bragdon

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Credits:
   Inspired by: Nic Tolstoshev - Automox Employee
   https://community.automox.com/t/powershell-script-to-remove-devices-that-have-been-disconnected-longer-than-x-days/1111

   #>

Param(
  [
    parameter(
      Mandatory=$True,
      Position=0, 
      HelpMessage='Org ID found in Automox Site URI after the o=.'
    )
  ][String]$orgID,

  [
    parameter(
      Mandatory=$True, 
      Position=1, 
      HelpMessage='API key found in the Automox console under Settings->Keys. Do not share!'
    )
  ][String]$apiKey,

  [
    parameter(
      Mandatory=$False, 
      Position=2, 
      HelpMessage='Any device older than this is removed. Defaults to 120 days.'
    )
  ][String] $maxDays='120',

  [
    parameter(
      Mandatory=$False, 
      Position=3,
      HelpMessage='Automox endpoint. In case it changes, or there is a test endpoint.'
      )
  ][String]$apiEndpoint='https://console.automox.com/api/',

  [
    parameter(
      Mandatory=$False, 
      Position=4, 
      HelpMessage='Change the logfile folder. Otherwise, it drops a logfile where this script was executed.'
    )
  ][String]$logFolder,

  [
    parameter(
      Mandatory=$False, 
      Position=5, 
      HelpMessage="API Table Reference."
    )
  ][String]$apiTable='servers',

  [
    parameter(
      Mandatory=$False, 
      Position=6, 
      HelpMessage="Must be set to true, or this system will not do anything destructive."
    )
  ][bool]$weaponize=$false

)

Try {
  # Used for time spans from the start of this script
  $scriptStartTime=Get-Date 
  $scriptName=$MyInvocation.MyCommand.Name
  Write-Verbose "$scriptName Initial Setup, Started running on $scriptStartTime"
  
  if ($logFolder) 
  {
    write-host "logFolder override was found. Writing logfile to $logFolder\$scriptName.log"
    $scriptLog = "$logFolder\$scriptName.log"
  } 
  else 
  {
    Write-Verbose "No logFolder was defined. Writing log file locally."
    $path = Get-Location
    $scriptLog = "$path\$scriptName.log"
  }
  "----- Execution started at: $scriptStartTime -----" | Out-File -FilePath $scriptLog -Append

  # Setup the object with default values. This value is used for all relevent return information.
  $returnObject = New-Object PSObject  
  $returnObject | Add-Member –MemberType NoteProperty –Name OrgID       –Value $orgId
  $returnObject | Add-Member –MemberType NoteProperty –Name ApiEndpoint –Value $apiEndpoint
  
  # Setup the needed keys to access the Automox API.
  $orgAndKey="?o=$orgID&api_key=$apiKey"

  # Optional Query for fine tuning the search. We've only set this to search for dissconnected devices. 
  $query='&connected=0'
  $returnObject | Add-Member –MemberType NoteProperty –Name Query –Value $query

  #Prepare the entire URI to communicate with the Automox API
  $getURI=$apiEndpoint + $apiTable + $orgAndKey + $query

  #Get the json body of the Web Request
  $request=$(Invoke-WebRequest -UseBasicParsing -Method Get -Uri $getURI)
  $jsonReturn=$request.Content


  #Convert to object with manipulatable properties/values
  $devices = $jsonReturn | ConvertFrom-Json
  $returnObject | Add-Member –MemberType NoteProperty –Name ServerCount –Value $($devices.count)

  # Let's return early if our server count is zero. 
  if ($devices.count -le 0) 
  {
    Return $returnObject
  } 
  else 
  {
    "  $($devices.count) devices found..." | Out-File -FilePath $scriptLog -Append 
  }
  $pulledServersIn=$((New-TimeSpan -Start $scriptStartTime -End $(Get-Date)).Seconds).ToString() + " seconds"
  Write-Verbose "Pulled servers from Automox API in $pulledServersIn"
  #################\ Server Count Completed /#################
  ############################################################
  #################/    Start Processing    \#################

  # Some prep work
  $processed     =@()
  $skipped       =@()
  $successDelete =@()
  $failDelete    =@()

  Write-Verbose "VVVVVVVVVVVVVVVVVVVVVVVV Processing VVVVVVVVVVVVVVVVVVVVVV"
  if ($weaponize) {"  !!! System is Weaponized !!!" | Out-File -FilePath $scriptLog -Append}
  "  going after systems that have not been seen for $maxDays days." | Out-File -FilePath $scriptLog -Append

  foreach ($target in $devices)
  {
    # Pull useful information
    $deviceID   = $target.id
    $deviceName = $target.name
    $lastCheckin = [datetime]$target.last_disconnect_time
    Write-Verbose "~~~~~~~ Checking Device: $deviceName ID: $deviceID ~~~~~~~"

    $span = New-TimeSpan -Start $lastCheckin
    if ($span.Days -ge $maxDays) 
    {
      Write-Verbose "  Last checked in date was $lastCheckin which is longer than $maxDays days ago."
      $processed += @{"DeviceName"=$deviceName;"ServerID"=$deviceID;"last_disconnect_time"=$lastCheckin}
      if ($weaponize) 
      {
        Write-Verbose "  Weaponized ~~> Attempting to process deletion."

        $delURI = $apiEndpoint + $apiTable + '/' + $deviceID + $orgAndKey
        try { 
          $delResponse = Invoke-WebRequest -UseBasicParsing -Method Delete -Uri $delURI
          Write-Verbose "  Successfully deleted server!"
          "  Deleted $deviceName" | Out-File -FilePath $scriptLog -Append
          $successDelete += @{"ServerName"=$deviceName;"ServerID"=$deviceID;"last_disconnectn_time"=$lastCheckin}
        }
        catch { 
          $ThisThrowMessage = $_.Exception.Message
          Write-Verbose "  Failed to Delete Server: $deviceName --> $ThisThrowMessage" 
          "  Something went wrong with deleting $deviceName --> $ThisThrowMessage" | Out-File -FilePath $scriptLog -Append
          $failDelete += @{"ServerName"=$deviceName;"ServerID"=$deviceID;"last_disconnect_time"=$lastCheckin}
        }
      }
      else
      {
        Write-Verbose "  What if ~~> This is running in protected mode."
        "  I would have Deleted $deviceName" | Out-File -FilePath $scriptLog -Append
      }

    }
    else 
    {
      Write-Verbose "  Skipping....."
      $skipped += @{"DeviceName"=$deviceName;"ServerID"=$deviceID;"last_disconnect_time"=$lastCheckin}
    }
  }

  "  We skipped over $($skipped.count) devices that were last seen within $maxDays days." | Out-File -FilePath $scriptLog -Append


  $returnObject | Add-Member –MemberType NoteProperty –Name Processed  –Value $($processed.count)
  $returnObject | Add-Member –MemberType NoteProperty –Name Skipped    –Value $($skipped.count)
  $returnObject | Add-Member –MemberType NoteProperty –Name Deleted    –Value $($successDelete.count)
  $returnObject | Add-Member –MemberType NoteProperty –Name Failed     –Value $($failDelete.count)
  $returnObject | Add-Member –MemberType NoteProperty –Name Weaponized –Value $([int]$weaponized)
  return (ConvertTo-Json $returnObject -Depth 3)
}

Catch {
    $ThisThrowMessage = "Failure: $scriptName threw: " + $_.Exception.Message
    Return $ThisThrowMessage
}

Finally {
  $totalExecutionTime = $((New-TimeSpan -Start $scriptStartTime -End $(Get-Date)).Seconds).ToString() + " seconds"
  Write-Verbose "Executed in: $totalExecutionTime"
  "----- Executed completed in: $totalExecutionTime -----" | Out-File -FilePath $scriptLog -Append
}

