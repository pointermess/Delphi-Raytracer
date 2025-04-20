unit uTypes;

interface

uses
  System.SyncObjs,
  System.SysUtils,
  Neslib.FastMath;

type
  TColorBuffer = array of array of TVector4;

  TPostProcessorSettings = record
  public
    Saturation : Single;
    Brightness : Single;
    Contrast : Single;

    ToneMapperStrength : Single;

    Enabled : Boolean;
  end;

  TMaterial = class
  private
  public
    Color : TVector4;
    Metalness : Single;
    Roughness : Single;

    EmissionColor : TVector4;
    EmissionIntensity : Single;

    constructor Create();

    function GetEmission() : TVector4;
  end;

  TSphere = class
  private
    FRadius: Single;
    FRotation: TQuaternion;
    FPosition: TVector3;
    FMaterial: TMaterial;
  public
    constructor Create();

    property Rotation : TQuaternion read FRotation write FRotation;
    property Position : TVector3 read FPosition write FPosition;
    property Radius : Single read FRadius write FRadius;

    property Material : TMaterial read FMaterial;
  end;

  THitInformation = record
  private
  public
    Sphere: TSphere;
    Normal: TVector3;
    Point: TVector3;
    Miss : Boolean;
  end;

  TRay = record
  private
    FDirection: TVector3;
    FOrigin: TVector3;
  public
    procedure Init(const AOrigin, ADirection : TVector3);

    function IntersectsWith(const ASphere: TSphere; out AIntersectionPoint: TVector3): Boolean;

    property Origin : TVector3 read FOrigin write FOrigin;
    property Direction : TVector3 read FDirection write FDirection;
  end;
  TRayBuffer = array of array of TRay;
  PRay = ^TRay;

  procedure LockRender();
  procedure UnlockRender();
  function ColorToVector4(const Color: Cardinal): TVector4;
  function Vector4ToColor(const Color: TVector4): Cardinal;
procedure EulerToQuaternion(const yaw, pitch, roll: Single; out quat: TQuaternion);
implementation

var
  FLockObject : TObject;
  FCriticalSection : TCriticalSection;

procedure LockRender();
begin
  //MonitorEnter(FLockObject);
  FCriticalSection.Enter();
end;

procedure UnlockRender();
begin
  //MonitorExit(FLockObject);
  FCriticalSection.Leave;
end;

procedure EulerToQuaternion(const yaw, pitch, roll: Single; out quat: TQuaternion);
var
  cy, sy, cp, sp, cr, sr: Single;
begin
  // Convert Euler angles to radians
  cy := Cos(yaw * 0.5);
  sy := Sin(yaw * 0.5);
  cp := Cos(pitch * 0.5);
  sp := Sin(pitch * 0.5);
  cr := Cos(roll * 0.5);
  sr := Sin(roll * 0.5);

  // Calculate quaternion components
  quat.W := cy * cp * cr - sy * sp * sr;
  quat.X := cy * cp * sr + sy * sp * cr;
  quat.Y := sy * cp * cr + cy * sp * sr;
  quat.Z := sy * cp * sr - cy * sp * cr;
end;


function ColorToVector4(const Color: Cardinal): TVector4;
begin
  // Extract color components from the integer
 Result.Z  := (Color and $FF) / 255;
 Result.Y  := ((Color shr 8) and $FF) / 255;
 Result.X  := ((Color shr 16) and $FF) / 255;
 Result.W := ((Color shr 24) and $FF) / 255;

end;

function Vector4ToColor(const Color: TVector4): Cardinal;
var
  R, G, B, A: Byte;
begin
  // Ensure values are within the range of 0 to 255
  R := Trunc(EnsureRange(Color.X, 0, 1) * 255);
  G := Trunc(EnsureRange(Color.Y, 0, 1) * 255);
  B := Trunc(EnsureRange(Color.Z, 0, 1) * 255);
  A := Trunc(EnsureRange(Color.W, 0, 1) * 255);

  // Pack the color components into a 4-byte integer
  Result := Cardinal(B) or (Cardinal(G) shl 8) or (Cardinal(R) shl 16) or (Cardinal(A) shl 24);
end;

{ TRay }

procedure TRay.Init(const AOrigin, ADirection: TVector3);
begin
  self.FOrigin := AOrigin;
  self.FDirection := ADirection;
end;

function TRay.IntersectsWith(const ASphere: TSphere; out AIntersectionPoint: TVector3): Boolean;
var
  OC: TVector3;
  a, b, c, discriminant, sqrtDiscriminant: Single;
begin
  OC := Origin - ASphere.Position; // Vector from sphere center to ray origin

  a := Direction.Dot(Direction); // Should be 1 if Direction is normalized
  b := 2.0 * OC.Dot(Direction);
  c := OC.Dot(OC) - Sqr(ASphere.Radius);

  discriminant := b * b - 4 * a * c;

  if discriminant < 0 then
  begin
    Result := False; // Ray does not intersect the sphere
  end
  else
  begin
    sqrtDiscriminant := Sqrt(discriminant);
    // Check for the closest intersection that is in front of the ray
    var t1 := (-b - sqrtDiscriminant) / (2 * a);
    var t2 := (-b + sqrtDiscriminant) / (2 * a);

    if t1 > 0 then
    begin
      AIntersectionPoint := Origin + (Direction * t1);
      Result := True;
    end
    else if t2 > 0 then
    begin
      AIntersectionPoint := Origin + (Direction * t2);
      Result := True; // Intersection, but further away
    end
    else
      Result := False; // Intersections are behind the ray's origin
  end;
end;

{ TSphere }

constructor TSphere.Create;
begin
  FMaterial := TMaterial.Create;

end;

{ TMaterial }

constructor TMaterial.Create;
begin
  EmissionColor.Init(1);
  EmissionIntensity := 0;
end;

function TMaterial.GetEmission: TVector4;
begin
  Result := EmissionColor * EmissionIntensity;
end;

initialization
  FLockObject := TObject.Create;
  FCriticalSection := TCriticalSection.Create();

finalization
  FCriticalSection.Enter;
  FLockObject.Free;
  FCriticalSection.Leave;
  FCriticalSection.Free;

end.
