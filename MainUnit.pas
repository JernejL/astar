// originally written by William Cairns - http://www.cairnsgames.co.za
// http://www.pascalgamedevelopment.com/forums/profile.php?mode=viewprofile&u=65

// Enchanchements, additional code by Jernej L.
// http://www.gtatools.com

unit MainUnit;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
    Menus, StdCtrls, Grids, Astar;

type
    TForm1 = class(TForm)
        StringGrid1: TStringGrid;
        MainMenu1: TMainMenu;
        EndPoint1: TMenuItem;
        Block1: TMenuItem;
        CLEARDATA1: TMenuItem;
        TESTO1: TMenuItem;
        EndPoint2: TMenuItem;
        Floor1: TMenuItem;
        N1: TMenuItem;
        N2: TMenuItem;
        N3: TMenuItem;
        N4: TMenuItem;
        procedure StartPoint1Click(Sender: TObject);
        procedure EndPoint1Click(Sender: TObject);
        procedure FormCreate(Sender: TObject);
        procedure Block1Click(Sender: TObject);
        procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
        procedure CLEARDATA1Click(Sender: TObject);
        procedure TESTO1Click(Sender: TObject);
        procedure Floor1Click(Sender: TObject);
        procedure FormResize(Sender: TObject);
    private
        FStartPoint: TPoint;
        FEndPoint: TPoint;
        procedure SetStartPoint(const Value: TPoint);
        procedure SetEndPoint(const Value: TPoint);
    private
    { Private declarations }
        Searching, Found: Boolean;
        property StartPoint: TPoint read FStartPoint write SetStartPoint;
        property EndPoint: TPoint read FEndPoint write SetEndPoint;
    public
    { Public declarations }
    end;

var
    Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.SetEndPoint(const Value: TPoint);
begin
    StringGrid1.Cells[FEndPoint.X, FEndPoint.Y] := '';
    FEndPoint := Value; 
  // The Cell with Z in it is the goal Point of the Search
    StringGrid1.Cells[FEndPoint.X, FEndPoint.Y] := 'Z';
end;

procedure TForm1.SetStartPoint(const Value: TPoint);
begin
    StringGrid1.Cells[FStartPoint.X, FStartPoint.Y] := '';
    FStartPoint := Value; 
  // The Cell with A in it is the starting Point of the Search
    StringGrid1.Cells[FStartPoint.X, FStartPoint.Y] := 'A';
end;

procedure TForm1.StartPoint1Click(Sender: TObject);
begin
    StartPoint := Point(StringGrid1.Selection.Left, StringGrid1.Selection.Top);
end;

procedure TForm1.EndPoint1Click(Sender: TObject);
begin
    EndPoint := Point(StringGrid1.Selection.Left, StringGrid1.Selection.Top);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
    StartPoint := Point(3, 5);
    EndPoint := Point(7, 5);
    Searching := False;
    Found := False;
end;

procedure TForm1.Block1Click(Sender: TObject);
var
    I, J: Integer;
begin
  // X indicates unpassable
  // Ensure Start and End Points are not overwritten
    for I := StringGrid1.Selection.Left to StringGrid1.Selection.Right do
        for J := StringGrid1.Selection.Top to StringGrid1.Selection.Bottom do
            if not ((I = StartPoint.X) and (J = StartPoint.Y)) and not ((I = EndPoint.X) and (J = EndPoint.Y)) then
                StringGrid1.Cells[I, J] := 'X';
end;

procedure TForm1.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
    food: single;
begin

//inherited;

    with Sender as TDrawGrid do
    begin
        Canvas.Brush.Color := clwindow;

        if gdselected in State then
        begin
            Canvas.Brush.Color := clbtnshadow;
        end;

        if StringGrid1.cells[ACol, ARow] = 'A' then
            Canvas.Brush.Color := clyellow;

        if StringGrid1.cells[ACol, ARow] = 'Z' then
            Canvas.Brush.Color := clblue;

        if StringGrid1.cells[ACol, ARow] = 'X' then
            Canvas.Brush.Color := clblack;

        if StringGrid1.cells[ACol, ARow] = 'P' then
            Canvas.Brush.Color := clred;

        Canvas.FillRect(Rect);

        food := strtointdef(StringGrid1.cells[ACol, ARow], 0);
        if (maxval = 0) or (food = 0) then
            exit;

        try
            food := 128 / maxval;

            Canvas.Brush.Color := rgb(255 - round(food * strtointdef(StringGrid1.cells[ACol, ARow], 0)), 255 - round(food * strtointdef(StringGrid1.cells[ACol, ARow], 0)), 255 - round(food * strtointdef(StringGrid1.cells[ACol, ARow], 0)));

        except
        end;

        Canvas.FillRect(Rect);
        Canvas.TextOut(Rect.left, Rect.top, StringGrid1.cells[ACol, ARow]);

    end;

