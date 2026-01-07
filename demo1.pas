
{$MODE objfpc}{$H+}

uses
  SysUtils, X, XLib, XUtil, ctypes;

var
  dpy: PDisplay;
  xwin: string;
  root_window_id: integer;
  root: TWindow;
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
  
begin
  dpy := XOpenDisplay(nil);
  xwin := GetEnvironmentVariable('XSCREENSAVER_WINDOW');
  root_window_id := StrToIntDef(xwin, 0);
  
  if root_window_id <> 0 then
  begin
    root := root_window_id;
  end else
  begin
    screen := DefaultScreen(dpy);
    root := XCreateSimpleWindow(dpy, RootWindow(dpy, screen), 0, 0, 600, 400, 1, BlackPixel(dpy, screen), WhitePixel(dpy, screen));
    XMapWindow(dpy, root);
  end;
  
  WriteLn('[DEBUG] root = ', root);
  
  XSelectInput(dpy, root, ExposureMask or StructureNotifyMask);
  XGetWindowAttributes(dpy, root, @wa);
  map := XCreatePixmap(dpy, root, wa.width, wa.height, wa.depth);
  gc := XCreateGC(dpy, root, 0, nil);
  wmDeleteMessage := XInternAtom(dpy, 'WM_DELETE_WINDOW', FALSE);
  XSetWMProtocols(dpy, root, @wmDeleteMessage, 1);
  
  fontStructure := XLoadQueryFont(dpy, 'fixed');
  XSetFont(dpy, gc, fontStructure^.fid);
  hello := TimeToStr(Now);
  XTextExtents(fontStructure, pchar(hello), Length(hello), @direction, @ascent, @descent, @overall);
  
  _x := 0;
  _y := ascent;
  dx := 1;
  dy := 1;
  
  while TRUE do
  begin
    if XCheckWindowEvent(dpy, root, StructureNotifyMask, @event)
    or XCheckTypedWindowEvent(dpy, root, ClientMessage, @event) then
      if (event._type = ConfigureNotify) then
      begin
      end else
      if (event._type = ClientMessage) then
        if event.xclient.data.l[0] = wmDeleteMessage then
          Break;
    
    XSetBackground(dpy, gc, $000000);
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
    
    Sleep(50);
  end;
  
  XFreePixmap(dpy, map);
  XFreeGC(dpy, gc);
  XDestroyWindow(dpy, root);
  XCloseDisplay(dpy);
end.
