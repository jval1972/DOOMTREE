//------------------------------------------------------------------------------
//
//  DOOMTREE: Doom Tree Sprite Generator
//  Copyright (C) 2021-2022 by Jim Valavanis
//
// DESCRIPTION:
//  OpenGL Rendering
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : https://sourceforge.net/projects/doom-tree/
//------------------------------------------------------------------------------

unit dt_gl;

interface

uses
  Windows,
  Graphics,
  dglOpenGL,
  proctree;

var
  gld_max_texturesize: integer = 0;
  gl_tex_format: integer = GL_RGBA8;
  gl_tex_filter: integer = GL_LINEAR;

procedure glInit;

procedure ResetCamera;

procedure glBeginScene(const Width, Height: integer);
procedure glEndScene(dc: HDC);
procedure glRenderEnviroment;
procedure glRenderTree(const t: tree_t);

type
  TCDCamera = record
    x, y, z: glfloat;
    ax, ay, az: glfloat;
  end;

var
  camera: TCDCamera;

var
  pt_rendredtriangles: integer = 0;

var
  trunktexture: TGLuint = 0;
  twigtexture: TGLuint = 0;

function gld_CreateTexture(const pic: TPicture; const transparent: boolean): TGLUint;

implementation

uses
  SysUtils,
  Classes,
  Math,
  dt_utils,
  dt_defs;

procedure ResetCamera;
begin
  camera.x := 0.0;
  camera.y := -3.0;
  camera.z := -6.0;
  camera.ax := 0.0;
  camera.ay := 0.0;
  camera.az := 0.0;
end;


{------------------------------------------------------------------}
{  Initialise OpenGL                                               }
{------------------------------------------------------------------}
procedure glInit;
begin
  glClearColor(0.0, 0.0, 0.0, 0.0);   // Black Background
  glShadeModel(GL_SMOOTH);            // Enables Smooth Color Shading
  glClearDepth(1.0);                  // Depth Buffer Setup
  glEnable(GL_DEPTH_TEST);            // Enable Depth Buffer
  glDepthFunc(GL_LESS);		            // The Type Of Depth Test To Do
  glEnable(GL_POINT_SIZE);

  glGetIntegerv(GL_MAX_TEXTURE_SIZE, @gld_max_texturesize);

  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);   //Realy Nice perspective calculations
  glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
  glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
  glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
end;

procedure infinitePerspective(fovy: GLdouble; aspect: GLdouble; znear: GLdouble);
var
  left, right, bottom, top: GLdouble;
  m: array[0..15] of GLdouble;
begin
  top := znear * tan(fovy * pi / 360.0);
  bottom := -top;
  left := bottom * aspect;
  right := top * aspect;

  m[ 0] := (2 * znear) / (right - left);
  m[ 4] := 0;
  m[ 8] := (right + left) / (right - left);
  m[12] := 0;

  m[ 1] := 0;
  m[ 5] := (2 * znear) / (top - bottom);
  m[ 9] := (top + bottom) / (top - bottom);
  m[13] := 0;

  m[ 2] := 0;
  m[ 6] := 0;
  m[10] := -1;
  m[14] := -2 * znear;

  m[ 3] := 0;
  m[ 7] := 0;
  m[11] := -1;
  m[15] := 0;

  glMultMatrixd(@m);
end;

procedure glBeginScene(const Width, Height: integer);
begin
  glDisable(GL_CULL_FACE);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;

  infinitePerspective(64.0, width / height, 0.01);

  glMatrixMode(GL_MODELVIEW);

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // Clear The Screen And The Depth Buffer
  glLoadIdentity;                                       // Reset The View

  glTranslatef(camera.x, camera.y, camera.z);
  glRotatef(camera.az, 0, 0, 1);
  glRotatef(camera.ay, 0, 1, 0);
  glRotatef(camera.ax, 1, 0, 0);
end;

procedure glEndScene(dc: HDC);
begin
  SwapBuffers(dc);                                // Display the scene
end;

procedure glRenderEnviroment;
const
  DRUNIT = 2.5;
  DREPEATS = 10;
  DWORLD = DREPEATS + 1;
var
  i: integer;
