unit connectframe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls;

type

  { TFrame1 }

  TFrame1 = class(TFrame)
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
uses blcksock, process, jsonparser, fpjson, main, Dialogs, connectstatus, DateUtils;

{$R *.lfm}

{ TFrame1 }

procedure TFrame1.Button1Click(Sender: TObject);
var
  Login, Password, STDOUT: String;
  Response: TJSONObject;
  Timer: Integer;
begin
  Login := Edit1.Text;
  Password := Edit2.Text;
  main.TCPClient.CloseSocket;
  main.TCPClient.Connect(main.Config.Strings['host'],main.Config.Strings['port']);
  if main.TCPClient.LastError <> 0 then
  begin
    ShowMessage('No connection to server');
    Exit;
  end;

  main.TCPClient.SendString(
    Format(
      '{"method":"login","login":"%s","password":"%s","resolution":"%dx%d"}'#13#10,
      [Login, Password, Screen.Width,Screen.Height]
    )
  );
  Response := TJSONObject(GetJSON(main.TCPClient.RecvString(16000)));
  main.TCPClient.CloseSocket;

  if Response.IndexOfName('error') <> -1 then
  begin
    ShowMessage(Response.Strings['error']);
    Exit;
  end;

  if Response.Booleans['exists_session'] then
    Sleep(2000);

  Timer := DateTimeToUnix(Now);
  While True do
  begin
    main.TCPClient.Connect(Response.Strings['host'], Response.Strings['port']);
    if (DateTimeToUnix(Now) - Timer) >= 10 then
    begin
      ShowMessage('No VNC connection');
      Break;
    end;
    if main.TCPClient.LastError = 0 then
    begin
      RunCommand('x11vnc -storepasswd '+Password+' /tmp/.vnc_pass',STDOUT);
      RunCommand('vncviewer -passwd /tmp/.vnc_pass -Fullscreen '+Response.Strings['host']+':'+Response.Strings['port'],STDOUT);
      Break;
    end;
    Sleep(100);
  end;

end;

end.

