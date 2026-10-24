# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

.PHONY: check check-package check-stock-package

check:
	for script in sys-kernel/*/*.ebuild tests/*.sh tools/*.sh; do bash -n "$$script" || exit; done
	awk -F '\t' 'NR > 1 { print $$3 "  " $$1 }' docs/upstream-files.tsv | sha256sum -c -
	git diff --check

check-package:
	bash tests/check-package.sh "$(ROOT)" "$(RELEASE)"

check-stock-package:
	bash tests/check-stock-package.sh "$(ROOT)" "$(DEVICE)"
