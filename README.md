New-StorageAccount Child Runbook
================================

            

 This runbook creates a new storage account and outputs the name of the storage account    It checks the name of the storage account and restricts it to 24 characters.    The Name parameter is to be seen as the project name in this
 instance.    Outputs the storage account name
 Can be used with New-CloudService and New-AvailabilityGroupVM to automate and standardise environment creation

Assign appropriate role for system managed identity under this Automation account before start this runbook.

More details: https://learn.microsoft.com/azure/automation/enable-managed-identity-for-automation#assign-role-to-a-system-assigned-managed-identity
 




 




        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
