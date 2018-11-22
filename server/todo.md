# Установка пакетов USBIP
## Для Fedora 28:
yum install usbip
## Для CentOS 7:
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
yum install kmod-usbip usbip-utils usbutils
### На 2018-11-21
В elrepo версия пакета kmod-usbip обновилась и может вызывать конфликты. Если так происходит, нужно установить более старую версию:
yum install kmod-usbip-1.0.1-2.el7_5.elrepo
