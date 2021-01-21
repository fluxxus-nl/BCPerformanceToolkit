// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 149103 "BCPT Create PO with N Lines"
{
    SingleInstance = true;

    trigger OnRun();
    begin
        If not IsInitialized or true then begin
            InitTest();
            IsInitialized := true;
        end;
        CreatePurchaseOrder(BCPTTestContext);
    end;

    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        IsInitialized: Boolean;
        NoOfLinesToCreate: Integer;
        NoOfLinesParamLbl: Label 'Lines';
        ParamValidationErr: Label 'Parameter is not defined in the correct format. The expected format is "%1"';


    local procedure InitTest();
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
    begin
        PurchaseSetup.Get();
        PurchaseSetup.TestField("Order Nos.");
        NoSeriesLine.SetRange("Series Code", PurchaseSetup."Order Nos.");
        NoSeriesLine.findset(true, true);
        repeat
            if NoSeriesLine."Ending No." <> '' then begin
                NoSeriesLine."Ending No." := '';
                NoSeriesLine.Modify(true);
            end;
        until NoSeriesLine.Next() = 0;
        commit();

        if Evaluate(NoOfLinesToCreate, BCPTTestContext.GetParameter(NoOfLinesParamLbl)) then;
    end;

    local procedure CreatePurchaseOrder(Var BCPTTestContext: Codeunit "BCPT Test Context")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        if not Vendor.get('10000') then
            Vendor.FindFirst();
        if not Item.get('70000') then
            Item.FindFirst();
        if NoOfLinesToCreate < 0 then
            NoOfLinesToCreate := 0;
        if NoOfLinesToCreate > 10000 then
            NoOfLinesToCreate := 10000;
        BCPTTestContext.StartScenario('Add Order');
        PurchaseHeader.init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Insert(true);
        BCPTTestContext.EndScenario('Add Order');
        BCPTTestContext.UserWait();
        BCPTTestContext.StartScenario('Enter Account No.');
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);
        Commit();
        BCPTTestContext.EndScenario('Enter Account No.');
        BCPTTestContext.UserWait();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        for i := 1 to NoOfLinesToCreate do begin
            PurchaseLine."Line No." += 10000;
            PurchaseLine.Init();
            PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
            PurchaseLine.Insert(true);
            BCPTTestContext.UserWait();
            if i = 10 then
                BCPTTestContext.StartScenario('Enter Line Item No.');
            PurchaseLine.Validate("No.", Item."No.");
            if i = 10 then
                BCPTTestContext.EndScenario('Enter Line Item No.');
            BCPTTestContext.UserWait();
            if i = 10 then
                BCPTTestContext.StartScenario('Enter Line Quantity');
            PurchaseLine.Validate(Quantity, 1);
            if i = 10 then
                BCPTTestContext.EndScenario('Enter Line Quantity');
            PurchaseLine.Modify(true);
            Commit();
            BCPTTestContext.UserWait();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"BCPT Line", 'OnGetDefaultParameters', '', false, false)]
    procedure OnGetDefaultParameters(CodeunitId: Integer; var DefaultParameters: Text[1000])
    begin
        if CodeunitId = Codeunit::"BCPT Create PO with N Lines" then
            DefaultParameters := CopyStr(NoOfLinesParamLbl + '=' + Format(10), 1, 1000);
        DefaultParameters := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"BCPT Line", 'OnValidateParameters', '', false, false)]
    procedure OnValidateParameters(CodeunitId: Integer; Params: Text[1000])
    var
        DefaultParameters: Text[1000];
    begin
        if CodeunitId = Codeunit::"BCPT Create PO with N Lines" then begin
            if StrPos(Params, NoOfLinesParamLbl) > 0 then begin
                Params := DelStr(Params, 1, StrLen(NoOfLinesParamLbl + '='));
                if Evaluate(NoOfLinesToCreate, Params) then
                    exit;
            end;
            OnGetDefaultParameters(CodeunitId, DefaultParameters);
            Error(ParamValidationErr, DefaultParameters);
        end;
    end;
}