//Canvas.DrawFocusRect(Rect);

end;

procedure TForm1.CLEARDATA1Click(Sender: TObject);
var
    I, J: Integer;
begin

    for I := 0 to StringGrid1.colcount do
        for J := 0 to StringGrid1.rowcount do
            if not ((I = StartPoint.X) and (J = StartPoint.Y)) and not ((I = EndPoint.X) and (J = EndPoint.Y)) then
                if StringGrid1.Cells[I, J] <> 'X' then
                    StringGrid1.Cells[I, J] := '';

    Searching := false;
    Found := false;

    setlength(Astack, 0);
end;

procedure TForm1.Floor1Click(Sender: TObject);
var
    I, J: Integer;
begin
  // X indicates unpassable
  // Ensure Start and End Points are not overwritten
    for I := StringGrid1.Selection.Left to StringGrid1.Selection.Right do
        for J := StringGrid1.Selection.Top to StringGrid1.Selection.Bottom do
            if not ((I = StartPoint.X) and (J = StartPoint.Y)) and not ((I = EndPoint.X) and (J = EndPoint.Y)) then
                StringGrid1.Cells[I, J] := '';
end;

procedure TForm1.FormResize(Sender: TObject);
begin
    StringGrid1.rowcount := StringGrid1.height div StringGrid1.defaultrowheight - 1;
    StringGrid1.colcount := StringGrid1.width div StringGrid1.defaultcolwidth - 1;
end;

function blocktester(X, Y, Fx, Fy: integer): integer;
begin

// this function is called when path finder asks you weither it can process coordinate X,Y
// Fx, Fy are the coordinates from where the pathfinder is coming, you can use
// that to make some blocks only passable thru some sides and not all 4.

// you return -1 if you dont allow pathfinder to go to that block - like walls,
// this can be used to limit search area of the pathfinder as well.

// if you allow the pathfinder to go to that specific block, return a positive number,
// returning zero means you want to terminate path finding.

    result := -1; // if it isnt anything else - it is wall

    with Form1 do
    begin

// you MUST allow it to go into empty cubes AND start cube as well otherwise it won't find path back to the start!
        if (StringGrid1.Cells[X, Y] = '') or // allow empty cells
            (StringGrid1.Cells[X, Y] = 'A')   // allow to go back to the goal

// THIS is the guts of path finding, the magic formula that tells the pathfinder
// which blocks are worth more, so you can make it to rush to the goal or to
// find the best path ever.. depends on how much cpu power you can spend!

// the default cost for passing 1 cube sideways is 10
// if you use diagonal movement those cost 14

// the final formula is sideways/diagonal cost + what you tell it here
            then
            result := ((ABS(EndPoint.X - X) + ABS(EndPoint.Y - Y)) * 3);

    end;
end;

procedure TForm1.TESTO1Click(Sender: TObject);
var
    I, J: Integer;
    ms: integer;
begin

    CLEARDATA1Click(CLEARDATA1);

    ms := gettickcount;
    Astar.findpath(StartPoint, EndPoint, point(StringGrid1.colcount, StringGrid1.rowcount), true, true, @blocktester);
    ms := gettickcount - ms;
// note that the timing is limited to 16 ms windows timer precision...

// show what type of path this is
    if astar.IsClosest = true then
		caption := 'Pathfinder - Closest Path' // close as it gets
    else if (high(astar.path) = -1) and (astar.Found = true) then
        caption := 'Pathfinder - Immediate Path' // no actual path - the goal is right next to start
    else
        caption := 'Pathfinder - Direct Path'; // normal path to the goal

    if astar.Found = false then
        caption := 'Pathfinder - No Path';

    caption := format('%s (%d Ms)', [caption, ms]);

    if astar.Found = false then
        exit; // no drawing

{  For I := 0 to StringGrid1.colcount-1 do
    For J := 0 to StringGrid1.rowcount-1 do begin
    if (StringGrid1.Cells[I,J] <> 'A') then
    if (StringGrid1.Cells[I,J] <> 'Z') then
    if (StringGrid1.Cells[I,J] <> 'X') then
        StringGrid1.Cells[I,J]:= inttostr(astar.grid[i, j]);
        end;  }

    for I := 0 to high(astar.path) do
        StringGrid1.Cells[astar.path[I].X, astar.path[I].Y] := 'P';

// highlight searching points
//for i:= 0 to high(astar.astack) do
//StringGrid1.Cells[astar.Astack[i].pt.x, astar.Astack[i].pt.y]:= 'P';

end;

end.

