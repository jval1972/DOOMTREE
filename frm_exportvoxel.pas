//------------------------------------------------------------------------------
//
//  DOOMTREE: Doom Tree Sprite Generator
//  Copyright (C) 2021-2022 by Jim Valavanis
//
// DESCRIPTION:
//  Export Voxel Form
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : https://sourceforge.net/projects/doom-tree/
//------------------------------------------------------------------------------

unit frm_exportvoxel;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Buttons, proctree, dt_voxels;

type
  TExportVoxelForm = class(TForm)
    BottomPanel: TPanel;
    ButtonPanel: TPanel;
    OKButton1: TButton;
    CancelButton1: TButton;
    MainPanel: TPanel;
    PreviewGroupBox: TGroupBox;
    Image1: TImage;
    Panel1: TPanel;
    Bevel2: TBevel;
    Label3: TLabel;
    FileNameEdit: TEdit;
    SelectFileButton: TSpeedButton;
    SaveVoxelDialog: TSaveDialog;
    SizeRadioGroup: TRadioGroup;
    PatchRadioGroup: TRadioGroup;
    frontSpeedButton: TSpeedButton;
    backSpeedButton: TSpeedButton;
    leftSpeedButton: TSpeedButton;
    rightSpeedButton: TSpeedButton;
    topSpeedButton: TSpeedButton;
    bottomSpeedButton: TSpeedButton;
    PalettePanel: TPanel;
    Label1: TLabel;
    SelectPaletteButton: TSpeedButton;
    PaletteNameEdit: TEdit;
    OpenPaletteDialog: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FileNameEditChange(Sender: TObject);
    procedure SelectFileButtonClick(Sender: TObject);
    procedure SizeRadioGroupClick(Sender: TObject);
    procedure SpeedButtonClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PatchRadioGroupClick(Sender: TObject);
    procedure SelectPaletteButtonClick(Sender: TObject);
  private
    { Private declarations }
  protected
    tree: tree_t;
    twigtex, trunktex: TBitmap;
    vox: voxelbuffer_p;
    procedure UpdateControls;
    procedure CreateVoxel;
  public
    { Public declarations }
    voxsize: integer;
    procedure SetTreeVoxelParams(const atree: tree_t; const avox: voxelbuffer_p;
      atwigtex, atrunktex: TBitmap);
  end;

implementation

{$R *.dfm}

uses
  dt_defs,
  dt_utils,
  dt_voxelexport;

procedure TExportVoxelForm.FormCreate(Sender: TObject);
var
  i: integer;
begin
  tree := nil;
  twigtex := nil;
  trunktex := nil;
  vox := nil;

  DoubleBuffered := True;
  for i := 0 to ComponentCount - 1 do
    if Components[i].InheritsFrom(TWinControl) then
      if not (Components[i] is TListBox) then
        (Components[i] as TWinControl).DoubleBuffered := True;

  Image1.Picture.Bitmap.PixelFormat := pf32bit;

  voxsize := opt_voxsize;
  if voxsize <> 32 then
    if voxsize <> 64 then
      if voxsize <> 128 then
        if voxsize <> 256 then
          voxsize := 128;

  if voxsize = 32 then
    SizeRadioGroup.ItemIndex := 0
  else if voxsize = 64 then
    SizeRadioGroup.ItemIndex := 1
  else if voxsize = 128 then
    SizeRadioGroup.ItemIndex := 2
  else
    SizeRadioGroup.ItemIndex := 3;

  if opt_voxpal in [0..5] then
    PatchRadioGroup.ItemIndex := opt_voxpal
  else
    PatchRadioGroup.ItemIndex := 0;

  PalettePanel.Visible := (PatchRadioGroup.ItemIndex = 5) and (PatchRadioGroup.Visible);
  PaletteNameEdit.Text := bigstringtostring(@opt_customvoxelpalette);
end;

procedure TExportVoxelForm.SetTreeVoxelParams(const atree: tree_t; const avox: voxelbuffer_p;
  atwigtex, atrunktex: TBitmap);
begin
  tree := atree;
  vox  := avox;
  twigtex := atwigtex;
  trunktex := atrunktex;
  CreateVoxel;
  UpdateControls;
end;

procedure TExportVoxelForm.CreateVoxel;
begin
  if (tree = nil) or (vox = nil) or (trunktex = nil) or (twigtex = nil) then
    Exit;

  Screen.Cursor := crHourglass;
  try
    case SizeRadioGroup.ItemIndex of
    0: voxsize := 32;
    1: voxsize := 64;
    2: voxsize := 128;
    else
      voxsize := 256;
    end;
    DT_CreateVoxelFromTree(tree, vox, voxsize, trunktex, twigtex);
  finally
    Screen.Cursor := crDefault;
  end;
