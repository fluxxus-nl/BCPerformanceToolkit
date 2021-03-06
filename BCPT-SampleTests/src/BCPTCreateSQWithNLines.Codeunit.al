// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 149105 "BCPT Create SQ with N Lines"
{
    SingleInstance = true;

    trigger OnRun();
    begin
        If not IsInitialized then begin
            InitTest();
            IsInitialized := true;
        end;
        CreateSalesQuote(BCPTTestContext);
    end;

    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        IsInitialized: Boolean;
        NoOfLinesToCreate: Integer;
        NoOfLinesParamLbl: Label 'Lines';
        ParamValidationErr: Label 'Parameter is not defined in the correct format. The expected format is "%1"';

    local procedure InitTest();
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
    begin
        SalesSetup.Get();
        SalesSetup.TestField("Quote Nos.");
        NoSeriesLine.SetRange("Series Code", SalesSetup."Quote Nos.");
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

    local procedure CreateSalesQuote(Var BCPTTestContext: Codeunit "BCPT Test Context")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        if not Customer.get('10000') then
            Customer.FindFirst();
        if not item.get('70000') then
            Item.FindFirst();
        if NoOfLinesToCreate < 0 then
            NoOfLinesToCreate := 0;
        if NoOfLinesToCreate > 10000 then
            NoOfLinesToCreate := 10000;
        BCPTTestContext.StartScenario('Add Order');
        SalesHeader.init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader.Insert(true);
        BCPTTestContext.EndScenario('Add Order');
        Commit();
        BCPTTestContext.UserWait();
        BCPTTestContext.StartScenario('Enter Account No.');
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);
        Commit();
        BCPTTestContext.EndScenario('Enter Account No.');
        BCPTTestContext.UserWait();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        for i := 1 to NoOfLinesToCreate do begin
            SalesLine."Line No." += 10000;
            SalesLine.Init();
            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine.Insert(true);
            BCPTTestContext.UserWait();
            if i = 10 then
                BCPTTestContext.StartScenario('Enter Line Item No.');
            SalesLine.Validate("No.", Item."No.");
            if i = 10 then
                BCPTTestContext.EndScenario('Enter Line Item No.');
            BCPTTestContext.UserWait();
            if i = 10 then
                BCPTTestContext.StartScenario('Enter Line Quantity');
            SalesLine.Validate(Quantity, 1);
            SalesLine.Modify(true);
            Commit();
            if i = 10 then
                BCPTTestContext.EndScenario('Enter Line Quantity');
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