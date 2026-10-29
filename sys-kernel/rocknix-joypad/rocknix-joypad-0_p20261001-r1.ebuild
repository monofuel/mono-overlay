# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

EAPI=8
inherit toolchain-funcs

DESCRIPTION="ROCKNIX single-ADC controller driver for the RG DS Plus"
HOMEPAGE="https://github.com/ROCKNIX/rocknix-joypad"
COMMIT=d02ed13aae08113f6f9e0e9d699cb29bb3450fa2
SRC_URI="https://github.com/ROCKNIX/rocknix-joypad/archive/${COMMIT}.tar.gz -> ${PN}-${COMMIT}.tar.gz"
S="${WORKDIR}/${PN}-${COMMIT}"
LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~arm64"

KERNEL_RELEASE=7.0.2-mono-rgdsplus-rocknix-r2
DEPEND="=sys-kernel/rg-ds-plus-rocknix-kernel-7.0.2-r2"
RDEPEND="${DEPEND}"
BDEPEND="sys-apps/kmod"

src_compile() {
	emake -C "${ESYSROOT}/usr/src/linux-${KERNEL_RELEASE}" \
		ARCH=arm64 CC="$(tc-getCC)" HOSTCC="$(tc-getBUILD_CC)" M="${S}" DEVICE=RK3566 modules
}

src_install() {
	insinto "/lib/modules/${KERNEL_RELEASE}/extra"
	doins rocknix-singleadc-joypad.ko
	dodoc CREDITS
}

pkg_postinst() {
	depmod -b "${EROOT:-/}" "${KERNEL_RELEASE}" || die
}

pkg_postrm() {
	if [[ -d ${EROOT}/lib/modules/${KERNEL_RELEASE} ]]; then
		depmod -b "${EROOT:-/}" "${KERNEL_RELEASE}" || die
	fi
}
