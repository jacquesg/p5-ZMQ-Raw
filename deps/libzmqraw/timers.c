#include <zmq.h>

#include <assert.h>
#include <stdlib.h>

#include "mutex.h"
#include "timers.h"


typedef struct zmq_raw_timers
{
	zmq_raw_mutex *mutex;
	void *timers;
	void *thread;
	int running;

	zmq_raw_timer **last;
	int run_count;

	zmq_pollitem_t wakeup_item;
	void *wakeup_context;
	void *wakeup_send;
	void *wakeup_recv;
} zmq_raw_timers;

typedef struct zmq_raw_timer
{
	int id;
	int running;
	int after;
	int interval;
	void *context;
	void *send;
	void *recv;
	void *recv_sv;
	zmq_raw_timers *timers;
} zmq_raw_timer;


static void timer_handler (int timer_id, void *arg);
static void timer_thread (void *arg);


zmq_raw_timers *zmq_raw_timers_create()
{
	zmq_raw_timers *timers = calloc (1, sizeof (zmq_raw_timers));
	timers->timers = zmq_timers_new();

	timers->wakeup_context = zmq_ctx_new();
	timers->wakeup_send = zmq_socket (timers->wakeup_context, ZMQ_PAIR);
	timers->wakeup_recv = zmq_socket (timers->wakeup_context, ZMQ_PAIR);

	zmq_bind (timers->wakeup_recv, "inproc://_wakeup");
	zmq_connect (timers->wakeup_send, "inproc://_wakeup");

	timers->wakeup_item.events = ZMQ_POLLIN;
	timers->wakeup_item.socket = timers->wakeup_recv;

	timers->mutex = zmq_raw_mutex_create();
	return timers;
}

void zmq_raw_timers_destroy (zmq_raw_timers *timers)
{
	assert (timers);

	zmq_raw_mutex_lock (timers->mutex);
	timers->running = 0;
	zmq_send_const (timers->wakeup_send, "", 1, ZMQ_DONTWAIT);
	zmq_raw_mutex_unlock (timers->mutex);

	if (timers->thread)
		zmq_threadclose (timers->thread);
	zmq_raw_mutex_destroy (timers->mutex);

	zmq_close (timers->wakeup_send);
	zmq_close (timers->wakeup_recv);
	zmq_ctx_term (timers->wakeup_context);
	zmq_timers_destroy (&timers->timers);

	free (timers);
}

static zmq_raw_timer *zmq_raw_timer_create (void *context, int after, int interval)
{
	int rc;
	char endpoint[64];
	static const int v = 1;
	static int id = 0;
	zmq_raw_timer *timer;

	assert (context);

	timer = calloc (1, sizeof (zmq_raw_timer));
	timer->send = zmq_socket (context, ZMQ_PAIR);
	if (timer->send == NULL)
	{
		fprintf(stderr, "could not create timer send socket: %d => %s\n",
			zmq_errno(), zmq_strerror (zmq_errno()));
		assert (timer->send);
	}

	timer->recv = zmq_socket (context, ZMQ_PAIR);
	if (timer->recv == NULL)
	{
		fprintf(stderr, "could not create timer receive socket: %d => %s\n",
			zmq_errno(), zmq_strerror (zmq_errno()));
		assert (timer->recv);
	}

	timer->after = after;
	timer->interval = interval;

	sprintf (endpoint, "inproc://_timer-%d", ++id);
	rc = zmq_bind (timer->recv, endpoint);
	assert (rc == 0);

	rc = zmq_setsockopt (timer->recv, ZMQ_CONFLATE, &v, sizeof (v));
	assert (rc == 0);

	rc = zmq_connect (timer->send, endpoint);
	assert (rc == 0);

	return timer;
}

static void zmq_raw_timer_destroy (zmq_raw_timer *timer)
{
	assert (timer);
	assert (timer->send);

	zmq_close (timer->send);
	timer->send = NULL;

	free (timer);
}

