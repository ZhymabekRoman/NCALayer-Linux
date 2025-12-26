DOWNLOAD_URL = https://ncl.pki.gov.kz/images/NCALayer/ncalayer.zip
MD5_SUM = fc44f518042ff8daf6087cd6dcc667cb
SHA1_SUM = 0341e0e0a6a983bb46cca454f75356d85f451be9

# Version management (from git tag or default)
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")
PKGNAME = ncalayer

# AppImage configuration
APPIMAGE_NAME = NCALayer-x86_64.AppImage
APPDIR = NCALayer.AppDir
APPIMAGETOOL_URL = https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage

.PHONY: all download verify clean appimage extract extract-jar build-appimage clean-appimage help clean-all install-certs pkg-arch pkg-deb pkg-rpm pkg-rpm-fedora clean-pkg

all: download verify

# Display help information
help:
	@echo "NCALayer Build System"
	@echo "====================="
	@echo ""
	@echo "Available targets:"
	@echo "  download         - Download ncalayer.zip from official source"
	@echo "  verify           - Verify downloaded archive checksums"
	@echo "  extract          - Extract ncalayer.zip archive"
	@echo "  extract-jar      - Extract embedded JAR from ncalayer.sh"
	@echo "  appimage         - Build complete AppImage (does everything)"
	@echo "  install-certs    - Install NCA certificates to browser databases"
	@echo "  clean            - Remove downloaded archive"
	@echo "  clean-appimage   - Remove all AppImage build artifacts"
	@echo "  clean-all        - Remove everything (archive + AppImage)"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Quick Start:"
	@echo "  make download      # Download the archive"
	@echo "  make verify        # Verify checksums"
	@echo "  make appimage      # Build AppImage"
	@echo "  make install-certs # Install NCA certificates to browsers"
	@echo ""
	@echo "Or simply:"
	@echo "  make appimage      # Downloads and builds everything automatically"
	@echo ""

download: ncalayer.zip

ncalayer.zip:
	@if [ -f ncalayer.zip ]; then \
		echo "ncalayer.zip already exists, skipping download"; \
	elif command -v aria2c >/dev/null 2>&1; then \
		echo "Using aria2c to download"; \
		aria2c -x 16 -s 16 $(DOWNLOAD_URL); \
	elif command -v curl >/dev/null 2>&1; then \
		echo "Using curl to download"; \
		curl -O $(DOWNLOAD_URL); \
	elif command -v wget >/dev/null 2>&1; then \
		echo "Using wget to download"; \
		wget $(DOWNLOAD_URL); \
	else \
		echo "Error: No suitable downloader found (aria2c, curl, or wget)"; \
		exit 1; \
	fi

verify: ncalayer.zip
	@if command -v md5sum >/dev/null 2>&1; then \
		echo "Verifying MD5 checksum"; \
		echo "$(MD5_SUM)  ncalayer.zip" | md5sum -c; \
	elif command -v sha1sum >/dev/null 2>&1; then \
		echo "Verifying SHA1 checksum"; \
		echo "$(SHA1_SUM)  ncalayer.zip" | sha1sum -c; \
	else \
		echo "Error: No hash verification tool found (md5sum or sha1sum)"; \
		exit 1; \
	fi

# Extract ncalayer.zip archive
extract: ncalayer.zip
	@echo "Extracting ncalayer.zip..."
	@unzip -q -o ncalayer.zip
	@echo "Extraction complete."

# Extract embedded JAR from ncalayer.sh
extract-jar: extract ncalayer.jar

ncalayer.jar: ncalayer.sh
	@echo "Extracting embedded JAR from ncalayer.sh..."
	@echo "Detecting JAR offset by searching for PK signature..."
	@JAR_OFFSET=$$(grep -abo "^PK" ncalayer.sh | head -1 | cut -d: -f1); \
	if [ -z "$$JAR_OFFSET" ]; then \
		echo "Error: Could not find JAR signature (PK) in ncalayer.sh"; \
		exit 1; \
	fi; \
	echo "Found JAR at byte offset: $$JAR_OFFSET"; \
	tail -c +$$JAR_OFFSET ncalayer.sh > ncalayer.jar; \
	if [ ! -s ncalayer.jar ]; then \
		echo "Error: Extracted JAR is empty"; \
		exit 1; \
	fi
	@echo "JAR extracted successfully: ncalayer.jar ($$(du -h ncalayer.jar | cut -f1))"
	@file ncalayer.jar | grep -q "Java archive\|Zip archive\|data" || (echo "Warning: Extracted file may not be a valid JAR" && file ncalayer.jar)

# Download appimagetool if not present
appimagetool:
	@if [ ! -f appimagetool ]; then \
		echo "Downloading appimagetool..."; \
		if command -v wget >/dev/null 2>&1; then \
			wget -q $(APPIMAGETOOL_URL) -O appimagetool; \
		elif command -v curl >/dev/null 2>&1; then \
			curl -sL $(APPIMAGETOOL_URL) -o appimagetool; \
		else \
			echo "Error: wget or curl required to download appimagetool"; \
			exit 1; \
		fi; \
		chmod +x appimagetool; \
		echo "appimagetool downloaded successfully."; \
	fi

