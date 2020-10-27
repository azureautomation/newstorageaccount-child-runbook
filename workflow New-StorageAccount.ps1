<# 
.SYNOPSIS  
     An Azure Automation Runbook to create a new storage account
 
.DESCRIPTION 
    This runbook creates a new storage account and outputs the name of the storage account
    It checks the name of the storage account and restricts it to 24 characters.
    The Name parameter is to be seen as the project name in this instance.
    Outputs the storage account name

    Can be used with New-CloudService and New-AvailabilityGroupVM to automate environment creation
 
.PARAMETER Name
    The project name - which will create a storage account named projectnamestorage restricted to
    24 characters and converted to lower case. 
 
.PARAMETER CredentialName 
    The name of the Azure Automation Credential Asset.
    This should be created using 
    http://azure.microsoft.com/blog/2014/08/27/azure-automation-authenticating-to-azure-using-azure-active-directory/  
 
.PARAMETER AzureSubscriptionName 
    The name of the Azure Subscription. 
 
.PARAMETER Location 
    The Location for the Storage Account 
    Current Options (January 2015)
        West Europe, North Europe, East US 2,Central US,South Central US,West US,North Central US                                                                                                                                                   
        East US,Southeast Asia,East Asia,Japan West,Japan East,Brazil South 
 
.PARAMETER Type
    The Type of Storage Account to create - Options are

        Standard_LRS  LOCALLY REDUNDANT STORAGE (LRS)
        Standard_ZRS  ZONE REDUNDANT STORAGE (ZRS)
        Standard_GRS  GEOGRAPHICALLY REDUNDANT STORAGE (GRS)
        Standard_RAGRS READ-ACCESS GEOGRAPHICALLY REDUNDANT STORAGE (RA-GRS)
   	
   More details :- http://azure.microsoft.com/en-gb/pricing/details/storage/ 

   If not specified the default of Standard_GRS  GEOGRAPHICALLY REDUNDANT STORAGE (GRS)
   will be used  	
 
.EXAMPLE 
    New-StorageAccount -Name ProjectName -CredentialName MasterCredential -AzureSubscriptionName SubName -Location 'North Europe'
    
    This will create a Geo Replicated Storage Account named projectnamestorage in North Europe

.EXAMPLE 
    New-StorageAccount -Name AVeryLongProjectName -CredentialName MasterCredential -AzureSubscriptionName SubName -Location 'North Europe' -Type Standard_LRS
    
    This will create a Locally Redundant Storage Account named averylongprojectnamesto in North Europe

.OUTPUTS
    Outputs a String value of the storage account name. 
 
.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 04/01/2015 
#> 

    workflow New-StorageAccount
{
[OutputType([string])]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$CredentialName,
        [Parameter(Mandatory=$true)]
        [string]$AzureSubscriptionName,
        [Parameter(Mandatory=$true)]
        [string]$Location,
        [Parameter(Mandatory=$False)]
        [string]$Type = 'Standard_GRS'
    )
    
    $ErrorActionPreference = "Stop"
    # Get the credential to use for Authentication to Azure and Azure Subscription Name
    $Cred = Get-AutomationPSCredential -Name $CredentialName
    
    # Connect to Azure and Select Azure Subscription
    $AzureAccount = Add-AzureAccount -Credential $Cred
    $AzureSubscription = Select-AzureSubscription -SubscriptionName $AzureSubscriptionName

    # Create/Verify Azure Storage Account Name
    $StorageAccountName = $Name + 'storage'
    $StorageAccountName = $StorageAccountName.ToLower()

    #Storage Account Name must be between 3 and 24 characters so
    if($StorageAccountName.Length -gt 24)
        {
        $StorageAccountName = $StorageAccountName.Substring(0,23)
        }
    $StorageAccountDesc = "Storage account for " -f $Name
    $StorageAccountLabel = "Storage" -f $Name
    $AzureStorageAccount = Get-AzureStorageAccount -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue

    #Create StorageAccount
    if(!$AzureStorageAccount) 
        {
        $AzureStorageAccount = New-AzureStorageAccount  -StorageAccountName $StorageAccountName -Description $StorageAccountDesc -Label $StorageAccountLabel -Location $Location -Type $Type
        $VerboseMessage = "{0} for {1} {2} (OperationId: {3})" -f $AzureStorageAccount.OperationDescription,$StorageAccountName,$AzureStorageAccount.OperationStatus,$AzureStorageAccount.OperationId
        }     
    else 
        { 
        $VerboseMessage = "Azure Storage Account {0}: Verified" -f $AzureStorageAccount.StorageAccountName 
        }
        
    #Sanity Check Storage Account Creation
    $AzureStorageAccount = Get-AzureStorageAccount -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue

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