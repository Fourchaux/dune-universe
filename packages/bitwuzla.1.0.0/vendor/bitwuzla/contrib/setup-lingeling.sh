#!/usr/bin/env bash
###
# Bitwuzla: Satisfiability Modulo Theories (SMT) solver.
#
# This file is part of Bitwuzla.
#
# Copyright (C) 2007-2021 by the authors listed in the AUTHORS file.
#
# See COPYING for more information on using this software.
##

set -e -o pipefail

source "$(dirname "$0")/setup-utils.sh"

LINGELING_DIR="${DEPS_DIR}/lingeling"
COMMIT_ID="03b4860d14016f42213ea271014f2f13d181f504"

download_github "arminbiere/lingeling" "$COMMIT_ID" "$LINGELING_DIR"
cd "${LINGELING_DIR}"

if is_windows; then
  component="Lingeling"
  last_patch_date="20190110"
  test_apply_patch "${component}" "${last_patch_date}"
fi

./configure.sh -fPIC
make -j${NPROC}
install_lib liblgl.a
install_include lglib.h
