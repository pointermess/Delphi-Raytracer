unit uRenderer;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Threading,
  FMX.Graphics,
  Neslib.FastMath,
  uCamera,
  uPostProcessor,
  uTypes,
  uWorld;

type
  TRenderer = class
  private
    FTaskCount: Integer;
    FLastFrameTime: Integer;
    FScreenBuffer : TColorBuffer;
    FCamera: TCamera;
    FWorld: TWorld;
    FTasks : array of ITask;
    FLastFrame : TBitmap;
    FStackCount : Integer;
    FSkyColor: TVector4;
    FPostProcessor : TPostProcessor;
    procedure PerPixel(const AX, AY : Integer; const ARays : TRayBuffer);
    procedure PerPixel2(const AX, AY : Integer; const ARays : TRayBuffer);

    procedure OnResolutionChanged();
    procedure OnPropertyChanged();
    procedure RenderTask(const ATaskIndex : Integer; const ARays : TRayBuffer; const ABitmapData : TBitmapData);
    procedure SetTaskCount(const Value: Integer);
    procedure ResetStacker();
  public
    PostProcessorSettings: TPostProcessorSettings;
    constructor Create(const ADisplayWidth, ADisplayHeight, ATaskCount : Integer);

    procedure Render();
    property TaskCount : Integer read FTaskCount write SetTaskCount;
    property LastFrame : TBitmap read FLastFrame;
    property LastFrameTime : Integer read FLastFrameTime;

    property Camera : TCamera read FCamera write FCamera;
    property World : TWorld read FWorld write FWorld;
    property SkyColor : TVector4 read FSkyColor write FSkyColor;

  end;

implementation

{ TRenderer }

constructor TRenderer.Create(const ADisplayWidth, ADisplayHeight, ATaskCount : Integer);
begin
  PostProcessorSettings.Saturation := 1;
  PostProcessorSettings.Contrast := 1;
  PostProcessorSettings.ToneMapperStrength := 1;
  PostProcessorSettings.Enabled := False;

  FPostProcessor := TPostProcessor.Create();

  FSkyColor := Vector4(0.4,0.7,1,0);

  FWorld := TWorld.Create;
  FStackCount := 0;
  TaskCount := ATaskCount;
  SetLength(FTasks, FTaskCount);
  FLastFrameTime := -1;

  SetLength(FScreenBuffer, ADisplayWidth, ADisplayHeight);

  FCamera := TCamera.Create(ADisplayWidth, ADisplayHeight);
  FCamera.OnPropertyChanged := OnPropertyChanged;

  FLastFrame := TBitmap.Create(ADisplayWidth, ADisplayHeight);
end;

procedure TRenderer.OnPropertyChanged;
begin
  OnResolutionChanged();
end;

procedure TRenderer.OnResolutionChanged;
begin
  FLastFrame.SetSize(FCamera.Resolution.X, FCamera.Resolution.Y);
  SetLength(FScreenBuffer, FCamera.Resolution.X,  FCamera.Resolution.Y);
  ResetStacker();
end;

procedure AttenuateLight(const Intensity: Single; const Distance: Double;
const LightColor, SurfaceColor: TVector4; var AOutput : TVector4); inline;
var
    AttenuatedIntensity: Double;
begin
  AttenuatedIntensity := Intensity * 10  / (Distance * Distance);

  // Apply the intensity to the surface color
  AOutput := ((SurfaceColor + LightColor) * AttenuatedIntensity);
end;

function Vector3ToSkyboxColor(const Vector: TVector3): TVector4;
const
  LightBlue: TVector4 = (X: 0.529; Y: 0.808; Z: 0.922; W: 1);
  DarkBlue: TVector4 = (X: 0.0; Y: 0.1; Z: 0.422; W: 1);
var
  T: Single;
begin
  // Interpolate between light blue and dark blue based on the y component
  // Assuming y component is in the range [0, 1]
  T := EnsureRange(Vector.Y, 0, 1); // Clamping y component between 0 and 1

  // Interpolate between light blue and dark blue
  Result.X := LightBlue.X * (1 - T) + DarkBlue.X * T;
  Result.Y := LightBlue.Y * (1 - T) + DarkBlue.Y * T;
  Result.Z := LightBlue.Z * (1 - T) + DarkBlue.Z * T;
end;

function CalculateLightValue(const DirectionalLightVector, NormalVector: TVector3): Single;
var
  DotProduct: Single;
begin
  // Calculate the dot product between the directional light vector and the normal vector
  DotProduct := DirectionalLightVector.Dot(NormalVector);

  // Ensure the dot product is within the range [0, 1]
  Result := Neslib.FastMath.EnsureRange(DotProduct, 0, 1);
