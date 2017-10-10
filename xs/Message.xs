MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Message

INCLUDE: const-xs-message_options.inc

SV *
new (class)
	SV *class

	PREINIT:
		int rc;
		zmq_msg_t *msg;

	CODE:
		Newx (msg, 1, zmq_msg_t);

		rc = zmq_msg_init (msg);
		zmq_raw_check_error (rc);

		ZMQ_NEW_OBJ (RETVAL, SvPVbyte_nolen (class), msg);

	OUTPUT: RETVAL

SV *
data (self, ...)
	SV *self

	PREINIT:
		int rc;
		zmq_msg_t *msg;

	CODE:
		msg = ZMQ_SV_TO_PTR (Message, self);

		if (items > 1)
		{
			STRLEN len;
			char *buf = SvPV (ST (1), len);

			rc = zmq_msg_close (msg);
			zmq_raw_check_error (rc);

			rc = zmq_msg_init_size (msg, len);
			zmq_raw_check_error (rc);

			Copy (buf, zmq_msg_data (msg), len, char);
		}

		if (zmq_msg_size (msg) == 0)
			XSRETURN_UNDEF;

		RETVAL = newSVpv (zmq_msg_data (msg), zmq_msg_size (msg));

	OUTPUT: RETVAL

int
more (self)
	SV *self

	CODE:
		RETVAL = zmq_msg_more (ZMQ_SV_TO_PTR (Message, self));

	OUTPUT: RETVAL

unsigned int
size (self)
	SV *self

	CODE:
		RETVAL = zmq_msg_size (ZMQ_SV_TO_PTR (Message, self));

	OUTPUT: RETVAL

int
get (self, property)
	SV *self
	int property

	PREINIT:
		int rc;

	CODE:
		rc = zmq_msg_get (ZMQ_SV_TO_PTR (Message, self), property);
		zmq_raw_check_error (rc);
		RETVAL = rc;

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	PREINIT:
		int rc;
		zmq_msg_t *msg;

	CODE:
		msg = ZMQ_SV_TO_PTR (Message, self);

		rc = zmq_msg_close (msg);
		zmq_raw_check_error (rc);
		Safefree (msg);

