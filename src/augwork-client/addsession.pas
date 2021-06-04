unit addsession;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls;

type

  { TFrame2 }

  TFrame2 = class(TFrame)
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    procedure Button1Click(Sender: TObject);

  private

  public

  end;

implementation
uses main, jsonparser, fpjson;

{$R *.lfm}

{ TFrame2 }

procedure TFrame2.Button1Click(Sender: TObject);
var
  SessionObject: TJSONObject;
begin
  SessionObject := TJSONObject.Create;
  SessionObject.Add('login', Edit2.Text);
  SessionObject.Add('password', Edit3.Text);

  main.Config.Objects['sessions'].Add(Edit1.Text, SessionObject);
  main.Form1.UpdateSessions;
  main.FileReader.Text := main.Config.FormatJSON;
  main.FileReader.SaveToFile('config.json');

  FreeAndNil(main.Form1.Frame1_1);
end;

end.

