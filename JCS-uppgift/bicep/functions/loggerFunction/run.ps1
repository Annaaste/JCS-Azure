

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Function Test {
  [cmdletbinding()]
  Param(    
      [Parameter(Mandatory)][ValidateLength(3,36)][ValidateNotNullOrEmpty()][string]$Item
  )
}

#checking if - sign repeats
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

#Checking if your in need of physical restraints
Function RetardCheck {
    param (
        [string]$rString,
        [string]$regarding
    )
    #Check if wrong chars are present
    if ($rString -match '^[a-z0-9_-]*$'){
        #Check if - sign is in end or begining of string
        if($rString -match '^\-' -or $rString -match '\-$'){          
            return $False
        }
        else{
            $repeatTest = RepeatCheck -checkString $rString -checkChar "-"
            if($repeatTest){               
                return $False
            }
            else{
                return $True
            }
        }        
    }
    else{      
        return $False        
    }    
}

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Connect-AzAccount -Identity

# Environment variables comming from Function properties/appsettings
$stName = $env:storageAccountName
$rgName = $env:resourceGroupName
$tableName = $env:tableSFTPName
Write-Output "check1"
$body = ''
$status = ''

#Checks if parameter is wrong length or null, if everything passes chekcer gets true
try {  
    $returnname = 'Container'
    Test -Item $Request.Body.containername
    $returnname = 'Username'
    Test -Item $Request.Body.username.ToLower()        
    $returnname = 'Company'    
    Test -Item $Request.Body.company.ToLower()
    $returnname = 'Firstname'  
    Test -Item $Request.Body.firstname
    $returnname = 'Lastname'  
    Test -Item $Request.Body.lastname
    $checker = $True
}
catch {
    $tester = $_.Exception.Message
    $body = "Encountered Error: $tester check parameter $returnname"
    $status = [HttpStatusCode]::BadRequest    
    #Write-Output $tester
    $checker = $False
}

$noteThis = ""

#$partition = "partition"

if ($checker) {
    $containername = $Request.Body.containername.ToLower()
    $username = $Request.Body.username.ToLower()
    $firstname = $Request.Body.firstname
    $lastname = $Request.Body.lastname
    $company = $Request.Body.company.ToLower()

    #Checks the strings with naming rules, if one does not get true it will stop coming if-check
    $fbiCheck1 = RetardCheck -rString $containername -regarding "ContainerName"
    if(!$fbiCheck1){
        $body = "Naming error in Container, only use letters numbers and - sign. Dont start name with or repeat - sign"
        $status = [HttpStatusCode]::BadRequest
    }
    $fbiCheck2 = RetardCheck -rString $company -regarding "Company"
    if(!$fbiCheck2){
        $body = "Naming error in Company, only use letters numbers and - sign. Dont start name with or repeat - sign"
        $status = [HttpStatusCode]::BadRequest        
    }    
    $fbiCheck3 = $username -match '^[a-z0-9]*$'
    #Username does not accept - char so no such test needed therefore a smaller check is done here
    if(!$fbiCheck3){
        $body = "Take your special characters and leave. Check parameter Username"
        $status = [HttpStatusCode]::BadRequest
    }
    if($fbiCheck1 -And $fbiCheck2 -And $fbiCheck3){
        $encryptionlist = Get-AzStorageEncryptionScope -ResourceGroupName $rgName -StorageAccountName $stName
        if($encryptionlist.Name -notcontains $company){
            $encryptionScope = New-AzStorageEncryptionScope -ResourceGroupName $rgName -StorageAccountName $stName -EncryptionScopeName $company -StorageEncryption
        }
        else{
            $encryptionScope = Get-AzStorageEncryptionScope -ResourceGroupName $rgName -StorageAccountName $stName -EncryptionScopeName $company
        }

        $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $stName)[0].Value
        $StorageContext = New-AzStorageContext -StorageAccountName $stName -StorageAccountKey $StorageAccountKey
        
        #Check if container name is already in use
        $storageContainerCheck = Get-AzStorageContainer -Context $StorageContext
        $storageContainerCheck.name
        if($storageContainerCheck.name -notcontains $containername){
            $cNameCheck = $True
        }
        else{
            $body = "That Containername already exist you drek, get some fucking fantasy. Check parameter ContainerName"      
            $status = [HttpStatusCode]::BadRequest      
            $cNameCheck = $False
        }

        ##Check if Username is already in use
        $storageUserCheck = Get-AzStorageLocalUser -ResourceGroupName $rgName -AccountName $stName
        $storageUserCheck.name
        if($storageUserCheck.name -notcontains $username){
            $uNameCheck = $True
        }
        else{
            $body = "That Username already exists you twat, get your own name. Check parameter UserName"
            $status = [HttpStatusCode]::BadRequest            
            $uNameCheck = $False
        }

        if($uNameCheck -And $cNameCheck){
            write-output "GREEN LIGHT MF! GET THE BOOZE!!!"

            New-AzstorageContainer -Context $StorageContext -Name $containername -DefaultEncryptionScope $encryptionScope.Name -PreventEncryptionScopeOverride $true
            $pmScope = New-AzStorageLocalUserPermissionScope -Permission rwdl -Service blob -ResourceName $containername
            $checkLocal = Set-AzStorageLocalUser -ResourceGroupName $rgName -AccountName $stName -UserName $username -HasSshPassword $true -HomeDirectory "/$containername" -PermissionScope $pmScope
            $sshPassword = New-AzStorageLocalUserSshPassword -ResourceGroupName $rgName -AccountName $stName -UserName $username
            $stringConn = "$stName.$username@$stName.blob.core.windows.net"

            $storageTable = Get-AzStorageTable –Name $tableName –Context $StorageContext
            $cloudTable = $storageTable.CloudTable
            $totalEntities=(Get-AzTableRow -table $cloudTable | measure).Count
            Write-Output "check3"
            $checkLocal    
            if($totalEntities -lt 1){
            Add-AzTableRow -table $cloudTable -partitionKey "partition1" -rowKey ("CA") -property @{"ContainerName"="$containername";"UserName"="$username";"FirstName"="$firstname";"LastName"="$lastname";"Company"="$company";"Userid"=1}
                }
            else{
                $pnumber = $totalEntities + 1
                Add-AzTableRow -table $cloudTable -partitionKey "partition$pnumber" -rowKey ("CA") -property @{"ContainerName"="$containername";"UserName"="$username";"FirstName"="$firstname";"LastName"="$lastname";"Company"="$company";"Userid"=$pnumber}
            }
            $sshPass = $sshPassword.sshPassword
            Write-Output "checker comming"
            $Message = "Hello $firstname $lastname `nYour username is$noteThis : $username `nYour password is : $sshPass `nConnection-string is : $stringConn"
            $status = [HttpStatusCode]::OK
            $Body = @{
                Message = $Message
                ConnectionString = $stringConn
                username = $username
                sshPassword = $sshPass
            }
        }
    }
}
Write-Output "check4"
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})