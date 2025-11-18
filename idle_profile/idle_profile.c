#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>
#include <time.h>
#include <wayland-client.h>
#include "ext-idle-notify-v1-client-protocol.h"

#define IDLE_TIMEOUT_SEC (31 * 60)  // 31 minutes
#define POWER_PROFILE_CMD "/usr/local/bin/power_profile"

struct app_state {
	struct wl_display *display;
	struct wl_registry *registry;
	struct wl_seat *seat;
	struct ext_idle_notifier_v1 *idle_notifier;
	struct ext_idle_notification_v1 *idle_notification;
	bool is_idle;
};

static void log_message( const char *msg )
{
	time_t now;
	char timestr[64];
	time( &now );
	struct tm *tm_info = localtime( &now );
	strftime( timestr, sizeof( timestr ), "%Y-%m-%d %H:%M:%S", tm_info );
	printf( "[%s] %s\n", timestr, msg );
	fflush( stdout );
}

// Power profile control
static void set_power_profile( const char *profile )
{
	char cmd[256];
	snprintf( cmd, sizeof( cmd ), "%s %s", POWER_PROFILE_CMD, profile );
	int ret = system( cmd );

	if( ret != 0 ) {
		fprintf( stderr, "Warning: Failed to set power profile to %s\n", profile );
	}
}

// Idle notification event handlers
static void idle_notification_idled( void *data,
                                     struct ext_idle_notification_v1 *notification )
{
	struct app_state *state = data;
	( void )notification; // Unused

	if( !state->is_idle ) {
		log_message( "System is idle. Setting low-power profile." );
		set_power_profile( "low-power" );
		state->is_idle = true;
	}
}

static void idle_notification_resumed( void *data,
                                       struct ext_idle_notification_v1 *notification )
{
	struct app_state *state = data;
	( void )notification; // Unused

	if( state->is_idle ) {
		log_message( "System is active. Setting performance profile." );
		set_power_profile( "performance" );
		state->is_idle = false;
	}
}

static const struct ext_idle_notification_v1_listener idle_notification_listener = {
	.idled = idle_notification_idled,
	.resumed = idle_notification_resumed,
};

// Registry event handlers
static void registry_global( void *data, struct wl_registry *registry,
                             uint32_t name, const char *interface,
                             uint32_t version )
{
	struct app_state *state = data;
	( void )version; // We use version 1 hardcoded

	if( strcmp( interface, ext_idle_notifier_v1_interface.name ) == 0 ) {
		state->idle_notifier = wl_registry_bind( registry, name,
		                                         &ext_idle_notifier_v1_interface, 1 );
		log_message( "Found ext-idle-notify-v1 interface" );
	}
	else if( strcmp( interface, "wl_seat" ) == 0 ) {
		state->seat = wl_registry_bind( registry, name,
		                                &wl_seat_interface, 1 );
		log_message( "Found wl_seat" );
	}
}

static void registry_global_remove( void *data, struct wl_registry *registry,
                                    uint32_t name )
{
	( void )data;    // Unused
	( void )registry; // Unused
	( void )name;    // Unused
	// Not used
}

static const struct wl_registry_listener registry_listener = {
	.global = registry_global,
	.global_remove = registry_global_remove,
};

int main( int argc, char *argv[] )
{
	struct app_state state = {0};
	( void )argc; // No command line arguments currently used
	( void )argv; // No command line arguments currently used

	log_message( "Power Profile Manager starting (Wayland ext-idle-notify-v1 mode)..." );

	// Connect to Wayland display
	state.display = wl_display_connect( NULL );

	if( !state.display ) {
		fprintf( stderr, "Error: Failed to connect to Wayland display\n" );
		fprintf( stderr, "Make sure you're running under Wayland (not X11)\n" );
		return 1;
	}

	// Get registry and bind to globals
	state.registry = wl_display_get_registry( state.display );
	wl_registry_add_listener( state.registry, &registry_listener, &state );

	// Process initial events to get globals
	wl_display_roundtrip( state.display );

	// Check if we got the idle notifier interface
	if( !state.idle_notifier ) {
		fprintf( stderr, "Error: Compositor doesn't support ext-idle-notify-v1 protocol\n" );
		fprintf( stderr, "Your compositor may not support this feature.\n" );
		wl_display_disconnect( state.display );
		return 1;
	}

	// Check if we got a seat
	if( !state.seat ) {
		fprintf( stderr, "Error: No seat found\n" );
		wl_display_disconnect( state.display );
		return 1;
	}

	// Create idle notification for our timeout (in milliseconds)
	uint32_t timeout_ms = IDLE_TIMEOUT_SEC * 1000;
	state.idle_notification = ext_idle_notifier_v1_get_idle_notification(
	                              state.idle_notifier, timeout_ms, state.seat );

	if( !state.idle_notification ) {
		fprintf( stderr, "Error: Failed to create idle notification\n" );
		wl_display_disconnect( state.display );
		return 1;
	}

	// Add listener for idle/resume events
	ext_idle_notification_v1_add_listener( state.idle_notification,
	                                       &idle_notification_listener, &state );

	log_message( "Power Profile Manager started successfully." );
	{
		char msg[128];
		snprintf( msg, sizeof( msg ), "Monitoring for %d minutes of idle time.",
		          IDLE_TIMEOUT_SEC / 60 );
		log_message( msg );
	}

	// Main event loop
	while( wl_display_dispatch( state.display ) != -1 ) {
		// Events are handled by callbacks
	}

	// Cleanup
	log_message( "Shutting down..." );

	if( state.idle_notification ) {
		ext_idle_notification_v1_destroy( state.idle_notification );
	}

	if( state.idle_notifier ) {
		ext_idle_notifier_v1_destroy( state.idle_notifier );
	}

	if( state.seat ) {
		wl_seat_destroy( state.seat );
	}

	if( state.registry ) {
		wl_registry_destroy( state.registry );
	}

	if( state.display ) {
		wl_display_disconnect( state.display );
	}

	return 0;
}
