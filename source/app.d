//import core.stdc.stdio;
import core.runtime;
import core.memory;

import bindbc.sdl;

// System print function instead of printf
extern(C) int __android_log_print(int prio, const(char)* tag, const(char)* fmt, ...);


enum /*android_LogPriority */{
  ANDROID_LOG_UNKNOWN = 0,
  ANDROID_LOG_DEFAULT,
  ANDROID_LOG_VERBOSE,
  ANDROID_LOG_DEBUG,
  ANDROID_LOG_INFO,
  ANDROID_LOG_WARN,
  ANDROID_LOG_ERROR,
  ANDROID_LOG_FATAL,
  ANDROID_LOG_SILENT
}

version(none)
enum /*log_id*/ {
  LOG_ID_MIN = 0,
  LOG_ID_MAIN = 0,
  LOG_ID_RADIO = 1,
  LOG_ID_EVENTS = 2,
  LOG_ID_SYSTEM = 3,
  LOG_ID_CRASH = 4,
  LOG_ID_STATS = 5,
  LOG_ID_SECURITY = 6,
  LOG_ID_KERNEL = 7,
  LOG_ID_MAX,
  LOG_ID_DEFAULT = 0x7FFFFFFF
}

/// Android log category tag
__gshared const (char)* LOG_TAG = "DAPP";

extern(C)
export int SDL_main(int argc, char** argv) 
{
	__android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, "entering main()\n");

	Runtime.initialize();
	scope(exit)
	  Runtime.terminate();
	__android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, "D RT initialized\n");

	__android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, "before loadSDL()\n");
	loadSDL();
	__android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, "after loadSDL()\n");

	SDL_Log("D SDL App start\n");

    SDL_Window *window;                    // Declare a pointer

    SDL_Init(SDL_INIT_VIDEO);              // Initialize SDL2

	//Screen dimensions
	SDL_Rect gScreenRect = { 0, 0, 320, 240 };

	//Get device display mode
	SDL_DisplayMode displayMode;
	if( SDL_GetCurrentDisplayMode( 0, &displayMode ) == 0 )
	{
		gScreenRect.w = displayMode.w;
		gScreenRect.h = displayMode.h;
	}

    // Create an application window with the following settings:
    window = SDL_CreateWindow(
        "An SDL2 window",                  // window title
        SDL_WINDOWPOS_UNDEFINED,           // initial x position
        SDL_WINDOWPOS_UNDEFINED,           // initial y position
        gScreenRect.w,                     // width, in pixels
        gScreenRect.h,                     // height, in pixels
        SDL_WINDOW_OPENGL                  // flags - see below
    );

    // Check that the window was successfully created
    if (!window) {
        // In the case that the window could not be made...
        SDL_Log("Could not create window: %s\n", SDL_GetError());
        return 1;
    }

    // The window is open: could enter program loop here (see SDL_PollEvent())
    // Setup renderer
    SDL_Renderer* renderer;
    renderer =  SDL_CreateRenderer( window, -1, SDL_RENDERER_ACCELERATED);

	if (!renderer) {
		SDL_Log("Could not create renderer: %s\n", SDL_GetError());
		return 1;
	}

    // Set render color to red ( background will be rendered in this color )
    SDL_SetRenderDrawColor( renderer, 255, 0, 0, 255 );

    // Clear winow
    SDL_RenderClear( renderer );

    // Creat a rect at pos ( 50, 50 ) that's 50 pixels wide and 50 pixels high.
    SDL_Rect r;
    r.x = 50;
    r.y = 50;
    r.w = 500;
    r.h = 500;

    // Set render color to blue ( rect will be rendered in this color )
    SDL_SetRenderDrawColor( renderer, 0, 0, 255, 255 );

	// turn off, we don't build the SDL image lib
	version(none)
	{
    // Render image
    //SDL_Surface *loadedImage = IMG_Load("res/hello.png");
	//SDL_Surface *loadedImage;
    //SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, loadedImage);
    //SDL_FreeSurface(loadedImage);

    //SDL_RenderCopy(renderer, texture, null, &r);
	}
    else 
        SDL_RenderFillRect(renderer, &r); // draws colored rect using options(color) set above

    // Render the rect to the screen
    SDL_RenderPresent(renderer);

    SDL_Delay(8000);  // Pause execution for 3000 milliseconds, for example

    // Close and destroy the window
    SDL_DestroyWindow(window);

    // Clean up
    SDL_Quit();

    __android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, "D main exit\n");

    return 0;
}