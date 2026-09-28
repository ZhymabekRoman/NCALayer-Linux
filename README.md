# NCALayer for Linux

**English** | [Русский](README.ru.md)

All source code in this project is open and fully reproducible. However, I take
no responsibility for any harm caused by using this project.

NCALayer is the digital signature application of the National Certification
Authority (NCA) of the Republic of Kazakhstan. This repository repackages the
official application into native Linux packages — it does not modify the
proprietary NCALayer JAR itself.

## Why port it to Linux

### The official installer's code quality

The upstream installer locates its helpers like this:

```bash
zenity=`whereis -b zenity | grep -i bin |  cut -d' ' -f2`;
```

and

```bash
certutil=`whereis -b certutil | grep -i bin |  cut -d' ' -f2`;
```

This is needlessly fragile — `which zenity` and `which certutil` do the same job
in one command.

The installer also hardcodes a specific terminal emulator, `gnome-terminal`,
which most distributions no longer ship by default. A portable launcher should
not assume one particular terminal.

### Broader distribution support

Currently supported targets:
 - Debian/Ubuntu
 - Arch Linux (via AUR)
 - Fedora/RedHat/CentOS
 - AppImage (universal format)

## Installation

### 📦 Prebuilt packages

Download prebuilt packages from
[GitHub Releases](https://github.com/ZhymabekRoman/NCALayer-Linux/releases/latest):

- **Arch Linux**: `ncalayer-*.pkg.tar.zst`
- **Debian/Ubuntu**: `ncalayer_*.deb`
- **Fedora** (bundled Java): `ncalayer-*fc*.rpm` (~260 MB)
- **RHEL/CentOS/Rocky** (system Java): `ncalayer-*el*.rpm` (~12 MB)
- **AppImage** (universal): `NCALayer-x86_64.AppImage`

### Arch Linux

**From the AUR:**
```bash
yay -S ncalayer
# or
paru -S ncalayer
```

**From a downloaded package:**
```bash
sudo pacman -U ncalayer-*.pkg.tar.zst
```

### Debian/Ubuntu

```bash
sudo dpkg -i ncalayer_*.deb
sudo apt-get install -f  # installs dependencies if needed
```

### Fedora/RHEL/CentOS

**Fedora** (bundled Java 8):
```bash
sudo dnf install ncalayer-*fc*.rpm
```

**Note:** Fedora does not ship Java in its official repositories
([details](https://docs.fedoraproject.org/en-US/quick-docs/installing-java/)),
so the Fedora package bundles Java 8 (~260 MB).

**RHEL/CentOS/Rocky Linux** (system Java 8):
```bash
sudo dnf install ncalayer-*el*.rpm
```

### AppImage (universal format)

```bash
chmod +x NCALayer-x86_64.AppImage
./NCALayer-x86_64.AppImage
```

The AppImage requires no installation and runs on any Linux distribution.

## Running the application

### Distribution packages (deb/rpm/pkg.tar.zst)

After installing, run:
```bash
ncalayer
```

Or find "NCALayer" in your application menu (under the "Network" section).

### AppImage

```bash
./NCALayer-x86_64.AppImage
```

## Installing the NCA RK certificates

The NCA certificates are installed **automatically** during package installation
for every existing user on the system.

To reinstall the certificates manually:

**Distribution packages:**
```bash
ncalayer-install-certs
```

**AppImage:**
```bash
./NCALayer-x86_64.AppImage --install-certs
```

Certificates are installed into Firefox, Chrome, Chromium and any other browser
that uses NSS databases.

## System requirements

### Distribution packages

**Debian/Ubuntu and Arch Linux** (~12 MB):
- **Java 8 JRE** (installed automatically as a dependency)
- **certutil** (from the nss-tools / libnss3-tools package)
- Optional: pcscd and libpcsclite for smart card support

**Fedora/RHEL/CentOS** (~260 MB):
- **Bundles a Java 8 JRE** (no system Java required)
- **certutil** (from the nss-tools package)
- Optional: pcsc-lite for smart card support

### AppImage (~103 MB)
- No dependencies (everything is bundled, including Java 8)
- Runs on any Linux distribution with glibc

## Compatibility with newer Java versions

NCALayer is designed for Java 8 and works best with that version. If you have a
newer Java (17+) installed, the application adds the
`-Djava.security.manager=allow` flag to work around the deprecated Security
Manager.

**Important:** Starting with Java 18 the Security Manager is disabled by
default, and from JDK 24 it is removed entirely
([JEP 411](https://openjdk.org/jeps/411)). With Java 17+ you may see a warning,
but the application should still run.

For best compatibility, Java 8 is recommended. More background on the issue:
https://stackoverflow.com/questions/76151072/error-during-sbt-launcher-java-lang-unsupportedoperationexception-the-security

## Building from source

For instructions on building the packages from source, see [BUILD.md](BUILD.md).

## License

Packaging and build scripts: MIT License (see [LICENSE](LICENSE))

NCALayer application: Copyright by the National Certification Authority of the
Republic of Kazakhstan
