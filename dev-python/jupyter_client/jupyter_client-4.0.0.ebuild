# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
PYTHON_COMPAT=( python2_7 python{3_3,3_4} )

inherit distutils-r1

DESCRIPTION="Jupyter protocol implementation and client libraries"
HOMEPAGE="http://jupyter.org"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
KEYWORDS="~amd64 ~x86"

LICENSE="BSD"
SLOT="0"
IUSE="test"

RDEPEND="
	dev-python/traitlets[${PYTHON_USEDEP}]
	dev-python/jupyter_core[${PYTHON_USEDEP}]
	>=dev-python/pyzmq-14.4.0[${PYTHON_USEDEP}]
	"
DEPEND="${RDEPEND}
	test? (
		dev-python/nose[${PYTHON_USEDEP}]
		dev-python/coverage[${PYTHON_USEDEP}]
		$(python_gen_cond_dep 'dev-python/mock[${PYTHON_USEDEP}]' python2_7)
		dev-python/ipykernel[${PYTHON_USEDEP}]
	)
	"

python_test() {
	nosetests --with-coverage jupyter_client || die
}
