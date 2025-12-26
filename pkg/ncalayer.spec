Name:           ncalayer
Version:        1.0.0
Release:        1%{?dist}
Summary:        NCALayer digital signature application

%global debug_package %{nil}

License:        MIT
URL:            https://github.com/ZhymabekRoman/NCALayer-Linux
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  make
BuildRequires:  wget
BuildRequires:  unzip
Requires:       java-1.8.0-openjdk
Requires:       nss-tools
Recommends:     pcsc-lite
ExclusiveArch:  x86_64

%description
NCALayer is the official digital signature application for Kazakhstan's
National Certification Authority (NCA) PKI infrastructure.

This package provides the core application for working with electronic
digital signatures, smart cards, and NCA certificates.

After installation, run 'ncalayer-install-certs' to install NCA
certificates to your browser databases.

%prep
%autosetup

%build
# Download and extract during build
make download
make verify
make extract
make extract-jar
make install-certs.sh

%install
# Install JAR
install -Dm644 ncalayer.jar %{buildroot}%{_datadir}/%{name}/ncalayer.jar

# Install certificates
install -Dm644 additions/cert/root_rsa.cer %{buildroot}%{_datadir}/%{name}/cert/root_rsa.cer
install -Dm644 additions/cert/nca_rsa.cer %{buildroot}%{_datadir}/%{name}/cert/nca_rsa.cer

# Install certificate installer
install -Dm755 install-certs.sh %{buildroot}%{_bindir}/%{name}-install-certs

# Install launcher
install -Dm755 pkg/launcher.sh %{buildroot}%{_bindir}/%{name}

# Install desktop entry
sed 's/Exec=ncalayer/Exec=\/usr\/bin\/ncalayer/' ncalayer.desktop.template > ncalayer.desktop
install -Dm644 ncalayer.desktop %{buildroot}%{_datadir}/applications/%{name}.desktop

# Install icon
install -Dm644 additions/ncalayer.png %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/%{name}.png

# Install documentation
install -Dm644 README.md %{buildroot}%{_docdir}/%{name}/README.md

%files
%doc README.md
%{_bindir}/%{name}
%{_bindir}/%{name}-install-certs
%{_datadir}/%{name}/ncalayer.jar
%{_datadir}/%{name}/cert/root_rsa.cer
%{_datadir}/%{name}/cert/nca_rsa.cer
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/256x256/apps/%{name}.png
%{_docdir}/%{name}/README.md

%post
echo ""
echo "========================================"
echo "NCALayer installed successfully!"
echo "========================================"
echo ""

# Automatically install certificates for all users
echo "Installing NCA certificates for all users..."
echo ""

# Install certificates for each user with a home directory
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")

        # Check if user exists
        if id "$username" >/dev/null 2>&1; then
            echo "Installing certificates for user: $username"

            # Run certificate installer as the user
            su - "$username" -c "/usr/bin/ncalayer-install-certs" 2>/dev/null || true
        fi
    fi
done

echo ""
echo "Certificate installation completed."
echo ""
echo "To start NCALayer:"
echo "  ncalayer"
echo ""
echo "If you need to reinstall certificates later, run:"
echo "  ncalayer-install-certs"
echo ""

%changelog
* Thu Dec 26 2024 ZhymabekRoman <robanokssamit@yandex.kz> - 1.0.0-1
- Initial package release
- Digital signature application for Kazakhstan NCA PKI
- System Java 8 dependency (no bundled JRE)