end;

function RGBSwap(const l: LongWord): LongWord;
var
  A: packed array[0..3] of byte;
  tmp: byte;
begin
  PLongWord(@A)^ := l;
  tmp := A[0];
  A[0] := A[2];
  A[2] := tmp;
  Result := PLongWord(@A)^;
end;

procedure TExportVoxelForm.UpdateControls;
var
  b, b2: TBitmap;
  buf2d: voxelbuffer2d_t;
  v: voxelview_t;
  x, y: integer;
  ln: PLongWordArray;
begin
  if (tree = nil) or (vox = nil) or (trunktex = nil) or (twigtex = nil) then
    Exit;

  b := TBitmap.Create;
  try
    b.Width := 256;
    b.Height := 256;
    b.PixelFormat := pf32bit;
    b.Canvas.Brush.Style := bsSolid;
    b.Canvas.Brush.Color := clBlack;
    b.Canvas.Pen.Style := psSolid;
    b.Canvas.Pen.Color := clBlack;
    b.Canvas.FillRect(Rect(0, 0, 256, 256));

    if frontSpeedButton.Down then
      v := vv_front
    else if backSpeedButton.Down then
      v := vv_back
    else if leftSpeedButton.Down then
      v := vv_left
    else if rightSpeedButton.Down then
      v := vv_right
    else if topSpeedButton.Down then
      v := vv_top
    else if bottomSpeedButton.Down then
      v := vv_down
    else
      v := vv_none;
    case SizeRadioGroup.ItemIndex of
    0: voxsize := 32;
    1: voxsize := 64;
    2: voxsize := 128;
    else
      voxsize := 256;
    end;
    vox_getviewbuffer(vox, voxsize, @buf2d, v);

    b2 := TBitmap.Create;
    try
      b2.Width := voxsize;
      b2.Height := voxsize;
      b2.PixelFormat := pf32bit;
      for y := 0 to b2.Height - 1 do
      begin
        ln := b2.ScanLine[y];
        for x := 0 to b2.Width - 1 do
          ln[x] := RGBSwap(buf2d[x, y]);
      end;

      b.Canvas.StretchDraw(Rect(0, 0, 256, 256), b2);
      Image1.Picture.Bitmap.Canvas.Draw(0, 0, b);
    finally
      b2.Free;
    end;

    Image1.Invalidate;
  finally
    b.Free;
  end;
end;

procedure TExportVoxelForm.FormShow(Sender: TObject);
begin
  UpdateControls;
end;

procedure TExportVoxelForm.FileNameEditChange(Sender: TObject);
var
  uName, uExt: string;
  e: boolean;
begin
  uName := Trim(FileNameEdit.Text);
  e := uName <> '';
  if e then
  begin
    uExt := UpperCase(ExtractFileExt(uName));
    e := (uExt = '.DDVOX') or (uExt = '.VOX');
    PatchRadioGroup.Visible := uExt = '.VOX';
    PalettePanel.Visible := (PatchRadioGroup.ItemIndex = 5) and (PatchRadioGroup.Visible);
  end;
  OKButton1.Enabled := e;
end;

procedure TExportVoxelForm.SelectFileButtonClick(Sender: TObject);
begin
  if SaveVoxelDialog.Execute then
  begin
    FileNameEdit.Text := SaveVoxelDialog.FileName;
    OKButton1.Enabled := True;
  end;
end;

procedure TExportVoxelForm.SizeRadioGroupClick(Sender: TObject);
begin
  CreateVoxel;
  UpdateControls;
end;

procedure TExportVoxelForm.SpeedButtonClick(Sender: TObject);
begin
  UpdateControls;
end;

procedure TExportVoxelForm.FormDestroy(Sender: TObject);
begin
  opt_voxsize := voxsize;
  opt_voxpal := PatchRadioGroup.ItemIndex;
  stringtobigstring(PaletteNameEdit.Text, @opt_customvoxelpalette);
end;

procedure TExportVoxelForm.PatchRadioGroupClick(Sender: TObject);
begin
  PalettePanel.Visible := PatchRadioGroup.ItemIndex = 5;
end;

procedure TExportVoxelForm.SelectPaletteButtonClick(Sender: TObject);
begin
  if OpenPaletteDialog.Execute then
    PaletteNameEdit.Text := OpenPaletteDialog.FileName;
end;

end.

