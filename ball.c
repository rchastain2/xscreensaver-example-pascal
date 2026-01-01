
/*
  Simple exemple de module xscreensaver utilisant la bibliothèque Cairo.
  
  La quasi totalité du code est empruntée à lavanet.c de Robert Zenz :
    https://github.com/RobertZenz/xscreensavers
  
  J'ai simplement remplacé les dessins originaux par une image dessinée avec la
  bibliothèque Cairo (pour le moment une balle rebondissante, parce que je
  n'avais pas d'autre idée).
*/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <cairo/cairo.h>
#include <cairo/cairo-xlib.h>
#include <unistd.h>

#include "vroot.h"

#define FALSE 0
#define TRUE 1
#define BALL_RADIUS 40

int debug = FALSE;

void parse_arguments(int argc, char *argv[])
{
  int i;
  for (i = 1; i < argc; i++) {
    if (strcasecmp(argv[i], "--debug") == 0) {
      debug = TRUE;
    }
  }
}

int GetTickCount()
{
  struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec * 1000 + t.tv_usec / 1000;
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
  char *xwin = getenv("XSCREENSAVER_WINDOW");
  int root_window_id = 0;

  if (xwin) {
    root_window_id = strtol(xwin, NULL, 0);
  }

  Window root;

  if (debug == FALSE) {
    if (root_window_id == 0) {
      printf("usage as standalone app: %s --debug\n", argv[0]);
      return EXIT_FAILURE;
    } else {
      root = root_window_id;
    }
  } else {
    int screen = DefaultScreen(dpy);
    root = XCreateSimpleWindow(dpy, RootWindow(dpy, screen), 0, 0, 600, 400, 1, BlackPixel(dpy, screen), WhitePixel(dpy, screen));
    XMapWindow(dpy, root);
  }
  
  XSelectInput(dpy, root, ExposureMask | StructureNotifyMask);
  XWindowAttributes wa;
  XGetWindowAttributes(dpy, root, &wa);
  Pixmap map = XCreatePixmap(dpy, root, wa.width, wa.height, wa.depth);
  GC gc = XCreateGC(dpy, root, 0, NULL);
  Atom wmDeleteMessage = XInternAtom(dpy, "WM_DELETE_WINDOW", False); /* Xlib defines the type Bool and the Boolean values True and False. */
  XSetWMProtocols(dpy, root, &wmDeleteMessage, 1);
  
  cairo_surface_t *sf = cairo_xlib_surface_create(dpy, map, DefaultVisual(dpy, DefaultScreen(dpy)), wa.width, wa.height);
  cairo_t *cr = cairo_create(sf);

  float x  = (float) wa.width / 3.0;
  float y  = (float) wa.height / 3.0;
  float dx = (float) seconds() + 320.0;
  float dy = (float) seconds() + 160.0;
  
  int lastUpdate = GetTickCount();
  int current;
  float dt;

  while (TRUE) {
    XEvent event;

    if (XCheckWindowEvent(dpy, root, StructureNotifyMask, &event) || XCheckTypedWindowEvent(dpy, root, ClientMessage, &event)) {
      if (event.type == ConfigureNotify) {
        XConfigureEvent xce = event.xconfigure;
        if (xce.width != wa.width || xce.height != wa.height) {
          wa.width = xce.width;
          wa.height = xce.height;
          
          cairo_destroy(cr);
          cairo_surface_destroy(sf);
          XFreePixmap(dpy, map);
          
          map = XCreatePixmap(dpy, root, wa.width, wa.height, wa.depth);
          sf = cairo_xlib_surface_create(dpy, map, DefaultVisual(dpy, DefaultScreen(dpy)), wa.width, wa.height);
          cr = cairo_create(sf);
          continue;
        }
      } else if (event.type == ClientMessage) {
        if (event.xclient.data.l[0] == wmDeleteMessage) {
          break;
        }
      }
    }

    draw(cr, x, y);
    XCopyArea(dpy, map, root, gc, 0, 0, wa.width, wa.height, 0, 0);
    XFlush(dpy);

    current = GetTickCount();
    dt = (float) (current - lastUpdate) / 1000.0;
    update(&x, &y, &dx, &dy, dt, wa.width, wa.height);
    lastUpdate = current;
    
    usleep(16000);
  }
  
  cairo_destroy(cr);
  cairo_surface_destroy(sf);

  XFreePixmap(dpy, map);
  XFreeGC(dpy, gc);
  XDestroyWindow(dpy, root);
  XCloseDisplay(dpy);

  return EXIT_SUCCESS;
}
