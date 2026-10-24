# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

EAPI=8

DESCRIPTION="Locally supplied Anbernic RG SP kernel and selected matching modules"
HOMEPAGE="https://win.anbernic.com/"
SRC_URI="
	${P}-Image
	${P}-board.dtb
	${P}-rtl_btlpm.ko
	${P}-8821cs.ko
"
S="${WORKDIR}"

# The vendor DTB has no verified source license; see docs/anbernic-stock-kernels.md.
LICENSE="GPL-2 all-rights-reserved"
SLOT="${PV}"
KEYWORDS="~arm64"
RESTRICT="bindist fetch mirror strip"

QA_PREBUILT="*"

pkg_nofetch() {
	einfo "Place the pinned files listed in SRC_URI in your configured Portage DISTDIR."
	einfo "See mono-overlay's docs/anbernic-stock-kernels.md for extraction instructions."
}

src_unpack() { :; }

src_install() {
	insinto "/usr/lib/${PN}/${PV}"
	newins "${DISTDIR}/${P}-Image" Image
	newins "${DISTDIR}/${P}-board.dtb" board.dtb
	insinto "/usr/lib/${PN}/${PV}/modules"
	newins "${DISTDIR}/${P}-rtl_btlpm.ko" rtl_btlpm.ko
	newins "${DISTDIR}/${P}-8821cs.ko" 8821cs.ko
}

pkg_postinst() {
	elog "Stock kernel, DTB and selected matching modules are in /usr/lib/${PN}/${PV}."
	elog "Boot packaging, firmware and activation are separate; /boot was not changed."
	ewarn "Matching vendor source and redistribution rights remain unverified. Keep payloads local."
}
