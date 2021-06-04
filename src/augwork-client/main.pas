unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  blcksock, connectframe, jsonparser, fpjson, process, addsession, optionsframe;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    ListBox1: TListBox;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Frame1_1: TFrame;
    Panel4: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

const
  VERSION = '0.5';

var
  Form1: TForm1;
  TCPClient: TTCPBlockSocket;
  FileReader: TStringList;
  Config: TJSONObject;

implementation
var
  NeedOptions: Boolean;

{$R *.lfm}

{ TForm1 }

{procedure TForm1.Button1Click(Sender: TObject);
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
  TCPClient.CloseSocket;

  RunCommand('x11vnc -storepasswd '+Password+' /tmp/.vnc_pass',STDOUT);
  Sleep(10000);
  RunCommand('vncviewer -passwd /tmp/.vnc_pass -Fullscreen '+Response.Strings['host']+':'+Response.Strings['port'],STDOUT);

end;     }

procedure TForm1.FormShow(Sender: TObject);
begin
  if NeedOptions then
  begin
    Frame1_1 := TFrame3.Create(Panel4);
    Frame1_1.Parent := Panel4;
    Frame1_1.Align := alClient;
  end;

  WindowState:=wsFullScreen;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Halt;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  FreeAndNil(Frame1_1);
  Frame1_1 := TFrame3.Create(Panel4);
  Frame1_1.Parent := Panel4;
  Frame1_1.Align := alClient;
end;

begin
  TCPClient := TTCPBlockSocket.Create;
  FileReader := TStringList.Create;
  NeedOptions := False;

  if not FileExists('config.json') then
  begin
    Config := TJSONObject.Create;
    Config.Add('host','');
    Config.Add('port',5900);
    FileReader.Text := Config.FormatJSON;
    FileReader.SaveToFile('config.json');
    NeedOptions := True;
  end else
  begin
    FileReader.LoadFromFile('config.json');
    Config := TJSONObject(GetJSON(FileReader.Text));
  end;
  if Config.Strings['host'] = '' then NeedOptions := True;
end.

