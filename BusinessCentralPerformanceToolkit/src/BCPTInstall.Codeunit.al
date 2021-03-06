// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 149020 "BCPT Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        // EnvironmentInformation: Codeunit "Environment Information";
        PermissionManager: Codeunit "Permission Manager";
    begin
        if PermissionManager.SoftwareAsAService() and (not PermissionManager.IsSandboxConfiguration) then
            Error(CannotInstallErr);
    end;

    var
        CannotInstallErr: Label 'Cannot install on environment that is not a Sandbox or OnPrem.//Please contact your administrator.';
}