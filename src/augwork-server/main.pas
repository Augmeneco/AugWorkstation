unit main;

interface

uses
  Classes, sysutils, blcksock, fgl, Process, jsonparser, fpjson;

type TIntegerList = specialize TFPGList<Integer>;

type TUserInfo = class;

type
  TDockerThread = class(TThread)
  protected
    UserInfo: TUserInfo;
    procedure Execute; override;
  public
    constructor Create(AUserInfo: TUserInfo);
end;

type
  TUserInfo = class
    Login: String;
    Password: String;
    Resolution: String;
    Port: Integer;
    Thread: TDockerThread;
end;

type TUsersThreads = specialize TFPGMap<String, TUserInfo>;

function GeneratePort: Integer;

var
  UsedPorts: TIntegerList;
  UsersThreads: TUsersThreads;

implementation

function GeneratePort: Integer;
var
  Port: Integer;
begin
  for Port:=5901 to 5999 do
    if UsedPorts.IndexOf(Port) = -1 then
    begin
      UsedPorts.Add(Port);
      Result := Port;
      Exit;
    end;
  WriteLn('No ports available');
end;

constructor TDockerThread.Create(AUserInfo: TUserInfo);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  UserInfo := AUserInfo;
end;

procedure TDockerThread.Execute;
var
  AProcess: TProcess;
  LStdOut: String;
begin
  if not DirectoryExists('../../home/'+UserInfo.Login) then
    RunCommand('/bin/bash',
      ['../scripts/install_home.sh',UserInfo.Login,UserInfo.Password],LStdOut);

  AProcess := TProcess.Create(nil);
  AProcess.Executable:= '/bin/bash';
  AProcess.Parameters.AddStrings(
    ['../scripts/start_docker.sh', UserInfo.Login, IntToStr(UserInfo.Port), UserInfo.Resolution]);
  AProcess.Options := [poUsePipes, poStderrToOutPut];
  AProcess.Execute;

  while True do
  begin
    if Terminated then
    begin
      AProcess.Terminate(0);
      Exit;
    end;
    Sleep(250);
  end;
  Free;
end;

var
  User: TUserInfo;
  ListenSocket, ClientSocket: TTCPBlockSocket;
  Data: String;
  Query, Response: TJSONObject;

begin
  UsedPorts := TIntegerList.Create;
  UsersThreads := TUsersThreads.Create;
  ClientSocket := TTCPBlockSocket.Create;

  ListenSocket := TTCPBlockSocket.Create;
  ListenSocket.CreateSocket;
  ListenSocket.Bind('0.0.0.0','5900');
  if ListenSocket.LastError <> 0 then
  begin
    WriteLn('Error binding port');
    Exit;
  end;

  ListenSocket.Listen;
  WriteLn('Listen connections...');

  while True do
  begin
    if ListenSocket.CanRead(1000) then
    begin
      ClientSocket.Socket := ListenSocket.Accept;
      WriteLn('Incoming connection: ',ClientSocket.GetRemoteSinIP,':',ClientSocket.GetRemoteSinPort);
      while True do
      begin
        Data := ClientSocket.RecvString(16000);
        if Data = '' then begin
          Writeln('Client exit');
          Break;
        end;
        Query := TJSONObject(GetJSON(Data));
        WriteLn(Query.FormatJSON());
        if Query.Strings['method'] = 'login' then
        begin
          if True then
          begin
            if UsersThreads.IndexOf(Query.Strings['login']) <> -1 then
            begin
              User := UsersThreads.KeyData[Query.Strings['login']];
              User.Thread.Terminate;
              UsedPorts.Remove(User.Port);
              UsersThreads.Remove(User.Login);
              FreeAndNil(User);
            end;

            User := TUserInfo.Create;
            User.Login := Query.Strings['login'];
            User.Password := Query.Strings['password'];
            User.Resolution := Query.Strings['resolution'];
            User.Port := GeneratePort;
            User.Thread := TDockerThread.Create(User);
            User.Thread.Start;

            UsersThreads.Add(User.Login, User);

            Response := TJSONObject.Create;
            Response.Add('host', 'cha14ka.tk');
            Response.Add('port', User.Port);
            Response.Add('password', User.Password);

            ClientSocket.SendString(Response.AsJSON+CRLF);
            ClientSocket.CloseSocket;
          end;
        end;

      end;
    end;
  end;
end.












