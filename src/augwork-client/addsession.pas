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
uses main;

{$R *.lfm}

{ TFrame2 }

procedure TFrame2.Button1Click(Sender: TObject);
begin
  main.Config.Add('da','pizda');
end;

end.

