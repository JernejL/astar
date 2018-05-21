// originally written by William Cairns - http://www.cairnsgames.co.za
// http://www.pascalgamedevelopment.com/forums/profile.php?mode=viewprofile&u=65

// Enchanchements, additional code by Jernej L.
// http://www.mathpudding.com

// please note that the path returned is REVERSED.

unit Astar;

interface

uses
    windows, dialogs, sysutils;

type
    AstarRec = packed record
        pt: Tpoint;
        w: integer;
    end;

    PInspectBlock = function(X, Y, Fx, Fy: integer): integer;

var
    Searching, Found: Boolean;
    Astack: array of AstarRec;

  // you fill in this:
    Source, Goal: Tpoint;
    freedom: integer; // 4=3 or 7=8

    CanGo: PInspectBlock;
    GRID: array of array of integer;
    GridDimensions: Tpoint;

  // you get out this:
    maxval: integer;
    patherror: boolean;
    Path: array of Tpoint;

  // fallback location
    closestpoint: AstarRec;
    IsClosest: boolean;
    Offsets: array[0..7] of record
        DX, DY: Integer;
        Cost: Integer;
    end =
    // 90° neighbour cubes
((
        DX: 0;
        DY: -1;
        Cost: 10
    ), (
        DX: -1;
        DY: 0;
        Cost: 10
    ), (
        DX: +1;
        DY: 0;
        Cost: 10
    ), (
        DX: 0;
        DY: +1;
        Cost: 10
    ),

     // 45° diagonals
        (
        DX: -1;
        DY: -1;
        Cost: 14
    ), (
        DX: +1;
        DY: -1;
        Cost: 14
    ), (
        DX: -1;
        DY: +1;
        Cost: 14
    ), (
        DX: +1;
        DY: +1;
        Cost: 14
    ));

procedure FindPath(const src, dest, Gridsize: Tpoint; const diagonals, pleasefallback: boolean; const grabcallback: PInspectBlock);

implementation

procedure InspectBlock(X, Y: Integer);
var
    I: Integer;
    W: Integer;
    AX, AY, AW, ABV: Integer;
begin

	// Calculate the initial weighting of this cell
    if (X = Source.x) and (Y = Source.y) then
        W := 0
    else
        W := GRID[X, Y];
	// Check each surrounding cell - if empty then
// calculate and add weighting
    for I := 0 to freedom do
    begin
        AX := X + Offsets[I].DX;
        AY := Y + Offsets[I].DY;

		// are we there yet?
        if (AX = Goal.X) and (AY = Goal.Y) then
        begin
            Found := True;
            Exit;
        end;

		// make sure it stays within the world
		if (AX >= 0) and (AY >= 0) and (AX <= GridDimensions.x - 1) and (AY <= GridDimensions.y - 1) = false then
			continue;

		// dont process start block
		if (AX = Source.x) and (AY = Source.y) then
			continue;
		// dont process same block again
        if GRID[AX, AY] <> 0 then
            continue;

        ABV := CanGo(AX, AY, X, Y);
        AW := W + Offsets[I].Cost + ABV;

        if (ABV <> -1) then // dont go thru walls
        begin

            if ABV = 0 then
            begin
                Found := false;
                Searching := false;
                Exit;
            end;

            GRID[AX, AY] := AW;
            if AW > maxval then
                maxval := AW;

            // this is the closest point in the path so far
            if (ABS(Goal.X - AX) + ABS(Goal.Y - AY)) < closestpoint.w then
            begin
                closestpoint.pt.x := AX;
                closestpoint.pt.y := AY;
                closestpoint.w := (ABS(Goal.X - AX) + ABS(Goal.Y - AY));
            end;

              // This block can be searched further

            setlength(Astack, length(Astack) + 1);
            with Astack[length(Astack) - 1] do
            begin
                pt.x := AX;
                pt.y := AY;
                W := AW;
            end;

        end;

    end;
end;

procedure Step;
var
    I, LC, J, W, X, Y: Integer;
    S: string;
