# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Mainline-based ROCKNIX kernel and board support for the Anbernic RG SP"
HOMEPAGE="https://github.com/ROCKNIX/distribution"
SRC_URI="https://www.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/linux-${PV}.tar.xz"
S="${WORKDIR}/linux-${PV}"

LICENSE="GPL-2"
SLOT="${PV}"
KEYWORDS="~arm64"
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
	eapply "${inputs}/patches/7.2/"*.patch
	eapply "${inputs}/patches/H700/"*.patch
	cp "${inputs}/sun50i-h700-anbernic-rg-sp.dts" arch/arm64/boot/dts/allwinner/ || die
	printf '\ndtb-y += sun50i-h700-anbernic-rg-sp.dtb\n' >> arch/arm64/boot/dts/allwinner/Makefile || die
	cp "${inputs}/linux.aarch64.conf" .config || die
	eapply_user
}

src_configure() {
	scripts/config --set-str LOCALVERSION "-mono-rgsp-rocknix-${PR}" || die
	scripts/config --disable LOCALVERSION_AUTO || die
	scripts/config --set-str INITRAMFS_SOURCE "" || die
	scripts/config --set-str EXTRA_FIRMWARE "" || die
	scripts/config --set-str EXTRA_FIRMWARE_DIR "" || die
	scripts/config --set-str DEFAULT_HOSTNAME "(none)" || die
	# The first boot needs neither an initramfs nor firmware to reach wired SSH.
	local setting
	for setting in USB_NET_DRIVERS USB_USBNET USB_NET_AX88179_178A USB_RTL8152 \
		MMC MMC_BLOCK MMC_SUNXI EXT4_FS DEVTMPFS DEVTMPFS_MOUNT; do
		scripts/config --enable "${setting}" || die
	done
	for setting in CFG80211 MAC80211 RTW88 RTW88_CORE RTW88_SDIO RTW88_8821C \
		RTW88_8821CS BT DRM_PANEL_MIPI; do
		scripts/config --module "${setting}" || die
	done
	emake ARCH=arm64 CC="$(tc-getCC)" HOSTCC="$(tc-getBUILD_CC)" olddefconfig
}

src_compile() {
	emake ARCH=arm64 CC="$(tc-getCC)" HOSTCC="$(tc-getBUILD_CC)" \
		DTC_FLAGS=-@ Image modules allwinner/sun50i-h700-anbernic-rg-sp.dtb
}

src_install() {
	local release
	release=$(<include/config/kernel.release)
	[[ ${release} == "7.2.0-mono-rgsp-rocknix-${PR}" ]] || die "Unexpected kernel release: ${release}"
	insinto "/usr/lib/${PN}/${release}"
	doins arch/arm64/boot/Image System.map Module.symvers
	newins .config config
	doins arch/arm64/boot/dts/allwinner/sun50i-h700-anbernic-rg-sp.dtb
	emake ARCH=arm64 CC="$(tc-getCC)" HOSTCC="$(tc-getBUILD_CC)" \
		INSTALL_MOD_PATH="${D}" DEPMOD=depmod modules_install
	rm "${ED}/lib/modules/${release}/build" || die
	if [[ -L ${ED}/lib/modules/${release}/source ]]; then
		rm "${ED}/lib/modules/${release}/source" || die
	fi
	einstalldocs
}

pkg_postinst() {
	elog "RG SP kernel artifacts are in /usr/lib/${PN}/; matching modules are in /lib/modules/."
	elog "Boot activation and external firmware are separate; /boot was not changed."
}
