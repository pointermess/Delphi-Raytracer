program MtTest;

uses
  System.StartUpCopy,
  FMX.Forms,
  fMtMain in 'fMtMain.pas' {Form2},
  uTypes in 'uTypes.pas',
  uWorld in 'uWorld.pas',
  uCamera in 'uCamera.pas',
  uRenderer in 'uRenderer.pas',
  uCameraController in 'uCameraController.pas',
  uPostProcessor in 'uPostProcessor.pas';

{$R *.res}

begin
  //ReportMemoryLeaksOnShutdown := TRue;
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
