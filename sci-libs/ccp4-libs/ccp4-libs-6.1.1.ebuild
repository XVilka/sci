# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit fortran eutils gnuconfig toolchain-funcs

FORTRAN="g77 gfortran ifc"

SRC="ftp://ftp.ccp4.ac.uk/ccp4"

PATCH_TOT="0"
# Here's a little scriptlet to generate this list from the provided
# index.patches file
#
# i=1; while read -a line; do [[ ${line//#} != ${line} ]] && continue;
# echo "PATCH${i}=( ${line[1]}"; echo "${line[0]} )"; (( i++ )); done <
# index.patches
#PATCH1=( src/topp_
#topp.f-r1.16.2.5-r1.16.2.6.diff )
#PATCH2=( .
#configure-r1.372.2.18-r1.372.2.19.diff )

DESCRIPTION="Protein X-ray crystallography toolkit"
HOMEPAGE="http://www.ccp4.ac.uk/"
RESTRICT="mirror"
SRC_URI="${SRC}/${PV}/${P/-libs}-core-src.tar.gz"
for i in $(seq $PATCH_TOT); do
	NAME="PATCH${i}[1]"
	SRC_URI="${SRC_URI}
		${SRC}/${PV}/patches/${!NAME}"
done
LICENSE="ccp4"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""
RDEPEND="virtual/lapack
		virtual/blas
		=sci-libs/fftw-2*
		app-shells/tcsh
	 !<sci-chemistry/ccp4-6.0.99"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${P/-libs}"

src_unpack() {
	unpack ${A}
	cd "${S}"

	einfo "Applying upstream patches ..."
	for patch in $(seq $PATCH_TOT); do
		base="PATCH${patch}"
		dir=$(eval echo \${${base}[0]})
		p=$(eval echo \${${base}[1]})
		pushd "${dir}" >& /dev/null
		ccp_patch "${DISTDIR}/${p}"
		popd >& /dev/null
	done
	einfo "Done."
	echo

	einfo "Applying Gentoo patches ..."
	# These two only needed when attempting to install outside build dir via
	# --bindir and --libdir instead of straight copying after build

	# it attempts to install some libraries during the build
	#ccp_patch "${FILESDIR}"/${P}-install-libs-at-install-time.patch
	# hklview/ipdisp.exe/xdlmapman/ipmosflm can't find libxdl_view
	# without this patch when --libdir is set
	# Rotgen still needs more patching to find it
	#ccp_patch "${FILESDIR}"/add-xdl-libdir.patch

	# it tries to create libdir, bindir etc on live system in configure
	ccp_patch "${FILESDIR}"/${PV}-dont-make-dirs-in-configure.patch

	# gerror_ gets defined twice on ppc if you're using gfortran/g95
	ccp_patch "${FILESDIR}"/6.0.2-ppc-double-define-gerror.patch

	einfo "Done." # done applying Gentoo patches
	echo

	gnuconfig_update
}

src_compile() {
	# Build system is broken if we set LDFLAGS
	unset LDFLAGS

	# GENTOO_OSNAME can be one of:
	# irix irix64 sunos sunos64 aix hpux osf1 linux freebsd
	# linux_compaq_compilers linux_intel_compilers generic Darwin
	# ia64_linux_intel Darwin_ibm_compilers linux_ibm_compilers
	if [[ "${FORTRANC}" = "ifc" ]]; then
		if use ia64; then
			GENTOO_OSNAME="ia64_linux_intel"
		else
			# Should be valid for x86, maybe amd64
			GENTOO_OSNAME="linux_intel_compilers"
		fi
	else
		# Should be valid for x86 and amd64, at least
		GENTOO_OSNAME="linux"
	fi

	# Sets up env
	ln -s \
		ccp4.setup-bash \
		"${S}"/include/ccp4.setup

	# We agree to the license by emerging this, set in LICENSE
	sed -i \
		-e "s~^\(^agreed=\).*~\1yes~g" \
		"${S}"/configure

	# Fix up variables -- need to reset CCP4_MASTER at install-time
	sed -i \
		-e "s~^\(setenv CCP4_MASTER.*\)/.*~\1"${WORKDIR}"~g" \
		-e "s~^\(setenv CCP4I_TCLTK.*\)/usr/local/bin~\1/usr/bin~g" \
		"${S}"/include/ccp4.setup*

	# Set up variables for build
	source "${S}"/include/ccp4.setup

	export CC=$(tc-getCC)
	export CXX=$(tc-getCXX)
	export COPTIM=${CFLAGS}
	export CXXOPTIM=${CXXFLAGS}
	# Default to -O2 if FFLAGS is unset
	export FC=${FORTRANC}
	export FOPTIM=${FFLAGS:- -O2}

	# Fix linking
	export SHARE_LIB="ld -shared -soname libmmdb.so --whole-archive -o libmmdb.so libmmdb.a ../libccif.a; \
			  ld -shared -soname libccp4c.so --whole-archive -o libccp4c.so libccp4c.a ../libccif.a; \
			  ld -shared -soname libccp4f.so --whole-archive -o libccp4f.so libccp4f.a libmmdb.a libccp4c.a ../libccif.a -lstdc++ $(gcc-config -L | awk -F: '{for(i=1; i<=NF; i++) printf " -L%s", $i}')"

	# Can't use econf, configure rejects unknown options like --prefix
	./configure \
		--onlylibs \
		--with-shared-libs \
		--with-fftw=/usr \
		--with-warnings \
		--disable-cctbx \
		--disable-clipper \
		--tmpdir="${TMPDIR}" \
		${GENTOO_OSNAME} || die "econf failed"
	emake -j1 onlylib || die "emake failed"
}

src_install() {
	# Set up variables for build
	source "${S}"/include/ccp4.setup

# Only needed when using --bindir and --libdir
	# Needed to avoid errors. Originally tried to make lib and bin
	# in configure script, now patched out by dont-make-dirs-in-configure.patch
#	dodir /usr/include /usr/$(get_libdir) /usr/bin

#	make install || die "install failed"
	einstall || die "install failed"

	# Libs
	for file in "${S}"/lib/*; do
		if [[ -d ${file} ]]; then
			continue
		elif [[ -x ${file} ]]; then
			dolib.so ${file} || die
		else
			insinto /usr/$(get_libdir)
			doins ${file} || die
		fi
	done

	# Fix libdir in all *.la files
	sed -i \
		-e "s:^\(libdir=\).*:\1\'/usr/$(get_libdir)\':g" \
		"${D}"/usr/$(get_libdir)/*.la

	# Data
	insinto /usr/share/ccp4
	doins -r "${S}"/lib/data || die

	# Include files
	insinto /usr/include
	for i in ccp4 mmdb; do
		doins -r "${S}"/include/${i} || die
	done
}

# Epatch wrapper for bulk patching
ccp_patch() {
	EPATCH_SINGLE_MSG="  ${1##*/} ..." epatch ${1}
}
