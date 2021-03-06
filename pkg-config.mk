ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += pkg-config
PKG-CONFIG_VERSION := 0.29.2
DEB_PKG-CONFIG_V   ?= $(PKG-CONFIG_VERSION)-1

pkg-config-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://pkgconfig.freedesktop.org/releases/pkg-config-$(PKG-CONFIG_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,pkg-config-$(PKG-CONFIG_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,pkg-config-$(PKG-CONFIG_VERSION).tar.gz,pkg-config-$(PKG-CONFIG_VERSION),pkg-config)

ifneq ($(wildcard $(BUILD_WORK)/pkg-config/.build_complete),)
pkg-config:
	@echo "Using previously built pkg-config."
else
pkg-config: pkg-config-setup gettext glib2.0
	cd $(BUILD_WORK)/pkg-config && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-installed-glib \
		--disable-host-tool
	+$(MAKE) -C $(BUILD_WORK)/pkg-config \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)/usr/include/glib-2.0 -I$(BUILD_BASE)/usr/lib/glib-2.0/include"
	+$(MAKE) -C $(BUILD_WORK)/pkg-config install \
		DESTDIR="$(BUILD_STAGE)/pkg-config"
	touch $(BUILD_WORK)/pkg-config/.build_complete
endif

pkg-config-package: pkg-config-stage
	# pkg-config.mk Package Structure
	rm -rf $(BUILD_DIST)/pkg-config
	
	# pkg-config.mk Prep pkg-config
	cp -a $(BUILD_STAGE)/pkg-config $(BUILD_DIST)
	
	# pkg-config.mk Sign
	$(call SIGN,pkg-config,general.xml)
	
	# pkg-config.mk Make .debs
	$(call PACK,pkg-config,DEB_PKG-CONFIG_V)
	
	# pkg-config.mk Build cleanup
	rm -rf $(BUILD_DIST)/pkg-config

.PHONY: pkg-config pkg-config-package
