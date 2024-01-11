
param ( 
    $resourceGroupName, $namePrefix
)
$stName = "$namePrefix-st"
$stName = $stName -replace '-',''
$rsvBName = "$namePrefix-rsv-bp"
$rsvName = "$namePrefix-rsv"

$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -name $rsvName
Set-AzRecoveryServicesVaultContext -vault $vault
$afsPol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $rsvBName
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -StorageAccountName $stName
$StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $stName)[0].Value
$StorageContext = New-AzStorageContext -StorageAccountName $stName -StorageAccountKey $StorageAccountKey
$FileshareContainer = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage 
$BackupItems = Get-AzRecoveryServicesBackupItem -WorkloadType $afspol.WorkloadType -VaultId $Vault.ID -Container $FileshareContainer
$StorageShares = Get-AzStorageShare -Context $StorageAccount.Context | Where-Object {$_.IsSnapShot -ne $True}
Write-Output $StorageShares
foreach($name in $StorageShares.name){
    if($BackupItems -eq $null){
      Enable-AzRecoveryServicesBackupProtection -Policy $afsPol -Name $name -StorageAccountName $stName  
    }
    else{
      if ($BackupItems.FriendlyName.Contains($name)){
        Write-Output $name
      }
      else {
        Enable-AzRecoveryServicesBackupProtection -Policy $afsPol -Name $name -StorageAccountName $stName 
      }
    }
}


