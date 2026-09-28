
{$MODE objfpc}{$H+}

uses
  SysUtils, Math, X, XLib, XUtil, keysym, agg_basics, agg_2D;

const
  CFrameDuration = 33;
  TILT = 0.38;
  PLANET_COUNT = 6;
  ASTEROID_COUNT = 220;
  STAR_COUNT = 450;
  TWINKLE_COUNT = 24;
  KEPLER = 0.06;

type
  TPlanet = record
    orbit, radius, angle, speed: double;
    light, base, dark: Color;
    ring, moon: boolean;
  end;

  TAsteroid = record
    orbit, angle, speed, size: double;
    shade: byte;
  end;

  TTwinkle = record
    x, y, size, phase, freq: double;
  end;

  TComet = record
    a, e, phi, theta, gm: double;
  end;

  TItemKind = (ikPlanet, ikComet, ikSun);

  TItem = record
    kind: TItemKind;
    index: integer;
    depth: double;
  end;

var
  width, height: integer;
  cx, cy, u: double;
  planets: array[0..PLANET_COUNT - 1] of TPlanet;
  asteroids: array[0..ASTEROID_COUNT - 1] of TAsteroid;
  twinkles: array[0..TWINKLE_COUNT - 1] of TTwinkle;
  comet: TComet;
  moonAngle: double;
  time: double;

function RGBA(const r, g, b: byte; const a: byte = 255): Color;
begin
  Result.Construct(r, g, b, a);
end;

procedure SetPlanet(const i: integer; const orbit, radius: double; const light, base, dark: Color; const ring: boolean = FALSE; const moon: boolean = FALSE);
begin
  planets[i].orbit := orbit;
  planets[i].radius := radius;
  planets[i].angle := Random * 2 * PI;
  planets[i].speed := KEPLER / Power(orbit, 1.5);
  planets[i].light := light;
  planets[i].base := base;
  planets[i].dark := dark;
  planets[i].ring := ring;
  planets[i].moon := moon;
end;

procedure InitScene;
var
  i: integer;
begin
  cx := width / 2;
  cy := height / 2;
  u := Min(width / 2, height / 2 / TILT) * 0.95;

  SetPlanet(0, 0.17, 0.018, RGBA(230, 225, 220), RGBA(150, 140, 135), RGBA(30, 28, 30));
  SetPlanet(1, 0.25, 0.028, RGBA(255, 245, 210), RGBA(220, 180, 110), RGBA(50, 35, 20));
  SetPlanet(2, 0.35, 0.031, RGBA(200, 240, 255), RGBA(50, 120, 210), RGBA(8, 18, 45), FALSE, TRUE);
  SetPlanet(3, 0.45, 0.022, RGBA(255, 200, 170), RGBA(200, 80, 45), RGBA(40, 12, 8));
  SetPlanet(4, 0.72, 0.068, RGBA(255, 240, 215), RGBA(210, 160, 110), RGBA(45, 28, 18));
  SetPlanet(5, 0.90, 0.052, RGBA(255, 245, 205), RGBA(215, 190, 130), RGBA(45, 38, 22), TRUE);

  for i := 0 to ASTEROID_COUNT - 1 do
  begin
    asteroids[i].orbit := 0.54 + Random * 0.08 + (Random - 0.5) * 0.03;
    asteroids[i].angle := Random * 2 * PI;
    asteroids[i].speed := KEPLER / Power(asteroids[i].orbit, 1.5);
    asteroids[i].size := 0.6 + Random * 1.2;
    asteroids[i].shade := 110 + Random(100);
  end;

  for i := 0 to TWINKLE_COUNT - 1 do
  begin
    twinkles[i].x := Random * width;
    twinkles[i].y := Random * height;
    twinkles[i].size := 4 + Random * 7;
    twinkles[i].phase := Random * 2 * PI;
    twinkles[i].freq := 0.8 + Random * 2.5;
  end;

  comet.a := 0.62;
  comet.e := 0.86;
  comet.phi := Random * 2 * PI;
  comet.theta := PI * 0.9;
  comet.gm := 4 * PI * PI * Power(comet.a, 3) / Sqr(45);

  moonAngle := 0;
  time := 0;
end;

procedure DrawTwinkles(const agg: Agg2D_ptr);
var
  i: integer;
  k: double;
  a: byte;
begin
  agg^.noLine;
  for i := 0 to TWINKLE_COUNT - 1 do
    with twinkles[i] do
    begin
      k := 0.5 + 0.5 * Sin(time * freq + phase);
      a := Round(40 + 215 * k * k);
      agg^.fillColor(220, 230, 255, a);
      agg^.star(x, y, 0.8, size * (0.6 + 0.4 * k), PI / 2, 4);
      agg^.fillRadialGradient(x, y, size * 0.5, RGBA(255, 255, 255, a), RGBA(180, 200, 255, 0));
      agg^.ellipse(x, y, size * 0.5, size * 0.5);
    end;
