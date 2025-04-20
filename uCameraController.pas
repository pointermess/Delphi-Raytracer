unit uCameraController;

interface

uses
  System.UITypes,
  Winapi.Windows,
  VCL.Controls,
  Neslib.FastMath,
  uTypes,
  uCamera;

type
  TCameraController = class
  private
    FCamera: TCamera;
  public
    constructor Create();

    procedure Update;

    property Camera : TCamera read FCamera write FCamera;
  end;

implementation

{ TCameraController }

constructor TCameraController.Create;
begin

end;

procedure TCameraController.Update;
var
  LShiftDown : Boolean;
  LMoveDistance : Single;
begin
  LMoveDistance := 0.15;

  if GetAsyncKeyState(vkShift) <0 then
    LMoveDistance := 0.4;

  Camera.BeginUpdate();

  if GetAsyncKeyState(vkW) < 0 then
    Camera.Position := Camera.Position + Camera.ForwardDir * LMoveDistance;
  if GetAsyncKeyState(vkS) < 0 then
    Camera.Position := Camera.Position - Camera.ForwardDir * LMoveDistance;
  if GetAsyncKeyState(vkQ) < 0 then
    Camera.Position := Camera.Position - Camera.UpDir * LMoveDistance;
  if GetAsyncKeyState(vkE) < 0 then
    Camera.Position := Camera.Position + Camera.UpDir * LMoveDistance;
  if GetAsyncKeyState(vkA) < 0 then
    Camera.Position := Camera.Position + Camera.LeftDir * LMoveDistance;
  if GetAsyncKeyState(vkD) < 0 then
    Camera.Position := Camera.Position + -Camera.LeftDir * LMoveDistance;

  Camera.EndUpdate();
end;

end.
