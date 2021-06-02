unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  blcksock, jsonparser, fpjson, process;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation
const
  VERSION = '0.2';
var
  TCPClient: TTCPBlockSocket;

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  Login, Password, STDOUT: String;
  Response: TJSONObject;
begin
  Login := Edit1.Text;
  Password := Edit2.Text;
  TCPClient.Connect('cha14ka.tk','5900');
  TCPClient.SendString(
    Format(
      '{"method":"login","login":"%s","password":"%s","resolution":"%dx%d"}'#13#10,
      [Login, Password, Screen.Width,Screen.Height]
    )
  );
  Response := TJSONObject(GetJSON(TCPClient.RecvString(16000)));

  RunCommand('x11vnc -storepasswd '+Password+' /tmp/.vnc_pass',STDOUT);
  Sleep(10000);
  RunCommand('vncviewer -passwd /tmp/.vnc_pass -Fullscreen '+Response.Strings['host']+':'+Response.Strings['port'],STDOUT);

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Halt;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  WindowState:=wsFullScreen;
  Label1.Caption := Label1.Caption+VERSION;
end;

begin
  TCPClient := TTCPBlockSocket.Create;
end.