end;

procedure DrawOrbits(const agg: Agg2D_ptr; const a0, a1: double);
var
  i: integer;
begin
  agg^.noFill;
  agg^.lineWidth(1);
  agg^.lineColor(130, 150, 220, 45);
  for i := 0 to PLANET_COUNT - 1 do
    agg^.arc(cx, cy, planets[i].orbit * u, planets[i].orbit * u * TILT, a0, a1);
end;

procedure DrawBackground(const agg: Agg2D_ptr);
var
  i: integer;
  x, y, r, s: double;
  b: byte;
begin
  agg^.noLine;
  agg^.fillLinearGradient(0, 0, width, height, RGBA(4, 6, 20), RGBA(14, 6, 30));
  agg^.rectangle(0, 0, width, height);

  agg^.fillRadialGradient(width * 0.15, height * 0.25, u * 0.7, RGBA(90, 40, 140, 70), RGBA(40, 20, 90, 0));
  agg^.ellipse(width * 0.15, height * 0.25, u * 0.7, u * 0.7);
  agg^.fillRadialGradient(width * 0.85, height * 0.8, u * 0.8, RGBA(20, 110, 140, 60), RGBA(10, 40, 90, 0));
  agg^.ellipse(width * 0.85, height * 0.8, u * 0.8, u * 0.8);
  agg^.fillRadialGradient(width * 0.7, height * 0.15, u * 0.5, RGBA(150, 50, 90, 45), RGBA(60, 20, 60, 0));
  agg^.ellipse(width * 0.7, height * 0.15, u * 0.5, u * 0.5);

  for i := 0 to STAR_COUNT - 1 do
  begin
    s := Random;
    x := Random * width;
    if s < 0.5 then
      y := x * height / width + (Random - 0.5) * height * 0.35
    else
      y := Random * height;
    r := 0.4 + Random * Random * 1.4;
    b := 120 + Random(135);
    agg^.fillColor(b, b, Min(255, b + 30), 150 + Random(105));
    agg^.ellipse(x, y, r, r);
  end;

  agg^.fillRadialGradient(cx, cy, u * 0.4, RGBA(255, 190, 80, 110), RGBA(255, 90, 0, 0));
  agg^.ellipse(cx, cy, u * 0.4, u * 0.4);

  DrawOrbits(agg, 0, 2 * PI);
end;

procedure DrawAsteroids(const agg: Agg2D_ptr; const front: boolean);
var
  i: integer;
  s: double;
begin
  agg^.noLine;
  for i := 0 to ASTEROID_COUNT - 1 do
    with asteroids[i] do
    begin
      s := Sin(angle);
      if (s >= 0) <> front then
        Continue;
      agg^.fillColor(shade, shade - 10, shade - 25, 200);
      agg^.ellipse(cx + orbit * u * Cos(angle), cy + orbit * u * TILT * s, size * (1 + 0.2 * s), size * (1 + 0.2 * s));
    end;
end;

procedure DrawSun(const agg: Agg2D_ptr);
var
  r, pulse: double;
begin
  r := 0.085 * u;
  pulse := 1 + 0.06 * Sin(time * 1.7);

  agg^.noLine;
  agg^.fillRadialGradient(cx, cy, r * 2.6, RGBA(255, 230, 140, 170), RGBA(255, 120, 20, 0));
  agg^.star(cx, cy, r * 1.1, r * 2.6 * pulse, time * 0.15, 14);
  agg^.fillRadialGradient(cx, cy, r * 2.1, RGBA(255, 250, 200, 150), RGBA(255, 160, 40, 0));
  agg^.star(cx, cy, r * 1.05, r * 2.1 / pulse, -time * 0.22, 9);

  agg^.fillRadialGradient(cx - r * 0.2, cy - r * 0.2, r * 1.2, RGBA(255, 255, 240), RGBA(255, 215, 90), RGBA(250, 130, 20));
  agg^.ellipse(cx, cy, r, r);

  agg^.clipBox(cx - r * 2.8, cy - r * 2.8, cx + r * 2.8, cy + r * 2.8);
  DrawOrbits(agg, PI, 2 * PI);
  agg^.clipBox(0, 0, width, height);
end;

procedure PlanetPosition(const orbit, angle: double; out x, y, scale: double);
begin
  x := cx + orbit * u * Cos(angle);
  y := cy + orbit * u * TILT * Sin(angle);
  scale := 1 + 0.18 * Sin(angle);
end;

