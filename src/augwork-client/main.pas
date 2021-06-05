unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, blcksock, connectframe, jsonparser, fpjson, process, addsession,
  optionsframe;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label1: TLabel;
    ListBox1: TListBox;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Frame1_1: TFrame;
    Panel4: TPanel;
    Splitter1: TSplitter;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure UpdateSessions;
  private

  public

  end;

const
  VERSION = '0.7';

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

procedure TForm1.UpdateSessions;
var
  JsonEnum: TJSONEnum;
begin
  ListBox1.Clear;
  for JsonEnum in Config.Objects['sessions'] do
  begin
    ListBox1.Items.Add(JsonEnum.Key);
  end;
end;

procedure TForm1.FormShow(Sender: TObject);

begin
  if NeedOptions then
  begin
    Frame1_1 := TFrame3.Create(Panel4);
    Frame1_1.Parent := Panel4;
    Frame1_1.Align := alClient;
    TFrame3(Frame1_1).Edit1.Text := Config.Strings['host'];
    TFrame3(Frame1_1).Edit2.Text := Config.Strings['port'];
  end;

  UpdateSessions;

  WindowState:=wsFullScreen;
  Label1.Caption := Label1.Caption + VERSION;
end;

procedure TForm1.ListBox1Click(Sender: TObject);
var
  SessionObject: TJSONObject;
begin
  if Assigned(Frame1_1) then
     FreeAndNil(Frame1_1);
  Frame1_1 := TFrame1.Create(Panel4);
  Frame1_1.Parent := Panel4;
  Frame1_1.Align := alClient;

  if ListBox1.ItemIndex <> -1 then
  begin
    SessionObject := Config.Objects['sessions'].Objects[ListBox1.Items[ListBox1.ItemIndex]];

    TFrame1(Frame1_1).Edit1.Text := SessionObject.Strings['login'];
    TFrame1(Frame1_1).Edit2.Text := SessionObject.Strings['password'];
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Halt;
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  SessionObject: TJSONObject;
begin
  if Assigned(Frame1_1) then
     FreeAndNil(Frame1_1);
  Frame1_1 := TFrame1.Create(Panel4);
  Frame1_1.Parent := Panel4;
  Frame1_1.Align := alClient;

  if ListBox1.ItemIndex <> -1 then
  begin
    SessionObject := Config.Objects['sessions'].Objects[ListBox1.Items[ListBox1.ItemIndex]];

    TFrame1(Frame1_1).Edit1.Text := SessionObject.Strings['login'];
    TFrame1(Frame1_1).Edit2.Text := SessionObject.Strings['password'];
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if Assigned(Frame1_1) then
     FreeAndNil(Frame1_1);
  Frame1_1 := TFrame3.Create(Panel4);
  Frame1_1.Parent := Panel4;
  Frame1_1.Align := alClient;
  TFrame3(Frame1_1).Edit1.Text := Config.Strings['host'];
  TFrame3(Frame1_1).Edit2.Text := Config.Strings['port'];
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if Assigned(Frame1_1) then
     FreeAndNil(Frame1_1);
  if ListBox1.ItemIndex = -1 then Exit;
  Config.Objects['sessions'].Delete(
    ListBox1.Items[ListBox1.ItemIndex]
  );
  UpdateSessions;
  FileReader.Text := Config.FormatJSON;
  FileReader.SaveToFile('config.json');
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if Assigned(Frame1_1) then
     FreeAndNil(Frame1_1);
  Frame1_1 := TFrame2.Create(Panel4);
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
    Config.Add('sessions',TJSONObject.Create);
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

