<# 
.SYNOPSIS  
     An Azure Automation Runbook to create a new storage account with system managed identity as Azure authentication
 
.DESCRIPTION 
    This runbook creates a new storage account and outputs the name of the storage account
    It checks the name of the storage account and restricts it to 24 characters.
    The Name parameter is to be seen as the project name in this instance.
    Outputs the storage account name
    Can be used with New-CloudService and New-AvailabilityGroupVM to automate and standardise environment creation
    
    Assign appropriate role for system managed identity under this Automation account before start this runbook.

    More details: https://learn.microsoft.com/azure/automation/enable-managed-identity-for-automation#assign-role-to-a-system-assigned-managed-identity
 
.PARAMETER SubscriptionId 
    The ID of subscription

.PARAMETER Name
    The project name - which will create a storage account named projectnamestorage restricted to
    24 characters and converted to lower case. 
 
.PARAMETER ResourceGroupName 
    The name of resource group
 
.PARAMETER Location 
    The Location for the Storage Account and Resource Group if not exist 
    If you're not sure which region to specify for the -Location parameter, you can retrieve a list of supported regions for your subscription with the Get-AzLocation command: Get-AzLocation | select Location
 
.PARAMETER Sku
    The Replication strategy of Storage Account to create - Options are

        Standard_LRS. Locally-redundant storage.
        Standard_ZRS. Zone-redundant storage.
        Standard_GRS. Geo-redundant storage.
        Standard_RAGRS. Read access geo-redundant storage.
        Premium_LRS. Premium locally-redundant storage.
        Premium_ZRS. Premium zone-redundant storage.
        Standard_GZRS - Geo-redundant zone-redundant storage.
        Standard_RAGZRS - Read access geo-redundant zone-redundant storage.
   	
   More details :- http://azure.microsoft.com/en-gb/pricing/details/storage/ 

   If not specified the default of Standard_LRS. Locally-redundant storage will be used  	
 
 .PARAMETER Kind
    The kind of Storage Account to create - Options are

        Storage. General purpose Storage account that supports storage of Blobs, Tables, Queues, Files and Disks.
        StorageV2. General Purpose Version 2 (GPv2) Storage account that supports Blobs, Tables, Queues, Files, and Disks, with advanced features like data tiering.
        BlobStorage. Blob Storage account which supports storage of Blobs only.
        BlockBlobStorage. Block Blob Storage account which supports storage of Block Blobs only.
        FileStorage. File Storage account which supports storage of Files only. The default value is StorageV2.

   If not specified the default of StorageV2 will be used  	

.EXAMPLE 
    New-StorageAccount -SubscriptionId '########-####-####-####-############' -Name ProjectName -ResourceGroupName RGName -Location 'North Europe'
    
    This will create a Locally-redundant Storage Account named projectnamestorage in North Europe

.EXAMPLE 
    New-StorageAccount -SubscriptionId '########-####-####-####-############' -Name AVeryLongProjectName -ResourceGroupName RGName -Location 'North Europe' -Sku Standard_GZRS -Kind StorageV2
    
    This will create a Geo-redundant zone-redundant Storage Account named averylongprojectnamesto in North Europe

.OUTPUTS
    Outputs a String value of the storage account name. 
 
.NOTES 
    AUTHOR: Nina Li
    DATE: 05/26/2023 
#> 

workflow New-StorageAccount
{
[OutputType([string])]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [Parameter(Mandatory=$true,HelpMessage="Name of storage account to create")]
        [string]$Name,
        [Parameter(Mandatory=$true,HelpMessage="Name of resource group")]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true,HelpMessage="Location of Storage account and Resource Group if it does not exist")]
        [string]$Location,
        [Parameter(Mandatory=$False,HelpMessage="Replication strategy, default value is Standard_LRS if not specified")]
        [string]$Sku = 'Standard_LRS',
        [Parameter(Mandatory=$False,HelpMessage="kind of storage account, default value is StorageV2 if not specified")]
        [string]$Kind = 'StorageV2'
    )
    
    #$ErrorActionPreference = "Stop"

    "Logging in to Azure..."
    # Ensures you do not inherit an AzContext in your runbook
    Disable-AzContextAutosave -Scope Process

    # Connect to Azure with system-assigned managed identity
    Connect-AzAccount -Identity

    # set and store context
    $AzureContext = Set-AzContext -SubscriptionId $SubscriptionId
    
    # Create/Verify Resource Group Name
    $AzureResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

    # Create Resource Group
    if(!$AzureResourceGroup) 
        {
        $AzureResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        $VerboseMessage = "Creating resource group : {0}" -f $AzureResourceGroup.ResourceGroupName
        }     
    else 
        { 
        $VerboseMessage = "Resource group {0}: Verified" -f $AzureResourceGroup.ResourceGroupName
        }

    # Create/Verify Azure Storage Account Name
    $StorageAccountName = $Name + 'storage'
    $StorageAccountName = $StorageAccountName.ToLower()

    #Storage Account Name must be between 3 and 24 characters so
    if($StorageAccountName.Length -gt 24)
        {
        $StorageAccountName = $StorageAccountName.Substring(0,23)
        }
  
    $AzureStorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue

    #Create StorageAccount
    if(!$AzureStorageAccount) 
        {
        $AzureStorageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -SkuName $Sku -Kind $Kind
        $VerboseMessage = "Creating storage account : {0}" -f $StorageAccountName
        }     
    else 
        { 
        $VerboseMessage = "Azure Storage Account {0}: Verified" -f $AzureStorageAccount.StorageAccountName 
        }
        
    #Sanity Check Storage Account Creation
    $AzureStorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue

    if($AzureStorageAccount)
    {
        $StorageAccountName = $AzureStorageAccount.StorageAccountName
        Write-Verbose "$VerboseMessage"
        Write-Output $StorageAccountName
    }
    else
    {
    Write-Error "$StorageAccountName not created. Please check logs"
    }
}
