# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

EAPI=8

DESCRIPTION="Locally supplied RG DS Plus AW88166 speaker profile"
HOMEPAGE="https://github.com/ROCKNIX/extra-firmware"
SRC_URI="${P}-aw88166_acf.bin"
S="${WORKDIR}"
# No redistribution grant is established for this vendor profile.
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~arm64"
RESTRICT="bindist fetch mirror strip"

pkg_nofetch() {
	einfo "Supply ${P}-aw88166_acf.bin in DISTDIR from your local stock firmware."
	einfo "The Manifest pins the bytes matching ROCKNIX's RG DS Plus profile."
}

src_unpack() { :; }

src_install() {
	insinto /lib/firmware
	newins "${DISTDIR}/${P}-aw88166_acf.bin" aw88166_acf.bin
}
