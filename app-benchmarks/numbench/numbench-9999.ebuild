# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

PYTHON_COMPAT=( python2_7 )

inherit git-r3 distutils-r1

DESCRIPTION="Automated benchmarks suite"
HOMEPAGE="http://soc.dev.gentoo.org/~spiros"
#EGIT_REPO_URI="git://git.overlays.gentoo.org/proj/auto-numerical-bench.git"
EGIT_REPO_URI="git://github.com/andyspiros/numbench.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""

IUSE=""

RDEPEND="
	!app-eselect/eselect-blas
	!app-eselect/eselect-cblas
	!app-eselect/eselect-lapack
	>=dev-python/matplotlib-1.0.0
	>=app-admin/eselect-1.3.2-r100"

python_install_all() {
	distutils-r1_python_install_all

	python_parallel_foreach_impl python_newscript exec.py numbench

	insinto /usr/share/numbench/samples
	doins samples/*.xml

	doman doc/numbench.1
}
