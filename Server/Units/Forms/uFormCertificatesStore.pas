{******************************************************************************}
{                                                                              }
{         ____             _     ____          _           ____                }
{        |  _ \  __ _ _ __| | __/ ___|___   __| | ___ _ __/ ___|  ___          }
{        | | | |/ _` | '__| |/ / |   / _ \ / _` |/ _ \ '__\___ \ / __|         }
{        | |_| | (_| | |  |   <| |__| (_) | (_| |  __/ |   ___) | (__          }
{        |____/ \__,_|_|  |_|\_\\____\___/ \__,_|\___|_|  |____/ \___|         }
{                             Project: Optix Gate                              }
{                                                                              }
{                                                                              }
{                   Author: DarkCoderSc (Jean-Pierre LESUEUR)                  }
{                   https://www.twitter.com/darkcodersc                        }
{                   https://bsky.app/profile/darkcodersc.bsky.social           }
{                   https://github.com/darkcodersc                             }
{                   License: GPL v3                                            }
{                                                                              }
{                                                                              }
{                                                                              }
{  Disclaimer:                                                                 }
{  -----------                                                                 }
{    We are doing our best to prepare the content of this app and/or code.     }
{    However, The author cannot warranty the expressions and suggestions       }
{    of the contents, as well as its accuracy. In addition, to the extent      }
{    permitted by the law, author shall not be responsible for any losses      }
{    and/or damages due to the usage of the information on our app and/or      }
{    code.                                                                     }
{                                                                              }
{    By using our app and/or code, you hereby consent to our disclaimer        }
{    and agree to its terms.                                                   }
{                                                                              }
{    Any links contained in our app may lead to external sites are provided    }
{    for convenience only.                                                     }
{    Any information or statements that appeared in these sites or app or      }
{    files are not sponsored, endorsed, or otherwise approved by the author.   }
{    For these external sites, the author cannot be held liable for the        }
{    availability of, or the content located on or through it.                 }
{    Plus, any losses or damages occurred from using these contents or the     }
{    internet generally.                                                       }
{                                                                              }
{                                                                              }
{                                                                              }
{******************************************************************************}

unit uFormCertificatesStore;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL,
  VirtualTrees, Vcl.Menus, Optix.OpenSSL.Helper;

type
  TTreeData = record
    Certificate : TX509Certificate;
  end;
  PTreeData = ^TTreeData;

  TFormCertificatesStore = class(TForm)
    VST: TVirtualStringTree;
    MainMenu: TMainMenu;
    File1: TMenuItem;
    GeneratenewCertificate1: TMenuItem;
    ImportRecommended1: TMenuItem;
    procedure GeneratenewCertificate1Click(Sender: TObject);
    procedure VSTChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure VSTFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure VSTGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
    procedure VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: string);
    procedure VSTGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: TImageIndex);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    {@M}
    procedure RegisterCertificate(const ACertificate : TX509Certificate);
    procedure Save();
    procedure Load();
  public
    { Public declarations }
  end;

var
  FormCertificatesStore: TFormCertificatesStore;

implementation

uses uFormGenerateNewCertificate, Optix.OpenSSL.Headers, Optix.Helper, Optix.Constants, Optix.Config.CertificatesStore,
     Optix.Config.Helper;

{$R *.dfm}

procedure TFormCertificatesStore.Save();
begin
  var AConfig := TOptixConfigCertificatesStore.Create();
  try
    for var pNode in VST.Nodes do begin
      var pData := PTreeData(pNode.GetData);

      AConfig.Add(pData^.Certificate);
    end;
  finally
    CONFIG_HELPER.Write('Certificates', AConfig);

    ///
    FreeAndNil(AConfig);
  end;
end;

procedure TFormCertificatesStore.Load();
begin
  var AConfig := TOptixConfigCertificatesStore(CONFIG_HELPER.Read('Certificates'));
  if not Assigned(AConfig) then
    Exit();
  try
    VST.BeginUpdate();
    try
      for var I := 0 to AConfig.Count -1 do begin
        var ACertificate := AConfig.Items[I];

        if not Assigned(ACertificate.pX509) or not Assigned(ACertificate.pPrivKey) then
          continue;

        ///
        RegisterCertificate(ACertificate);
      end;
    finally
      VST.EndUpdate();
    end;
  finally
    FreeAndNil(AConfig);
  end;
end;

procedure TFormCertificatesStore.RegisterCertificate(const ACertificate : TX509Certificate);
begin
  VST.BeginUpdate();
  try
    var pNode := VST.AddChild(nil);
    var pData := PTreeData(pNode.GetData);

    pData^.Certificate := ACertificate;
  finally
    VST.EndUpdate();
  end;
end;

procedure TFormCertificatesStore.VSTChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  TVirtualStringTree(Sender).Refresh();
end;

procedure TFormCertificatesStore.VSTFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
begin
  TVirtualStringTree(Sender).Refresh();
end;

procedure TFormCertificatesStore.VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  var pData := PTreeData(Node.GetData);

  TOptixOpenSSLHelper.FreeCertificate(pData^.Certificate);
end;

procedure TFormCertificatesStore.VSTGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind;
  Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: TImageIndex);
begin
  var pData := PTreeData(Node.GetData);

  if Column <> 0 then
    Exit();

  case Kind of
    TVTImageKind.ikNormal, TVTImageKind.ikSelected :
      ImageIndex := IMAGE_CERTIFICATE;

    TVTImageKind.ikState: ;
    TVTImageKind.ikOverlay: ;
  end;
end;

procedure TFormCertificatesStore.VSTGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TTreeData);
end;

procedure TFormCertificatesStore.VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType; var CellText: string);
begin
  var pData := PTreeData(Node.GetData);

  CellText := '';

  case Column of
    0 : CellText := pData^.Certificate.C;
    1 : CellText := pData^.Certificate.O;
    2 : CellText := pData^.Certificate.CN;
    3 : CellText := pData^.Certificate.Fingerprint;
  end;

  ///
  CellText := DefaultIfEmpty(CellText);
end;

procedure TFormCertificatesStore.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Save();
end;

procedure TFormCertificatesStore.FormCreate(Sender: TObject);
begin
  Load();
end;

procedure TFormCertificatesStore.GeneratenewCertificate1Click(Sender: TObject);
begin
  var AForm := TFormGenerateNewCertificate.Create(self);
  try
    AForm.ShowModal();
    ///

    if AForm.Canceled then
      Exit();

    var ACertificate : TX509Certificate;
    Zeromemory(@ACertificate, SizeOf(TX509Certificate));
    try
      ACertificate.pPrivKey := TOptixOpenSSLHelper.NewPrivateKey();

      ACertificate.pX509 := TOptixOpenSSLHelper.NewX509(
        ACertificate.pPrivKey,
        AForm.EditC.Text,
        AForm.EditO.Text,
        AForm.EditCN.Text
      );

      TOptixOpenSSLHelper.RetrieveCertificateInformation(ACertificate);

      ///
      RegisterCertificate(ACertificate);
    except
      on E : Exception do begin
        TOptixOpenSSLHelper.FreeCertificate(ACertificate);
      end;
    end;
  finally
    FreeAndNil(AForm);
  end;
end;

end.
