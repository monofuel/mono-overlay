# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

.PHONY: check check-package check-stock-package check-rg-sp-package

check:
	for script in sys-kernel/*/*.ebuild sys-boot/*/*.ebuild sys-firmware/*/*.ebuild tests/*.sh tools/*.sh; do bash -n "$$script" || exit; done
	for inventory in docs/*upstream-files.tsv; do awk -F '\t' 'NR > 1 { print $$3 "  " $$1 }' "$$inventory" | sha256sum -c - || exit; done
	git diff --check

check-package:
	bash tests/check-package.sh "$(ROOT)" "$(RELEASE)"

check-stock-package:
	bash tests/check-stock-package.sh "$(ROOT)" "$(DEVICE)"

check-rg-sp-package:
	bash tests/check-rg-sp-package.sh "$(ROOT)"
