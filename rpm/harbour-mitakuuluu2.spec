Name:       harbour-mitakuuluu2

# >> macros
# << macros

%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}
Summary:    Mitäkuuluu
Version:    0.5
Release:    9
Group:      Qt/Qt
License:    WTFPL
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 libexif
#Requires:   qtcontacts-sqlite-qt5 >= 0.1.37
Requires:   nemo-transferengine-qt5
Requires:   declarative-transferengine-qt5 >= 0.0.44
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
#BuildRequires:  pkgconfig(Qt5Contacts)
BuildRequires:  pkgconfig(sailfishapp)
#BuildRequires:  pkgconfig(contactcache-qt5) >= 0.0.61
#BuildRequires:  pkgconfig(qtcontacts-sqlite-qt5-extensions) >= 0.1.41
BuildRequires:  pkgconfig(mlite5)
BuildRequires:  desktop-file-utils
BuildRequires:  libexif-devel
BuildRequires:  pkgconfig(nemotransferengine-qt5)
BuildRequires:  gstreamer-devel

%description
Short description of my SailfishOS Application

%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qtc_qmake5  \
    VERSION=%{version} \
    RELEASE=%{release}

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
%{_datadir}/dbus-1/services
/etc/mce
/etc/profiled
%{_datadir}/lipstick/notificationcategories
%{_datadir}/ngfd/events.d
#%{_datadir}/jolla-gallery/mediasources
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/86x86/apps
%{_datadir}/%{name}
#/usr/lib/qt5/qml/harbour/mitakuuluu2/sharecontacts
/usr/lib/nemo-transferengine/plugins
/usr/lib/systemd/user
%{_bindir}
# >> files
# << files
