#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw

BOOT:
	static int x;
