# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Trusted Firmware-A BL31 for the Anbernic RG SP H700 boot chain"
HOMEPAGE="https://www.trustedfirmware.org/projects/tf-a/"
SRC_URI="https://github.com/TrustedFirmware-A/trusted-firmware-a/archive/v${PV}.tar.gz -> trusted-firmware-a-${PV}.tar.gz"
S="${WORKDIR}/trusted-firmware-a-${PV}"

LICENSE="BSD BSD-2 ISC Apache-2.0-with-LLVM-exceptions"
SLOT="${PV}"
KEYWORDS="~arm64"
BDEPEND="app-arch/xz-utils"

src_prepare() {
	default
	cp "${FILESDIR}/BSD-2" "${FILESDIR}/Apache-2.0-with-LLVM-exceptions" \
		"${FILESDIR}/NOTICE" . || die
}

src_compile() {
	# Firmware links directly with ld, so host GCC-driver flags do not apply.
	emake PLAT=sun50i_h616 ARCH=aarch64 \
		CC="$(tc-getCC)" LD="$(tc-getLD)" AR="$(tc-getAR)" \
		OC="$(tc-getOBJCOPY)" OD="$(tc-getOBJDUMP)" \
		CFLAGS="-ffat-lto-objects" LDFLAGS="" bl31
}

src_install() {
	insinto "/usr/lib/${PN}/${PVR}"
	doins build/sun50i_h616/release/bl31.bin build/sun50i_h616/release/bl31/bl31.elf
	dodoc docs/license.rst
	# Permissive notices must accompany the compiled firmware as well as sources.
	dodoc -r licenses
	dodoc BSD-2 Apache-2.0-with-LLVM-exceptions NOTICE
	# Keep the complete notices of the actual C, assembly and header inputs.
	local dependencies=( build/sun50i_h616/release/{bl31,libc,libfdt}/*.d )
	awk '{ for (i = 1; i <= NF; i++) if ($i !~ /[:\\]$/) print $i }' \
		"${dependencies[@]}" | LC_ALL=C sort -u > "${T}/build-inputs.list" || die
	tar -cJf "${T}/build-inputs.tar.xz" -T "${T}/build-inputs.list" || die
	dodoc "${T}/build-inputs.tar.xz"
	# U-Boot copies these notices when embedding BL31.
	docompress -x "/usr/share/doc/${PF}"
}
