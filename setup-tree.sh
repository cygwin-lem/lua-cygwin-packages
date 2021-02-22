#!/bin/bash

################################################################
PKGDIR=./repos
CYGDIR=./lua-cygwin

################################################################
declare -A CYGWIN_PACKAGES=(
[lua54]="https://github.com/cygwin-lem/lua-cygport lua54_gh-pages"
[lua53]="https://github.com/cygwin-lem/lua-cygport lua53_gh-pages"
[lua51]="https://github.com/cygwin-lem/lua-cygport lua51_gh-pages"

[luarocks]="https://github.com/cygwin-lem/luarocks-cygport luarocks_gh-pages"

[lua-crypto]="https://github.com/cygwin-lem/lua-crypto-cygport lua-crypto_gh-pages"
[lua-luaossl]="https://github.com/cygwin-lem/lua-luaossl-cygport lua-luaossl_gh-pages"

[lua-lunitx]="https://github.com/cygwin-lem/lua-lunitx-cygport lua-lunitx_gh-pages"

[lua-lpeg]="https://github.com/cygwin-lem/lua-lpeg-cygport lua-lpeg_gh-pages"
 [lua-json]="https://github.com/cygwin-lem/lua-json-cygport lua-json_gh-pages"

[lua-ldap]="https://github.com/cygwin-lem/lua-ldap-cygport lua-ldap_gh-pages"

[lua-lfs]="https://github.com/cygwin-lem/lua-lfs-cygport lua-lfs_gh-pages"
 [lua-pl]="https://github.com/cygwin-lem/lua-pl-cygport lua-pl_gh-pages"
  [lua-ldoc]="https://github.com/cygwin-lem/lua-ldoc-cygport lua-ldoc_gh-pages"

[lua-lgi]="https://github.com/cygwin-lem/lua-lgi-cygport lua-lgi_gh-pages"

[lua-socket]="https://github.com/cygwin-lem/lua-socket-cygport lua-socket_gh-pages"
 [lua-logging]="https://github.com/cygwin-lem/lua-logging-cygport lua-logging_gh-pages"
 [lua-luasec]="https://github.com/cygwin-lem/lua-luasec-cygport lua-luasec_gh-pages"

[lua-lxp]="https://github.com/cygwin-lem/lua-lxp-cygport lua-lxp_gh-pages"

[lua-say]="https://github.com/cygwin-lem/lua-say-cygport lua-say_gh-pages"
  [lua-luassert]="https://github.com/cygwin-lem/lua-luassert-cygport lua-luassert_gh-pages"

# Obsolete
#[lua-luadoc]="https://github.com/cygwin-lem/lua-luadoc-cygport lua-luadoc_gh-pages"

# Pending
#[lua-cliargs]="https://github.com/cygwin-lem/lua-cliargs-cygport lua-cliargs_gh-pages"
#[lua-mediator]="https://github.com/cygwin-lem/lua-mediator-cygport lua-mediator_gh-pages"
)

################################################################
declare -A M_ARCH=(
  [noarch]=noarch
  [x86]=i686
  [x86_64]=x86_64
)

################################################################

v () {
  local N="${1}"
  shift $N || return 1
  printf '%s' "${1}"
}

################################################################
get_pkg () {
  local P="${1}"
  if [ -d "${PKGDIR}/${P}" ]; then
    rm -rf "${PKGDIR}/${P}" 
  fi
  mkdir -p "${PKGDIR}"

  local R=$(v 1 ${CYGWIN_PACKAGES[${P}]})
  local B=$(v 2 ${CYGWIN_PACKAGES[${P}]})
  git clone ${R} --branch ${B} --depth 1 ${PKGDIR}/${P}
}

get_pkgs () {
  local P
  rm -rf "${PKGDIR}"
  mkdir -p "${PKGDIR}"
  for P in "${!CYGWIN_PACKAGES[@]}"; do
    printf '%s\n' "$P"
    get_pkg "$P"
  done
}

################################################################
prep_tree () {
  local ARCH

  rm -rf "${CYGDIR}"

  for ARCH in x86 x86_64 noarch ; do
    D="${CYGDIR}/${ARCH}/release"
    mkdir -p "${D}"
    find "${PKGDIR}" -maxdepth 3 -type d -name dist \
    | grep -e "${M_ARCH[${ARCH}]}"'/dist$' \
    | sed -e 's|$|/.|' \
    | xargs -r cp -prt "${D}"
  done
}

################################################################
mksetupini_options=(
  "--disable-check=missing-required-package"
  "--disable-check=missing-depended-package"
  "--disable-check=missing-curr"
)

setup_tree () {
  local ARCH
  pushd "${CYGDIR}"
  for ARCH in x86 x86_64 ; do
    mksetupini \
      "${mksetupini_options[@]}" \
      --arch ${ARCH} \
      --inifile=${ARCH}/setup.ini \
      --releasearea=. \
      ;
    bzip2 <${ARCH}/setup.ini >${ARCH}/setup.bz2
    xz -6e <${ARCH}/setup.ini >${ARCH}/setup.xz
    zstd <${ARCH}/setup.ini >${ARCH}/setup.zst
  done
  popd
}

################################################################list2html () {
list2html () {
  echo "<html><body><ul>"
  perl -ne 'chop; $type=""; $type=" type=\"text/plain\"" if /\.hint$/ ; print "<li><a href=\"$_\"$type>$_</a></li>\n";'
  echo "</ul></body></html>"
}

makelist () {
  mkdir -p "${CYGDIR}" 
  pushd "${CYGDIR}" > /dev/null
  echo ../index.html
  find . -type f
  popd > /dev/null
}

make_index_html () {
  local TMPFILE=".index.html.$$"
  local DSTFILE="${CYGDIR}/index.html"
  rm -f "${DSTFILE}" > /dev/null 2>&1
  makelist | list2html > "${TMPFILE}"
  mv "${TMPFILE}" "${DSTFILE}"
}

################################################################
get_pkgs
prep_tree
setup_tree
make_index_html
