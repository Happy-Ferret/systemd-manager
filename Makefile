DESTDIR = /usr
version = $(shell awk 'NR == 3 {print substr($$3, 2, length($$3)-2)}' Cargo.toml)
arch = $(shell dpkg --print-architecture)

all:
	cargo rustc --release -- -C opt-level=3 -C lto

install:
	install -d $(DESTDIR)/bin/
	install -d $(DESTDIR)/share/applications/
	install -d $(DESTDIR)/share/polkit-1/actions/
	install -m 755 target/release/systemd-manager $(DESTDIR)/bin/
	install -m 755 assets/systemd-manager-pkexec $(DESTDIR)/bin/
	install -m 644 assets/systemd-manager.desktop $(DESTDIR)/share/applications/
	install -m 644 assets/org.freedesktop.policykit.systemd-manager.policy $(DESTDIR)/share/polkit-1/actions/

uninstall:
	rm $(DESTDIR)/bin/systemd-manager
	rm $(DESTDIR)/bin/systemd-manager-pkexec
	rm $(DESTDIR)/share/applications/systemd-manager.desktop
	rm $(DESTDIR)/share/polkit-1/actions/org.freedesktop.policykit.systemd-manager.policy

tar:
	install -d systemd-manager
	install -d systemd-manager/bin
	install -d systemd-manager/share/applications
	install -d systemd-manager/share/polkit-1/actions
	install -m 755 target/release/systemd-manager systemd-manager/bin/
	install -m 755 assets/systemd-manager-pkexec systemd-manager/bin/
	install -m 644 assets/systemd-manager.desktop systemd-manager/share/applications/
	install -m 644 assets/org.freedesktop.policykit.systemd-manager.policy systemd-manager/share/polkit-1/actions/
	tar cf - "systemd-manager" | xz -zf > systemd-manager-$(version).tar.xz

ubuntu:
	sudo apt install libgtk-3-dev
	cargo build --release
	strip target/release/systemd-manager
	sed "2s/.*/Version: $(version)/g" -i debian/DEBIAN/control
	sed "7s/.*/Architecture: $(arch)/g" -i debian/DEBIAN/control
	install -d debian/usr/bin
	install -d debian/usr/share/applications
	install -d debian/usr/share/polkit-1/actions/
	install -m 755 target/release/systemd-manager debian/usr/bin
	install -m 755 assets/systemd-manager-pkexec debian/usr/bin/
	install -m 644 assets/systemd-manager.desktop debian/usr/share/applications/
	install -m 644 assets/org.freedesktop.policykit.systemd-manager.policy debian/usr/share/polkit-1/actions
	fakeroot dpkg-deb --build debian systemd-manager.deb
	sudo dpkg -i systemd-manager.deb