begin
  if opt_renderevniroment then
  begin
    glColor3f(1.0, 1.0, 1.0);

    glBegin(GL_LINES);
      for i := -DREPEATS to DREPEATS do
      begin
        glVertex3f((DREPEATS + 1) * DRUNIT, 0.0, i * DRUNIT);
        glVertex3f(-(DREPEATS + 1) * DRUNIT, 0.0, i * DRUNIT);
      end;
      for i := -DREPEATS to DREPEATS do
      begin
        glVertex3f(i * DRUNIT, 0.0, (DREPEATS + 1) * DRUNIT);
        glVertex3f(i * DRUNIT, 0.0, -(DREPEATS + 1) * DRUNIT);
      end;
    glEnd;

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    glColor3f(0.5, 0.6, 0.1);
    glBegin(GL_QUADS);
      glVertex3f(DWORLD * DRUNIT, -DWORLD * DRUNIT, DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, -DWORLD * DRUNIT, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, -DWORLD * DRUNIT, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, -DWORLD * DRUNIT, DWORLD * DRUNIT);

      glVertex3f(DWORLD * DRUNIT, 0.0, DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, 0.0, -DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, -DWORLD * DRUNIT, -DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, -DWORLD * DRUNIT, DWORLD * DRUNIT);

      glVertex3f(DWORLD * DRUNIT, 0.0, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, 0.0, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, -DWORLD * DRUNIT, -DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, -DWORLD * DRUNIT, -DWORLD * DRUNIT);

      glVertex3f(-DWORLD * DRUNIT, 0.0, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, 0.0, DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, -DWORLD * DRUNIT, DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, -DWORLD * DRUNIT, -DWORLD * DRUNIT);

      glVertex3f(-DWORLD * DRUNIT, 0.0, DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, 0.0, DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, -DWORLD * DRUNIT, DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, -DWORLD * DRUNIT, DWORLD * DRUNIT);
    glEnd;

    glDisable(GL_CULL_FACE);
    glColor3f(0.5, 0.5, 1.0);
    glBegin(GL_QUADS);
      glVertex3f(DWORLD * DRUNIT, DWORLD * DRUNIT, DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, DWORLD * DRUNIT, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, DWORLD * DRUNIT, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, DWORLD * DRUNIT, DWORLD * DRUNIT);

      glVertex3f(DWORLD * DRUNIT, -DRUNIT / 50, DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, -DRUNIT / 50, -DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, DWORLD * DRUNIT, -DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, DWORLD * DRUNIT, DWORLD * DRUNIT);

      glVertex3f(DWORLD * DRUNIT, -DRUNIT / 50, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, -DRUNIT / 50, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, DWORLD * DRUNIT, -DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, DWORLD * DRUNIT, -DWORLD * DRUNIT);

      glVertex3f(-DWORLD * DRUNIT, -DRUNIT / 50, -DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, -DRUNIT / 50, DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, DWORLD * DRUNIT, DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, DWORLD * DRUNIT, -DWORLD * DRUNIT);

      glVertex3f(-DWORLD * DRUNIT, -DRUNIT / 50, DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, -DRUNIT / 50, DWORLD * DRUNIT);
      glVertex3f(DWORLD * DRUNIT, DWORLD * DRUNIT, DWORLD * DRUNIT);
      glVertex3f(-DWORLD * DRUNIT, DWORLD * DRUNIT, DWORLD * DRUNIT);
    glEnd;
  end;
end;

procedure glRenderFaces(const mVertCount, mFaceCount: integer;
  const mVert, mNormal: array of fvec3_t; const mUV: array of fvec2_t;
  const mFace: array of ivec3_t);
var
  i: integer;
  procedure _render_rover(const r: integer);
  begin
    glTexCoord2f(mUV[r].u, mUV[r].v);
    glvertex3f(mVert[r].x, mVert[r].y, mVert[r].z);
  end;
begin
  glBegin(GL_TRIANGLES);
    for i := 0 to mFaceCount - 1 do
    begin
      _render_rover(mFace[i].x);
      _render_rover(mFace[i].y);
      _render_rover(mFace[i].z);
    end;
  glEnd;
  pt_rendredtriangles := pt_rendredtriangles + mFaceCount;
end;

procedure glRenderTree(const t: tree_t);
begin
  if opt_renderwireframe then
    glPolygonMode( GL_FRONT_AND_BACK, GL_LINE )
  else
    glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );

  glColor4f(1.0, 1.0, 1.0, 1.0);

  glEnable(GL_TEXTURE_2D);

  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);

  glBindTexture(GL_TEXTURE_2D, trunktexture);

  pt_rendredtriangles := 0;
  glRenderFaces(t.mVertCount, t.mFaceCount, t.mVert, t.mNormal, t.mUV, t.mFace);
  if opt_rendertwig then
  begin
    glBindTexture(GL_TEXTURE_2D, twigtexture);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GEQUAL, 0.5);
    glRenderFaces(t.mTwigVertCount, t.mTwigFaceCount, t.mTwigVert, t.mTwigNormal, t.mTwigUV, t.mTwigFace);
  end;

  glBindTexture(GL_TEXTURE_2D, 0);
  glDisable(GL_TEXTURE_2D);
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
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

function gld_CreateTexture(const pic: TPicture; const transparent: boolean): TGLUint;
const
  TEXTDIM = 256;
var
  buffer, line: PLongWordArray;
  bm: TBitmap;
  i, j: integer;
  dest: PLongWord;
begin
  bm := TBitmap.Create;
  bm.Width := TEXTDIM;
  bm.Height := TEXTDIM;
  bm.PixelFormat := pf32bit;
  bm.Canvas.StretchDraw(Rect(0, 0, TEXTDIM, TEXTDIM), pic.Graphic);

  GetMem(buffer, TEXTDIM * TEXTDIM * SizeOf(LongWord));
  dest := @buffer[0];
  for j := bm.Height - 1 downto 0 do
  begin
    line := bm.ScanLine[j];
    for i := bm.Height - 1 downto 0 do
    begin
      dest^ := RGBSwap(line[i]);
      inc(dest);
    end;
  end;
  bm.Free;

  if transparent then
    for i := 0 to TEXTDIM * TEXTDIM - 1 do
      if buffer[i] and $FFFFFF = 0 then
        buffer[i] := 0
      else
        buffer[i] := buffer[i] or $FF000000;

  glGenTextures(1, @Result);
  glBindTexture(GL_TEXTURE_2D, Result);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,
               TEXTDIM, TEXTDIM,
               0, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

  FreeMem(buffer, TEXTDIM * TEXTDIM * SizeOf(LongWord));
end;

end.
