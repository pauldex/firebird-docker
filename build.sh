#!/bin/bash
set -e
CPUC=$(awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo)
BDEPS="bzip2
ca-certificates
curl
file
g++
gcc
libicu-dev
libncurses5-dev
libtommath-dev
make
procps
zlib1g-dev"

export CXXFLAGS="-std=gnu++98 -fno-lifetime-dse -fno-delete-null-pointer-checks -fno-strict-aliasing"

apt-get update
apt-get install -qy --no-install-recommends \
    libicu57 \
    libtommath1
apt-get install -qy --no-install-recommends ${BDEPS}
mkdir -p /home/firebird
cd /home/firebird
curl -o firebird-source.tar.bz2 -L \
    "${FBURL}"
tar --strip=1 -xf firebird-source.tar.bz2
./configure \
    --prefix=${PREFIX}/ --with-fbbin=${PREFIX}/bin/ --with-fbsbin=${PREFIX}/bin/ --with-fblib=${PREFIX}/lib/ \
    --with-fbinclude=${PREFIX}/include/ --with-fbdoc=${PREFIX}/doc/ --with-fbudf=${PREFIX}/UDF/ \
    --with-fbsample=${PREFIX}/examples/ --with-fbsample-db=${PREFIX}/examples/empbuild/ --with-fbhelp=${PREFIX}/help/ \
    --with-fbintl=${PREFIX}/intl/ --with-fbmisc=${PREFIX}/misc/ --with-fbplugins=${PREFIX}/ \
    --with-fbconf="${VOLUME}/etc/" --with-fbmsg=${PREFIX}/ \
    --with-fblog="${VOLUME}/log/" --with-fbglock=/var/firebird/run/ \
    --with-fbsecure-db="${VOLUME}/system"
make -j${CPUC}
make silent_install
cd /
rm -rf /home/firebird
find ${PREFIX} -name .debug -prune -exec rm -rf {} \;
apt-get purge -qy --auto-remove ${BDEPS}
rm -rf /var/lib/apt/lists/*

mkdir -p "${PREFIX}/skel/"

# This allows us to initialize a random value for sysdba password
mv "${VOLUME}/system/security3.fdb" "${PREFIX}/skel/security3.fdb"

# Cleaning up to restrict access to specific path and allow changing that path easily to
# something standard. See github issue https://github.com/jacobalberty/firebird-docker/issues/12
sed -i 's/^#DatabaseAccess/DatabaseAccess/g' "${VOLUME}/etc/firebird.conf"
sed -i "s~^\(DatabaseAccess\s*=\s*\).*$~\1Restrict ${DBPATH}~" "${VOLUME}/etc/firebird.conf"

mv "${VOLUME}/etc" "${PREFIX}/skel"
