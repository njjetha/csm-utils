Name:           csm-utils
Version:        %{version}
Release:        1%{?dist}
Summary:        RHEL pkg for csm-utils
BuildArch:      x86_64
License:        BSD-3-Clause-Clear
Source0:        %{name}-%{version}.tar.gz
Requires:       bash

%global __brp_ldconfig %{nil}

%description
csm-utils for csm host

%prep
%setup -q

%install
echo -e "\n Starting INSTALL step... \n"
%{__rm} -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{_bindir}
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/udev/rules.d
install -m 755 csm-utils/csm-nbdkit.sh $RPM_BUILD_ROOT%{_bindir}/csm-nbdkit.sh
install -m 644 csm-utils/csm-nbdkit@.service $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system/csm-nbdkit@.service
install -m 755 csm-utils/csm-configure-ip.sh $RPM_BUILD_ROOT%{_bindir}/csm-configure-ip.sh
install -m 644 csm-utils/csm-configure-ip@.service $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system/csm-configure-ip@.service
install -m 755 csm-utils/csm-nbdkit-stop.sh $RPM_BUILD_ROOT%{_bindir}/csm-nbdkit-stop.sh
install -m 755 csm-utils/csm-store-ddr.sh $RPM_BUILD_ROOT%{_bindir}/csm-store-ddr.sh
install -m 644 csm-utils/csm-store-ddr@.service $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system/csm-store-ddr@.service
install -m 755 csm-utils/decimal-to-hex.sh $RPM_BUILD_ROOT%{_bindir}/decimal-to-hex.sh
install -m 644 csm-utils/99-mhi-csm-ctrl-device.rules $RPM_BUILD_ROOT%{_sysconfdir}/udev/rules.d
install -m 644 csm-utils/99-csm-device-remove.rules $RPM_BUILD_ROOT%{_sysconfdir}/udev/rules.d
install -m 755 csm-utils/csm-check-repair.sh $RPM_BUILD_ROOT%{_bindir}/csm-check-repair.sh
install -m 755 csm-utils/csm-event-handler.sh $RPM_BUILD_ROOT%{_bindir}/csm-event-handler.sh

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%{_bindir}/csm-nbdkit.sh
%{_bindir}/csm-nbdkit-stop.sh
%{_bindir}/csm-configure-ip.sh
%{_bindir}/csm-check-repair.sh
%{_bindir}/csm-event-handler.sh
%{_bindir}/csm-store-ddr.sh
%{_bindir}/decimal-to-hex.sh
%{_sysconfdir}/systemd/system/csm-nbdkit@.service
%{_sysconfdir}/systemd/system/csm-configure-ip@.service
%{_sysconfdir}/systemd/system/csm-store-ddr@.service
%config %{_sysconfdir}/udev/rules.d/99-mhi-csm-ctrl-device.rules
%config %{_sysconfdir}/udev/rules.d/99-csm-device-remove.rules