zmq_raw_timer *zmq_raw_timers_start (zmq_raw_timers *timers, void *context, int after, int interval)
{
	int rc;
	zmq_raw_timer *timer;

	assert (timers);
	assert (context);

	zmq_raw_mutex_lock (timers->mutex);

	timer = zmq_raw_timer_create (context, after, interval);
	timer->id = zmq_timers_add (timers->timers, timer->after, timer_handler, timer);
	timer->running = 1;
	timer->timers = timers;

	if (!timers->running)
	{
		/* start the timer thread */
		timers->running = 1;
		timers->thread = zmq_threadstart (timer_thread, timers);
	}
	else
	{
		/* wakeup the timer thread */
		zmq_send_const (timers->wakeup_send, "", 1, ZMQ_DONTWAIT);
	}

	zmq_raw_mutex_unlock (timers->mutex);

	return timer;
}

void zmq_raw_timers_reset (zmq_raw_timer *timer)
{
	assert (timer);

	zmq_raw_mutex_lock (timer->timers->mutex);
	zmq_timers_reset (timer->timers->timers, timer->id);
	zmq_raw_mutex_unlock (timer->timers->mutex);
}

void zmq_raw_timers__stop (zmq_raw_timer *timer)
{
	assert (timer);

	if (timer->running)
	{
		timer->running = 0;
		zmq_timers_cancel (timer->timers->timers, timer->id);
	}
}

void zmq_raw_timers_stop (zmq_raw_timer *timer)
{
	assert (timer);

	zmq_raw_mutex_lock (timer->timers->mutex);
	zmq_raw_timers__stop (timer);
	zmq_raw_mutex_unlock (timer->timers->mutex);
}

void zmq_raw_timers_remove (zmq_raw_timer *timer)
{
	assert (timer);

	zmq_raw_timers_stop (timer);
	zmq_raw_timer_destroy (timer);
}

int zmq_raw_timer_id (zmq_raw_timer *timer)
{
	assert (timer);
	return timer->id;
}

void *zmq_raw_timer_get_recv (zmq_raw_timer *timer)
{
	assert (timer);
	return timer->recv;
}

int zmq_raw_timer_is_running (zmq_raw_timer *timer)
{
	assert (timer);
	return timer->running;
}

void zmq_raw_timer_set_sv (zmq_raw_timer *timer, void *sv)
{
	assert (timer);
	assert (sv);
	timer->recv_sv = sv;
	timer->recv = NULL;
}

void *zmq_raw_timer_get_sv (zmq_raw_timer *timer)
{
	return timer->recv_sv;
}


void timer_thread (void *arg)
{
	int count = 0, running = 1;
	long timeout;
	zmq_raw_timers *timers = (zmq_raw_timers *)arg;

	while (running)
	{
		zmq_raw_mutex_lock (timers->mutex);

		/* clear any 'pending' wakeup signals */
		zmq_recv (timers->wakeup_recv, NULL, 0, ZMQ_DONTWAIT);

		timers->last = NULL;
		timers->run_count = 0;
		zmq_timers_execute (timers->timers);

		while (--timers->run_count >= 0)
		{
			int index = timers->run_count;
			zmq_raw_timer *timer = timers->last[index];

			if (timer->interval == 0)
				zmq_raw_timers__stop (timer);
			else
				zmq_timers_set_interval (timers->timers, timer->id,
					(size_t)timer->interval);
		}

		if (timers->last)
			free (timers->last);

		running = timers->running;
		timeout = zmq_timers_timeout (timers->timers);
		zmq_raw_mutex_unlock (timers->mutex);

		/* sleep for 'timeout'. this may be interrupted
		 * by adding a new timer*/
		if (running)
			zmq_poll (&timers->wakeup_item, 1, timeout);
	}
}

void timer_handler (int timer_id, void *arg)
{
	/* this is guaranteed to execute with the timers mutex locked */
	zmq_raw_timer *timer = (zmq_raw_timer *)arg;

	assert (timer->running);
	assert (timer->id == timer_id);

	zmq_send_const (timer->send, "", 1, ZMQ_DONTWAIT);

	zmq_raw_timers *timers = timer->timers;
	int index = timers->run_count++;

	if (index == 0)
		timers->last = calloc (1, sizeof (zmq_raw_timer *));
	else
		timers->last = realloc (timers->last, timers->run_count*sizeof (zmq_raw_timer *));

	assert (timers->last);
	timers->last[index] = timer;
}
