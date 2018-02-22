unit test;

interface

uses
  Classes,
  TestFramework, uMailer;

type
  TTestOverbyteICS = class(TTestCase, IMailLogger)
  private
    FMailer: TMailer;
    {$REGION 'IMailLogger'}
    procedure Log(const AMsg: string);
    {$ENDREGION}
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestMemoryCorruptionWhenReconnectAfterAbort;
  end;

implementation

uses
  SysUtils,
  OverbyteICSSmtpProt;

{ TTestOverbyteICS }

procedure TTestOverbyteICS.Log(const AMsg: string);
begin
  Status(AMsg);
end;

procedure TTestOverbyteICS.SetUp;
begin
  inherited;
  FMailer := TMailer.Create(Self);
  FMailer.Host := GetEnvironmentVariable('SMTP_HOST');
  FMailer.Port := GetEnvironmentVariable('SMTP_PORT');
  FMailer.Username := GetEnvironmentVariable('SMTP_USER');
  FMailer.Password := GetEnvironmentVariable('SMTP_PASS');
  FMailer.FromName := GetEnvironmentVariable('SMTP_FROM');
  FMailer.RcptName.Add(GetEnvironmentVariable('SMTP_RECEPIENT'));
  FMailer.AuthType := smtpAuthNone;
  FMailer.Timeout := 5;
end;

procedure TTestOverbyteICS.TearDown;
begin
  FreeAndNil(FMailer);
  inherited;
end;

procedure TTestOverbyteICS.TestMemoryCorruptionWhenReconnectAfterAbort;
begin
  FMailer.TestConnectionAndAbort;
  CheckFalse(FMailer.MailSent, 'Mail must not be sent');
  FMailer.TestConnection;
  CheckTrue(FMailer.MailSent, 'Mail must be sent');
end;

initialization
  RegisterTest(TTestOverbyteICS.Suite);
end.
