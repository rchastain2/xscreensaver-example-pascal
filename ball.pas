
{$MODE objfpc}{$H+}

uses
  SysUtils, X, XLib, XUtil, Cairo, CairoXLib;

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
  
  while TRUE do
  begin
    if XCheckWindowEvent(dpy, root, StructureNotifyMask, @event) or XCheckTypedWindowEvent(dpy, root, ClientMessage, @event) then
      if (event._type = ConfigureNotify) then
      begin
      end else
      if (event._type = ClientMessage) then
        if event.xclient.data.l[0] = wmDeleteMessage then
          Break;
    
		XSetBackground(dpy, gc, $000000);
		XSetForeground(dpy, gc, $000000);
		XFillRectangle(dpy, map, gc, 0, 0, wa.width, wa.height);
    XSetForeground(dpy, gc, $FFFF00);
    hello := TimeToStr(Now);
    XDrawImageString(dpy, map, gc, 50, 50, pchar(hello), Length(hello));
    XCopyArea(dpy, map, root, gc, 0, 0, wa.width, wa.height, 0, 0);
    XFlush(dpy);
    
    Sleep(16);
  end;
  
  XFreePixmap(dpy, map);
  XFreeGC(dpy, gc);
  XDestroyWindow(dpy, root);
  XCloseDisplay(dpy);
end.
