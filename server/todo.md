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

# Install order
## Install packages
1. usbutils
2. kernel modules
3. usbip utils
## Install scripts
1. /etc/modules-load.d/usbipd.conf
2. /scripts/usbipd.sh
3. /etc/systemd/system/usbipd.service
## Enable service
1. Enable service
2. Open port for incoming:
firewall-cmd --permanent --zone=(some zone or all zones) --add-port=3240/tcp
firewall-cmd –reload

# ToDo here
## Filter devices by vendor's name
In progress.
1. Name and/or ID are defined in $VENDOR variable in /scripts/usbipd.sh
2. Сопоставить ID и дружественные имена вендоров.
3. Передавать имя/айди вендора как аргумент при запуске службы.
4. Дать возможность выбора вендора при установке.
5. Дать возможность множественного выбора.
Множественные аргументы для юнитов - пример: https://superuser.com/questions/728951/systemd-giving-my-service-multiple-arguments
6. Unbind devices when service stops - Done.