
{$MODE objfpc}{$H+}

uses
  SysUtils, X, XLib, XUtil, keysym, Cairo, CairoXLib;

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
  CFrameDuration = 16;

var
  dpy: PDisplay;
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
  _x, _y, dx, dy: double;
  sf: pcairo_surface_t;
  cr: pcairo_t;
  ex: cairo_text_extents_t;
  s: string;
  lastUpdate, current, dt: qword;
  frameStart, elapsed: qword;

begin
  Randomize;

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
  map := XCreatePixmap(dpy, root, wa.width, wa.height, wa.depth);
  gc := XCreateGC(dpy, root, 0, nil);

  _x := Random(wa.width div 2);
  _y := Random(wa.height div 2);
  dx := Random(40) + 40;
  dy := Random(20) + 20;

  sf := cairo_xlib_surface_create(dpy, map, wa.visual, wa.width, wa.height);
  cr := cairo_create(sf);

  cairo_select_font_face(cr, CFontName, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
  cairo_set_font_size(cr, 48);

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

    s := TimeToStr(Now);
    draw(cr, _x, _y, s);

    XCopyArea(dpy, map, root, gc, 0, 0, wa.width, wa.height, 0, 0);
    XFlush(dpy);

    cairo_text_extents(cr, pchar(s), @ex);
    update(_x, _y, dx, dy, dt / 1000, wa.width, wa.height, ex);

    lastUpdate := current;

    elapsed := GetTickCount64 - frameStart;
    if elapsed < CFrameDuration then
      Sleep(Cardinal(CFrameDuration - elapsed));
  end;

  cairo_destroy(cr);
  cairo_surface_destroy(sf);

  XFreePixmap(dpy, map);
  XFreeGC(dpy, gc);

  if own_window then
    XDestroyWindow(dpy, root);

  XCloseDisplay(dpy);
end.
