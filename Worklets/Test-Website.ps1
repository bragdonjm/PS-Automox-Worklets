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
Inspired by: Automox Employee

Test website reachability and latency


#>


# We set Param here so -verbose comes online.
# Change the $Target= to whatever you would like. 

Param(
  [
    parameter(
      Mandatory=$False,
      Position=0, 
      HelpMessage='Specify the target website you wish to test.'
    )
  ][String]$target='https://console.automox.com/'

)

###################### Function Definitions ######################
function test-website {
  Param(
    [
      parameter(
        Mandatory=$False,
        Position=0, 
        HelpMessage='Specify the target website you wish to test.'
      )
    ][String]$target='https://console.automox.com/'
  )

  Try {
    $loadedIn = Measure-Command -Expression {
      $response = Invoke-WebRequest -Uri $target
    }  

    
    $return = @{}
    $return.siteTested        = $target
    $return.loadedInSeconds   = $([Math]::Round($loadedIn.TotalSeconds, 4))
    $return.serverType        = $response.Headers.Server
    $return.statusCode        = $response.StatusCode
    $return.statusDescription =  $response.StatusDescription

    return $return
  }

  Catch {
    Throw $_.Exception.Message
  }

  Finally {
  }

}


Try {

  # Used for time spans from the start of this script
  $scriptStartTime=Get-Date
  $scriptName=$MyInvocation.MyCommand.Name
  Write-Verbose “$scriptName Initial Setup, Started running on $scriptStartTime”

  $results = $(test-website -target $target)

  return ConvertTo-Json -InputObject $results

}

Catch {
  $ThisThrowMessage = "Failure: $scriptName threw: " + $_.Exception.Message
  Throw $ThisThrowMessage
}

Finally {
  $totalExecutionTime = $((New-TimeSpan -Start $scriptStartTime -End $(Get-Date)).Seconds).ToString() + " seconds"
  Write-Verbose “Executed in: $totalExecutionTime”
}