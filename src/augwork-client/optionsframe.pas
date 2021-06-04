unit optionsframe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls;

type

  { TFrame3 }

  TFrame3 = class(TFrame)
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

implementation
uses main;

{$R *.lfm}

{ TFrame3 }

procedure TFrame3.Button1Click(Sender: TObject);
begin
  main.Config.Strings['host'] := Edit1.Text;
  main.Config.Strings['port'] := Edit2.Text;
  main.FileReader.Text := main.Config.FormatJSON;
  main.FileReader.SaveToFile('config.json');
end;

end.

