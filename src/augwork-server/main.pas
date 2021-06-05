unit main;

interface

uses
  Classes, sysutils, blcksock, fgl, Process, jsonparser, fpjson, BaseUnix, md5;

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

procedure HandleSigInt(aSignal: LongInt); cdecl;

var
  UsedPorts: TIntegerList;
  UsersThreads: TUsersThreads;
  UsersConfig, Config: TJSONObject;
  ListenSocket, ClientSocket: TTCPBlockSocket;

implementation

procedure HandleSigInt(aSignal: LongInt); cdecl;
begin
  WriteLn('Handle SigInt');
  ListenSocket.CloseSocket;
  ClientSocket.CloseSocket;
  Halt(1);
end;

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
  AProcess.Executable := '/bin/bash';
  AProcess.Parameters.AddStrings(
    ['../scripts/start_docker.sh', UserInfo.Login, IntToStr(UserInfo.Port), UserInfo.Resolution]);
  AProcess.Options := [poUsePipes, poStderrToOutPut];
  AProcess.Execute;

  while True do
  begin
    if Terminated then
    begin
      RunCommand('/usr/bin/pkill',['-P',IntToStr(AProcess.ProcessID)],LStdOut);
      Exit;
    end;
    Sleep(250);
  end;
  Free;
end;

var
  User: TUserInfo;
  Data, Salt, Login, Password: String;
  Query, Response: TJSONObject;
  I: Integer;
  FileReader: TStringList;
  ExistsSession: Boolean;

initialization
begin
  FpSignal(SigInt, @HandleSigInt);

  FileReader := TStringList.Create;
  UsedPorts := TIntegerList.Create;
  UsersThreads := TUsersThreads.Create;
  ClientSocket := TTCPBlockSocket.Create;
  ExistsSession := False;

  if not FileExists('config.json') then
  begin
    WriteLn('Config file dont exists');
    Exit;
  end;

  FileReader.LoadFromFile('config.json');
  Config := TJSONObject(GetJSON(FileReader.Text));
  Salt := Config.Strings['salt'];

  if not FileExists('users_data.json') then
  begin
    FileReader.Text := '{}';
    FileReader.SaveToFile('users_data.json');
  end;
  FileReader.LoadFromFile('users_data.json');
  UsersConfig := TJSONObject(GetJSON(FileReader.Text));

  if ParamStr(1) = 'useradd' then
  begin
    if ParamCount <> 3 then
    begin
      WriteLn('Wrong arguments');
      Exit;
    end;

    Login := LowerCase(ParamStr(2));
    Password := ParamStr(3);

    if UsersConfig.IndexOfName(Login) <> -1 then
    begin
      WriteLn('This user already exists');
      Exit;
    end;

    UsersConfig.Add(Login, TJSONObject.Create);
    UsersConfig.Objects[Login].Add(
      'password', MD5Print(MD5String(Password+Salt))
    );
    FileReader.Text := UsersConfig.FormatJSON;
    FileReader.SaveToFile('users_data.json');
    WriteLn('User ',Login,' was added');
    Exit;
  end;

  ListenSocket := TTCPBlockSocket.Create;
  ListenSocket.CreateSocket;
  ListenSocket.Bind('0.0.0.0',Config.Strings['port']);
  if ListenSocket.LastError <> 0 then
  begin
    WriteLn('Error binding port');
    Exit;
  end;

  ListenSocket.Listen;
  WriteLn('Listen connections...');

  while True do
  begin
    try
    if ListenSocket.CanRead(1000) then
    begin
      ClientSocket.Socket := ListenSocket.Accept;
      WriteLn('Incoming connection: ',ClientSocket.GetRemoteSinIP,':',ClientSocket.GetRemoteSinPort);
      while True do
      begin
        Data := ClientSocket.RecvString(16000);
        WriteLn('Client message: ',Data);
        if Data = '' then begin
          Writeln('Client exit');
          ClientSocket.CloseSocket;
          Break;
        end;
        Query := TJSONObject(GetJSON(Data));
        WriteLn(Query.FormatJSON());

        if Query.Strings['method'] = 'killall' then
        begin
          for I:=0 to UsersThreads.Count-1 do
          begin
            WriteLn('Killing '+UsersThreads.Data[i].Login);
            UsersThreads.Data[i].Thread.Terminate;
          end;
        end;

        if Query.Strings['method'] = 'login' then
        begin
          if UsersConfig.IndexOfName(Query.Strings['login']) = -1 then
          begin
            ClientSocket.SendString('{"error":"This user dont exists"}'+CRLF);
            Writeln('Client exit');
            ClientSocket.CloseSocket;
          end else
          if UsersConfig.Objects[Query.Strings['login']].Strings['password'] =
             MD5Print(MD5String(Query.Strings['password']+Salt)) then
          begin
            if UsersThreads.IndexOf(Query.Strings['login']) <> -1 then
            begin
              WriteLn('Killing exists session');
              User := UsersThreads.KeyData[Query.Strings['login']];
              User.Thread.Terminate;
              UsedPorts.Remove(User.Port);
              UsersThreads.Remove(User.Login);
              FreeAndNil(User);
              ExistsSession := True;
            end;

            User := TUserInfo.Create;
            User.Login := LowerCase(Query.Strings['login']);
            User.Password := Query.Strings['password'];
            User.Resolution := Query.Strings['resolution'];
            User.Port := GeneratePort;
            User.Thread := TDockerThread.Create(User);
            User.Thread.Start;

            UsersThreads.Add(User.Login, User);

            Response := TJSONObject.Create;
            Response.Add('host', Config.Strings['host']);
            Response.Add('port', User.Port);
            Response.Add('password', User.Password);
            Response.Add('exists_session', ExistsSession);

            ClientSocket.SendString(Response.AsJSON+CRLF);
            Writeln('Client exit');
            ClientSocket.CloseSocket;
            ExistsSession := False;
          end
          else
          begin
            WriteLn('Wrong password on user "',Query.Strings['login'],
                    '" from IP: ',ClientSocket.GetRemoteSinIP);
            ClientSocket.SendString('{"error":"Wrong password"}'+CRLF);
            ClientSocket.CloseSocket;
          end;
        end;

        ClientSocket.CloseSocket;
      end;
    end;
    except
      on E: Exception do
      begin
        WriteLn('Client exit');
        WriteLn('Error: '+ E.ClassName + #13#10 + E.Message);
        ClientSocket.CloseSocket;
      end;
    end;
  end;

end;

end.
