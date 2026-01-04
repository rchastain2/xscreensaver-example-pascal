
{$MODE objfpc}{$H+}

uses
  SysUtils, X, XLib, XUtil, Cairo, CairoXLib;

const
  BALL_RADIUS = 40;

procedure draw(const cr: pcairo_t; const x, y: double);
begin
  cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
  cairo_paint(cr);
  cairo_arc(cr, x, y, BALL_RADIUS, 0, 2 * PI);
  cairo_set_source_rgb(cr, 0.165, 0.322, 0.745);
  cairo_fill(cr);
end;

procedure update(var x, y, dx, dy: double; const dt: double; const width, height: integer);
begin
  x := x + dx * dt;
  y := y + dy * dt;

  if x < BALL_RADIUS then
  begin
    x := 2 * BALL_RADIUS - x;
    dx := -1 * dx;
  end else if x > width - BALL_RADIUS then
  begin
    x := 2 * (width - BALL_RADIUS) - x;
    dx := -1 * dx;
  end;

  if y < BALL_RADIUS then
  begin
    y := 2 * BALL_RADIUS - y;
    dy := -1 * dy;
  end else if y > height - BALL_RADIUS then
  begin
    y := 2 * (height - BALL_RADIUS) - y;
    dy := -1 * dy;
  end;
end;

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
  
  _x, _y, dx, dy: double;

  sf: pcairo_surface_t;
  cr: pcairo_t;

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
  
  _x := wa.width / 3;
  _y := wa.height / 3;
  dx := 180.0;
  dy := 120.0;
  
  sf := cairo_xlib_surface_create(dpy, map, DefaultVisual(dpy, DefaultScreen(dpy)), wa.width, wa.height);
  cr := cairo_create(sf);
  
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
    
    draw(cr, _x, _y);
    XCopyArea(dpy, map, root, gc, 0, 0, wa.width, wa.height, 0, 0);
    XFlush(dpy);
    
    update(_x, _y, dx, dy, 0.016, wa.width, wa.height);
    
    Sleep(16);
  end;
  
  cairo_destroy(cr);
  cairo_surface_destroy(sf);
  
  XFreePixmap(dpy, map);
  XFreeGC(dpy, gc);
  XDestroyWindow(dpy, root);
  XCloseDisplay(dpy);
end.
