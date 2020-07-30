 <#
.SYNOPSIS
    Change_VMware_Tools_Location.ps1 - PowerShell Script to change the VMware Tools location to a central one (like a datastore)
.DESCRIPTION
    This script is used to alter the default VMware Tools location to a central one (for all ESXi hosts).
    It will list a grid view of all datastores so you can select the one to use and prompts you for the name of the folder to create.
    The VMware Tools files itself will not be uploaded, this is a manual action.

    This script only works on vSphere 6.7 Update 1 and newer. Older versions require a different method for changing the VMware Tools location!
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Jesper Alberts, Twitter: @jesperalberts

    Change Log    V1.00, 12/03/2020 - Initial version
#>

try {
    # Connect to the specified vCenter Server
    Connect-viserver -Server $vCenterServer -Credential $Credentials -ErrorAction Stop

    # Specify different variables used in the script
    $ESXiHosts = Get-VMHost
    $DSName = (Get-Datastore | Out-GridView -PassThru).Name
    $DSFolder = Read-Host ("Enter the folder name for the VMware Tools Repository")
    $DSPath = "/vmfs/volumes/$DSName"
    $Location = "$DSPath/$DSFolder"

    # Start with testing if the directory exists, if not it will be created. Otherwise the VMware Tools location will be changed.

    # Start with testing if the directory exists, if not it will be created. Otherwise the VMware Tools location will be changed.
    Write-Output "Checking if the folder already exists on the datastore"
    $Datastore = Get-Datastore -Name "$DSName"
    New-PSDrive -Location $Datastore -Name DS -PSProvider VimDatastore -Root "\" | Out-Null
    $CheckPath = Test-Path "DS:\$DSFolder"

    If ($CheckPath -match "False") {
      Write-Output "The folder '$DSFolder' on datastore '$DSName' does not exist, creating it now."
      # Creating the folder on the datastore
      New-Item -Path "DS:\$DSFolder" -ItemType Directory | Out-Null
      #  Disconnects the earlier created PSDrive
      Remove-PSDrive -Name DS -Confirm:$false | Out-Null
    }
    ForEach ($ESXiHost in $ESXiHosts) {
      $esx = Get-VMHost -Name $ESXiHost
      $OldLocation = $esx.ExtensionData.QueryProductLockerLocation()
      $esx.ExtensionData.UpdateProductLockerLocation($Location) | Out-Null
      Write-Output "Changed VMware Tools location on $ESXiHost from $OldLocation to $Location"
    }
    Disconnect-VIServer -Confirm:$False | Out-Null
  }
  catch {
    Write-Warning $Error[0]
  }