
{$MODE objfpc}{$H+}

uses
  SysUtils, X, XLib, XUtil, keysym, ctypes;

const
  CFrameDuration = 50;

var
  dpy: PDisplay;
  xwin: string;
  root_window_id: TWindow;
  root: TWindow;
  own_window: boolean;
  running: boolean;
  screen: integer;
  wa: TXWindowAttributes;
  map: TPixmap;
  gc: TGC;
  event: TXEvent;
  wmDeleteMessage: TAtom;
  hello: string;

  fontStructure: PXFontStruct;
  direction, ascent, descent: cint;
  overall: TXCharStruct;
  _x, _y, dx, dy: integer;

  frameStart, elapsed: qword;

begin
  dpy := XOpenDisplay(nil);

  if dpy = nil then
  begin
    WriteLn(ErrOutput, 'Failed to open display');
    Halt(1);
  end;

  xwin := GetEnvironmentVariable('XSCREENSAVER_WINDOW');
  root_window_id := StrToQWordDef(xwin, 0);
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

  WriteLn('[DEBUG] root = ', root);

  XSelectInput(dpy, root, ExposureMask or StructureNotifyMask or KeyPressMask);
  XGetWindowAttributes(dpy, root, @wa);
  map := XCreatePixmap(dpy, root, wa.width, wa.height, wa.depth);
  gc := XCreateGC(dpy, root, 0, nil);

  fontStructure := XLoadQueryFont(dpy, 'fixed');
  XSetFont(dpy, gc, fontStructure^.fid);
  hello := TimeToStr(Now);
  XTextExtents(fontStructure, pchar(hello), Length(hello), @direction, @ascent, @descent, @overall);

  _x := 0;
  _y := ascent;
  dx := 1;
  dy := 1;

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

    XSetForeground(dpy, gc, $000000);
    XFillRectangle(dpy, map, gc, 0, 0, wa.width, wa.height);
    XSetForeground(dpy, gc, $00FF00);
    hello := TimeToStr(Now);
    XDrawImageString(dpy, map, gc, _x, _y, pchar(hello), Length(hello));
    XCopyArea(dpy, map, root, gc, 0, 0, wa.width, wa.height, 0, 0);
    XFlush(dpy);

    _x := _x + dx;
    if _x = -1 then
    begin
      _x := 1;
      dx := -1 * dx;
    end else
    if _x = wa.width - overall.width then
    begin
      _x := wa.width - overall.width - 2;
      dx := -1 * dx;
    end;

    _y := _y + dy;
    if _y < ascent then
    begin
      _y := ascent + 1;
      dy := -1 * dy;
    end else
    if _y = wa.height - descent then
    begin
      _y := wa.height - descent - 2;
      dy := -1 * dy;
    end;

    elapsed := GetTickCount64 - frameStart;
    if elapsed < CFrameDuration then
      Sleep(Cardinal(CFrameDuration - elapsed));
  end;

  XFreePixmap(dpy, map);
  XFreeGC(dpy, gc);

  if own_window then
    XDestroyWindow(dpy, root);

  XCloseDisplay(dpy);
end.
