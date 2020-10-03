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



#>


# We set Param here so -verbose comes online.
# Make sure Mandatory is False, or this will not work as a worklet

Param(
  [
    parameter(
      Mandatory=$False,
      Position=0, 
      HelpMessage='Enter in help example here.'
    )
  ][String]$example='example'

)


Try {

  # Used for time spans from the start of this script
  $scriptStartTime=Get-Date
  $scriptName=$MyInvocation.MyCommand.Name
  Write-Verbose “$scriptName Initial Setup, Started running on $scriptStartTime”


}

Catch {
  $ThisThrowMessage = "Failure: $scriptName threw: " + $_.Exception.Message
  Throw $ThisThrowMessage
}

Finally {
  $totalExecutionTime = $((New-TimeSpan -Start $scriptStartTime -End $(Get-Date)).Seconds).ToString() + " seconds"
  Write-Verbose “Executed in: $totalExecutionTime”
}