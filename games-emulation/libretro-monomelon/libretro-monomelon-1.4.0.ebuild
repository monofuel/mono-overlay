# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

EAPI=8
CMAKE_BUILD_TYPE=Release
inherit cmake flag-o-matic toolchain-funcs

DESCRIPTION="monoMelon: melonDS DS with internal-call optimization and open-workload PGO"
HOMEPAGE="https://github.com/monofuel/mono-overlay https://github.com/JesseTG/melonds-ds"
COMMIT=f394adbacb5722ee97c1b37c8064da9a25818310
SRC_URI="https://github.com/JesseTG/melonds-ds/archive/${COMMIT}.tar.gz -> libretro-melondsds-${PV}.tar.gz"
S="${WORKDIR}/melonds-ds-${COMMIT}"

# Preserve upstream's bundled dependency versions, including its melonDS branch.
# FetchContent receives only these checksummed, unpacked source directories.
MY_DEPS=(
	"MELONDS JesseTG/melonDS 16f127dbb587a73371827ce79689c5d237c4b59b"
	"LIBRETRO_COMMON libretro/libretro-common fa8a1b572a444fcb552007019f8caf68281108aa"
	"EMBED_BINARIES andoalon/embed-binaries 078b62beba97e8192c99bfb16d5e17220cfc7598"
	"GLM g-truc/glm 6f14f4792a0cde5d0cf2c910506724d61cb95834"
	"LIBSLIRP JesseTG/libslirp-mirror e61dbd459c8c06607b3a84694489427e8ec60f17"
	"PNTR robloach/pntr a47fe167703b0ac3bfad00785b20b0dce6712509"
	"FMT fmtlib/fmt 1be298e1bd68957e4cd352e1f676f00e07dcfb57"
	"YAMC yohhoy/yamc 4e015a7e8eb0d61c34e6928676c8c78881a72d73"
	"SPAN_LITE martinmoene/span-lite f63fe2974943b5f555b928b10d910e457fbb93d4"
	"DATE HowardHinnant/date 179a6b921ccd6179b5b04dce812a89f71a51b4df"
	"ZLIB madler/zlib da607da739fa6047df13e66a2af6b8bec7c2a498"
)
for dep in "${MY_DEPS[@]}"; do
	read -r name repository revision <<< "${dep}"
	SRC_URI+=" https://github.com/${repository}/archive/${revision}.tar.gz -> libretro-melondsds-${name,,}-${revision}.tar.gz"
done
unset dep name repository revision

SRC_URI+=" pgo? ( https://github.com/monofuel/mono-overlay/releases/download/monomelon-training-v1/monomelon-training-1.tar.xz )"

LICENSE="BSD BSD-1 BSD-2 GPL-2+ GPL-3+ MIT OFL-1.1 Unlicense ZLIB pgo? ( CC0-1.0 )"
SLOT="0"
KEYWORDS="~arm64"
IUSE="+jit opengl pgo"
RESTRICT="test"

BDEPEND="pgo? ( >=dev-lang/nim-2.2 )"

DEPEND="opengl? ( media-libs/libglvnd )"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/libretro-melondsds-${PV}-optional-git.patch"
	"${FILESDIR}/libretro-melondsds-${PV}-external-sources.patch"
)

monomelon_configure() {
	local dep name repository revision
	local mycmakeargs=(
		-DCMAKE_C_FLAGS="${CPPFLAGS} ${CFLAGS}"
		-DCMAKE_CXX_FLAGS="${CPPFLAGS} ${CXXFLAGS}"
		-DCMAKE_C_FLAGS_RELEASE=-DNDEBUG
		-DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON
		-DFETCHCONTENT_UPDATES_DISCONNECTED=ON
		-DBUILD_SHARED_LIBS=OFF
		-DENABLE_JIT=$(usex jit)
		-DENABLE_OPENGL=$(usex opengl)
		-DENABLE_COMPUTE_RENDERER=$(usex opengl)
		-DENABLE_THREADED_RENDERER=ON
		-DENABLE_LTO_RELEASE=OFF
		-DENABLE_LTO=OFF
		-DUSE_CCACHE=OFF
		-DTRACY_ENABLE=OFF
		-DBUILD_TESTING=OFF
	)
	for dep in "${MY_DEPS[@]}"; do
		read -r name repository revision <<< "${dep}"
		mycmakeargs+=(
			"-DFETCHCONTENT_SOURCE_DIR_${name}=${WORKDIR}/${repository##*/}-${revision}"
			"-D${name}_REPOSITORY_TAG=${revision}"
		)
		# FetchContent uppercases names but preserves upstream's hyphens.
		if [[ ${name} == *_* ]]; then
			mycmakeargs+=( "-DFETCHCONTENT_SOURCE_DIR_${name//_/-}=${WORKDIR}/${repository##*/}-${revision}" )
		fi
	done
	cmake_src_configure
}

