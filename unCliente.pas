unit unCliente;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.Mask, IdHTTP, IdSSLOpenSSL,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, System.JSON, XMLDoc, XMLIntf, IdMessage, IdExplicitTLSClientServerBase,
  IdMessageClient, IdSMTPBase, IdSMTP, IdText, IdAttachmentFile;

type
  TFRMPR101 = class(TForm)
    edNome: TEdit;
    Label1: TLabel;
    edEmail: TEdit;
    label5: TLabel;
    btnSalvar: TBitBtn;
    medCPF: TMaskEdit;
    Label3: TLabel;
    medTelefone: TMaskEdit;
    Label4: TLabel;
    medCEP: TMaskEdit;
    Label2: TLabel;
    IdHTTP1: TIdHTTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    Label6: TLabel;
    edLogradouro: TEdit;
    Label7: TLabel;
    edNumero: TEdit;
    Label8: TLabel;
    edComplemento: TEdit;
    Label9: TLabel;
    edBairro: TEdit;
    Label10: TLabel;
    edCidade: TEdit;
    Label11: TLabel;
    edEstado: TEdit;
    Label12: TLabel;
    edPais: TEdit;
    chkEnviaremail: TCheckBox;
    Label13: TLabel;
    edEmailorigem: TEdit;
    Label14: TLabel;
    edSenha: TEdit;
    Label15: TLabel;
    edEndereco: TEdit;
    Label17: TLabel;
    edPorta: TEdit;
    Label16: TLabel;
    edEmaildestino: TEdit;
    Label18: TLabel;
    edIdentidade: TEdit;
    procedure medCEPExit(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
     procedure Gerar_XML();
    function BuscarCEP(CEP  : string) : Boolean;
    function ValidaCEP(CEP  : string) : Boolean;
    function ValidarEmail() : Boolean;
    function ValidarDados() : Boolean;
    function EnviarEmail(const AEmitente, AAssunto, ADestino, AAnexo: String; ACorpo: TStrings): Boolean;

  end;

var
  FRMPR101: TFRMPR101;
  API : string;
  vCEP : string;
  vRetorno : Boolean;
  vMensagem : string;

implementation

{$R *.dfm}

{ TFRMPR101 }

procedure TFRMPR101.btnSalvarClick(Sender: TObject);
var
 vCorpoEmail : TStringList;
begin


   if ValidarDados() then
   begin
      Gerar_XML;

      ShowMessage('Dados Salvos com Sucesso !!! ') ;

      if chkEnviaremail.Checked then
      begin
          if ValidarEmail() then
          begin
            vCorpoEmail := TStringList.Create;
            vCorpoEmail.Clear;

            With vCorpoEmail do
            begin
               Add('Nome: '       + edNome.text);
               Add('Identidade: ' + edIdentidade.text);
               Add('CPF: '        + medCPF.text);
               Add('Telefone: '   + medTelefone.text);
               Add('E-mail: '     + edEmail.text);
               Add('CEP: '        + medCEP.text);
               Add('Logradouro: ' + edLogradouro.text);
               Add('N?mero: '     + edNumero.text);
               Add('Complemento: '+ edComplemento.text);
               Add('Bairro: '     + edBairro.text);
               Add('Cidade: '     + edCidade.text);
               Add('UF: '         + edEstado.text);
               Add('Pa?s: '       + edPais.text);
           end;


              if EnviarEmail('Cadastro de Cliente', 'Usu?rio teste', edEmaildestino.Text, ExtractFilePath(ParamStr(0)) + 'cliente.xml', vCorpoEmail ) then
                messagedlg('E-MAIL ENVIADO COM SUCESSO.', mtinformation, [mbok], 0)
              else
                messagedlg('N?O FOI POSS?VEL ENVIAR O E-MAIL.', mtwarning, [mbok], 0);
          end
          else
             messagedlg('Favor  preencher os dados do E-mail corretamente. ', mtwarning, [mbok], 0);
      end

   end
   else
     messagedlg('Favor  preencher os campos. ', mtwarning, [mbok], 0);
end;

function TFRMPR101.BuscarCEP(CEP: string): Boolean;
const
  INVALIDO = '{"erro":true}';
var
 vLista : TStringStream;
 JSONValue : TJSonValue;
 vLista_erro  : string;
 Response: TStringStream;
 vDadosJson : string;
begin
  vCEP := '';
  vLista_erro := '';
  vLista_erro := 'erro';
 // vDadosJson := '';

   IdHTTP1.Create();
   API := 'https://viacep.com.br/ws/';

   vCEP := StringReplace(CEP,'-','',[rfReplaceAll]);

   API := API + vCEP + '/json' ;

   //IdHTTP1.Get(API, Response);

   JSONValue := TJSonObject.ParseJSONValue(IdHTTP1.Get(API));

   vDadosJson :=  JSONValue.ToString;

   // N?o consegui testar o CEP inv?lido

  // ShowMessage(JSONValue.ToString) ;

//    if vDadosJson.Equals(INVALIDO) = True  then
//    begin
//      ShowMessage('CEP Inv?lido');
//      medCEP.SetFocus;
//    end
//    else
//       begin
          edLogradouro.Text := JsonValue.GetValue<string>('logradouro');
          edComplemento.Text := JsonValue.GetValue<string>('complemento');
          edBairro.Text := JsonValue.GetValue<string>('bairro');
          edCidade.Text := JsonValue.GetValue<string>('localidade');
          edEstado.Text := JSONValue.GetValue<string>('uf');
          edPais.Text := 'Brasil';
//       end;
end;

function TFRMPR101.EnviarEmail(const AEmitente, AAssunto, ADestino,
  AAnexo: String; ACorpo: TStrings): Boolean;
var
  idMsg                : TIdMessage;
  idText               : TIdText;
  idSMTP               : TIdSMTP;
  idSSLIOHandlerSocket : TIdSSLIOHandlerSocketOpenSSL;
begin
  try
    try
      //Configura os par?metros necess?rios para SSL
      IdSSLIOHandlerSocket                   := TIdSSLIOHandlerSocketOpenSSL.Create(Self);
      IdSSLIOHandlerSocket.SSLOptions.Method := sslvSSLv23;
      IdSSLIOHandlerSocket.SSLOptions.Mode  := sslmClient;
      //Vari?vel referente a mensagem
      idMsg                            := TIdMessage.Create(Self);
      idMsg.CharSet                    := 'utf-8';
      idMsg.Encoding                   := meMIME;
      idMsg.From.Name                  := AEmitente;
      idMsg.From.Address               := edEmailorigem.text;
      idMsg.Priority                   := mpNormal;
      idMsg.Subject                    := AAssunto;
      //Add Destinat?rio(s)
      idMsg.Recipients.Add;
      idMsg.Recipients.EMailAddresses := ADestino;
      idMsg.CCList.EMailAddresses      := 'hacson25@hotmail.com';
      //Vari?vel do texto
      idText := TIdText.Create(idMsg.MessageParts);
      idText.Body.Add(ACorpo.Text);
      idText.ContentType := 'text/html; text/plain; charset=iso-8859-1';
      //Prepara o Servidor
      idSMTP                           := TIdSMTP.Create(Self);
      idSMTP.IOHandler                 := IdSSLIOHandlerSocket;
     // idSMTP.UseTLS                    := utUseImplicitTLS;
      idSMTP.AuthType                  := satDefault;
      idSMTP.Host                      := edEndereco.text;
      idSMTP.AuthType                  := satDefault;
      idSMTP.Port                      := strtoint(edPorta.text);
      idSMTP.Username                  := edEmailorigem.text;
      idSMTP.Password                  := edSenha.text;
      idSMTP.UseTLS := utUseExplicitTLS;

      //Conecta e Autentica
      idSMTP.Connect;
      idSMTP.Authenticate;
      if AAnexo <> EmptyStr then
        if FileExists(AAnexo) then
          TIdAttachmentFile.Create(idMsg.MessageParts, AAnexo);
      //Se a conex?o foi bem sucedida, envia a mensagem
      if idSMTP.Connected then
      begin
        try
          IdSMTP.Send(idMsg);
        except on E:Exception do
          begin
            ShowMessage('Erro ao tentar enviar: ' + E.Message);
          end;
        end;
      end;
      //Depois de tudo pronto, desconecta do servidor SMTP
      if idSMTP.Connected then
        idSMTP.Disconnect;
      Result := True;
    finally
      UnLoadOpenSSLLibrary;
      FreeAndNil(idMsg);
      FreeAndNil(idSSLIOHandlerSocket);
      FreeAndNil(idSMTP);
    end;
  except on e:Exception do
    begin
      Result := False;
    end;
  end;

end;

procedure TFRMPR101.Gerar_XML;
var
  XMLDoc: TXMLDocument;
  DadosCliente, DadosEndereco: IXMLNode;
begin
  XMLDoc := TXMLDocument.Create(Self);
  try
    XMLDoc.Active := True;

    DadosCliente := XMLDoc.AddChild('Cliente');
    DadosCliente.ChildValues['Nome']       := edNome.Text;
    DadosCliente.ChildValues['Identidade'] := edIdentidade.Text;
    DadosCliente.ChildValues['CPF']        := medCPF.Text;
    DadosCliente.ChildValues['Telefone']   := medTelefone.Text;
    DadosCliente.ChildValues['Email']      := edEmail.Text;

    DadosEndereco := DadosCliente.AddChild('Endereco');
    DadosEndereco.ChildValues['CEP']         := medCEP.Text;
    DadosEndereco.ChildValues['Logradouro']  := edLogradouro.Text;
    DadosEndereco.ChildValues['Numero']      := edNumero.Text;
    DadosEndereco.ChildValues['Complemento'] := edComplemento.Text;
    DadosEndereco.ChildValues['Bairro']      := edBairro.Text;
    DadosEndereco.ChildValues['Cidade']      := edCidade.Text;
    DadosEndereco.ChildValues['UF']          := edEstado.Text;
    DadosEndereco.ChildValues['Pais']        := edPais.Text;

    XMLDoc.SaveToFile(ExtractFilePath(ParamStr(0)) + 'cliente.xml');
  finally
    XMLDoc.Free;
  end;

end;

procedure TFRMPR101.medCEPExit(Sender: TObject);
begin
    if ValidaCEP(medCEP.Text) = false  then
    Begin
      ShowMessage(vMensagem)
    End
    else
      begin
        BuscarCEP(medCEP.Text);
      end;
end;

function TFRMPR101.ValidaCEP(CEP: string): Boolean;
begin
  vCEP := '';
  vRetorno := True;
  vMensagem := '';


  vCEP := StringReplace(CEP,'-','',[rfReplaceAll]);

   if vCEP.Length <> 8  then
   begin
      vRetorno := False;
      vMensagem := vMensagem + 'CEP Inv?lido';
   end;

   Result :=  vRetorno;

end;

function TFRMPR101.ValidarDados: Boolean;
begin
    vRetorno := true;

  if length( edNome.text ) < 10 then
     vRetorno := false;
  if length( edIdentidade.Text) < 4 then
     vRetorno := false;
  if length( medCPF.Text ) < 11 then
      vRetorno := false;
  if length( medTelefone.Text ) < 10 then
     vRetorno := false;
  if length( medCEP.Text ) <> 8 then
     vRetorno := false;

   Result := vRetorno;
end;

function TFRMPR101.ValidarEmail: Boolean;
begin
  vRetorno := True;

  if length ( edEndereco.Text ) < 10 then
    vRetorno := false;
  if trim( edporta.text ) = '' then
    vRetorno := false;
  if length( edEmailorigem .text ) < 10 then
    vRetorno := false;
  if length( edsenha.text ) < 2 then
    vRetorno := false;
  if length( edEmaildestino.Text ) < 5 then
    vRetorno := false;

  Result := vRetorno;

end;

end.
