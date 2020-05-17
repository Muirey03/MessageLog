export ARCHS = arm64 armv7 arm64e

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libmessagelog
libmessagelog_FILES = MessageLog.xm
libmessagelog_LIBRARIES = substrate
ADDITIONAL_CFLAGS = -DTHEOS_LEAN_AND_MEAN

include $(THEOS_MAKE_PATH)/library.mk

internal-stage::
	mkdir -p usr/lib
	cp $(THEOS_STAGING_DIR)/usr/lib/libmessagelog.dylib usr/lib/libmessagelog.dylib
