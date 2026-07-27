VESC_TOOL ?= $(if $(wildcard ./vesc_tool),./vesc_tool,vesc_tool)

PKG = vesc_scooter_support.vescpkg

all: $(PKG)

$(PKG): pkgdesc.qml ui.qml scooter_support.lisp README.md version
	$(VESC_TOOL) --buildPkgFromDesc pkgdesc.qml --testPkgDesc 'vesc:maxim 120' --testPkgDesc 'vesc:pronto'

clean:
	rm -f $(PKG)

.PHONY: all clean
