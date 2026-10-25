# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit python-any-r1 toolchain-funcs

DESCRIPTION="ROCKNIX H700 U-Boot and SPL for Anbernic RG SP LPDDR3 and LPDDR4"
HOMEPAGE="https://www.u-boot.org/"
SRC_URI="https://github.com/u-boot/u-boot/archive/v${PV}.tar.gz -> u-boot-${PV}.tar.gz"
S="${WORKDIR}/u-boot-${PV}"

LICENSE="GPL-2 BSD BSD-2 ISC Apache-2.0-with-LLVM-exceptions"
SLOT="${PV}"
KEYWORDS="~arm64"
DEPEND="=sys-boot/rg-sp-trusted-firmware-a-2.15.0-r0"
BDEPEND="
	${PYTHON_DEPS}
	$(python_gen_any_dep 'dev-python/pyelftools[${PYTHON_USEDEP}] dev-python/setuptools[${PYTHON_USEDEP}]')
	dev-lang/swig
	dev-libs/openssl
	sys-devel/bison
	sys-devel/flex
"

python_check_deps() {
	python_has_version "dev-python/pyelftools[${PYTHON_USEDEP}]" &&
		python_has_version "dev-python/setuptools[${PYTHON_USEDEP}]"
}

src_prepare() {
	eapply "${FILESDIR}/${PV}/"*.patch
	cp "${FILESDIR}/${PV}/"*defconfig configs/ || die
	eapply_user
}

uboot_make() {
	emake O="${WORKDIR}/build-${1}" ARCH=arm \
		CC="$(tc-getCC)" LD="$(tc-getLD)" AR="$(tc-getAR)" \
		NM="$(tc-getNM)" OBJCOPY="$(tc-getOBJCOPY)" OBJDUMP="$(tc-getOBJDUMP)" \
		HOSTCC="$(tc-getBUILD_CC)" HOSTCXX="$(tc-getBUILD_CXX)" HOSTSTRIP=true \
		PYTHON="${PYTHON}" PYTHON3="${PYTHON}" \
		BL31="${ESYSROOT}/usr/lib/rg-sp-trusted-firmware-a/2.15.0/bl31.bin" \
		CONFIG_MKIMAGE_DTC_PATH=scripts/dtc/dtc "${@:2}"
}

src_configure() {
	local dram
	for dram in lpddr3 lpddr4; do
		uboot_make "${dram}" "anbernic_rg35xx_h700_${dram}_defconfig"
	done
}

src_compile() {
	local dram
	for dram in lpddr3 lpddr4; do
		uboot_make "${dram}"
	done
}

src_install() {
	local dram
	for dram in lpddr3 lpddr4; do
		insinto "/usr/lib/${PN}/${PVR}/${dram}"
		doins "${WORKDIR}/build-${dram}/u-boot-sunxi-with-spl.bin"
		newins "${WORKDIR}/build-${dram}/.config" config
	done
	dodoc README
	dodoc -r Licenses
	# SPL embeds BL31, so its component notices must travel with this package.
	dodoc -r "${ESYSROOT}/usr/share/doc/rg-sp-trusted-firmware-a-2.15.0"
	docompress -x "/usr/share/doc/${PF}/rg-sp-trusted-firmware-a-2.15.0/build-inputs.tar.xz"
}
