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

Failed Logons
Please note - this is designed to check for logon failures of remote windows systems not
jointed to Active Directory. If you would like active directory, you should be checking against
the PDCEmulator in a central location. 

Credits:
  ___        _                              _____                _                            
 / _ \      | |                            |  ___|              | |                           
/ /_\ \_   _| |_ ___  _ __ ___   _____  __ | |__ _ __ ___  _ __ | | ___  _   _  ___  ___  ___ 
|  _  | | | | __/ _ \| '_ ` _ \ / _ \ \/ / |  __| '_ ` _ \| '_ \| |/ _ \| | | |/ _ \/ _ \/ __|
| | | | |_| | || (_) | | | | | | (_) >  <  | |__| | | | | | |_) | | (_) | |_| |  __/  __/\__ \
\_| |_/\__,_|\__\___/|_| |_| |_|\___/_/\_\ \____/_| |_| |_| .__/|_|\___/ \__, |\___|\___||___/
                                                          | |             __/ |               
                                                          |_|            |___/    
#>


#Requires -RunAsAdministrator

# We set Param here so -verbose comes online.
# Make sure Mandatory is False, or this will not work as a worklet

Param(
  [
    parameter(
      Mandatory=$False,
      Position=0, 
      HelpMessage='Event ID you would like to search for in the security log.'
    )
  ][String]$eventId='4625'

)


Try {

  # Used for time spans from the start of this script
  $scriptStartTime=Get-Date
  $scriptName=$MyInvocation.MyCommand.Name
  Write-Verbose “$scriptName Initial Setup, Started running on $scriptStartTime”
  $LogonType = @{
    '2' = 'Interactive'
    '3' = 'Network'
    '4' = 'Batch'
    '5' = 'Service'
    '7' = 'Unlock'
    '8' = 'Networkcleartext'
    '9' = 'NewCredentials'
    '10' = 'RemoteInteractive'
    '11' = 'CachedInteractive'
   }

  $failedLogons = Get-WinEvent -FilterHashtable @{
                                                   LogName = 'Security'
                                                   ID = $eventId
                                                  }


    $return = @()
    foreach ($event in $failedLogons){
        $return+= [pscustomobject]@{
            TargetAccount = $event.properties.Value[5]
            LogonType = $LogonType["$($event.properties.Value[10])"]
            CallingComputer = $event.Properties.Value[13]
            IPAddress = $event.Properties.Value[19]
            TimeStamp = $event.TimeCreated
        }
}


  Write-Output "Total number of events: $($Return.Count)"
  return $return | Format-Table
}

Catch {
  $ThisThrowMessage = "Failure: $scriptName threw: " + $_.Exception.Message
  Throw $ThisThrowMessage
}

Finally {
  $totalExecutionTime = $((New-TimeSpan -Start $scriptStartTime -End $(Get-Date)).Seconds).ToString() + " seconds"
  Write-Verbose “Executed in: $totalExecutionTime”
}