src_configure() {
	append-flags -fno-semantic-interposition
	if use pgo; then
		tc-is-gcc || die "PGO currently requires GCC"
		append-flags "-fprofile-prefix-path=${BUILD_DIR}"
		append-flags "-fprofile-generate=${T}/pgo" -fprofile-update=atomic
	fi
	monomelon_configure
}

src_compile() {
	cmake_src_compile
	if use pgo; then
		local cpu
		case $(tc-arch) in
			arm64) cpu=arm64 ;;
			amd64) cpu=amd64 ;;
			*) die "Unsupported PGO training architecture" ;;
		esac
		local -a runner=()
		if [[ -n ${MONOMELON_PGO_RUNNER} ]]; then
			[[ -x ${MONOMELON_PGO_RUNNER} ]] || die "PGO runner is not executable"
			runner=( "${MONOMELON_PGO_RUNNER}" )
		elif tc-is-cross-compiler; then
			die "Cross PGO requires MONOMELON_PGO_RUNNER (for example, qemu-aarch64)"
		fi
		# The runner uses only Nim's standard library and never opens audio or video devices.
		nim c --skipParentCfg:on --skipProjCfg:on -d:release --opt:speed \
			--os:linux --cpu:"${cpu}" --cc:gcc \
			--gcc.exe:"$(tc-getCC)" --gcc.linkerexe:"$(tc-getCC)" \
			--${cpu}.linux.gcc.exe:"$(tc-getCC)" --${cpu}.linux.gcc.linkerexe:"$(tc-getCC)" \
			--passC:"-I${WORKDIR}/libretro-common-fa8a1b572a444fcb552007019f8caf68281108aa/include" \
			-o:"${T}/monomelon-train" "${FILESDIR}/train.nim" || die "Cannot build PGO runner"
		local rom name
		for rom in "${WORKDIR}"/monomelon-training-1/roms/*.nds; do
			name=${rom##*/}
			"${runner[@]}" "${T}/monomelon-train" \
				"${BUILD_DIR}/src/libretro/melondsds_libretro.so" "${rom}" \
				"${T}/training-${name}" 360 || die "PGO training failed: ${name}"
		done
		local -a profiles=( "${T}"/pgo/*GPU3D_Soft.cpp.gcda )
		[[ ${#profiles[@]} == 1 && -s ${profiles[0]} ]] || die "No software-renderer PGO profile"
		filter-flags '-fprofile-generate=*' -fprofile-update=atomic
		append-flags "-fprofile-use=${T}/pgo" -fprofile-partial-training -Werror=coverage-mismatch
		monomelon_configure
		cmake_src_compile
		local symbols
		symbols=$("$(tc-getNM)" --defined-only "${BUILD_DIR}/src/libretro/melondsds_libretro.so") || die
		[[ ${symbols} != *__gcov_* ]] || die "Final core still contains profiling instrumentation"
	fi
}

src_install() {
	docompress -x "/usr/share/doc/${PF}/licenses/libretro-common-source.tar.gz"
	insinto "/usr/$(get_libdir)/libretro"
	newins "${BUILD_DIR}/src/libretro/melondsds_libretro.so" monomelon_libretro.so
	insinto /usr/share/libretro/info
	sed 's/melonDS DS/monoMelon/g' "${BUILD_DIR}/melondsds_libretro.info" > "${T}/monomelon_libretro.info" || die
	doins "${T}/monomelon_libretro.info"
	dodoc README.md CHANGELOG.md "${BUILD_DIR}/melondsds-LICENSE.txt"
	printf '%s\n' "melonds-ds JesseTG/melonds-ds ${COMMIT}" "${MY_DEPS[@]}" > "${T}/SOURCES.txt" || die
	dodoc "${T}/SOURCES.txt"

	# Keep bundled notices alongside upstream's generated combined attribution.
	if use pgo; then
		docinto training
		dodoc "${WORKDIR}/monomelon-training-1/BUILD.txt" "${WORKDIR}/monomelon-training-1/SDK-PACKAGES.txt"
		dodoc -r "${WORKDIR}/monomelon-training-1/licenses"
	fi

	docinto licenses
	local dep name repository revision source notice
	for dep in "${MY_DEPS[@]}"; do
		read -r name repository revision <<< "${dep}"
		source="${WORKDIR}/${repository##*/}-${revision}"
		for notice in LICENSE LICENSE.txt LICENSE.md COPYING COPYING.txt COPYRIGHT copying.txt; do
			if [[ -f ${source}/${notice} ]]; then
				newdoc "${source}/${notice}" "${name}-${notice}"
			fi
		done
		# libretro-common keeps its notices per file, without a central license.
		if [[ ${name} == LIBRETRO_COMMON ]]; then
			newdoc "${DISTDIR}/libretro-melondsds-${name,,}-${revision}.tar.gz" libretro-common-source.tar.gz
		fi
	done
}
