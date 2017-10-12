MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Proxy

SV *
new (class)
	SV *class

	PREINIT:
		zmq_raw_proxy *proxy = NULL;

	CODE:
		Newxz (proxy, 1, zmq_raw_proxy);
		ZMQ_NEW_OBJ (RETVAL, "ZMQ::Raw::Proxy", proxy);

	OUTPUT: RETVAL

void
start (self, frontend, backend, ...)
	SV *self
	SV *frontend
	SV *backend

	CODE:
		zmq_proxy_steerable (ZMQ_SV_TO_PTR (Socket, frontend),
			ZMQ_SV_TO_PTR (Socket, backend),
			SvOK (ST (3)) ? ZMQ_SV_TO_PTR (Socket, ST (3)) : NULL,
			SvOK (ST (4)) ? ZMQ_SV_TO_PTR (Socket, ST (4)) : NULL);