begin
	if Found then
		Exit;
		
    if not Searching then
    begin
		// Do the first Step in the search pattern
        InspectBlock(Source.X, Source.Y);
        Searching := True;
    end
    else
    begin

        if high(astack) = -1 then
        begin
            patherror := true;
            exit;
        end;

        LC := 0;

		// instead of sorting the list every time, swapping bunch of items
		// we just find the lowest cost item in the list

        for I := 0 to length(Astack) - 1 do
        begin
            if astack[I].W < astack[LC].W then
                LC := I;
        end;

        X := Astack[LC].pt.x;
        Y := Astack[LC].pt.y;
        W := Astack[LC].W;

//      if length(astack) > 1 then begin // don't delete if it is the only way we have left
      // now delete this item
      // Move compensates for overlaps between the source and destination blocks.
        move(astack[LC + 1], astack[LC], (length(Astack) - 1 - LC) * sizeof(AstarRec));
        setlength(Astack, length(Astack) - 1); // delete last item physicaly
//      end;

      // Do one Step in the search pattern
        InspectBlock(X, Y);
    end;

end;

procedure CalcBestPath;
var
    lowest, prev: Tpoint;
    lowvalue: integer;
    finished: boolean;

    function findbestprev(pt: Tpoint): Tpoint;
    var
        i, ax, ay: integer;
    begin

		  // Check each surrounding cell - if empty then
		  // calculate and add weighting
        for i := 0 to freedom do
        begin
            ax := pt.X + Offsets[i].DX;
            ay := pt.Y + Offsets[i].DY;

            if (ax < 0) or (ay < 0) or (ax > GridDimensions.x - 1) or (ay > GridDimensions.y - 1) then
                continue;

            if (ax = source.X) and (ay = source.Y) then
            begin
                finished := True;
                Exit;
            end;

//        if CanGo(AX, AY, pt.X, pt.Y) = -1 then continue; // can't go here

            if GRID[ax, ay] > 0 then
            begin

                if GRID[ax, ay] < lowvalue then
                begin
                    lowvalue := GRID[ax, ay];
                    lowest.x := ax;
                    lowest.y := ay;
                end;

            end;
        end;

{        If (lowest.x = source.X) and (lowest.y = source.Y) then
        Begin
          finished := True;
          Exit;
        End;
}
    end;

begin

    if Found = false then
        exit;

    finished := false;
    lowvalue := maxint;

    lowest := Goal;

    repeat
        findbestprev(lowest);

        if finished = false then
        begin
            setlength(Path, length(path) + 1);
            Path[length(path) - 1] := lowest;
        end;

	//if (prev.x = lowest.x) and (prev.y = lowest.y) then           showmessage(inttostr(prev.x) + ' - ' + inttostr(prev.y)); //finished:= true;

	until (finished = true);

end;

procedure LookForPath;
begin
    repeat
        step;
    until (found = true) or (patherror = true);
end;

procedure FindPath(const src, dest, Gridsize: Tpoint; const diagonals, pleasefallback: boolean; const grabcallback: PInspectBlock);
var
    i: integer;
begin
    Source := src;
    Goal := dest;

    if diagonals = true then
        freedom := 7
    else
        freedom := 3;
    CanGo := grabcallback;

    GridDimensions := Gridsize;
    Searching := false;
    Found := false;
    patherror := false;
    closestpoint.w := maxint;
    IsClosest := false;

    setlength(Astack, 0);
    setlength(Path, 0);

    setlength(GRID, 0, 0); // zero it
    setlength(GRID, Gridsize.x, Gridsize.y);
	//fillchar(GRID[0], sizeof(GRID[0]), 0);

	//for i:= 0 to gridsize.x-1 do
	//fillchar(grid[i][0], gridsize.x * 4, 0);

	//for i:= 0 to gridsize.x-1 do
	//fillchar(@grid[i][0]^, gridsize.y * 4, 0);

	// find the path now
    LookForPath;

	// if closest point fallback is wanted process the path to closest point
    if (patherror = true) and (pleasefallback = true) then
    begin
        Goal := closestpoint.pt;

        Searching := false;
        Found := false;
        patherror := false;
        closestpoint.w := maxint;

        setlength(GRID, 0, 0); // zero it
        setlength(GRID, Gridsize.x, Gridsize.y);

		// add the closest point first
        setlength(Path, length(path) + 1);
        Path[length(path) - 1] := closestpoint.pt;

        LookForPath;

        CalcBestPath;

        IsClosest := true;

    end
    else if patherror = false then
        CalcBestPath; // no fallback, just find the path if there is one

end;

end.

