
{$MODE objfpc}{$H+}

uses
  SysUtils, X, XLib, XUtil, Cairo, CairoXLib;

const
  BALL_RADIUS = 100;

procedure draw(const cr: pcairo_t; const x, y: double; const image: pcairo_surface_t; const offset_x, offset_y: double);
begin
  cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
  cairo_paint(cr);
  cairo_save(cr);
  cairo_arc(cr, x, y, BALL_RADIUS, 0, 2 * PI);
  cairo_clip(cr);
  cairo_set_source_surface(cr, image, offset_x, offset_y);
  cairo_paint(cr);
  cairo_restore(cr);
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
  root_window_id: integer;
  root: TWindow;
  screen: integer;
  wa: TXWindowAttributes;
  map: TPixmap;
  gc: TGC;
  event: TXEvent;
  wmDeleteMessage: TAtom;
  
  _x, _y, dx, dy: double;

  image: pcairo_surface_t;
  image_width, image_height: integer;
  offset_x, offset_y: double;
  
  sf: pcairo_surface_t;
  cr: pcairo_t;
  
  lastUpdate, current, dt: qword;
  
begin
  dpy := XOpenDisplay(nil);
  root_window_id := StrToIntDef(GetEnvironmentVariable('XSCREENSAVER_WINDOW'), 0);
  
  if root_window_id <> 0 then
  begin
    root := root_window_id;
  end else
  begin
    screen := DefaultScreen(dpy);
    root := XCreateSimpleWindow(dpy, RootWindow(dpy, screen), 0, 0, 640, 480, 1, BlackPixel(dpy, screen), WhitePixel(dpy, screen));
    XMapWindow(dpy, root);
  end;
  
  XSelectInput(dpy, root, ExposureMask or StructureNotifyMask);
  XGetWindowAttributes(dpy, root, @wa);
  
  WriteLn(Format('[DEBUG] wa.width %d wa.height %d', [wa.width, wa.height]));
  
  map := XCreatePixmap(dpy, root, wa.width, wa.height, wa.depth);
  gc := XCreateGC(dpy, root, 0, nil);
  
  wmDeleteMessage := XInternAtom(dpy, 'WM_DELETE_WINDOW', FALSE);
  XSetWMProtocols(dpy, root, @wmDeleteMessage, 1);
  
  _x := wa.width / 3;
  _y := wa.height / 3;
  dx := 180.0;
  dy := 120.0;
  
  image := cairo_image_surface_create_from_png(pchar(ExtractFilePath(ParamStr(0)) + 'corot.png'));
  image_width := cairo_image_surface_get_width(image);
  image_height := cairo_image_surface_get_height(image);
  
  WriteLn(Format('[DEBUG] image_width %d image_height %d', [image_width, image_height]));
  
  sf := cairo_xlib_surface_create(dpy, map, DefaultVisual(dpy, DefaultScreen(dpy)), wa.width, wa.height);
  cr := cairo_create(sf);
  
  offset_x := 0;
  offset_y := 0;
  
  if wa.width  < image_width  then offset_x := - Random(image_width  - wa.width);
  if wa.height < image_height then offset_y := - Random(image_height - wa.height);
  
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
    
    draw(cr, _x, _y, image, offset_x, offset_y);
    
    XCopyArea(dpy, map, root, gc, 0, 0, wa.width, wa.height, 0, 0);
    XFlush(dpy);
    
    update(_x, _y, dx, dy, dt / 1000, wa.width, wa.height);
    
    lastUpdate := current;
    Sleep(16);
  end;
  
  cairo_destroy(cr);
  cairo_surface_destroy(sf);
  cairo_surface_destroy(image);
  
  XFreePixmap(dpy, map);
  XFreeGC(dpy, gc);
  XDestroyWindow(dpy, root);
  XCloseDisplay(dpy);
end.
