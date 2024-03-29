//------------------------------------------------------------------------------
//
//  DOOMTREE: Doom Tree Sprite Generator
//  Copyright (C) 2021-2022 by Jim Valavanis
//
// DESCRIPTION:
//  Utility functions
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : https://sourceforge.net/projects/doom-tree/
//------------------------------------------------------------------------------

unit proctree_helpers;

interface

uses
  Classes, proctree;

procedure PT_SavePropertiesBinary(const p: properties_t; const s: TStream);

procedure PT_LoadPropertiesBinary(const p: properties_t; const s: TStream);

procedure PT_SaveTreeToObj(const t: tree_t; const s: TStream);

implementation

uses
  SysUtils;

procedure PT_SavePropertiesBinary(const p: properties_t; const s: TStream);
begin
  with p do
  begin
    s.Write(mClumpMax, SizeOf(single));
    s.Write(mClumpMin, SizeOf(single));
    s.Write(mLengthFalloffFactor, SizeOf(single));
    s.Write(mLengthFalloffPower, SizeOf(single));
    s.Write(mBranchFactor, SizeOf(single));
    s.Write(mRadiusFalloffRate, SizeOf(single));
    s.Write(mClimbRate, SizeOf(single));
    s.Write(mTrunkKink, SizeOf(single));
    s.Write(mMaxRadius, SizeOf(single));
    s.Write(mTreeSteps, SizeOf(integer));
    s.Write(mTaperRate, SizeOf(single));
    s.Write(mTwistRate, SizeOf(single));
    s.Write(mSegments, SizeOf(integer));
    s.Write(mLevels, SizeOf(integer));
    s.Write(mSweepAmount, SizeOf(single));
    s.Write(mInitialBranchLength, SizeOf(single));
    s.Write(mTrunkLength, SizeOf(single));
    s.Write(mDropAmount, SizeOf(single));
    s.Write(mGrowAmount, SizeOf(single));
    s.Write(mVMultiplier, SizeOf(single));
    s.Write(mTwigScale, SizeOf(single));
    s.Write(mSeed, SizeOf(integer));
    s.Write(mRseed, SizeOf(integer));
  end;
end;

procedure PT_LoadPropertiesBinary(const p: properties_t; const s: TStream);
begin
  with p do
  begin
    s.Read(mClumpMax, SizeOf(single));
    s.Read(mClumpMin, SizeOf(single));
    s.Read(mLengthFalloffFactor, SizeOf(single));
    s.Read(mLengthFalloffPower, SizeOf(single));
    s.Read(mBranchFactor, SizeOf(single));
    s.Read(mRadiusFalloffRate, SizeOf(single));
    s.Read(mClimbRate, SizeOf(single));
    s.Read(mTrunkKink, SizeOf(single));
    s.Read(mMaxRadius, SizeOf(single));
    s.Read(mTreeSteps, SizeOf(integer));
    s.Read(mTaperRate, SizeOf(single));
    s.Read(mTwistRate, SizeOf(single));
    s.Read(mSegments, SizeOf(integer));
    s.Read(mLevels, SizeOf(integer));
    s.Read(mSweepAmount, SizeOf(single));
    s.Read(mInitialBranchLength, SizeOf(single));
    s.Read(mTrunkLength, SizeOf(single));
    s.Read(mDropAmount, SizeOf(single));
    s.Read(mGrowAmount, SizeOf(single));
    s.Read(mVMultiplier, SizeOf(single));
    s.Read(mTwigScale, SizeOf(single));
    s.Read(mSeed, SizeOf(integer));
    s.Read(mRseed, SizeOf(integer));
  end;
end;

procedure PT_SaveTreeToObj(const t: tree_t; const s: TStream);
var
  i: integer;
  a, b, c: integer;
  buf: string;

  function F2S(const f: single): string;
  var
    x: integer;
  begin
    Result := Format('%1.16f', [f]);
    for x := 1 to Length(Result) do
      if (Result[x] = ',') or (Result[x] = DecimalSeparator) then
        Result[x] := '.';
  end;

  procedure Add(const s: string);
  begin
    buf := buf + s;
  end;

begin
  buf := '';

  Add('mtllib tree.mtl'#13#10);
  for i := 0 to t.mVertCount - 1 do
    Add('v ' + F2S(t.mVert[i].x) + ' ' + F2S(t.mVert[i].y) + ' ' +  F2S(t.mVert[i].z) + #13#10);

  for i := 0 to t.mTwigVertCount - 1 do
    Add('v ' + F2S(t.mTwigVert[i].x) + ' ' + F2S(t.mTwigVert[i].y) + ' ' + F2S(t.mTwigVert[i].z) + #13#10);

  for i := 0 to t.mVertCount - 1 do
    Add('vn ' + F2S(t.mNormal[i].x) + ' ' +  F2S(t.mNormal[i].y) + ' ' + F2S(t.mNormal[i].z) + #13#10);

  for i := 0 to t.mTwigVertCount - 1 do
    Add('vn ' + F2S(t.mTwigNormal[i].x) + ' ' + F2S(t.mTwigNormal[i].y) + ' ' + F2S(t.mTwigNormal[i].z) + #13#10);

  for i := 0 to t.mVertCount - 1 do
    Add('vt ' + F2S(t.mUV[i].u) + ' ' + F2S(t.mUV[i].v) + #13#10);

  for i := 0 to t.mTwigVertCount - 1 do
    Add('vt ' + F2S(t.mTwigUV[i].u) + ' ' + F2S(t.mTwigUV[i].v) + #13#10);

  Add('g tree\nusemtl tree'#13#10);
  for i := 0 to t.mFaceCount - 1 do
  begin
    a := t.mFace[i].x + 1;
    b := t.mFace[i].y + 1;
    c := t.mFace[i].z + 1;
    Add(Format('f %d/%d/%d %d/%d/%d %d/%d/%d'#13#10, [a, a, a, b, b, b, c, c, c]));
  end;

  Add('g twig\nusemtl twig'#13#10);
  for i := 0 to t.mTwigFaceCount - 1 do
  begin
    a := t.mTwigFace[i].x + t.mVertCount + 1;
    b := t.mTwigFace[i].y + t.mVertCount + 1;
    c := t.mTwigFace[i].z + t.mVertCount + 1;
    Add(Format('f %d/%d/%d %d/%d/%d %d/%d/%d'#13#10, [a, a, a, b, b, b, c, c, c]));
  end;

  for i := 1 to Length(buf) do
    s.Write(buf[i], SizeOf(char));
end;

end.