end;

procedure TRenderer.PerPixel(const AX, AY: Integer; const ARays : TRayBuffer);
var
  LHit, LShadowHit : THitInformation;
  LMultiplier : Single;
  LRay, LShadowRay : TRay;
  FBounces : Integer;
  FBounceIndex: Integer;
  LLightMultiplier, LShadowMultiplier : Single;
  LFinalColor, LMatColor : TVector4;

  LContribution : TVector4;
  LFinalLight : TVector4;
begin
  FBounces := 4;

  LRay.Init(Camera.Position,(ARays[AX, AY].Direction
    + Vector3(Random * 0.0008 - 0.0004,Random * 0.0008 - 0.0004,Random * 0.0008 - 0.0004)
    ).NormalizeFast
  );

  LFinalLight.Init(0,0,0,0);
  LMultiplier := 0.7;

  LContribution.Init(1);

  for FBounceIndex := 0 to FBounces do
  begin
    LLightMultiplier := 1;

    LHit := World.FirstHit(@LRay);

    if LHit.Miss then
    begin
      //LFinalColor := LFinalColor + Vector3ToSkyboxColor(LRay.Direction) * LMultiplier;
      LFinalLight := LFinalLight + Vector3ToSkyboxColor(LRay.Direction) * LContribution;
      Break;
    end;

    LShadowRay.Init(Vector3(10,10,10), (LHit.Point-Vector3(10)).Normalize) ;
    LShadowHit := World.FirstHit(@LShadowRay);
    if LShadowHit.Sphere <> LHit.Sphere then
      LMultiplier := 0.5;


    LMatColor := LHit.Sphere.Material.Color;
    //LLightMultiplier := LLightMultiplier * CalculateLightValue(Vector3(-1,-1,-1), LHit.Normal);


    //LFinalColor := LFinalColor + LMatColor * LLightMultiplier * LMultiplier;
    LContribution := LContribution * LMatColor * LMultiplier;
    LFinalLight := LFinalLight + LHit.Sphere.Material.GetEmission;

    LRay.Direction := LRay.Direction.Reflect(LHit.Normal + Vector3(Random * 3 - 1.5,Random * 3 - 1.5,Random * 3 - 1.5) * LHit.Sphere.Material.Roughness).Normalize;
    LRay.Origin := LHit.Point + (LRay.Direction * 0.003);

    LMultiplier := LMultiplier * 0.7;
  end;

  LFinalLight.W := 1;
  FScreenBuffer[AX, AY] := FScreenBuffer[AX, AY] + (LFinalLight);
end;

procedure TRenderer.PerPixel2(const AX, AY: Integer; const ARays: TRayBuffer);
var
  LHit, LShadowHit, LRefractHit : THitInformation;
  LMultiplier : Single;
  LRay, LShadowRay, LRefractRay : TRay;
  FBounces : Integer;
  FBounceIndex: Integer;
  LLightMultiplier, LShadowMultiplier : Single;
  LFinalColor, LMatColor : TVector4;
begin
  FBounces := 0;

  LRay.Init(Camera.Position,(ARays[AX, AY].Direction
    + Vector3(Random * 0.002 - 0.001,Random * 0.002 - 0.001,Random * 0.002 - 0.001)).Normalize
  );

  LFinalColor.Init(0,0,0,0);
  LMultiplier := 0.7;
  for FBounceIndex := 0 to FBounces do
  begin
    LLightMultiplier := 3;

    LHit := World.FirstHit(@LRay);

    if LHit.Miss then
    begin
      LFinalColor := LFinalColor + Vector3ToSkyboxColor(LRay.Direction) * LMultiplier;
      Break;
    end;

    LShadowRay.Init(Vector3(10,10,10), (LHit.Point-Vector3(10)).Normalize) ;
    LShadowHit := World.FirstHit(@LShadowRay);
    if LShadowHit.Sphere <> LHit.Sphere then
      LMultiplier := 0.5;


    LMatColor := LHit.Sphere.Material.Color;

    if (LMatColor.X = 1) and (LMatColor.Y = 1) and (LMatColor.Z = 1) then
    begin
      // hit refracting material
      LRefractRay.Init(
        LHit.Point + LHit.Normal * 0.005,
        //((ARays[AX, AY].Direction)).Normalize * -1
        ((ARays[AX, AY].Direction.Refract(LHit.Normal, 1.1))).Normalize * -1
      );

      LRefractHit := World.FirstHit(@LRefractRay);
      LMatColor := Vector4(1,0,1,1);
      if (not LRefractHit.Miss) and (LRefractHit.Sphere = LHit.Sphere) then
      begin
        if LRefractHit.Point.Distance(LHit.Point) > 2 then
        begin
          LRefractRay.Init(
            LRefractHit.Point - LRefractHit.Normal * 0.005,
            //((ARays[AX, AY].Direction)).Normalize * -1
            ((LRefractRay.Direction.Refract(LRefractHit.Normal, 1.1))).Normalize
          );
          LRefractHit := World.FirstHit(@LRefractRay);
          if (not LRefractHit.Miss) and (LRefractHit.Sphere <> LHit.Sphere) then
          begin
            //LMatColor := Vector4(1,1,0,1);
            LMatColor := LRefractHit.Sphere.Material.Color;
          end;
        end;
      end;

    end;

    LLightMultiplier := CalculateLightValue(Vector3(-1,-1,-1), LHit.Normal);


    LFinalColor := LFinalColor + LMatColor * LLightMultiplier * LMultiplier;

    LMultiplier := LMultiplier * 0.7;
  end;

  LFinalColor.W := 1;
  FScreenBuffer[AX, AY] := FScreenBuffer[AX, AY] + (LFinalColor);
