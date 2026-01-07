
{$MODE objfpc}{$H+}

uses
  SysUtils, X, XLib, XUtil, Cairo, CairoXLib;

procedure draw(const cr: pcairo_t; const x, y: double; const atext: string);
begin
  cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
  cairo_paint(cr);
  cairo_set_source_rgb(cr, 0.118, 0.565, 1.000);
  cairo_move_to(cr, x, y);
  cairo_show_text(cr, pchar(atext));
end;

procedure update(var x, y, dx, dy: double; const dt: double; const width, height: integer; const ex: cairo_text_extents_t);
begin
  x := x + dx * dt;
  y := y + dy * dt;

  if x < ex.x_bearing then
  begin
    x := 2 * ex.x_bearing - x;
    dx := -1 * dx;
  end else
  if x > width - ex.width then
  begin
    x := 2 * (width - ex.width) - x;
    dx := -1 * dx;
  end;

  if y < -ex.y_bearing then
  begin
    y := 2 * -ex.y_bearing - y;
    dy := -1 * dy;
  end else
  if y > height then
  begin
    y := 2 * height - y;
    dy := -1 * dy;
  end;
end;

const
  CFontName = 'Palatine Parliamentary';
  
var
  dpy: PDisplay;
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
  ex: cairo_text_extents_t;
  s: string;
  lastUpdate, current, dt: qword;
  
begin
  Randomize;
  
  dpy := XOpenDisplay(nil);
  root_window_id := StrToIntDef(GetEnvironmentVariable('XSCREENSAVER_WINDOW'), 0);
  
  if root_window_id <> 0 then
  begin
    root := root_window_id;
  end else
  begin
    screen := DefaultScreen(dpy);
    root := XCreateSimpleWindow(dpy, RootWindow(dpy, screen), 0, 0, 600, 400, 1, BlackPixel(dpy, screen), WhitePixel(dpy, screen));
    XMapWindow(dpy, root);
  end;
  
  XSelectInput(dpy, root, ExposureMask or StructureNotifyMask);
  XGetWindowAttributes(dpy, root, @wa);
  map := XCreatePixmap(dpy, root, wa.width, wa.height, wa.depth);
  gc := XCreateGC(dpy, root, 0, nil);
  wmDeleteMessage := XInternAtom(dpy, 'WM_DELETE_WINDOW', FALSE);
  XSetWMProtocols(dpy, root, @wmDeleteMessage, 1);
  
  _x := Random(wa.width div 2);
  _y := Random(wa.height div 2);
  dx := Random(40) + 40;
  dy := Random(20) + 20;
  
  sf := cairo_xlib_surface_create(dpy, map, DefaultVisual(dpy, DefaultScreen(dpy)), wa.width, wa.height);
  cr := cairo_create(sf);
  
  cairo_select_font_face(cr, CFontName, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
  cairo_set_font_size(cr, 48);
  
  lastUpdate := GetTickCount64;
  
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
    
    current := GetTickCount64;
    dt := current - lastUpdate;
    
    s := TimeToStr(Now);
    draw(cr, _x, _y, s);
    
    XCopyArea(dpy, map, root, gc, 0, 0, wa.width, wa.height, 0, 0);
    XFlush(dpy);
    
    cairo_text_extents(cr, pchar(s), @ex);
    update(_x, _y, dx, dy, dt / 1000, wa.width, wa.height, ex);
    
    lastUpdate := current;
    Sleep(16);
  end;
  
  cairo_destroy(cr);
  cairo_surface_destroy(sf);
  
  XFreePixmap(dpy, map);
  XFreeGC(dpy, gc);
  XDestroyWindow(dpy, root);
  XCloseDisplay(dpy);
end.
