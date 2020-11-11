# Invoke default behavior
. (Join-Path $runPath $MyInvocation.MyCommand.Name)

if ($env:setup_users -eq "Y") {
    $envUserString = $env:additionalUser
    $authUserArray = $envUserString.Split(",")
    $authPass = $env:userpassword
    $secpasswd = ConvertTo-SecureString $authPass -AsPlainText -Force
    $BCUsers = Get-NAVServerUser -ServerInstance BC
    foreach ($authUser in $authUserArray) {
        $UserExists = $BCUsers | Where-Object { $_.UserName -like $authUser }
        if (! $UserExists) {
            Write-Host ("Setting up {0}" -f $authUser)
            New-NAVServerUser -Tenant default -UserName $authUser -LicenseType Full -ServerInstance BC -Password $secpasswd -ErrorAction Ignore
            New-NAVServerUserPermissionSet -UserName $authUser -PermissionSetId SUPER -ServerInstance BC
        }
    }
}
Get-NavServerUser -serverInstance $ServerInstance -tenant default | ? LicenseType -eq "FullUser" | ForEach-Object {
    $UserId = $_.UserSecurityId
    Write-Host "Assign Premium plan for $($_.Username)"
    $dbName = $DatabaseName
    if ($multitenant) {
        $dbName = $TenantId
    }
    $userPlanTableName = 'User Plan$63ca2fa4-4f03-4f2b-a480-172fef340d3f'
    Invoke-Sqlcmd -ErrorAction Ignore -ServerInstance 'localhost\SQLEXPRESS' -Query "USE [$DbName]
    INSERT INTO [dbo].[$userPlanTableName] ([Plan ID],[User Security ID]) VALUES ('{8e9002c0-a1d8-4465-b952-817d2948e6e2}','$userId')"
}