# Build AppImage structure
build-appimage: extract-jar appimagetool install-certs.sh
	@echo "Building AppImage structure..."
	@rm -rf $(APPDIR)
	@mkdir -p $(APPDIR)/usr/bin
	@mkdir -p $(APPDIR)/usr/lib
	@mkdir -p $(APPDIR)/usr/share/icons/hicolor/256x256/apps

	@echo "Copying application files..."
	@cp -r additions/jre8_ncalayer $(APPDIR)/usr/lib/
	@cp ncalayer.jar $(APPDIR)/usr/lib/
	@cp -r additions/cert $(APPDIR)/usr/lib/
	@cp additions/ncalayer.png $(APPDIR)/usr/share/icons/hicolor/256x256/apps/
	@cp additions/ncalayer.png $(APPDIR)/

	@echo "Installing AppRun launcher..."
	@cp AppRun.template $(APPDIR)/AppRun
	@chmod +x $(APPDIR)/AppRun

	@echo "Installing desktop entry..."
	@cp ncalayer.desktop.template $(APPDIR)/ncalayer.desktop

	@echo "Embedding certificate installer..."
	@cp install-certs.sh $(APPDIR)/usr/bin/
	@chmod +x $(APPDIR)/usr/bin/install-certs.sh

	@echo "AppImage structure created successfully."
	@echo "Total size: $$(du -sh $(APPDIR) | cut -f1)"

# Package AppImage
appimage: build-appimage
	@echo "Packaging AppImage..."
	@ARCH=x86_64 ./appimagetool $(APPDIR) $(APPIMAGE_NAME)
	@echo ""
	@echo "=========================================="
	@echo "AppImage created successfully!"
	@echo "File: $(APPIMAGE_NAME)"
	@echo "Size: $$(du -h $(APPIMAGE_NAME) | cut -f1)"
	@echo "=========================================="
	@echo ""
	@echo "Usage: ./$(APPIMAGE_NAME)"
	@echo "Extract: ./$(APPIMAGE_NAME) --appimage-extract"
	@echo ""

# Clean downloaded archive
clean:
	rm -f ncalayer.zip

# Clean AppImage build artifacts
clean-appimage:
	@echo "Cleaning AppImage build artifacts..."
	@rm -rf $(APPDIR)
	@rm -f $(APPIMAGE_NAME)
	@rm -f ncalayer.jar
	@rm -f ncalayer.sh
	@rm -rf additions
	@rm -f appimagetool
	@rm -f install-certs.sh
	@rm -f "Инструкция NCALayer.txt"
	@echo "AppImage artifacts cleaned."

# Generate install-certs.sh with embedded certificates
install-certs.sh: extract install-certs.sh.template
	@echo "Generating install-certs.sh with embedded certificates..."
	@if [ ! -f "additions/cert/root_rsa.cer" ] || [ ! -f "additions/cert/nca_rsa.cer" ]; then \
		echo "Error: Certificate files not found. Run 'make extract' first."; \
		exit 1; \
	fi
	@ROOT_B64=$$(base64 -w 0 additions/cert/root_rsa.cer); \
	NCA_B64=$$(base64 -w 0 additions/cert/nca_rsa.cer); \
	sed -e "s|@@ROOT_CERT_BASE64@@|$$ROOT_B64|g" \
	    -e "s|@@NCA_CERT_BASE64@@|$$NCA_B64|g" \
	    install-certs.sh.template > install-certs.sh
	@chmod +x install-certs.sh
	@echo "Generated install-certs.sh (standalone with embedded certs)"

# Install NCA certificates to system browsers
install-certs: install-certs.sh
	@./install-certs.sh

# Clean everything
clean-all: clean clean-appimage
	@echo "All build artifacts cleaned."

# Package building targets for distribution packages
pkg-arch:
	@echo "Building Arch Linux package..."
	@if [ ! -f pkg/PKGBUILD ]; then \
		echo "Error: pkg/PKGBUILD not found"; \
		exit 1; \
	fi
	@cd pkg && makepkg -cf --noconfirm

pkg-deb:
	@echo "Building Debian/Ubuntu package..."
	@if [ ! -d debian ]; then \
		echo "Error: debian/ directory not found"; \
		exit 1; \
	fi
	@dpkg-buildpackage -us -uc -b

pkg-rpm:
	@echo "Building RPM package (RHEL/CentOS - system Java)..."
	@if [ ! -f pkg/ncalayer-rhel.spec ]; then \
		echo "Error: pkg/ncalayer-rhel.spec not found"; \
		exit 1; \
	fi
	@rpmbuild -ba pkg/ncalayer-rhel.spec

pkg-rpm-fedora:
	@echo "Building RPM package (Fedora - bundled Java)..."
	@if [ ! -f pkg/ncalayer-fedora.spec ]; then \
		echo "Error: pkg/ncalayer-fedora.spec not found"; \
		exit 1; \
	fi
	@rpmbuild -ba pkg/ncalayer-fedora.spec

clean-pkg:
	@echo "Cleaning package artifacts..."
	@rm -f pkg/*.pkg.tar.zst
	@rm -f ../*.deb ../*.buildinfo ../*.changes
	@rm -rf debian/.debhelper debian/ncalayer debian/files
	@rm -f *.rpm