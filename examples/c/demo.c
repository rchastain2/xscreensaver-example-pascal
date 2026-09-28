
/*
  Simple exemple de module xscreensaver utilisant la bibliothèque Cairo.

  La quasi totalité du code est empruntée à lavanet.c de Robert Zenz :
    https://github.com/RobertZenz/xscreensavers

  J'ai seulement remplacé l'animation originale, par une animation dessinée avec
  la bibliothèque Cairo (pour le moment une balle rebondissante, parce que je
  n'avais pas d'autre idée).
*/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <sys/time.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <cairo/cairo.h>
#include <cairo/cairo-xlib.h>

#define FALSE 0
#define TRUE 1
#define BALL_RADIUS 40

int debug = FALSE;
long frameDuration = 5000;

void parse_arguments(int argc, char *argv[])
{
  int i;
  for (i = 1; i < argc; i++) {
    if (strcasecmp(argv[i], "--debug") == 0) {
      debug = TRUE;
    }
  }
}

long GetTickCount()
{
  struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec * 1000L + t.tv_usec / 1000;
}

long elapsed_microseconds(struct timeval *start)
{
  struct timeval now;
  gettimeofday(&now, NULL);
  return (now.tv_sec - start->tv_sec) * 1000000L + (now.tv_usec - start->tv_usec);
}

int seconds()
{
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec % 60;
}

void draw(cairo_t *cr, float x, float y)
{
  cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
  cairo_paint(cr);
  cairo_arc(cr, x, y, BALL_RADIUS, 0, 2 * M_PI);
  cairo_set_source_rgb(cr, 0.165, 0.322, 0.745);
  cairo_fill(cr);
}

void update(float *x, float *y, float *dx, float *dy, float dt, int width, int height)
{
  *x += *dx * dt;
  *y += *dy * dt;

  if (*x < BALL_RADIUS) {
    *x = 2 * BALL_RADIUS - *x;
    *dx = -1 * *dx;
  } else if (*x > width - BALL_RADIUS) {
    *x = 2 * (width - BALL_RADIUS) - *x;
    *dx = -1 * *dx;
  }

  if (*y < BALL_RADIUS) {
    *y = 2 * BALL_RADIUS - *y;
    *dy = -1 * *dy;
  } else if (*y > height - BALL_RADIUS) {
    *y = 2 * (height - BALL_RADIUS) - *y;
    *dy = -1 * *dy;
  }
}

int main(int argc, char *argv[])
{
  parse_arguments(argc, argv);

  Display *dpy = XOpenDisplay(getenv("DISPLAY"));

  if (dpy == NULL) {
    fprintf(stderr, "%s: cannot open display\n", argv[0]);
    return EXIT_FAILURE;
  }

  char *xwin = getenv("XSCREENSAVER_WINDOW");
  Window root_window_id = 0;

  if (xwin) {
    root_window_id = strtoul(xwin, NULL, 0);
  }

  Window root;
  Atom wmDeleteMessage = None;

  if (debug == FALSE) {
    if (root_window_id == 0) {
      printf("usage as standalone app: %s --debug\n", argv[0]);
      XCloseDisplay(dpy);
      return EXIT_FAILURE;
    }
    root = root_window_id;
  } else {
    int screen = DefaultScreen(dpy);
    root = XCreateSimpleWindow(dpy, RootWindow(dpy, screen), 0, 0, 600, 400, 1, BlackPixel(dpy, screen), WhitePixel(dpy, screen));
    wmDeleteMessage = XInternAtom(dpy, "WM_DELETE_WINDOW", False); /* Xlib defines the type Bool and the Boolean values True and False. */
    XSetWMProtocols(dpy, root, &wmDeleteMessage, 1);
    XMapWindow(dpy, root);
  }

  XSelectInput(dpy, root, ExposureMask | StructureNotifyMask | KeyPressMask);
  XWindowAttributes wa;
  XGetWindowAttributes(dpy, root, &wa);
  Pixmap map = XCreatePixmap(dpy, root, wa.width, wa.height, wa.depth);
  GC gc = XCreateGC(dpy, root, 0, NULL);

  cairo_surface_t *sf = cairo_xlib_surface_create(dpy, map, wa.visual, wa.width, wa.height);
  cairo_t *cr = cairo_create(sf);

  float x  = (float) wa.width / 3.0;
  float y  = (float) wa.height / 3.0;
  float dx = (float) seconds() + 320.0;
  float dy = (float) seconds() + 160.0;

  long lastUpdate = GetTickCount();
  long current, dt;

  int running = TRUE;

  while (running) {
    struct timeval frameStart;
    gettimeofday(&frameStart, NULL);

    XEvent event;

    while (running && XPending(dpy)) {
      XNextEvent(dpy, &event);

      if (event.type == ConfigureNotify) {
        XConfigureEvent xce = event.xconfigure;
        if (xce.width != wa.width || xce.height != wa.height) {
          wa.width = xce.width;
          wa.height = xce.height;

          cairo_destroy(cr);
          cairo_surface_destroy(sf);
          XFreePixmap(dpy, map);

          map = XCreatePixmap(dpy, root, wa.width, wa.height, wa.depth);
          sf = cairo_xlib_surface_create(dpy, map, wa.visual, wa.width, wa.height);
          cr = cairo_create(sf);
        }
      } else if (event.type == KeyPress) {
        if (XLookupKeysym(&event.xkey, 0) == XK_Escape) {
          running = FALSE;
        }
      } else if (event.type == ClientMessage) {
        if ((Atom) event.xclient.data.l[0] == wmDeleteMessage) {
          running = FALSE;
        }
      }
    }

    if (running == FALSE) {
      break;
    }

    current = GetTickCount();
    dt = current - lastUpdate;

    if (dt > 0)
    {
      draw(cr, x, y);
      XCopyArea(dpy, map, root, gc, 0, 0, wa.width, wa.height, 0, 0);
      XFlush(dpy);

      update(&x, &y, &dx, &dy, (float)dt/1000, wa.width, wa.height);

      lastUpdate = current;
    }

    long elapsed = elapsed_microseconds(&frameStart);

    if (elapsed < frameDuration) {
      usleep(frameDuration - elapsed);
    }
  }

  cairo_destroy(cr);
  cairo_surface_destroy(sf);

  XFreePixmap(dpy, map);
  XFreeGC(dpy, gc);

  if (debug == TRUE) {
    XDestroyWindow(dpy, root);
  }

  XCloseDisplay(dpy);

  return EXIT_SUCCESS;
}
