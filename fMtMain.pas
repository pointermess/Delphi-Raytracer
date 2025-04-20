unit fMtMain;

interface

uses
  Vcl.Controls, // Todo move to  controller
  Neslib.FastMath,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Threading,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, System.DateUtils,
  uCamera,
  uRenderer,
  uCameraController,
  uTypes,
  uWorld, FMX.Layouts, FMX.ListBox, FMX.EditBox, FMX.NumberBox, FMX.Edit,
  FMX.TabControl;

type
  TForm2 = class(TForm)
    btn1: TButton;
    img1: TImage;
    tmr1: TTimer;
    tbc1: TTabControl;
    tbtmDisplay: TTabItem;
    vrtscrlbx: TVertScrollBox;
    grp1: TGroupBox;
    lbl2: TLabel;
    lyt2: TLayout;
    lyt3: TLayout;
    lbl3: TLabel;
    edtCameraX: TEdit;
    lyt31: TLayout;
    lbl31: TLabel;
    edtCameraY: TEdit;
    lyt32: TLayout;
    lbl32: TLabel;
    edtCameraZ: TEdit;
    lbl1: TLabel;
    lyt: TLayout;
    lyt1: TLayout;
    lbl33: TLabel;
    edt: TEdit;
    lyt5: TLayout;
    lbl311: TLabel;
    edt3: TEdit;
    lyt6: TLayout;
    lbl321: TLabel;
    edt4: TEdit;
    nmbrbx1: TNumberBox;
    edt1: TEdit;
    trckbr: TTrackBar;
    trckbr1: TTrackBar;
    trckbr2: TTrackBar;
    trckbr3: TTrackBar;
    trckbr4: TTrackBar;
    trckbr5: TTrackBar;
    btn11: TButton;
    btn2: TButton;
    chk1: TCheckBox;
    btn3: TButton;
    grp2: TGroupBox;
    lbl4: TLabel;
    lytZ: TLayout;
    lyt4: TLayout;
    rb1: TRadioButton;
    edt2: TEdit;
    rb2: TRadioButton;
    lyt7: TLayout;
    lbl5: TLabel;
    edt5: TEdit;
    lyt8: TLayout;
    lbl6: TLabel;
    edt6: TEdit;
    lyt9: TLayout;
    chk2: TCheckBox;
    ln1: TLine;
    tbtmObjects: TTabItem;
    vrtscrlbx1: TVertScrollBox;
    grp11: TGroupBox;
    lbl21: TLabel;
    lyt10: TLayout;
    lyt11: TLayout;
    lbl34: TLabel;
    edt7: TEdit;
    lyt12: TLayout;
    lbl312: TLabel;
    edt8: TEdit;
    lyt13: TLayout;
    lbl322: TLabel;
    edt9: TEdit;
    lbl7: TLabel;
    lyt14: TLayout;
    lyt15: TLayout;
    lbl35: TLabel;
    edt10: TEdit;
    lyt16: TLayout;
    lbl313: TLabel;
    edt11: TEdit;
    lyt17: TLayout;
    lbl323: TLabel;
    edt12: TEdit;
    nmbrbx: TNumberBox;
    edt13: TEdit;
    trckbr6: TTrackBar;
    trckbr7: TTrackBar;
    trckbr8: TTrackBar;
    trckbr9: TTrackBar;
    trckbr10: TTrackBar;
    trckbr11: TTrackBar;
    btn12: TButton;
    btn21: TButton;
    chk11: TCheckBox;
    lst1: TListBox;
    spl1: TSplitter;
    lyt18: TLayout;
    grp21: TGroupBox;
    lyt19: TLayout;
    lyt20: TLayout;
    lbl42: TLabel;
    Layout1: TLayout;
    Label1: TLabel;
    CheckBox1: TCheckBox;
    lyt201: TLayout;
    lbl421: TLabel;
    lyt202: TLayout;
    lbl422: TLabel;
    nmbrbx2: TNumberBox;
    nmbrbx3: TNumberBox;
    nmbrbx4: TNumberBox;
    procedure FormCreate(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure trckbr2Change(Sender: TObject);
    procedure img1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure img1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure img1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure edt2Change(Sender: TObject);
    procedure lyt18Paint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure CheckBox1Change(Sender: TObject);
  private
    { Private declarations }
    aiii : Integer;
    FMouseDown : Boolean;
      FValueStartX, FValueStartY : Single;
      FMousePos, FMouseStart : TPointF;
  public
    { Public declarations }
//    FScreenBuffer : array of array of Cardinal;
    FIsBusy : Boolean;


//    World : TWorld;
//    Camera : TCamera;

    CenterSphere : TSphere;
    Renderer : TRenderer ;
    Controller : TCameraController;

    procedure Render();
    procedure RenderTask(AIndex : Integer);
    procedure PerPixel(AX, AY : Integer; ARay : TRay);
  end;


var
  Form2: TForm2;
implementation

{$R *.fmx}


procedure TForm2.CheckBox1Change(Sender: TObject);
begin
  LockRender();
  Renderer.PostProcessorSettings.Enabled := CheckBox1.IsChecked;
  UnlockRender();
end;

procedure TForm2.edt2Change(Sender: TObject);
begin
//  MonitorEnter(Renderer);
//  MonitorEnter(Renderer.Camera);
  LockRender();
  Renderer.Camera.Resolution := PointF(img1.Width * StrToFloat(edt2.Text), img1.Height * StrToFloat(edt2.Text)).Round;
  UnlockRender();
//  MonitorExit(Renderer.Camera);
//  MonitorExit(Renderer);
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  FIsBusy := False;

  Renderer := TRenderer.Create(1280, 720, 8);
  Renderer.PostProcessorSettings.Contrast := 1.6;
  Renderer.PostProcessorSettings.Brightness := 0;
  Renderer.PostProcessorSettings.Saturation := 1.6;
  Renderer.PostProcessorSettings.Enabled := true;

  Controller := TCameraController.Create;
  Controller.Camera := Renderer.Camera;


  // front
  CenterSphere := TSphere.Create;
  CenterSphere.Position := Vector3(-3.3,0,-8);
  CenterSphere.Radius := 1.5;
  CenterSphere.Material.Color.Init(1,0,0,0);
  Renderer.World.AddSphere(CenterSphere);

  CenterSphere := TSphere.Create;
  CenterSphere.Position := Vector3(0,0,-8);
  CenterSphere.Material.Color.Init(1,1,1,0);
  CenterSphere.Radius := 1.5;
  Renderer.World.AddSphere(CenterSphere);

  CenterSphere := TSphere.Create;
  CenterSphere.Position := Vector3(0,0,-12);
  CenterSphere.Material.Color.Init(0,1,0,0);
  CenterSphere.Radius := 1.5;
  Renderer.World.AddSphere(CenterSphere);

  CenterSphere := TSphere.Create;
  CenterSphere.Position := Vector3(3.3,0,-8);
  CenterSphere.Material.Color.Init(0,0,1,0);
  CenterSphere.Radius := 1.5;
  Renderer.World.AddSphere(CenterSphere);

  CenterSphere := TSphere.Create;
  CenterSphere.Position := Vector3(0,-102,0);
  CenterSphere.Material.Color.Init(0.3,0.3,0.3,0);
  CenterSphere.Radius := 100;
  CenterSphere.Material.EmissionColor.Init(1,1,0.3,1);
  CenterSphere.Material.EmissionIntensity := 1;
  CenterSphere.Material.Roughness := 0.005;
  Renderer.World.AddSphere(CenterSphere);

end;

procedure TForm2.FormResize(Sender: TObject);
begin
//  MonitorEnter(Renderer);
//  MonitorEnter(Renderer.Camera);
  LockRender();
  TThread.Synchronize(nil, procedure
    begin
      Renderer.Camera.Resolution := PointF(img1.Width/1.3, img1.Height/1.3).Round;
    end
  );
  UnlockRender();
//  MonitorExit(Renderer);
//  MonitorExit(Renderer.Camera);
end;

procedure TForm2.img1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FMouseDown := True;
  FMouseStart := PointF(X, Y);
  FValueStartX := trckbr2.Value;
  FValueStartY := trckbr3.Value;
end;

procedure TForm2.img1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
const
  DegPerPx = 0.5;
var
  LValue : Single;
begin

  FMousePos := PointF(X, Y);

  if not FMouseDown then
    Exit;

//  MonitorEnter(Renderer);
//  MonitorEnter(Renderer.Camera);
  img1.Cursor := crNone;

  LValue := FValueStartX + (DegPerPx * (X - FMouseStart.X));

  if LValue >= 360 then
    LValue := 0;
  if LValue < 0 then
    LValue := 359.99999;

  FValueStartX := LValue;


  LValue := FValueStartY + (DegPerPx * (Y - FMouseStart.Y));
  if LValue >= 360 then
    LValue := 0;
  if LValue < 0 then
    LValue := 359.99999;

  FValueStartY := LValue;

  LockRender();
  TThread.Synchronize(nil, procedure
  begin
    trckbr2.BeginUpdate;
    trckbr4.BeginUpdate;
    trckbr2.Value := FValueStartX;
    trckbr4.Value := LValue;
    UnlockRender();
  end);


  FMouseStart := img1.LocalRect.CenterPoint.Round;
  Vcl.Controls.Mouse.CursorPos := self.ClientToScreen(img1.AbsoluteRect.CenterPoint).Round;
//  MonitorExit(Renderer.Camera);
//  MonitorExit(Renderer);
end;

procedure TForm2.img1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FMouseDown := False;
  img1.Cursor := crDefault;
end;

procedure TForm2.lyt18Paint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  Canvas.DrawBitmap(Renderer.LastFrame, Renderer.LastFrame.Bounds, ARect, 1, False);
end;

procedure TForm2.PerPixel(AX, AY: Integer; ARay : TRay);
var
  LHit : THitInformation;
begin
//  LHit := World.FirstHit(ARay);
//
//  if not LHit.Miss then
//  begin
//    FScreenBuffer[AX, AY] := $ff000000 + $ff;
//  end;
end;

procedure TForm2.Render;
var
  LX, LY : Integer;
  LData : TBitmapData;
  LDateTime : TDateTime;
  LTasks : array of ITask;
begin

//  self.BeginUpdate;
//  LDateTime := Now;
//
//  SetLength(LTasks,8);
//
//  LTasks[0] := TTask.Run(procedure begin RenderTask(0); end);
//  LTasks[1] := TTask.Run(procedure begin RenderTask(1); end);
//  LTasks[2] := TTask.Run(procedure begin RenderTask(2); end);
//  LTasks[3] := TTask.Run(procedure begin RenderTask(3); end);
//  LTasks[4] := TTask.Run(procedure begin RenderTask(4); end);
//  LTasks[5] := TTask.Run(procedure begin RenderTask(5); end);
//  LTasks[6] := TTask.Run(procedure begin RenderTask(6); end);
//  LTasks[7] := TTask.Run(procedure begin RenderTask(7); end);
//
//  TTask.WaitForAll(LTasks);
//
//
//  FBitmap.Map(TMapAccess.Write, LData);
//  for LX := 0 to 1920 - 1 do
//  begin
//    for LY := 0 to 1080 - 1 do
//    begin
//       //adasd LData.SetPixel(LX, LY, FScreenBuffer[LX, LY]);
//    end;
//  end;
//  FBitmap.Unmap(LData);
//  Caption := Millisecondsbetween(Now, LDateTime).ToString;
//
//  self.EndUpdate;
end;

procedure TForm2.RenderTask(AIndex: Integer);
  var
  LB,LY,LX : Integer;
  begin
//    for LX := AIndex * (FDisplayWidth div 8) to AIndex * (FDisplayWidth div 8) + (FDisplayWidth div 8) - 1 do
//    begin
//      for LY := 0 to FDisplayHeight - 1 do
//      //TParallel.For(0, 499, procedure(LY : Integer)
//      begin
//        //FScreenBuffer[LX, LY] := $ff000000 + lx * ly + aiii;
//      //asad PerPixel(LX, LY, Camera.Rays[LX, LY]);
//        //FScreenBuffer[LX, LY] := $ff000000 + AIndex * 20 + aiii * LY + aiii * LX;
//      end;
//    end;
  end;


procedure TForm2.tmr1Timer(Sender: TObject);
var
  LDateTime : TDateTime;
begin
  if FIsBusy then Exit;
  FIsBusy := True;
  BeginUpdate();
  LDateTime := Now;


//  MonitorEnter(Renderer.Camera);
//  MonitorEnter(Renderer);
  LockRender();
  Controller.Update;
  UnlockRender();
//  MonitorExit(Renderer.Camera);
//  MonitorExit(Renderer);

TTask.Run(
  procedure
  begin
    Renderer.Render();
    TThread.Synchronize(nil, procedure begin
      img1.Bitmap.Assign(Renderer.LastFrame);
      //lyt18.Repaint();
      Caption := Renderer.LastFrameTime.ToString();
      Caption := Millisecondsbetween(Now, LDateTime).ToString;
      FIsBusy := false;
      EndUpdate();
    end)
  end);
end;






procedure TForm2.trckbr2Change(Sender: TObject);
var
  LRot : TQuaternion;
begin
//  MonitorEnter(Renderer);
//  MonitorEnter(Renderer.Camera);

      EulerToQuaternion(Radians(trckbr2.Value), Radians(trckbr3.Value), Radians(trckbr4.Value), LRot);
      Renderer.Camera.Rotation := LRot;
//  MonitorEnter(Renderer.Camera);
//  MonitorExit(Renderer);
end;

end.
