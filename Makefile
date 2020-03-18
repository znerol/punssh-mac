prefix ?= /usr/local
bindir ?= $(prefix)/bin
pkgversion ?= 1.0.0

buildconf ?= release
builddir := $(shell swift build --configuration $(buildconf) --show-bin-path)

buildpayload = Build/pkgroot/payload
buildscripts = Build/pkgroot/scripts

build:
	swift build -c $(buildconf)

install: build
	install -d "$(bindir)"
	install -m 0755 "$(builddir)/punssh-defaults" "$(bindir)"
	install -m 0755 "$(builddir)/punssh-status" "$(bindir)"

uninstall:
	rm -f "$(bindir)/punssh-defaults"
	rm -f "$(bindir)/punssh-status"

clean:
	rm -rf .build
	rm -rf Build

pkgroot: build
	install -d $(buildscripts)
	install -m 0755 Scripts/preinstall $(buildscripts)
	install -m 0755 Scripts/postinstall $(buildscripts)
	install -d $(buildpayload)/Library/LaunchDaemons
	install -m 0644 LaunchDaemons/ch.znerol.punssh-defaults.plist $(buildpayload)/Library/LaunchDaemons
	install -d $(buildpayload)/Library/PunSSH/Bin
	install -m 0755 Scripts/punssh-connect $(buildpayload)/Library/PunSSH/Bin
	$(MAKE) install prefix=$(buildpayload)/Library/PunSSH bindir=$(buildpayload)/Library/PunSSH/Bin

pkg: pkgroot
	install -d Build
	pkgbuild --identifier ch.znerol.punssh --version $(pkgversion) --root $(buildpayload) --scripts $(buildscripts) Build/PunSSH-$(pkgversion).pkg


.PHONY: build install uninstall clean

