# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

EAPI=8

inherit toolchain-funcs

DESCRIPTION="ROCKNIX kernel and board support for the Anbernic RG DS Plus"
HOMEPAGE="https://github.com/ROCKNIX/distribution"
SRC_URI="https://www.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/linux-${PV}.tar.xz"
S="${WORKDIR}/linux-${PV}"

LICENSE="GPL-2"
SLOT="${PV}"
KEYWORDS="~arm64"
RDEPEND="sys-apps/kmod"

BDEPEND="
	app-alternatives/bc
	app-arch/lzop
	app-arch/xz-utils
	dev-lang/perl
	dev-libs/openssl
	sys-apps/kmod
	sys-devel/bison
	sys-devel/flex
	virtual/libelf
"

src_prepare() {
	local inputs="${FILESDIR}/${PV}"
	eapply "${inputs}/patches/mainline/"*.patch
	eapply "${inputs}/patches/mainline-rockchip/"*.patch
	eapply "${inputs}/patches/7.0/"*.patch
	eapply "${inputs}/patches/RK3566/"*.patch
	cp "${inputs}/panel-generic-dsi.c" drivers/gpu/drm/panel/ || die
	printf '\nobj-y += panel-generic-dsi.o\n' >> drivers/gpu/drm/panel/Makefile || die
	cp "${inputs}/dts/"* arch/arm64/boot/dts/rockchip/ || die
	printf '\ndtb-y += rk3568-anbernic-rg-ds-plus.dtb\n' >> arch/arm64/boot/dts/rockchip/Makefile || die
	eapply "${inputs}/patches/local/"*.patch
	cp "${inputs}/linux.aarch64.conf" .config || die
	eapply_user
}

src_configure() {
	# Keep artifacts separate from both the stock kernel and other revisions.
	scripts/config --set-str LOCALVERSION "-mono-rgdsplus-rocknix-${PR}" || die
	scripts/config --disable LOCALVERSION_AUTO || die
	# ROCKNIX embeds its own userspace. Gentoo boot integration is separate.
	scripts/config --set-str INITRAMFS_SOURCE "" || die
	scripts/config --set-str DEFAULT_HOSTNAME "(none)" || die
	scripts/config --set-str EXTRA_FIRMWARE "" || die
	# Reuse a firmware framebuffer for console output before native DRM starts.
	scripts/config --enable FB_SIMPLE || die
	emake ARCH=arm64 CC="$(tc-getCC)" HOSTCC="$(tc-getBUILD_CC)" olddefconfig
}

src_compile() {
	emake ARCH=arm64 CC="$(tc-getCC)" HOSTCC="$(tc-getBUILD_CC)" \
		DTC_FLAGS=-@ Image modules rockchip/rk3568-anbernic-rg-ds-plus.dtb
}

src_install() {
	local release
	release=$(<include/config/kernel.release)
	[[ ${release} == "${PV}-mono-rgdsplus-rocknix-${PR}" ]] || die "Unexpected kernel release: ${release}"

	insinto "/usr/lib/${PN}/${release}"
	doins arch/arm64/boot/Image System.map Module.symvers
	newins .config config
	doins arch/arm64/boot/dts/rockchip/rk3568-anbernic-rg-ds-plus.dtb

	emake ARCH=arm64 CC="$(tc-getCC)" HOSTCC="$(tc-getBUILD_CC)" \
		INSTALL_MOD_PATH="${D}" DEPMOD=depmod modules_install
	rm "${ED}/lib/modules/${release}/build" || die
	if [[ -L ${ED}/lib/modules/${release}/source ]]; then
		rm "${ED}/lib/modules/${release}/source" || die
	fi

	# Keep the generated headers and build tools needed by external modules.
	local build="${ED}/usr/src/linux-${release}"
	mkdir -p "${build}/arch/arm64/kernel" || die
	cp -a .config Makefile Kbuild Kconfig Module.symvers System.map \
		include scripts "${build}/" || die
	cp -a arch/arm64/Makefile arch/arm64/include "${build}/arch/arm64/" || die
	# Drop references to architecture trees and documentation not included here.
	find "${build}/scripts" -type l ! -exec test -e {} \; -delete || die
	if [[ -f arch/arm64/kernel/module.lds ]]; then
		cp -a arch/arm64/kernel/module.lds "${build}/arch/arm64/kernel/" || die
	fi
	# Absolute links work with both merged-/usr and traditional /lib layouts.
	dosym "/usr/src/linux-${release}" "/lib/modules/${release}/build"
	einstalldocs
}

pkg_postinst() {
	# Include separately packaged drivers when replacing the dependency indexes.
	depmod -b "${EROOT:-/}" "${PV}-mono-rgdsplus-rocknix-${PR}" || die
	elog "Kernel artifacts are in /usr/lib/${PN}/; modules are in /lib/modules/."
	elog "Boot integration and hardware validation are separate; /boot was not changed."
}