end;

procedure TRenderer.Render();
var
  LDateTime : TDateTime;
  LData : TBitmapData;
  LX,LY : Integer;
  LTaskIndex: Integer;
  LColor : TVector4;
begin
  LDateTime := Now;

//  MonitorEnter(Camera);
//  MonitorEnter(self);

  LockRender();

  Inc(FStackCount);
  FLastFrame.Map(TMapAccess.Write, LData);
  TParallel.For(0, FTaskCount - 1, procedure(AIndex : Integer) begin
    RenderTask(AIndex, Camera.Rays, LData)
  end);
  FLastFrame.Unmap(LData);



//  Inc(FStackCount);
//  FLastFrame.Map(TMapAccess.Write, LData);
//  for LX := 0 to FCamera.Resolution.X - 1 do
//  begin
//    for LY := 0 to FCamera.Resolution.Y - 1 do
//    begin
//      if PostProcessorSettings.Enabled then
//      begin
//        LColor := FPostProcessor.PostProcess(FScreenBuffer[LX, LY] / FStackCount, PostProcessorSettings);
//        LData.SetPixel(LX, LY, Vector4ToColor(LColor));
//      end
//      else
//        LData.SetPixel(LX, LY, Vector4ToColor(FScreenBuffer[LX, LY] / FStackCount));
//    end;
//  end;
//  FLastFrame.Unmap(LData);



//  MonitorExit(Camera);
//  MonitorExit(self);
  UnlockRender();

  FLastFrameTime := Millisecondsbetween(Now, LDateTime);
end;

procedure TRenderer.RenderTask(const ATaskIndex: Integer; const ARays : TRayBuffer; const ABitmapData : TBitmapData);
var
  LB,LX : Integer;
  LY : Integer;
  LStart, LEnd : Integer;
  LColor : TVector4;
begin
  LStart := ATaskIndex * (Camera.Resolution.X div FTaskCount);

  if ATaskIndex = FTaskCount - 1 then
    LEnd := Camera.Resolution.X
  else
    LEnd := ATaskIndex * (Camera.Resolution.X div FTaskCount) + (Camera.Resolution.X div FTaskCount);

  for LX := LStart to LEnd - 1 do
  //TParallel.For(LStart, LEnd - 1, procedure(LX : Integer)
  begin
    for LY := 0 to Camera.Resolution.Y - 1 do
    begin
      PerPixel(LX, LY, ARays);

      if PostProcessorSettings.Enabled then
      begin
        LColor := FPostProcessor.PostProcess(FScreenBuffer[LX, LY] / FStackCount, PostProcessorSettings);
        ABitmapData.SetPixel(LX, LY, Vector4ToColor(LColor));
      end
      else
        ABitmapData.SetPixel(LX, LY, Vector4ToColor(FScreenBuffer[LX, LY] / FStackCount));
      //FScreenBuffer[LX, LY] := $ff000000 + lx * ly + aiii;
      //FScreenBuffer[LX, LY] := $ff000000 + AIndex * 20 + aiii * LY + aiii * LX;
    end;
  //end);
  end
end;

procedure TRenderer.ResetStacker;
var
  LX, LY : Integer;
begin
  FStackCount := 0;
  for LY := 0 to Camera.Resolution.Y - 1 do
    for LX := 0 to Camera.Resolution.X - 1 do
      FScreenBuffer[LX, LY].Init(0);
end;

procedure TRenderer.SetTaskCount(const Value: Integer);
begin
  FTaskCount := Value;
end;

end.
