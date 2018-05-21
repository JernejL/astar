program AStarTut;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {Form1},
  Astar in 'Astar.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
