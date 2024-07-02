Import-Module Microsoft.Graph.Authentication
$ClientId = Get-AutomationVariable -Name 'ClientId'
$TenantId = Get-AutomationVariable -Name 'TenantId'
$Thumbprint = Get-AutomationVariable -Name 'Thumbprint'
Connect-MgGraph -clientId $ClientId -tenantId $TenantId -certificatethumbprint $Thumbprint -NoWelcome

#Create a user group (can be static or dynamic) and replace the object ID here.
$UserGroupID = "USER GROUP OBJECT ID" #Update with the group ID of user group

#Create a static group, paste the ID here.
$DeviceGroupID = "DEVICE GROUP OBJECT ID"

#Hold all the device Ids of a certain group
$AllDevicesInGroup = @()
$DevicesTBA = @()
$ValidDevices = @()
$DevicesToRemove = @()

#RETRIVE CURRENT DEVICES IN DEVICE GROUP
$DevicesCurrentlyInGroup = Get-MgGroupMember -GroupId $DeviceGroupID -All -Select Id

#GET ALL THE USERS IN THE USER GROUP
$MembersOfUserGroup = Get-MgGroupMember -GroupId $UserGroupID -All -Select Id

#FOR EACH USER, RETRIEVE ALL DEVICES AND APPEND TO ARRAY
foreach ($member in $MembersOfUserGroup) {
    $userId = $member.Id
    $userDevices = Get-MgUserOwnedDevice -UserId $userId -Select Id
    if ($userDevices) {
        foreach ($device in $userDevices) {
            $AllDevicesInGroup += $device.Id
        }
    }
}

#Loop through devices and filter for Windows devices with MDM set to "Microsoft Intune"
foreach ($member in $MembersOfUserGroup) {
    $userId = $member.Id
    $userDevices = Get-MgUserOwnedDevice -UserId $userId -Select Id

    if ($userDevices) {
        foreach ($device in $userDevices) {
            $deviceDetails = Get-MgDevice -DeviceId $device.Id -Select Id, TrustType, ManagementType

            if ($deviceDetails -and $deviceDetails.TrustType -eq "AzureAd" -and $deviceDetails.ManagementType -eq "MDM") {
                $ValidDevices += $device.Id
            }
        }
    }
}

#CHECK IF EACH DEVICE IN $VALIDDEVICES IS PRESENT IN THE DEVICE GROUP AND APPEND TO $DEVICESTBA IF NOT FOUND
foreach ($deviceId in $ValidDevices) {
    $found = $false
    foreach ($currentDevice in $DevicesCurrentlyInGroup) {
        if ($deviceId -eq $currentDevice.Id) {
            $found = $true
            break
        }
    }
    if (-not $found) {
        $DevicesTBA += $deviceId
    }
}

#ADD DEVICES THAT WERE NOT FOUND AND USERS ARE IN USER GROUP
foreach ($deviceId in $DevicesTBA) {
    $params = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$deviceId"
    }

    New-MgGroupMemberByRef -GroupId $DeviceGroupID -BodyParameter $params -ErrorAction SilentlyContinue
}

Write-Output "Devices to add $DevicesTBA"

#ADD TO ARRAY IF THE DEVICE IS IN THE DEVICE GROUP, BUT THE USER WAS REMOVED FROM THE USER GROUP
foreach ($currentDevice in $DevicesCurrentlyInGroup) {
    $deviceFound = $false

    foreach ($member in $MembersOfUserGroup) {
        $userId = $member.Id

        if ($AllDevicesInGroup -contains $currentDevice.Id) {
            $deviceFound = $true
            break
        }
    }

    if (-not $deviceFound) {
        $DevicesToRemove += $currentDevice.Id
    }
}

Write-Output "Devices To be removed: $DevicesToRemove"

#REMOVE THE DEVICES IN THE $DEVICESTOREMOVEARRAY
foreach ($deviceId in $DevicesToRemove) {
    Remove-MgGroupMemberDirectoryObjectByRef -GroupId $DeviceGroupID -DirectoryObjectId $deviceId -ErrorAction SilentlyContinue
}