CFLAGS=-O2 -Wall

kobo_hwconfig:

pkg: kobo_hwconfig
	mkdir -p pkg/usr/bin
	cp kobo_hwconfig pkg/usr/bin
	dpkg-deb -b pkg/ .

clean:
	rm kobo_hwconfig pkg/usr/bin/kobo_hwconfig *.deb