procedure DrawSphere(const agg: Agg2D_ptr; const x, y, r: double; const light, base, dark: Color);
var
  dx, dy, d: double;
begin
  dx := cx - x;
  dy := cy - y;
  d := Max(Hypot(dx, dy), 1e-6);
  agg^.noLine;
  agg^.fillRadialGradient(x + dx / d * r * 0.5, y + dy / d * r * 0.5, r * 1.9, light, base, dark);
  agg^.ellipse(x, y, r, r);
end;

procedure DrawRing(const agg: Agg2D_ptr; const x, y, r: double; const front: boolean);
var
  a0: double;
begin
  if front then
    a0 := PI
  else
    a0 := 0;
  agg^.resetTransformations;
  agg^.translate(-x, -y);
  agg^.rotate(-0.35);
  agg^.translate(x, y);
  agg^.noFill;
  agg^.lineWidth(r * 0.35);
  agg^.lineColor(200, 175, 125, 170);
  agg^.arc(x, y, r * 1.75, r * 0.55, a0, a0 + PI);
  agg^.lineWidth(r * 0.18);
  agg^.lineColor(235, 215, 170, 200);
  agg^.arc(x, y, r * 2.2, r * 0.7, a0, a0 + PI);
  agg^.resetTransformations;
end;

procedure DrawPlanet(const agg: Agg2D_ptr; const i: integer);
var
  x, y, s, r, mx, my, ms, mr: double;
  moonFront: boolean;
begin
  with planets[i] do
  begin
    PlanetPosition(orbit, angle, x, y, s);
    r := radius * u * s;

    moonFront := FALSE;
    mx := 0;
    my := 0;
    mr := 0;
    if moon then
    begin
      mx := x + r * 2.3 * Cos(moonAngle);
      my := y + r * 2.3 * TILT * Sin(moonAngle);
      ms := 1 + 0.15 * Sin(moonAngle);
      mr := r * 0.3 * ms;
      moonFront := Sin(moonAngle) >= 0;
      if not moonFront then
        DrawSphere(agg, mx, my, mr, RGBA(240, 240, 235), RGBA(150, 150, 150), RGBA(25, 25, 30));
    end;

    if ring then
      DrawRing(agg, x, y, r, FALSE);

    DrawSphere(agg, x, y, r, light, base, dark);

    if i = 2 then
    begin
      agg^.noFill;
      agg^.lineWidth(r * 0.12);
      agg^.lineColor(120, 190, 255, 90);
      agg^.ellipse(x, y, r * 1.04, r * 1.04);
    end;

    if ring then
      DrawRing(agg, x, y, r, TRUE);

    if moon and moonFront then
      DrawSphere(agg, mx, my, mr, RGBA(240, 240, 235), RGBA(150, 150, 150), RGBA(25, 25, 30));
  end;
end;

procedure CometPosition(out x, y, dist: double);
var
  r: double;
begin
  with comet do
  begin
    r := a * (1 - e * e) / (1 + e * Cos(theta));
    dist := r;
    x := cx + r * u * Cos(theta + phi);
    y := cy + r * u * TILT * Sin(theta + phi);
  end;
end;

procedure DrawComet(const agg: Agg2D_ptr);
var
  x, y, dist, dx, dy, d, len, w, tx, ty, px, py: double;
begin
  CometPosition(x, y, dist);
  dx := x - cx;
  dy := y - cy;
  d := Max(Hypot(dx, dy), 1e-6);
  dx := dx / d;
  dy := dy / d;
  px := -dy;
  py := dx;

  len := Min(u * 0.06 / Max(dist, 0.05), u * 0.7);
  w := u * 0.012;
  tx := x + dx * len;
  ty := y + dy * len;

  agg^.noLine;
  agg^.fillLinearGradient(x, y, tx, ty, RGBA(220, 235, 255, 170), RGBA(150, 190, 255, 0));
  agg^.resetPath;
  agg^.moveTo(x + px * w, y + py * w);
  agg^.cubicCurveTo(x + px * w * 2 + dx * len * 0.3, y + py * w * 2 + dy * len * 0.3,
    tx + px * w * 4, ty + py * w * 4, tx + px * w * 3.5, ty + py * w * 3.5);
  agg^.lineTo(tx - px * w * 1.5, ty - py * w * 1.5);
  agg^.cubicCurveTo(x - px * w * 1.5 + dx * len * 0.5, y - py * w * 1.5 + dy * len * 0.5,
    x - px * w * 1.2, y - py * w * 1.2, x - px * w, y - py * w);
  agg^.closePolygon;
  agg^.drawPath(FillOnly);

  agg^.fillLinearGradient(x, y, x + dx * len * 1.2, y + dy * len * 1.2, RGBA(140, 200, 255, 150), RGBA(60, 120, 255, 0));
  agg^.resetPath;
  agg^.moveTo(x + px * w * 0.4, y + py * w * 0.4);
  agg^.lineTo(x + dx * len * 1.2 + px * w * 0.8, y + dy * len * 1.2 + py * w * 0.8);
  agg^.lineTo(x + dx * len * 1.2 - px * w * 0.8, y + dy * len * 1.2 - py * w * 0.8);
  agg^.lineTo(x - px * w * 0.4, y - py * w * 0.4);
  agg^.closePolygon;
  agg^.drawPath(FillOnly);

  agg^.fillRadialGradient(x, y, w * 2.5, RGBA(255, 255, 255, 255), RGBA(200, 225, 255, 160), RGBA(150, 190, 255, 0));
  agg^.ellipse(x, y, w * 2.5, w * 2.5);
