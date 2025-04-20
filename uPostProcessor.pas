unit uPostProcessor;

interface

uses
  Neslib.FastMath,
  uTypes;

type
  TPostProcessor = class
  private
  public
    constructor Create();

    function PostProcess(const AColor: TVector4; const ASettings : TPostProcessorSettings) : TVector4;
  end;

implementation

function ApplyBrightness(const Color: TVector4; const Brightness: Single): TVector4;
begin
  Result.X := EnsureRange(Color.X + Brightness, 0, 1);
  Result.Y := EnsureRange(Color.Y + Brightness, 0, 1);
  Result.Z := EnsureRange(Color.Z + Brightness, 0, 1);
  Result.W := Color.W;
end;

function ApplyContrast(const Color: TVector4; Contrast: Single): TVector4;
begin
  // Apply contrast adjustment
  Result.X := ((Color.X - 0.5) * Contrast) + 0.5;
  Result.Y := ((Color.Y - 0.5) * Contrast) + 0.5;
  Result.Z := ((Color.Z - 0.5) * Contrast) + 0.5;
  Result.W := Color.W; // Keep alpha channel unchanged
end;

function ACES_ToneMapping(const Color: TVector4): TVector4;
const
  A = 2.51;
  B = 0.03;
  C = 2.43;
  D = 0.59;
  E = 0.14;
begin
  Result.X := EnsureRange((Color.X * (A * Color.X + B)) / (Color.X * (C * Color.X + D) + E), 0, 1);
  Result.Y := EnsureRange((Color.Y * (A * Color.Y + B)) / (Color.Y * (C * Color.Y + D) + E), 0, 1);
  Result.Z := EnsureRange((Color.Z * (A * Color.Z + B)) / (Color.Z * (C * Color.Z + D) + E), 0, 1);
  Result.W := Color.W;
end;

function Cinematic_ToneMapping(const Color: TVector4): TVector4;
const
  A = 2.51;
  B = 0.03;
  C = 2.43;
  D = 0.59;
  E = 0.14;
  FilmicStrength = 1.2; // Adjust according to preference
begin
  // Apply ACES tone mapping algorithm
  Result.X := EnsureRange((Color.X * (A * Color.X + B)) / (Color.X * (C * Color.X + D) + E), 0, 1);
  Result.Y := EnsureRange((Color.Y * (A * Color.Y + B)) / (Color.Y * (C * Color.Y + D) + E), 0, 1);
  Result.Z := EnsureRange((Color.Z * (A * Color.Z + B)) / (Color.Z * (C * Color.Z + D) + E), 0, 1);
  Result.W := Color.W;

  // Apply filmic curve
  Result.X := Power(Result.X, FilmicStrength);
  Result.Y := Power(Result.Y, FilmicStrength);
  Result.Z := Power(Result.Z, FilmicStrength);

  // Add additional cinematic effects here (e.g., color grading, vignetting, lens effects)
  // Example:
  // Result := ApplyColorGrading(Result);
  // Result := ApplyVignetting(Result);
  // Result := ApplyLensEffects(Result);

end;

function ReinhardToneMapping(const Color: TVector4; Exposure: Single): TVector4;
const
  WhitePoint = 0.5; // Adjust as needed
var
  Luminance, LuminanceAdjusted : Single;
begin
  // Calculate luminance
  Luminance := (Color.X + Color.Y + Color.Z) / 3;

  // Apply exposure adjustment
  LuminanceAdjusted := Luminance / (1 + Luminance);

  // Normalize color
  Result.X := Color.X / (Color.X + WhitePoint);
  Result.Y := Color.Y / (Color.Y + WhitePoint);
  Result.Z := Color.Z / (Color.Z + WhitePoint);

  // Apply tone mapping
  Result.X := Result.X * LuminanceAdjusted / Luminance;
  Result.Y := Result.Y * LuminanceAdjusted / Luminance;
  Result.Z := Result.Z * LuminanceAdjusted / Luminance;
  Result.W := Color.W;
end;

function AdjustExposure(const Color: TVector4; Exposure: Single): TVector4;
begin
  // Apply exposure adjustment
  Result.X := Color.X / Exposure;
  Result.Y := Color.Y / Exposure;
  Result.Z := Color.Z / Exposure;

  // Clamp color to ensure it stays within valid range
  Result.X := EnsureRange(Result.X, 0, 1);
  Result.Y := EnsureRange(Result.Y, 0, 1);
  Result.Z := EnsureRange(Result.Z, 0, 1);
  Result.W := 1;
end;

function ApplySaturation(const Color: TVector4; Saturation: Single): TVector4;
var
  Gray: Single;
begin
  // Convert color to grayscale
  Gray := (Color.X + Color.Y + Color.Z) / 3;

  // Interpolate between grayscale and original color based on saturation
  Result.X := EnsureRange(Gray + Saturation * (Color.X - Gray), 0, 1);
  Result.Y := EnsureRange(Gray + Saturation * (Color.Y - Gray), 0, 1);
  Result.Z := EnsureRange(Gray + Saturation * (Color.Z - Gray), 0, 1);
  Result.W := Color.W; // Keep alpha channel unchanged
end;

{ TPostProcessor }

constructor TPostProcessor.Create;
begin

end;

function TPostProcessor.PostProcess(const AColor: TVector4; const ASettings : TPostProcessorSettings) : TVector4;
var
  LX, LY: Integer;
begin
  Result := AColor;

  Result := Cinematic_ToneMapping(Result);
  Result := AdjustExposure(Result, 1.1);
  Result := ApplyBrightness(Result, ASettings.Brightness);
  Result := ApplyContrast(Result, ASettings.Contrast);
  Result := ApplySaturation(Result, ASettings.Saturation);
end;

end.
