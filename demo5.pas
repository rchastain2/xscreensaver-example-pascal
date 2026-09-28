
{$MODE objfpc}{$H+}

uses
  SysUtils, X, XLib, XUtil, keysym, agg_basics, agg_2D;

const
  BALL_RADIUS = 40;
  CFrameDuration = 16;

procedure draw(const agg: Agg2D_ptr; const x, y: double);
begin
  agg^.clearAll(0, 0, 0);
  agg^.fillColor(35, 151, 212);
  agg^.lineColor(38, 47, 69);
  agg^.lineWidth(1);
  agg^.ellipse(x, y, BALL_RADIUS, BALL_RADIUS);
end;

procedure update(var x, y, dx, dy: double; const dt: double; const width, height: integer);
begin
  x := x + dx * dt;
  y := y + dy * dt;

  if x < BALL_RADIUS then
  begin
    x := 2 * BALL_RADIUS - x;
    dx := -1 * dx;
  end else
  if x > width - BALL_RADIUS then
  begin
    x := 2 * (width - BALL_RADIUS) - x;
    dx := -1 * dx;
  end;

  if y < BALL_RADIUS then
  begin
    y := 2 * BALL_RADIUS - y;
    dy := -1 * dy;
  end else
  if y > height - BALL_RADIUS then
  begin
    y := 2 * (height - BALL_RADIUS) - y;
    dy := -1 * dy;
  end;
end;

var
  dpy: PDisplay;
  root_window_id: TWindow;
  root: TWindow;
  own_window: boolean;
  running: boolean;
  screen: integer;
  wa: TXWindowAttributes;
  gc: TGC;
  event: TXEvent;
  wmDeleteMessage: TAtom;

  _x, _y, dx, dy: double;

  buffer: pbyte;
  image: PXImage;
  agg: Agg2D_ptr;

  lastUpdate, current, dt: qword;
  frameStart, elapsed: qword;

begin
  dpy := XOpenDisplay(nil);

  if dpy = nil then
  begin
    WriteLn(ErrOutput, 'Failed to open display');
    Halt(1);
  end;

  root_window_id := StrToQWordDef(GetEnvironmentVariable('XSCREENSAVER_WINDOW'), 0);
  own_window := FALSE;
  wmDeleteMessage := 0;

  if root_window_id <> 0 then
  begin
    root := root_window_id;
  end else
  begin
    own_window := TRUE;
    screen := DefaultScreen(dpy);
    root := XCreateSimpleWindow(dpy, RootWindow(dpy, screen), 0, 0, 600, 400, 1, BlackPixel(dpy, screen), WhitePixel(dpy, screen));
    wmDeleteMessage := XInternAtom(dpy, 'WM_DELETE_WINDOW', FALSE);
    XSetWMProtocols(dpy, root, @wmDeleteMessage, 1);
    XMapWindow(dpy, root);
  end;

  XSelectInput(dpy, root, ExposureMask or StructureNotifyMask or KeyPressMask);
  XGetWindowAttributes(dpy, root, @wa);

  if wa.depth < 24 then
  begin
    WriteLn(ErrOutput, 'Unsupported depth: ', wa.depth);
    if own_window then
      XDestroyWindow(dpy, root);
    XCloseDisplay(dpy);
    Halt(1);
  end;

  gc := XCreateGC(dpy, root, 0, nil);

  buffer := GetMem(wa.width * wa.height * 4);
  image := XCreateImage(dpy, wa.visual, wa.depth, ZPixmap, 0, pchar(buffer), wa.width, wa.height, 32, wa.width * 4);

  New(agg, Construct);
  agg^.attach(int8u_ptr(buffer), wa.width, wa.height, wa.width * 4);

  _x := wa.width / 3;
  _y := wa.height / 3;
  dx := 180.0;
  dy := 120.0;

  lastUpdate := GetTickCount64;

  running := TRUE;

  while running do
  begin
    frameStart := GetTickCount64;

    while running and (XPending(dpy) > 0) do
    begin
      XNextEvent(dpy, @event);
      if event._type = KeyPress then
      begin
        if XLookupKeysym(@event.xkey, 0) = XK_Escape then
          running := FALSE;
      end else
      if event._type = ClientMessage then
      begin
        if TAtom(event.xclient.data.l[0]) = wmDeleteMessage then
          running := FALSE;
      end;
    end;

    if not running then
      Break;

    current := GetTickCount64;
    dt := current - lastUpdate;

    draw(agg, _x, _y);

    XPutImage(dpy, root, gc, image, 0, 0, 0, 0, wa.width, wa.height);
    XFlush(dpy);

    update(_x, _y, dx, dy, dt / 1000, wa.width, wa.height);

    lastUpdate := current;

    elapsed := GetTickCount64 - frameStart;
    if elapsed < CFrameDuration then
      Sleep(Cardinal(CFrameDuration - elapsed));
  end;

  Dispose(agg, Destruct);

  image^.data := nil;
  XDestroyImage(image);
  FreeMem(buffer);

  XFreeGC(dpy, gc);

  if own_window then
    XDestroyWindow(dpy, root);

  XCloseDisplay(dpy);
end.