end;

procedure DrawScene(const agg: Agg2D_ptr);
var
  items: array[0..PLANET_COUNT + 1] of TItem;
  count, i, j: integer;
  tmp: TItem;
  x, y, dist: double;
begin
  DrawTwinkles(agg);
  DrawAsteroids(agg, FALSE);

  count := 0;
  for i := 0 to PLANET_COUNT - 1 do
  begin
    items[count].kind := ikPlanet;
    items[count].index := i;
    items[count].depth := Sin(planets[i].angle) * planets[i].orbit;
    Inc(count);
  end;
  CometPosition(x, y, dist);
  items[count].kind := ikComet;
  items[count].index := 0;
  items[count].depth := (y - cy) / TILT / u;
  Inc(count);
  items[count].kind := ikSun;
  items[count].index := 0;
  items[count].depth := 0;
  Inc(count);

  for i := 1 to count - 1 do
  begin
    tmp := items[i];
    j := i - 1;
    while (j >= 0) and (items[j].depth > tmp.depth) do
    begin
      items[j + 1] := items[j];
      Dec(j);
    end;
    items[j + 1] := tmp;
  end;

  for i := 0 to count - 1 do
    case items[i].kind of
      ikPlanet: DrawPlanet(agg, items[i].index);
      ikComet: DrawComet(agg);
      ikSun:
        begin
          DrawSun(agg);
          DrawAsteroids(agg, TRUE);
        end;
    end;
end;

procedure UpdateScene(const dt: double);
var
  i: integer;
  r: double;
begin
  time := time + dt;
  for i := 0 to PLANET_COUNT - 1 do
    planets[i].angle := planets[i].angle + planets[i].speed * dt;
  for i := 0 to ASTEROID_COUNT - 1 do
    asteroids[i].angle := asteroids[i].angle + asteroids[i].speed * dt;
  moonAngle := moonAngle + 1.4 * dt;

  with comet do
  begin
    r := a * (1 - e * e) / (1 + e * Cos(theta));
    theta := theta + Sqrt(gm * a * (1 - e * e)) / (r * r) * dt;
    if theta > 2 * PI then
      theta := theta - 2 * PI;
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

  size: integer;
  buffer, background: pbyte;
  image: PXImage;
  agg: Agg2D_ptr;

  lastUpdate, current: qword;
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
    root := XCreateSimpleWindow(dpy, RootWindow(dpy, screen), 0, 0, 960, 600, 1, BlackPixel(dpy, screen), BlackPixel(dpy, screen));
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

  width := wa.width;
  height := wa.height;

  gc := XCreateGC(dpy, root, 0, nil);

  size := width * height * 4;
  buffer := GetMem(size);
  background := GetMem(size);
  image := XCreateImage(dpy, wa.visual, wa.depth, ZPixmap, 0, pchar(buffer), width, height, 32, width * 4);

  Randomize;
  InitScene;

  New(agg, Construct);
  agg^.attach(int8u_ptr(background), width, height, width * 4);
  DrawBackground(agg);
  agg^.attach(int8u_ptr(buffer), width, height, width * 4);

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
    UpdateScene((current - lastUpdate) / 1000);
    lastUpdate := current;

    Move(background^, buffer^, size);
    DrawScene(agg);

    XPutImage(dpy, root, gc, image, 0, 0, 0, 0, width, height);
    XFlush(dpy);

    elapsed := GetTickCount64 - frameStart;
    if elapsed < CFrameDuration then
      Sleep(Cardinal(CFrameDuration - elapsed));
  end;

  Dispose(agg, Destruct);

  image^.data := nil;
  XDestroyImage(image);
  FreeMem(background);
  FreeMem(buffer);

  XFreeGC(dpy, gc);

  if own_window then
    XDestroyWindow(dpy, root);

  XCloseDisplay(dpy);
end.
