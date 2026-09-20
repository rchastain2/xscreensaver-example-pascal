/*
 * lavanet.c
 *
 *      Author: Robert 'Bobby' Zenz
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

#include "vroot.h"

#define FALSE 0
#define TRUE 1
#define BLACK 0x000000
#define WHITE 0xFFFFFF

struct vector {
	float x;
	float y;
};

struct line {
	float startX;
	float startY;
	float endX;
	float endY;
	int value;
};

int targetRed = 0;
int targetGreen = 255;
int targetBlue = 255;

// Global, sorry.
int debug = FALSE;
int pointCount = 200;
float minimumDistance = 100;
int targetFps = 60;
float topChange = 0.1f;
float topSpeed = 0.5f;

float get_random() {
	return ((float) rand() / RAND_MAX - 0.5f) * 2;
}

unsigned long make_color(unsigned char red, unsigned char green,
		unsigned char blue) {
	unsigned long color = red;
	color = color << 8;

	color |= green;
	color = color << 8;

	color |= blue;

	return color;
}

float sign(float x) {
	float val = x > 0;
	return val - (x < 0);
}

void draw_lines(struct line *lines, int lineCount, Display *dpy, GC g,
		Pixmap pixmap) {
	int idx;
	for (idx = 0; idx < lineCount; idx++) {
		struct line *line = &lines[idx];
		int brightness = 255 - line->value;
		XSetForeground(dpy, g, make_color(targetRed * brightness / 255,
				targetGreen * brightness / 255,
				targetBlue * brightness / 255));
		XDrawLine(dpy, pixmap, g, line->startX, line->startY, line->endX,
				line->endY);
	}
}

int gather_lines(struct vector *points, struct line *lines) {
	int counter = 0;
	int idx;
	for (idx = 0; idx < pointCount; idx++) {
		struct vector *pointA = &points[idx];
		int idx2 = 0;
		for (idx2 = idx + 1; idx2 < pointCount; idx2++) {
			struct vector *pointB = &points[idx2];

			// Check distance between points
			float distance = hypotf(pointA->x - pointB->x,
					pointA->y - pointB->y);

			if (distance < minimumDistance) {
				struct line *newLine = &lines[counter];
				newLine->startX = pointA->x;
				newLine->startY = pointA->y;
				newLine->endX = pointB->x;
				newLine->endY = pointB->y;
				newLine->value = (int) floorf(distance / minimumDistance * 255);
				counter++;
			}
		}
	}

	return counter;
}

int sort_lines(const void *a, const void *b) {
	struct line *lineA = (struct line*) a;
	struct line *lineB = (struct line*) b;
	if (lineA->value == lineB->value) {
		return 0;
	} else if (lineA->value > lineB->value) {
		return -1;
	}

	return 1;
}

void move_points(struct vector *points, struct vector *velocities,
		XWindowAttributes wa) {
	int idx;
	for (idx = 0; idx < pointCount; idx++) {
		struct vector *velocity = &velocities[idx];

		velocity->x += get_random() * topChange;
		velocity->y += get_random() * topChange;

		if (fabsf(velocity->x) > topSpeed) {
			velocity->x = topSpeed * sign(velocity->x);
		}

		if (fabsf(velocity->y) > topSpeed) {
			velocity->y = topSpeed * sign(velocity->y);
		}

		struct vector *point = &points[idx];
		point->x += velocity->x;
		point->y += velocity->y;

		if (point->x < 0) {
			point->x = wa.width;
		}
		if (point->x > wa.width) {
			point->x = 0;
		}
		if (point->y < 0) {
			point->y = wa.height;
		}
		if (point->y > wa.height) {
			point->y = 0;
		}
	}
}

void parse_arguments(int argc, char *argv[]) {
	int idx;
	for (idx = 1; idx < argc; idx++) {
		if (strcasecmp(argv[idx], "--debug") == 0) {
			debug = TRUE;
		}
	}
}

long elapsed_microseconds(struct timeval *start) {
	struct timeval now;
	gettimeofday(&now, NULL);
	return (now.tv_sec - start->tv_sec) * 1000000L
			+ (now.tv_usec - start->tv_usec);
}

int main(int argc, char *argv[])
{
	parse_arguments(argc, argv);

	// Some stuff
	long frameDuration = 1000000L / targetFps;

	// Create our display
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

	// Get the root window
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
		// Let's create our own window.
		int screen = DefaultScreen(dpy);
		root = XCreateSimpleWindow(dpy, RootWindow(dpy, screen), 24, 48, 860,
				640, 1, BlackPixel(dpy, screen), WhitePixel(dpy, screen));

		// this is to terminate nicely:
		wmDeleteMessage = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
		XSetWMProtocols(dpy, root, &wmDeleteMessage, 1);
		XMapWindow(dpy, root);
	}

	XSelectInput(dpy, root, ExposureMask | StructureNotifyMask | KeyPressMask);

	// Get the window attributes
	XWindowAttributes wa;
	XGetWindowAttributes(dpy, root, &wa);

	// Create the buffer
	Pixmap double_buffer = XCreatePixmap(dpy, root, wa.width, wa.height,
			wa.depth);

	// And new create our graphics context to draw on
	GC g = XCreateGC(dpy, root, 0, NULL);

	struct timeval tv;
	gettimeofday(&tv, NULL);
	srand(tv.tv_sec);

	struct vector points[pointCount];
	struct vector velocities[pointCount];
	int counter = 0;
	for (counter = 0; counter < pointCount; counter++) {
		points[counter].x = rand() % wa.width;
		points[counter].y = rand() % wa.height;

		velocities[counter].x = get_random() * topSpeed;
		velocities[counter].y = get_random() * topSpeed;
	}

	size_t maxLineCount = (size_t) pointCount * (pointCount - 1) / 2;
	struct line *lines = malloc(
			(maxLineCount > 0 ? maxLineCount : 1) * sizeof(struct line));

	if (lines == NULL) {
		fprintf(stderr, "%s: out of memory\n", argv[0]);
		return EXIT_FAILURE;
	}

	int running = TRUE;

	while (running) {
		struct timeval frameStart;
		gettimeofday(&frameStart, NULL);

		XEvent event;
		while (running && XPending(dpy)) {
			XNextEvent(dpy, &event);

			if (event.type == ConfigureNotify) {
				XConfigureEvent xce = event.xconfigure;

				// This event type is generated for a variety of
				// happenings, so check whether the window has been
				// resized.

				if (xce.width != wa.width || xce.height != wa.height) {
					wa.width = xce.width;
					wa.height = xce.height;

					XFreePixmap(dpy, double_buffer);
					double_buffer = XCreatePixmap(dpy, root, wa.width,
							wa.height, wa.depth);
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

		// Clear the pixmap used for double buffering
		XSetForeground(dpy, g, BLACK);
		XFillRectangle(dpy, double_buffer, g, 0, 0, wa.width, wa.height);

		// Move the points around
		move_points(points, velocities, wa);

		// Gather the lines and draw them
		int lineCount = gather_lines(points, lines);
		qsort(lines, lineCount, sizeof(struct line), sort_lines);
		draw_lines(lines, lineCount, dpy, g, double_buffer);

		XCopyArea(dpy, double_buffer, root, g, 0, 0, wa.width, wa.height, 0, 0);
		XFlush(dpy);

		long elapsed = elapsed_microseconds(&frameStart);
		if (elapsed < frameDuration) {
			usleep(frameDuration - elapsed);
		}
	}

	// cleanup
	free(lines);
	XFreePixmap(dpy, double_buffer);
	XFreeGC(dpy, g);

	if (debug == TRUE) {
		XDestroyWindow(dpy, root);
	}

	XCloseDisplay(dpy);

	return EXIT_SUCCESS;
}
