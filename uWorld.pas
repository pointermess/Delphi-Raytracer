unit uWorld;

interface

uses
  Neslib.FastMath,
  uTypes;

type
  TWorld = class
  private
    FSpheres: TArray<TSphere>;
  public
    procedure AddSphere(const ASphere : TSphere);

    property Spheres :  TArray<TSphere> read FSpheres;

    function FirstHit(const ARay : PRay) : THitInformation;
  end;

implementation


{ TWorld }

procedure TWorld.AddSphere(const ASphere: TSphere);
begin
  SetLength(FSpheres, Length(Spheres) + 1);
  Spheres[Length(Spheres) - 1] := ASphere;
end;

function TWorld.FirstHit(const ARay: PRay): THitInformation;
var
  LObject, LClosest : TSphere;
  LTempPoint, LClosestPoint : TVector3;
  LClosestDistance : Single;
  LDistance : Single;
begin
  LClosestDistance := INFINITE;
  Result.Miss := true;

  for LObject in Spheres do
  begin
    if ARay^.IntersectsWith(LObject, LTempPoint) then
    begin
      LDistance := LTempPoint.DistanceSquared(ARay^.Origin);
      if LDistance > LClosestDistance then
        Continue;
      LClosestDistance := LDistance;
      LClosestPoint := LTempPoint;
      LClosest := LObject;
    end;
  end;


  if LClosestDistance < INFINITE then
  begin
    Result.Sphere := LClosest;
    Result.Normal := (LClosest.Position-LClosestPoint).Normalize();
    Result.Point := LClosestPoint;
    Result.Miss := false;
  end;
end;

end.
