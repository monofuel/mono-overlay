# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

.PHONY: check check-package

check:
	bash -n sys-kernel/rg-ds-plus-rocknix-kernel/*.ebuild tests/check-package.sh
	awk -F '\t' 'NR > 1 { print $$3 "  " $$1 }' docs/upstream-files.tsv | sha256sum -c -
	git diff --check

check-package:
	bash tests/check-package.sh "$(ROOT)" "$(RELEASE)"
