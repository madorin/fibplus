{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  About dialog of the FIBPlus IDE tools.                       }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBAbout;

interface

uses
  System.Classes, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.ImageCollection, Vcl.VirtualImage;

type
  TFIBAboutForm = class(TForm)
    IconCollection: TImageCollection;
    IconImage: TVirtualImage;
    ProductLabel: TLabel;
    DescriptionLabel: TLabel;
    ProjectLink: TLinkLabel;
    SupportLink: TLinkLabel;
    OKButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure LinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
  end;

procedure ShowFIBAbout;

implementation

{$R *.dfm}

uses
  System.SysUtils, Winapi.Windows, Winapi.ShellAPI, FIB, FIBToolsConsts;

procedure TFIBAboutForm.FormCreate(Sender: TObject);
var
  Stream: TResourceStream;
  ResourceName: string;
begin
  Caption := SAboutCaption;
  ProductLabel.Caption := Format(SAboutProduct, [FIBVersionString]);
  DescriptionLabel.Caption := SAboutDescription;
  ProjectLink.Caption := Format('<a href="%s">%s</a>', [FIBProjectURL, SAboutProjectLink]);
  SupportLink.Caption := Format('<a href="%s">%s</a>', [FIBSupportURL, SAboutSupportLink]);
  OKButton.Caption := SOKButton;
  for ResourceName in ['FIB_ICON_128', 'FIB_ICON_256'] do
  begin
    Stream := TResourceStream.Create(HInstance, ResourceName, RT_RCDATA);
    try
      IconCollection.Add('Icon', Stream);
    finally
      Stream.Free;
    end;
  end;
  IconImage.ImageIndex := 0;
end;

procedure TFIBAboutForm.LinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
begin
  ShellExecute(0, 'open', PChar(Link), nil, nil, SW_SHOWNORMAL);
end;

procedure ShowFIBAbout;
var
  Form: TFIBAboutForm;
begin
  Form := TFIBAboutForm.Create(Application);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

end.
