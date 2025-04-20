unit uCamera;

interface

uses
  System.Types,
  System.SysUtils,
  System.Threading,
  Neslib.FastMath,
  uTypes;

type
  TCameraNotifyProc = procedure of object;

  TCamera = class
  private
    FRotation: TQuaternion;
    FPosition: TVector3;
    FRays : TRayBuffer;
    FOnPropertyChanged: TCameraNotifyProc;
    FLeftDir: TVector3;
    FForwardDir: TVector3;
    FUpDir: TVector3;
    FResolution: TPoint;
    FIsUpdating : Boolean;
    function GetReay(AX, AY: Integer): PRay;
    procedure SetPosition(const Value: TVector3);
    procedure SetRotation(const Value: TQuaternion);
    procedure SetResolution(const Value: TPoint);
    procedure SetIsUpdating(const Value: Boolean);
  public
    constructor Create(const ADisplayWidth, ADisplayHeight : Integer);

    property Rotation : TQuaternion read FRotation write SetRotation;
    property Position : TVector3 read FPosition write SetPosition;

    property Resolution : TPoint read FResolution write SetResolution;

    procedure CalculateRays();
    procedure BeginUpdate();
    procedure EndUpdate();

    property Ray[AX, AY : Integer] : PRay read GetReay;
    property Rays : TRayBuffer read FRays;

    property UpDir : TVector3 read FUpDir;
    property ForwardDir : TVector3 read FForwardDir;
    property LeftDir : TVector3 read FLeftDir;

    property IsUpdating : Boolean read FIsUpdating write SetIsUpdating;
    property OnPropertyChanged : TCameraNotifyProc read FOnPropertyChanged write FOnPropertyChanged;
  end;

implementation

{ TCamera }

procedure TCamera.BeginUpdate;
begin

end;

procedure TCamera.CalculateRays;
var
  LFovScaleY, LFovScaleX : Single;
  LX, LY : Integer;
  LOffsetX, LOffsetY: Single;
  vec : TVector4;
  vec2 :  TVector3;

  LRotationMatrix : TMatrix4;
  FTempRays : TRayBuffer;
begin
  SetLength(FTempRays, Resolution.X, Resolution.Y);

  LFovScaleY := FastTan((Radians(60) / 2));
  LFovScaleX := LFovScaleY * (Resolution.X / Resolution.Y);

  LRotationMatrix := Rotation.ToMatrix;

  TParallel.For(0, Resolution.X * Resolution.Y - 1, procedure(I: Integer)
  var
    LX, LY : Integer;
    LOffsetX, LOffsetY: Single;
    vec : TVector4;
    vec2 :  TVector3;
  begin
    LX := I mod Resolution.X;
    LY := I div Resolution.X;

     LOffsetX := (2 * (LX + 0.5) / Resolution.X - 1) * LFovScaleX;
     LOffsetY := (1 - 2 * (LY + 0.5) / Resolution.Y) * LFovScaleY;
     vec.Init(LOffsetX, LOffsetY, -1, 0);

     // Apply camera rotation to ray direction
     vec := TVector4(LRotationMatrix * (vec));

    vec2.Init(vec.X, vec.Y, vec.Z);
    FTempRays[LX, LY].Init(Position, vec2);
  end);

  FRays := FTempRays;
  SetLength(FTempRays, 0, 0);
end;

constructor TCamera.Create(const ADisplayWidth, ADisplayHeight: Integer);
begin
  FIsUpdating := False;
  FOnPropertyChanged := nil;

  FPosition.Init(0, 0, 0);
  FRotation.Init(0, 0, 0);

  FResolution := Point(ADisplayWidth, ADisplayHeight);


  CalculateRays();
end;

procedure TCamera.EndUpdate;
begin

end;

function TCamera.GetReay(AX, AY: Integer): PRay;
begin
  Result := @FRays[AX, AY];
end;

procedure TCamera.SetIsUpdating(const Value: Boolean);
begin
  FIsUpdating := Value;

  if not FIsUpdating then
  OnPropertyChanged();
end;

procedure TCamera.SetPosition(const Value: TVector3);
begin
  FPosition := Value;
  if (not FIsUpdating) then
    CalculateRays();

  if Assigned(OnPropertyChanged) and (not FIsUpdating) then
    OnPropertyChanged();
end;

procedure TCamera.SetResolution(const Value: TPoint);
begin
  FResolution := Value;
  if (not FIsUpdating) then
    CalculateRays();

  if Assigned(OnPropertyChanged) and (not FIsUpdating) then
    OnPropertyChanged();
end;

procedure TCamera.SetRotation(const Value: TQuaternion);
var
  LMatrix : TMatrix4;
begin
  
  FRotation := Value;       
  if (not FIsUpdating) then
    CalculateRays();

  LMatrix := Value.ToMatrix;
  FForwardDir.Init(
    -LMatrix.m13,
    -LMatrix.m23,
    -LMatrix.m33
  );

  FUpDir.Init(
    LMatrix.m12,
    LMatrix.m22,
    LMatrix.m32
  );

  LeftDir.Init(
    -LMatrix.m11,
    -LMatrix.m21,
    -LMatrix.m31
  );

  if Assigned(OnPropertyChanged) and (not FIsUpdating) then
    OnPropertyChanged();
end;

end.
