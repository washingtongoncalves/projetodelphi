program PCliente;

uses
  Vcl.Forms,
  unCliente in 'unCliente.pas' {FRMPR101};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFRMPR101, FRMPR101);
  Application.Run;
end.
