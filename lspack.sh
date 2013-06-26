#!/bin/bash - 
#===============================================================================
#
#          FILE:  lspack
# 
#         USAGE:  ./lspack  regexp -v -h -d
# 
#   DESCRIPTION:  Listuje zainstalowane pakiety wg. wzorcu wyszukiwania
# 	@Debian
# 	Program wyszukuje pakietów zainstalowanych w systemie pasujących do wyrażenia regularnego 
# 	standardowo używa dpkg aczkolwiek podobno dlocate jest szybsze, dpkg domyślnie jest zainstalowany w systemie
# 
#       OPTIONS:  -v -h -d
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Rogoża Piotr rogoza.piotr@wp.eu
#       COMPANY: dracoRP
#       CREATED: 12.02.2010 09:24:01 CET
#      REVISION:  ---
#===============================================================================

NAME=lspack 

#-------------------------------------------------------------------------------
#  Funkcje
#-------------------------------------------------------------------------------
short_usage(){ #{{{
	echo -e "Usage: `basename $0` 'regular expression' -h -v -c"
} #}}}
usage(){ #{{{
	echo -e "\t-v show version of packages"
	echo -e "\t-h show help"
	echo -e "\t-s search in package's description "
	echo -e "\t-d show description of packages"
} #}}}
#-------------------------------------------------------------------------------
#  Opcje startowe, interpretacja parametrów itp.
#-------------------------------------------------------------------------------
#{{{
if [ $# -eq 0 ]; then 
	short_usage 
	exit 1
fi
PARAMETR="hvsd"
set -- `getopt -uq $PARAMETR $*`
if (( $? )); then
	short_usage
	exit
fi
#PACKAGE=`echo "$*" | awk -F'--' '{print $2}' | tr -d ' '`
PACKAGE=`echo "$*" | sed 's/.*--\ //g'`
DESC=1
SHOWDESC=1
while getopts $PARAMETR OPT; do
	case $OPT in
		h)
		short_usage
		usage
		exit
		;;
		v)
		VERSION=1
		;;
		s)
		unset DESC
		;;
		d)
		unset SHOWDESC
		;;
		?)
		usage
		exit
	esac
done
#}}}
#-------------------------------------------------------------------------------
#  Wybór wyszukiwania pakietu w zależności od systemu operacyjnego
#-------------------------------------------------------------------------------
#{{{
OS=`whichos`
case $OS in
	gentoo) #{{{
	;; #}}}
	debian) #{{{
	PROG=$(command -pv dpkg || command -pv dlocate)
	#PROG=dlocate
	[ ${PROG##*/} != "dlocate" ] && S="*"
	$PROG -l "${S}${PACKAGE}${S}" | sed -ne '/^i/p' | sed -e 's/^i[a-z]\ \ //' -e 's/\ \{2,\}/\ /g' -e 's/\ /\t/' -e 's/\ /\t/'
	;; #}}}
	archlinux) #{{{
	#REPO=`grep '^\[' /etc/pacman.conf | grep -v options | tr -d '[]' | tr '\n' ' ' | sed 's/\ \([a-z]\)/\\\|\1/g'`
	#Coś się zmianiło i pacman -Qs pokazuje zainstalowane pakiety jako local
	#pacman -Qq | grep pakiet jest szybszy niż pacman -Qqs pakiet
	REPO='^local'
	if [ -n "$SHOWDESC" ]; then
		#pacman -Qsq ${PACKAGE} #tylko nazwy
		pacman -Qs ${PACKAGE}  | grep "$REPO${DESC:+.*$PACKAGE}" | grep "$REPO" | cut -d'/' -f2 | cut -d' ' -f1${VERSION:+,2}
	else
		echo "not yet"
		#pacman -Qs ${PACKAGE}  | ${DESC:+grep ".*$PACKAGE"} #| sed 's/^[[:space:]]//' 
		#| cut -d'/' -f2 | cut -d' ' -f1${VERSION:+,2}
	fi
	;; #}}}
	*)
	echo "Wybacz tego systemu jeszcze nie przeglądałem"
esac
#}}}
exit 0

