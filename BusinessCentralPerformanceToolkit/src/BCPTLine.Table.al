// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
table 149001 "BCPT Line"
{
    DataClassification = SystemMetadata;
    // Extensible = false;
    // Access = Internal;

    fields
    {
        field(1; "BCPT Code"; Code[10])
        {
            Caption = 'BCPT Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "BCPT Header";
            DataClassification = CustomerContent;
        }
        field(2; "Line No."; Integer)
        {
            Editable = false;
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3; "Codeunit ID"; Integer)
        {
            Caption = 'Codeunit ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Codeunit));
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                CodeunitMetadata: Record "CodeUnit Metadata";
                BCPTLookupRoles: Page "BCPT Lookup Codeunits";
            begin
                BCPTLookupRoles.LookupMode := true;
                if BCPTLookupRoles.RunModal() = ACTION::LookupOK then begin
                    BCPTLookupRoles.GetRecord(CodeunitMetadata);
                    Validate("Codeunit ID", CodeunitMetadata.ID);
                end;
            end;

            trigger OnValidate()
            var
                CodeunitMetadata: Record "CodeUnit Metadata";
            begin
                CodeunitMetadata.Get("Codeunit ID");
                CalcFields("Codeunit Name");
                if ("Codeunit ID" = Codeunit::"BCPT Role Wrapper") or not (CodeunitMetadata.TableNo in [0, Database::"BCPT Line"]) then
                    Error(NotSupportedCodeunitErr, "Codeunit Name");
                "Run in Foreground" := CodeunitMetadata.SubType = CodeunitMetadata.SubType::Test;

                BCPTTestParamProviderInitialized := false;
                Parameters := GetDefaultParametersIfAvailable();
            end;
        }
        field(4; "Codeunit Name"; Text[80])
        {
            Caption = 'Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = CONST(Codeunit), "Object ID" = field("Codeunit ID")));
        }
        field(5; "No. of Sessions"; Integer)
        {
            Caption = 'No. of Sessions';
            InitValue = 1;
            MinValue = 1;
            MaxValue = 100;
            DataClassification = CustomerContent;
        }
        field(6; "Description"; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(9; "Status"; Enum "BCPT Line Status")
        {
            Caption = 'Status';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(10; "Min. User Delay (ms)"; Integer)
        {
            Caption = 'Min. User Delay (ms)';
            MinValue = 100;
            MaxValue = 10000;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                If "Max. User Delay (ms)" < "Min. User Delay (ms)" then
                    "Max. User Delay (ms)" := "Min. User Delay (ms)";
            end;
        }
        field(11; "Max. User Delay (ms)"; Integer)
        {
            Caption = 'Max. User Delay (ms)';
            MinValue = 1000;
            MaxValue = 30000;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                If "Max. User Delay (ms)" < "Min. User Delay (ms)" then
                    "Max. User Delay (ms)" := "Min. User Delay (ms)";
            end;
        }
        field(12; "Delay (sec. btwn. iter.)"; Integer)
        {
            Caption = 'Delay between iterations (sec.)';
            DataClassification = CustomerContent;
            InitValue = 5;
            MinValue = 1;
        }
        field(13; "Delay Type"; Option)
        {
            Caption = 'Delay Type';
            DataClassification = CustomerContent;
            OptionMembers = ,,,,,,,,,,Fixed,,,,,,,,,,Random;
            OptionCaption = ',,,,,,,,,,Fixed,,,,,,,,,,Random';
        }
        field(14; "Version Filter"; Integer)
        {
            Caption = 'Version Filter';
            FieldClass = FlowFilter;
        }
        field(15; "No. of Iterations"; Integer)
        {
            Caption = 'No. of Iterations';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Count("BCPT Log Entry" where("BCPT Code" = field("BCPT Code"), "BCPT Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Scenario')));
        }
        field(16; "Total Duration (ms)"; Integer)
        {
            Caption = 'Total Duration (ms)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Sum("BCPT Log Entry"."Duration (ms)" where("BCPT Code" = field("BCPT Code"), "BCPT Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Scenario')));
        }
        field(18; "Run in Foreground"; Boolean)
        {
            Caption = 'Run in Foreground';
            DataClassification = CustomerContent;
        }
        field(19; Sequence; Option)
        {
            Caption = 'Sequence';
            OptionMembers = Initialization,Scenario,Finish;
            DataClassification = CustomerContent;
        }
        field(21; Indentation; Integer)
        {
            Caption = 'Indentation';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(23; "No. of Running Sessions"; Integer)
        {
            Caption = 'No. of Running Sessions';
            DataClassification = CustomerContent;
        }
        field(24; Parameters; Text[250])
        {
            Caption = 'Parameters';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Rec."Codeunit ID" = 0 then
                    exit;

                ValidateParameters(Parameters);
            end;

            trigger OnLookup()
            var
                BCPTParameterLines: Page "BCPT Parameters";
            begin
                BCPTParameterLines.SetParamTable(Rec.Parameters);
                BCPTParameterLines.LookupMode := true;
                BCPTParameterLines.Editable := true;
                if BCPTParameterLines.RunModal() = Action::LookupOK then
                    Rec.Parameters := CopyStr(BCPTParameterLines.GetParameterString(), 1, MaxStrLen(rec.Parameters));
            end;
        }
        field(25; "Base Version Filter"; Integer)
        {
            Caption = 'Base Version Filter';
            FieldClass = FlowFilter;
        }
        field(26; "No. of Iterations - Base"; Integer)
        {
            Caption = 'No. of Iterations - Base';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Count("BCPT Log Entry" where("BCPT Code" = field("BCPT Code"), "BCPT Line No." = field("Line No."), Version = field("Base Version Filter"), Operation = const('Scenario')));
        }
        field(27; "Total Duration - Base (ms)"; Integer)
        {
            Caption = 'Total Duration - Base (ms)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Sum("BCPT Log Entry"."Duration (ms)" where("BCPT Code" = field("BCPT Code"), "BCPT Line No." = field("Line No."), Version = field("Base Version Filter"), Operation = const('Scenario')));
        }
    }

    keys
    {
        key(Key1; "BCPT Code", "Line No.")
        {
            Clustered = true;
        }
    }

    var
        NotSupportedCodeunitErr: Label 'Codeunit %1 can not be used for benchmark testing.', Comment = '%1 = codeunit name';
        BCPTTestParamProviderInitialized: Boolean;

    local procedure GetDefaultParametersIfAvailable() DefaultParameters: Text[1000]
    begin
        // if SetParametersProvider() then
        //     exit(BCPTTestParamProvider.GetDefaultParameters());
        OnGetDefaultParameters("Codeunit ID", DefaultParameters);
    end;

    local procedure ValidateParameters(Params: Text[1000])
    begin
        OnValidateParameters("Codeunit ID", Params)
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetDefaultParameters(CodeunitID: Integer; var DefaultParameters: Text[1000])
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnValidateParameters(CodeunitID: Integer; Params: Text[1000])
    begin
    end;
}