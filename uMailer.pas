unit uMailer;

interface

uses
  Classes,
  OverbyteICSSmtpProt;

type
  IMailLogger = interface
    ['{DC8FE02F-41AB-4899-AE08-007BDF7D3F55}']
    procedure Log(const AMsg: string);
  end;

  TMailer = class(TSSlSmtpCli)
  private
    FMailSent: Boolean;
    FAbortAfterConnection: Boolean;
    FLogger: IMailLogger;
    procedure SmtpDisplay(Sender: TObject; Msg: string);
    procedure SmtpRequestDone(Sender: TObject; RqType: TSmtpRequest; ErrorCode: Word);
    procedure TestPortValue;
  public
    constructor Create(ALogger: IMailLogger); reintroduce;
    procedure BeforeDestruction; override;

    procedure TestConnectionAndAbort;
    procedure TestConnection;

    property MailSent: Boolean read FMailSent;
  end;

implementation

uses
  SysUtils, StrUtils, TypInfo;

{ TMailer }

procedure TMailer.BeforeDestruction;
begin
  FLogger := nil;
  inherited;
end;

constructor TMailer.Create(ALogger: IMailLogger);
begin
  inherited Create(nil);
  FMailSent := False;
  FAbortAfterConnection := False;
  OnDisplay := SmtpDisplay;
  OnCommand := SmtpDisplay;
  OnRequestDone := SmtpRequestDone;
  FLogger := ALogger;
end;

procedure TMailer.SmtpDisplay(Sender: TObject; Msg: string);
begin
  FLogger.Log(Msg);
  if FAbortAfterConnection and AnsiStartsText('DATA', Msg) then
  begin
    FLogger.Log('Aborting!');
    Abort;
  end;
end;

procedure TMailer.SmtpRequestDone(Sender: TObject; RqType: TSmtpRequest; ErrorCode: Word);
begin
  FLogger.Log(Format('Request done: %s: %d: %s',
    [GetEnumName(TypeInfo(TSmtpRequest), Ord(RqType)), FStatusCode, FLastResponse]));
  if ErrorCode = 0 then
  begin
    case RqType of
      smtpConnect:
        if AuthType = smtpAuthNone then
          Helo
        else
          Ehlo;
      smtpEhlo:
        Auth;
      smtpAuth, smtpHelo:
        Mail;
      smtpMail:
        FMailSent := True;
      smtpQuit:
        // do nothing;
    else
      Quit;
    end;
  end
  else if RqType <> smtpQuit then
    Quit;
end;

procedure TMailer.TestConnection;
begin
  TestPortValue;
  FMailSent := False;
  ConnectSync;
end;

procedure TMailer.TestConnectionAndAbort;
begin
  FAbortAfterConnection := True;
  try
    TestConnection;
  finally
    FAbortAfterConnection := False;
  end;
end;

procedure TMailer.TestPortValue;
begin
  if Port = EmptyStr then
    Port := '25';
end;

end.
