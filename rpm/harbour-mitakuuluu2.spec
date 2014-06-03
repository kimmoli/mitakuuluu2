Name:       harbour-mitakuuluu2

# >> macros
# << macros

%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}
Summary:    Mitäkuuluu
Version:    0.7.6
Release:    1
Group:      Qt/Qt
License:    WTFPL
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5
Requires:   nemo-transferengine-qt5
Requires:   declarative-transferengine-qt5 >= 0.0.44
Requires:   qt5-qtdeclarative-import-sensors qt5-qtsensors-plugin-gestures-sensor, qt5-qtsensors-plugin-gestures-shake
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(sailfishapp)
BuildRequires:  pkgconfig(mlite5)
BuildRequires:  desktop-file-utils
BuildRequires:  pkgconfig(nemotransferengine-qt5)
BuildRequires:  gstreamer-devel
BuildRequires:  libcontacts-qt5-devel qtcontacts-sqlite-qt5-extensions

%description
Short description of my SailfishOS Application

%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qtc_make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%pre
# >> pre

if /sbin/pidof harbour-mitakuuluu2-server > /dev/null; then
killall harbour-mitakuuluu2-server
fi

if /sbin/pidof harbour-mitakuuluu2 > /dev/null; then
killall harbour-mitakuuluu2
fi
# << pre

%preun
# >> preun

if /sbin/pidof harbour-mitakuuluu-server > /dev/null; then
killall harbour-mitakuuluu-server
fi

if /sbin/pidof harbour-mitakuuluu2 > /dev/null; then
killall harbour-mitakuuluu2
fi
# << preun

%post
# >> post
systemctl-user restart ngfd.service
systemctl restart mce.service
# << post

%files
%defattr(-,root,root,-)
%{_datadir}/dbus-1/services/*.service
%config /etc/mce/*.ini
%config /etc/profiled/*.ini
%config %{_datadir}/ngfd/events.d/*.ini
%config %{_datadir}/lipstick/notificationcategories/*.conf
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
%{_datadir}/%{name}
/usr/lib/nemo-transferengine/plugins/*.so
/usr/lib/systemd/user/*.service
%attr(4755, root, root) %{_bindir}/harbour-mitakuuluu2-helper
%{_bindir}/harbour-mitakuuluu2-server
%{_bindir}/harbour-mitakuuluu2
# >> files
# << files
