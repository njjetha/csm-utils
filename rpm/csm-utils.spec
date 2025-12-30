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
install -m 755 csm-utils/csm-device-health.sh $RPM_BUILD_ROOT%{_bindir}/csm-device-health.sh
install -m 644 csm-utils/csm-device-health@.service $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system/csm-device-health@.service
install -m 755 csm-utils/csm-nbdkit-stop.sh $RPM_BUILD_ROOT%{_bindir}/csm-nbdkit-stop.sh
install -m 755 csm-utils/csm-store-ddr.sh $RPM_BUILD_ROOT%{_bindir}/csm-store-ddr.sh
install -m 644 csm-utils/csm-store-ddr@.service $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system/csm-store-ddr@.service
install -m 755 csm-utils/decimal-to-hex.sh $RPM_BUILD_ROOT%{_bindir}/decimal-to-hex.sh
install -m 755 csm-utils/csm-host-debugger.sh $RPM_BUILD_ROOT%{_bindir}/csm-host-debugger.sh
install -m 755 csm-utils/csm-host-logger.sh $RPM_BUILD_ROOT%{_bindir}/csm-host-logger.sh
install -m 644 csm-utils/csm-host-logger@.service $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system/csm-host-logger@.service
install -m 644 csm-utils/csm-host-logger@.timer $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system/csm-host-logger@.timer
install -m 755 csm-utils/csm-host-log-crash.sh $RPM_BUILD_ROOT%{_bindir}/csm-host-log-crash.sh
install -m 644 csm-utils/host_log_crash.cfg $RPM_BUILD_ROOT%{_sysconfdir}/host_log_crash.cfg
install -m 644 csm-utils/99-mhi-csm-ctrl-device.rules $RPM_BUILD_ROOT%{_sysconfdir}/udev/rules.d
install -m 644 csm-utils/99-csm-device-remove.rules $RPM_BUILD_ROOT%{_sysconfdir}/udev/rules.d
install -m 755 csm-utils/csm-check-repair.sh $RPM_BUILD_ROOT%{_bindir}/csm-check-repair.sh
install -m 755 csm-utils/csm-event-handler.sh $RPM_BUILD_ROOT%{_bindir}/csm-event-handler.sh
install -m 755 csm-utils/csm-collect-conf.sh $RPM_BUILD_ROOT%{_bindir}/csm-collect-conf.sh
install -m 644 csm-utils/csm-collect-conf@.service $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system/csm-collect-conf@.service
install -m 644 csm-utils/csm-collect-conf@.timer $RPM_BUILD_ROOT%{_sysconfdir}/systemd/system/csm-collect-conf@.timer

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
%{_bindir}/csm-device-health.sh
%{_bindir}/csm-host-debugger.sh
%{_bindir}/csm-host-logger.sh
%{_bindir}/csm-collect-conf.sh
%{_bindir}/csm-host-log-crash.sh
%{_sysconfdir}/systemd/system/csm-nbdkit@.service
%{_sysconfdir}/systemd/system/csm-configure-ip@.service
%{_sysconfdir}/systemd/system/csm-store-ddr@.service
%{_sysconfdir}/systemd/system/csm-device-health@.service
%{_sysconfdir}/systemd/system/csm-host-logger@.service
%{_sysconfdir}/systemd/system/csm-host-logger@.timer
%{_sysconfdir}/systemd/system/csm-collect-conf@.service
%{_sysconfdir}/systemd/system/csm-collect-conf@.timer
%{_sysconfdir}/host_log_crash.cfg
%config %{_sysconfdir}/udev/rules.d/99-mhi-csm-ctrl-device.rules
%config %{_sysconfdir}/udev/rules.d/99-csm-device-remove.rules
