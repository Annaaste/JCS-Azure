using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Functions

#Main continue code, if all checks are passed this will run
function DoTheStuff {
  $partition = "partition"
  $body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."
  if ($name) {
      $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $stName)[0].Value
      $StorageContext = New-AzStorageContext -StorageAccountName $stName -StorageAccountKey $StorageAccountKey
      $StorageShares = Get-AzStorageShare -Context $StorageContext
      $StorageShares.Name
      if ($StorageShares.Name -notcontains $name) {
          
          $shareNew = New-AzStorageShare -Context $StorageContext -Name $name
          $storageTable = Get-AzStorageTable –Name $tableName –Context $StorageContext
          $cloudTable = $storageTable.CloudTable
          $totalEntities=(Get-AzTableRow -table $cloudTable | measure).Count
          if($totalEntities -lt 1){
            Add-AzTableRow -table $cloudTable -partitionKey "partition1" -rowKey ("CA") -property @{"FileShareName"="$name";"FirstName"="$fname";"LastName"="$lname";"userid"=1}
          }
          else{
          $pnumber = $totalEntities + 1
          Add-AzTableRow -table $cloudTable -partitionKey "partition$pnumber" -rowKey ("CA") -property @{"FileShareName"="$name";"FirstName"="$fname";"LastName"="$lname";"userid"=$pnumber}
          }
          $shareUri = $shareNew.CloudFileShare.Uri
          $global:body = "Hello $fname, your fileshare $name was created successfully. The share-url is $shareUri"
      }
      else{
          $global:body = "This filesharename is taken, please choose another one"
      }
  }     
}

Function Test {
  [cmdletbinding()]
  Param(    
      [Parameter(Mandatory)][ValidateLength(3,63)][ValidateNotNullOrEmpty()][string]$Item
  )
}

#Checks if lenght is ok and null check
Function Check{
    try {  
        Test -Item $name
        return $True
    }
    catch {
        return $False
    }
}

#checking if - char repeats
Function RepeatCheck {
    param (
        [string]$checkString,
        [char]$checkChar
    )
    $rep = ($checkString | Select-String -Pattern ($checkChar + "{2,}")).Matches.Count

    if($rep -gt 0){
        #Upprepas
        return $True
    }
    else{
        #Upprepas ej
        return $False
    }
}


# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Connect-AzAccount -Identity
$counter
$stName = $env:storageAccountName
$rgName = $env:resourceGroupName
$tableName = $env:tableFileshareName

$missingname = ""
$missingfname = ""
$missinglname = ""

#Main Code
if (-not $name) {
    $name = $Request.Body.filesharename.ToLower()
    $fname = $Request.Body.firstname
    $lname = $Request.Body.lastname
}

if($name -eq $null -or $fname -eq $null -or $lname -eq $null){
    if($name -eq $null){
        $missingname = ", fileshare name"
    }
    if($fname -eq $null){
      $missingfname = ", firstname"
    }
    if($lname -eq $null){
      $missinglname = ", lastname"
    }
    
    write-output "You are missing$missingname$missingfname$missinglname Sucker!"
    $body = "You are missing$missingname$missingfname$missinglname! Rethink your life choices"
    $status = [HttpStatusCode]::BadRequest
    
}
else{


#Checking if your in need of mental service
    #Check if only certain char in string
    if ($name -match '^[a-z0-9_-]*$'){
        #Check if - is in begining or end of string
        if($name -match '^\-' -or $name -match '\-$'){
            $body = "Even if this is somekind of fetisch you can not use the - sign in the begining or end of the name"
            $checkBool = $False
            $status = [HttpStatusCode]::BadRequest
        }
        else{
            $repeatTest = RepeatCheck -checkString $name -checkChar "-"
            #Last check, checks that - chars doesnt repeat in line
            if($repeatTest){
                $body = "Go see a doctor, you can not spam - chars"
                $checkBool = $False
                $status = [HttpStatusCode]::BadRequest
            }
            else{
                $checkBool = $True
            }
        }        
    }
    else{
        
        $body = "Did you get drunk and pass out on the keyboard? Only use letters, number or the - sign"
        $status = [HttpStatusCode]::BadRequest
        $checkBool = $False        
    }    
    
    if($checkBool){
        if(Check){
            #Finally getting to the right function
            $status = [HttpStatusCode]::OK
            DoTheStuff
        }
        else{
            $body = "Wrong naming lenght, should be between 3-63 char" 
            $status = [HttpStatusCode]::BadRequest           
        }
    }    
}
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
