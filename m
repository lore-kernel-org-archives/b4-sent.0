From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 25 Sep 2026 12:09:43 -0700
Subject: [PATCH v3 6/6] perf test: Test lazy symbol loading and symbol
 memory limits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-perf-symbol-memory-send-v3-6-3e4e234c363b@uber.com>
References: <20260925-perf-symbol-memory-send-v3-0-3e4e234c363b@uber.com>
In-Reply-To: <20260925-perf-symbol-memory-send-v3-0-3e4e234c363b@uber.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Alexei Starovoitov <ast@kernel.org>, 
 Andrii Nakryiko <andriin@fb.com>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=29667; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=ub9sV1S3/GfdrmBsPpJG3/8wswdAu70FqyVJD6pDjtY=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqtshES/8TfyfNId/N7+HDGjQiVvem2UbePgpwI
 8EtzLH9BSKJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCarbIRBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtgDcg//f8fJCFccToTW3CAia7fCiFIKmg0RAzm
 DOS41UlK4SDmpXlgMig17iTLm5mwKBdxUjs5izB1DfAaJiuNcixZe+Mcf15RnXkqegofwEhVZ4g
 RYcbQJOfosVBxEzzhYi+XA0e+Ga3kvMop/5o2HQa9DrG2etWe0dEf23Bvxezorwc8VjJeNIk0Xs
 VxW/kCS1slic9hTGo6R/EFOkq0WrR1227YRO75UrXSdkE+UtST3YNd25Hq9gZyAHJsKr1JALgxr
 fDDmkOZ0b4a+ubjHbRITk9PjawAuiAtxysL7HxfSLVMhmrb7/82PtB6Xr09TvudRnPcrFnXNWQk
 pBbrqEAU2LK7jYDT4IZe2stTxYEODaoLQFAyZiFXrVgzVQA0LMdf+Qpb0Vd9892Z73dD5PDO2kc
 Ifx3/W3NqIwvtMgfRwc4wYm9+6sfy0/sd7wC86SIrZYP8n3FhTtrR1X5MDyNgGFGvLn2cEaTgPj
 POzfKr/FL13mSEOrj/Q8GQfbafuavoJsocRKX2zuQZtpF3by5t90ab0qvXfeljjXmqBxbdNdfut
 1U5bZSSj1iOiqQ6gpL1duvkjVjMpo9Pvf5tcpDTw9KyJQ9IpndjlmFKfAv5OqrJyi3zXIvPZziu
 AsPUuqrPjMLht+1VpPwKdw1F2Qa3XYDWoOOAT+YpAoWw0ghGMa0E=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a perf script shell test for --lazy-load-symbols and
--max-symbol-bytes.

Record a small callchain fixture, require evidence that the controlled
perf DSO built an on-demand index, and compare only extracted occurrences
of the controlled test_loop symbol. This avoids coupling the test to
addresses, diagnostics, or architecture-specific symbols for which the
eager and lazy loaders have documented differences.

Derive the constrained lazy budget from the unlimited run's
index-reservation peak. This gives a deterministic boundary where the
index fits and later materialization reaches the limit. Also verify eager
limiting, malformed size rejection, and one-time warning behavior.

Report unsupported recording, missing controlled output, unavailable
libelf, and unavailable dependent data as skips without replacing a prior
failure. Keep helper returns safe under set -e, and cover skip-status
preservation separately.

Add unit tests for the shared duplicate-selection policy, truncated
string-table reads, lazy address and name lookup across a closed data
descriptor, and address lookups racing name lookups while the symbol
budget truncates materialization. The last test also checks that a DSO
does not change once its name-sorted array has been built.

Add a unit test that loads a DSO (perf itself, or the one given with
--dso) eagerly and lazily and compares every symbol address and name.
Run it from a shell test on a hand-built split-debuginfo binary whose
function section is NOBITS in the debug file and has no PT_LOAD in the
runtime file, so both loaders must fall back to the runtime section
header.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 .../tests/shell/lazy_load_symbols_split_debug.sh   | 113 +++++
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 278 ++++++++++++
 .../tests/shell/script_lazy_load_symbols_skip.sh   |  26 ++
 tools/perf/tests/symbol-bytes.c                    | 505 +++++++++++++++++++++
 4 files changed, 922 insertions(+)

diff --git a/tools/perf/tests/shell/lazy_load_symbols_split_debug.sh b/tools/perf/tests/shell/lazy_load_symbols_split_debug.sh
new file mode 100755
index 000000000000..4e6335d88377
--- /dev/null
+++ b/tools/perf/tests/shell/lazy_load_symbols_split_debug.sh
@@ -0,0 +1,113 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# lazy symbol loading with split debuginfo
+
+# Build a stripped binary whose symbols live in a --only-keep-debug file,
+# where a function's section is NOBITS (with a different sh_offset) and has
+# no PT_LOAD in the runtime ELF. Lazy and eager loading must then both fall
+# back to the runtime section header and agree on the symbol addresses.
+
+set -e
+
+err=0
+tmpdir=$(mktemp -d /tmp/__perf_test.lazy_split_debug.XXXXX)
+
+cleanup() {
+	rm -rf "${tmpdir}"
+	trap - EXIT TERM INT
+}
+
+trap_cleanup() {
+	echo "Unexpected signal in ${FUNCNAME[1]}"
+	cleanup
+	exit 1
+}
+trap trap_cleanup EXIT TERM INT
+
+skip() {
+	echo "Lazy-load split debuginfo [Skipped: $1]"
+	cleanup
+	exit 2
+}
+
+if ! perf check feature -q libelf; then
+	skip "no libelf support"
+fi
+
+for tool in cc objcopy strip readelf dd; do
+	if ! command -v "${tool}" > /dev/null; then
+		skip "${tool} not found"
+	fi
+done
+
+cat > "${tmpdir}/prog.c" << EOF
+__attribute__((section("splittext"), noinline, used))
+int split_func(int x)
+{
+	return x * 3 + 1;
+}
+
+int main(int argc, char **argv)
+{
+	(void)argv;
+	return split_func(argc);
+}
+EOF
+
+prog="${tmpdir}/prog"
+if ! cc -O1 -g -o "${prog}" "${tmpdir}/prog.c" \
+	-Wl,--section-start=splittext=0x800000 2> /dev/null; then
+	skip "cannot build test program"
+fi
+objcopy --only-keep-debug "${prog}" "${prog}.debug"
+strip -s "${prog}"
+objcopy --add-gnu-debuglink="${prog}.debug" "${prog}"
+
+# The debug file must keep splittext as NOBITS at a stale offset.
+debug_sec=$(readelf -SW "${prog}.debug" | grep ' splittext ' || true)
+run_sec=$(readelf -SW "${prog}" | grep ' splittext ' || true)
+if ! echo "${debug_sec}" | grep -q NOBITS; then
+	skip "splittext is not NOBITS in the debug file"
+fi
+debug_off=$(echo "${debug_sec}" | sed 's/.*splittext *//' | awk '{print $3}')
+run_off=$(echo "${run_sec}" | sed 's/.*splittext *//' | awk '{print $3}')
+if [ -z "${run_off}" ] || [ "${debug_off}" = "${run_off}" ]; then
+	skip "splittext offsets do not differ"
+fi
+
+# Drop the PT_LOAD covering splittext so program header lookup fails.
+phoff=$(readelf -hW "${prog}" | awk '/Start of program headers/ {print $5}')
+phentsize=$(readelf -hW "${prog}" | awk '/Size of program headers/ {print $5}')
+idx=$(readelf -lW "${prog}" | awk '
+	/^Program Headers:/ { in_ph = 1; next }
+	in_ph && /^  Type/ { next }
+	in_ph && /^ *$/ { exit }
+	in_ph && /^  [A-Z]/ {
+		if ($1 == "LOAD" && $3 ~ /^0x0*800000$/) { print n; exit }
+		n++
+	}')
+if [ -z "${phoff}" ] || [ -z "${phentsize}" ] || [ -z "${idx}" ]; then
+	skip "no PT_LOAD for splittext"
+fi
+dd if=/dev/zero of="${prog}" bs=1 seek=$((phoff + idx * phentsize)) count=4 \
+	conv=notrunc 2> /dev/null
+if readelf -lW "${prog}" 2> /dev/null | grep -q 'LOAD .*0x0*800000 '; then
+	echo "Lazy-load split debuginfo [Failed to drop PT_LOAD]"
+	err=1
+fi
+
+if [ "${err}" -eq 0 ]; then
+	export PERF_BUILDID_DIR="${tmpdir}/buildid"
+	if ! perf test --dso "${prog}" "Lazy and eager symbol parity" 2>&1 | \
+		grep -q ': Ok$'; then
+		perf test --dso "${prog}" -vv "Lazy and eager symbol parity" 2>&1 | \
+			grep -E 'symbols$|mismatch|no symbols|no lazy' || true
+		echo "Lazy-load split debuginfo [Failed parity]"
+		err=1
+	else
+		echo "Lazy-load split debuginfo [Success]"
+	fi
+fi
+
+cleanup
+exit ${err}
diff --git a/tools/perf/tests/shell/script_lazy_load_symbols.sh b/tools/perf/tests/shell/script_lazy_load_symbols.sh
new file mode 100755
index 000000000000..7e193c1c3d1f
--- /dev/null
+++ b/tools/perf/tests/shell/script_lazy_load_symbols.sh
@@ -0,0 +1,278 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# perf script lazy symbol loading tests (exclusive)
+#
+# Verifies that --lazy-load-symbols matches the default eager loader for a
+# controlled symbol, and that --max-symbol-bytes caps symbol allocations
+# (emitting [unknown] plus a warning) without crashing.
+
+mark_skip() {
+	if [ "${err}" -eq 0 ]; then
+		err=2
+	fi
+	return 0
+}
+
+if [ "${PERF_LAZY_LOAD_SYMBOLS_TEST_HELPERS:-}" = 1 ]; then
+	return 0
+fi
+
+set -e
+
+shelldir=$(dirname "$0")
+# shellcheck source=lib/perf_has_symbol.sh
+. "${shelldir}"/lib/perf_has_symbol.sh
+
+testsym="test_loop"
+perf_path=$(readlink -f "$(command -v perf)")
+lazy_index_budget=
+
+skip_test_missing_symbol ${testsym}
+
+if ! perf check feature -q libelf
+then
+	echo "Lazy symbol loading [Skipped no libelf support]"
+	exit 2
+fi
+
+err=0
+temp_dir=$(mktemp -d /tmp/__perf_test.lazy_load.XXXXX)
+perfdata="${temp_dir}/perf.data"
+eager_out="${temp_dir}/eager.out"
+lazy_out="${temp_dir}/lazy.out"
+lazy_err="${temp_dir}/lazy.err"
+eager_sym_out="${temp_dir}/eager.sym.out"
+lazy_sym_out="${temp_dir}/lazy.sym.out"
+
+cleanup() {
+	rm -rf "${temp_dir}"
+	trap - EXIT TERM INT
+}
+
+trap_cleanup() {
+	echo "Unexpected signal in ${FUNCNAME[1]}"
+	cleanup
+	exit 1
+}
+trap trap_cleanup EXIT TERM INT
+
+test_lazy_load_identical() {
+	echo "Lazy-load output matches eager loader"
+
+	# Record a small profile with callchains so symbol resolution runs.
+	if ! perf record -o "${perfdata}" -g -- perf test -w thloop 2> /dev/null
+	then
+		echo "Lazy-load identical [Skipped record not supported]"
+		mark_skip
+		return 0
+	fi
+
+	if ! perf script -i "${perfdata}" 2> /dev/null > "${eager_out}" || \
+	   ! perf script -v --lazy-load-symbols -i "${perfdata}" \
+		2> "${lazy_err}" > "${lazy_out}"
+	then
+		echo "Lazy-load identical [Failed perf script error]"
+		err=1
+		return
+	fi
+	if ! grep -q "on-demand index:" "${lazy_err}"
+	then
+		echo "Lazy-load identical [Failed lazy loader fell back to eager]"
+		err=1
+		return
+	fi
+	lazy_index_budget=$(awk -v dso="${perf_path}: on-demand index:" \
+		'index($0, dso) { sub(/^.* budget=/, ""); print; exit }' \
+		"${lazy_err}")
+	case "${lazy_index_budget}" in
+	''|*[!0-9]*)
+		echo "Lazy-load identical [Failed controlled DSO has no index]"
+		err=1
+		return
+		;;
+	esac
+
+	# The comparison is only meaningful if something actually resolved;
+	# two all-[unknown] outputs would also match.
+	if ! grep -q "${testsym}" "${eager_out}"
+	then
+		echo "Lazy-load identical [Skipped no ${testsym} resolved]"
+		mark_skip
+		return 0
+	fi
+
+	grep -w -o "${testsym}" "${eager_out}" > "${eager_sym_out}"
+	if ! grep -w -o "${testsym}" "${lazy_out}" > "${lazy_sym_out}"
+	then
+		echo "Lazy-load identical [Failed no lazy ${testsym} resolved]"
+		err=1
+		return
+	fi
+
+	if ! cmp -s "${eager_sym_out}" "${lazy_sym_out}"
+	then
+		echo "Lazy-load identical [Failed ${testsym} output differs]"
+		err=1
+		return
+	fi
+	echo "Lazy-load identical [Success]"
+}
+
+test_max_symbol_bytes() {
+	echo "--max-symbol-bytes budget enforcement"
+
+	# Depends on ${perfdata} from test_lazy_load_identical.
+	if [ ! -s "${perfdata}" ]
+	then
+		echo "--max-symbol-bytes budget [Skipped record not supported]"
+		mark_skip
+		return 0
+	fi
+
+	# A tiny budget forces most symbols to be dropped as [unknown],
+	# with a single warning, and must not crash.
+	if ! perf script --max-symbol-bytes=1K -i "${perfdata}" > /dev/null \
+		2> "${temp_dir}/budget.err"
+	then
+		echo "--max-symbol-bytes budget [Failed nonzero exit]"
+		err=1
+		return
+	fi
+	if ! grep -q "symbol memory budget exceeded" "${temp_dir}/budget.err"
+	then
+		echo "--max-symbol-bytes budget [Failed missing warning]"
+		err=1
+		return
+	fi
+	if perf script --max-symbol-bytes=1Kjunk -i "${perfdata}" \
+		> /dev/null 2>&1
+	then
+		echo "--max-symbol-bytes budget [Failed malformed size accepted]"
+		err=1
+		return
+	fi
+	if ! perf script --max-symbol-bytes=0 -i "${perfdata}" \
+		> /dev/null 2>&1
+	then
+		echo "--max-symbol-bytes budget [Failed zero not accepted]"
+		err=1
+		return
+	fi
+
+	# The unlimited run logged the peak accounted bytes at the controlled
+	# DSO's index reservation, before alias dedup may have released bytes.
+	# Reuse that peak as the budget: deterministic index construction fits,
+	# while subsequent materialization must hit the limit.
+	if ! perf script -v --lazy-load-symbols \
+		--max-symbol-bytes="${lazy_index_budget}B" \
+		-i "${perfdata}" > /dev/null 2> "${temp_dir}/lazy-budget.err"
+	then
+		echo "--max-symbol-bytes lazy budget [Failed nonzero exit]"
+		err=1
+		return
+	fi
+	if ! grep -Fq "${perf_path}: on-demand index:" \
+		"${temp_dir}/lazy-budget.err" ||
+	   ! grep -q "symbol memory budget exceeded" "${temp_dir}/lazy-budget.err"
+	then
+		echo "--max-symbol-bytes lazy budget [Failed no indexed budget case]"
+		err=1
+		return
+	fi
+	warnings=$(grep -c "symbol memory budget exceeded" \
+		"${temp_dir}/lazy-budget.err" || true)
+	if [ "${warnings}" -ne 1 ]
+	then
+		echo "--max-symbol-bytes lazy budget [Failed warning count: ${warnings}]"
+		err=1
+		return
+	fi
+	echo "--max-symbol-bytes budget [Success]"
+}
+
+test_budget_truncation_range() {
+	local longsym
+	local first_symbol
+	local trunc_source="${temp_dir}/truncation.S"
+	local trunc_binary="${temp_dir}/truncation"
+	local trunc_data="${temp_dir}/truncation.data"
+	local trunc_out="${temp_dir}/truncation.out"
+	local trunc_err="${temp_dir}/truncation.err"
+
+	echo "--max-symbol-bytes truncation range"
+
+	if [ "$(uname -m)" != x86_64 ]; then
+		echo "--max-symbol-bytes truncation range [Skipped x86_64 only]"
+		mark_skip
+		return 0
+	fi
+
+	longsym=$(printf 's%.0s' {1..900})
+	cat > "${trunc_source}" <<EOF
+	.text
+	.globl ${longsym}
+	.type ${longsym}, @function
+${longsym}:
+	call omitted_symbol
+	mov \$60, %eax
+	xor %edi, %edi
+	syscall
+
+	.globl omitted_symbol
+	.type omitted_symbol, @function
+omitted_symbol:
+	mov \$500000000, %ecx
+1:
+	dec %ecx
+	jnz 1b
+	ret
+	.size omitted_symbol, .-omitted_symbol
+EOF
+	if ! cc -nostdlib -no-pie -Wl,--build-id=none -Wl,-e,"${longsym}" \
+		-o "${trunc_binary}" "${trunc_source}"
+	then
+		echo "--max-symbol-bytes truncation range [Skipped compiler unsupported]"
+		mark_skip
+		return 0
+	fi
+
+	first_symbol=$(readelf -W -s "${trunc_binary}" |
+		awk '$4 == "FUNC" && $7 != "UND" { print $8; exit }')
+	if [ "${first_symbol}" != "${longsym}" ]; then
+		echo "--max-symbol-bytes truncation range [Skipped unexpected symbol order]"
+		mark_skip
+		return 0
+	fi
+
+	if ! perf record -o "${trunc_data}" -e cycles:u -F 1000 -- \
+		"${trunc_binary}" 2> /dev/null
+	then
+		echo "--max-symbol-bytes truncation range [Skipped record not supported]"
+		mark_skip
+		return 0
+	fi
+	if ! perf script --max-symbol-bytes=1K -i "${trunc_data}" -F ip,sym,dso \
+		> "${trunc_out}" 2> "${trunc_err}"
+	then
+		echo "--max-symbol-bytes truncation range [Failed perf script error]"
+		err=1
+		return
+	fi
+
+	if ! grep -q "symbol memory budget exceeded" "${trunc_err}" ||
+	   ! grep -F "${trunc_binary}" "${trunc_out}" | grep -q '\[unknown\]' ||
+	   grep -Fq "${longsym}" "${trunc_out}"
+	then
+		echo "--max-symbol-bytes truncation range [Failed omitted range resolved]"
+		err=1
+		return
+	fi
+	echo "--max-symbol-bytes truncation range [Success]"
+}
+
+test_lazy_load_identical
+test_max_symbol_bytes
+test_budget_truncation_range
+
+cleanup
+exit $err
diff --git a/tools/perf/tests/shell/script_lazy_load_symbols_skip.sh b/tools/perf/tests/shell/script_lazy_load_symbols_skip.sh
new file mode 100755
index 000000000000..136503863fdd
--- /dev/null
+++ b/tools/perf/tests/shell/script_lazy_load_symbols_skip.sh
@@ -0,0 +1,26 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# perf script lazy symbol loading skip status
+
+set -e
+
+shelldir=$(dirname "$0")
+PERF_LAZY_LOAD_SYMBOLS_TEST_HELPERS=1
+. "${shelldir}"/script_lazy_load_symbols.sh
+unset PERF_LAZY_LOAD_SYMBOLS_TEST_HELPERS
+
+err=0
+mark_skip
+if [ "${err}" -ne 2 ]; then
+	echo "Lazy-load skip status [Failed expected 2, got ${err}]"
+	exit 1
+fi
+
+err=1
+mark_skip
+if [ "${err}" -ne 1 ]; then
+	echo "Lazy-load skip status [Failed skip overwrote failure: ${err}]"
+	exit 1
+fi
+
+echo "Lazy-load skip status [Success]"
diff --git a/tools/perf/tests/symbol-bytes.c b/tools/perf/tests/symbol-bytes.c
index d3055f5ed321..eef14e6e573b 100644
--- a/tools/perf/tests/symbol-bytes.c
+++ b/tools/perf/tests/symbol-bytes.c
@@ -1,12 +1,27 @@
 // SPDX-License-Identifier: GPL-2.0
+#include <fcntl.h>
+#include <inttypes.h>
 #include <limits.h>
 #include <pthread.h>
 #include <stdint.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <sys/mman.h>
+#include <unistd.h>
+#include <linux/kernel.h>
+#include <linux/zalloc.h>
 
 #include "debug.h"
+#include "dso.h"
+#include "env.h"
+#include "machine.h"
+#include "map.h"
 #include "symbol.h"
 #include "symbol_conf.h"
 #include "tests.h"
+#include "thread.h"
+#include "util.h"
 
 struct reserve_arg {
 	size_t bytes;
@@ -83,8 +98,498 @@ static int test__symbol_bytes_reservation(struct test_suite *test __maybe_unused
 	return ret;
 }
 
+static int test__symbol_bytes_duplicate_selection(struct test_suite *test __maybe_unused,
+						  int subtest __maybe_unused)
+{
+	struct duplicate_case {
+		struct symbol_candidate a, b;
+		int expected;
+	} cases[] = {
+		{ { 1, "a", STT_FUNC, STB_GLOBAL }, { 0, "b", STT_FUNC, STB_GLOBAL }, SYMBOL_A },
+		{ { 1, "a", STT_NOTYPE, STB_GLOBAL }, { 1, "b", STT_FUNC, STB_GLOBAL }, SYMBOL_B },
+		{ { 1, "a", STT_FUNC, STB_WEAK }, { 1, "b", STT_FUNC, STB_GLOBAL }, SYMBOL_B },
+		{ { 1, "a", STT_FUNC, STB_GLOBAL }, { 1, "b", STT_FUNC, STB_LOCAL }, SYMBOL_A },
+		{ { 1, "name", STT_FUNC, STB_GLOBAL },
+		  { 1, "_name", STT_FUNC, STB_GLOBAL }, SYMBOL_A },
+		{ { 1, "a", STT_FUNC, STB_GLOBAL }, { 1, "long", STT_FUNC, STB_GLOBAL }, SYMBOL_B },
+	};
+	size_t i;
+
+	for (i = 0; i < ARRAY_SIZE(cases); i++) {
+		if (symbol__choose_best(&cases[i].a, &cases[i].b) != cases[i].expected)
+			return TEST_FAIL;
+	}
+	return TEST_OK;
+}
+
+#ifdef HAVE_LIBELF_SUPPORT
+static int truncated_name_case(size_t file_size, unsigned int expected_reads)
+{
+	char path[] = "/tmp/perf-lazy-truncated-XXXXXX";
+	struct dso *data_dso = NULL;
+	char *contents = NULL;
+	char *name_heap = NULL;
+	char namebuf[1024];
+	const char *name;
+	unsigned int nr_reads;
+	int ret = TEST_FAIL;
+	int fd = -1;
+
+	contents = malloc(file_size);
+	if (!contents)
+		goto out;
+	memset(contents, 'a', file_size);
+
+	fd = mkstemp(path);
+	if (fd < 0 || write(fd, contents, file_size) != (ssize_t)file_size)
+		goto out;
+	close(fd);
+	fd = -1;
+
+	data_dso = dso__new(path);
+	if (!data_dso || dso__data_set_path(data_dso, path) < 0)
+		goto out;
+	dso__set_binary_type(data_dso, DSO_BINARY_TYPE__SYSTEM_PATH_DSO);
+	name = dso__read_ondemand_symbol_name(data_dso, 0, 8192, 0,
+					      namebuf, sizeof(namebuf),
+					      &name_heap, &nr_reads);
+	if (name || name_heap || nr_reads != expected_reads)
+		goto out;
+	ret = TEST_OK;
+out:
+	if (fd >= 0)
+		close(fd);
+	if (data_dso)
+		dso__put(data_dso);
+	unlink(path);
+	free(name_heap);
+	free(contents);
+	return ret;
+}
+
+static int test__symbol_bytes_truncated_name(struct test_suite *test __maybe_unused,
+					     int subtest __maybe_unused)
+{
+	/*
+	 * One byte is short in the stack-buffer read.  1023 bytes fills it
+	 * exactly, so the following read exercises the heap-buffer path.
+	 */
+	if (truncated_name_case(1, 1) != TEST_OK ||
+	    truncated_name_case(1023, 2) != TEST_OK)
+		return TEST_FAIL;
+	return TEST_OK;
+}
+
+#define LAZY_SYM_START	0x1000
+#define LAZY_SYM_SIZE	0x10
+#define LAZY_NAME_FMT	"lazy_sym_%03u"
+#define LAZY_NAME_LEN	sizeof("lazy_sym_000")
+
+static void lazy_name(char *buf, u32 i)
+{
+	snprintf(buf, LAZY_NAME_LEN, LAZY_NAME_FMT, i % 1000);
+}
+
+struct lazy_fixture {
+	char		path[32];
+	struct dso	*dso;
+	struct map	*map;
+	u32		nr;
+};
+
+/*
+ * Build a DSO whose symbols exist only in a lazy index: @nr adjacent
+ * functions named lazy_sym_NNN, with names in a string-table file read
+ * through a private data DSO.
+ */
+static int lazy_fixture__init(struct lazy_fixture *f, u32 nr)
+{
+	struct dso_ondemand *od = NULL;
+	char *strtab;
+	int fd, ret = -1;
+	u32 i;
+
+	memset(f, 0, sizeof(*f));
+	f->nr = nr;
+	strcpy(f->path, "/tmp/perf-lazy-names-XXXXXX");
+
+	strtab = malloc(nr * LAZY_NAME_LEN);
+	if (!strtab)
+		return -1;
+	for (i = 0; i < nr; i++)
+		lazy_name(strtab + i * LAZY_NAME_LEN, i);
+
+	fd = mkstemp(f->path);
+	if (fd < 0) {
+		f->path[0] = '\0';
+		goto out;
+	}
+	if (write(fd, strtab, nr * LAZY_NAME_LEN) != (ssize_t)(nr * LAZY_NAME_LEN)) {
+		close(fd);
+		goto out;
+	}
+	close(fd);
+
+	f->dso = dso__new("/not/the/symbol/source");
+	od = zalloc(sizeof(*od));
+	if (!f->dso || !od)
+		goto out;
+	od->sorted = calloc(nr, sizeof(*od->sorted));
+	od->data_dso = dso__new(f->path);
+	if (!od->sorted || !od->data_dso ||
+	    dso__data_set_path(od->data_dso, f->path) < 0)
+		goto out;
+	dso__set_binary_type(od->data_dso, DSO_BINARY_TYPE__SYSTEM_PATH_DSO);
+	od->strtab_size = nr * LAZY_NAME_LEN;
+	od->nr_sorted = nr;
+	od->nr_alloc = nr;
+	for (i = 0; i < nr; i++) {
+		od->sorted[i] = (struct sym_idx) {
+			.start = LAZY_SYM_START + i * LAZY_SYM_SIZE,
+			.end = LAZY_SYM_START + (i + 1) * LAZY_SYM_SIZE,
+			.name_off = i * LAZY_NAME_LEN,
+			.binding = STB_GLOBAL,
+			.type = STT_FUNC,
+		};
+	}
+	if (!symbol__try_account_bytes(od->nr_alloc * sizeof(*od->sorted)))
+		goto out;
+	dso__set_ondemand(f->dso, od);
+	od = NULL;
+	dso__set_loaded(f->dso);
+	f->map = map__new2(0, f->dso);
+	if (f->map)
+		ret = 0;
+out:
+	if (od) {
+		if (od->data_dso)
+			dso__put(od->data_dso);
+		free(od->sorted);
+		free(od);
+	}
+	free(strtab);
+	return ret;
+}
+
+static void lazy_fixture__exit(struct lazy_fixture *f)
+{
+	map__put(f->map);
+	dso__put(f->dso);
+	if (f->path[0])
+		unlink(f->path);
+}
+
+static bool lazy_symbol_ok(const struct symbol *sym, u32 i)
+{
+	char name[LAZY_NAME_LEN];
+
+	lazy_name(name, i);
+	return sym->start == LAZY_SYM_START + i * LAZY_SYM_SIZE && !strcmp(sym->name, name);
+}
+
+static int lazy_nr_symbols(struct dso *dso)
+{
+	struct rb_node *node;
+	int nr = 0;
+
+	for (node = rb_first_cached(dso__symbols(dso)); node; node = rb_next(node))
+		nr++;
+	return nr;
+}
+
+static int test__symbol_bytes_lazy_name_lookup(struct test_suite *test __maybe_unused,
+					       int subtest __maybe_unused)
+{
+	unsigned long saved_max = symbol_conf.max_symbol_bytes;
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	size_t baseline = symbol__bytes_used();
+	struct lazy_fixture f;
+	struct symbol *sym;
+	int ret = TEST_FAIL;
+
+	symbol_conf.max_symbol_bytes = 0;
+	symbol_conf.lazy_load_symbols = true;
+	if (lazy_fixture__init(&f, 2))
+		goto out;
+
+	sym = map__find_symbol(f.map, LAZY_SYM_START + 1);
+	if (!sym || !lazy_symbol_ok(sym, 0))
+		goto out;
+
+	/* Name lookup must still work after the data descriptor is closed. */
+	dso__data_close(dso__ondemand(f.dso)->data_dso);
+	sym = map__find_symbol_by_name(f.map, "lazy_sym_001");
+	if (!sym || !lazy_symbol_ok(sym, 1) || dso__ondemand(f.dso))
+		goto out;
+	if (lazy_nr_symbols(f.dso) != 2)
+		goto out;
+	ret = TEST_OK;
+out:
+	lazy_fixture__exit(&f);
+	symbol_conf.max_symbol_bytes = saved_max;
+	symbol_conf.lazy_load_symbols = saved_lazy;
+	if (symbol__bytes_used() != baseline)
+		ret = TEST_FAIL;
+	return ret;
+}
+
+struct lazy_lookup_arg {
+	struct lazy_fixture	*f;
+	bool			by_name;
+	bool			failed;
+};
+
+static void *lazy_lookup(void *data)
+{
+	struct lazy_lookup_arg *arg = data;
+	struct lazy_fixture *f = arg->f;
+	u32 i, round;
+
+	for (round = 0; round < 16; round++) {
+		for (i = 0; i < f->nr; i++) {
+			struct symbol *sym;
+
+			if (arg->by_name) {
+				char name[LAZY_NAME_LEN];
+
+				lazy_name(name, i);
+				sym = map__find_symbol_by_name(f->map, name);
+			} else {
+				sym = map__find_symbol(f->map, LAZY_SYM_START +
+						       i * LAZY_SYM_SIZE + 1);
+			}
+			if (sym && !lazy_symbol_ok(sym, i))
+				arg->failed = true;
+		}
+	}
+	return NULL;
+}
+
+/*
+ * Address lookups race with name lookups while the symbol budget stops
+ * materialization part way. Once a name lookup has run, the DSO must no
+ * longer grow, even after budget becomes available again.
+ */
+static int test__symbol_bytes_lazy_budget_race(struct test_suite *test __maybe_unused,
+					       int subtest __maybe_unused)
+{
+	enum { NR_SYMS = 256, NR_ADDR_THREADS = 4, NR_THREADS = NR_ADDR_THREADS + 2 };
+	unsigned long saved_max = symbol_conf.max_symbol_bytes;
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	size_t baseline = symbol__bytes_used();
+	size_t charge = symbol_conf.priv_size + sizeof(struct symbol) + LAZY_NAME_LEN;
+	struct lazy_lookup_arg args[NR_THREADS];
+	pthread_t threads[NR_THREADS];
+	struct lazy_fixture f;
+	int created = 0, nr_symbols, i;
+	int ret = TEST_FAIL;
+
+	symbol_conf.max_symbol_bytes = 0;
+	symbol_conf.lazy_load_symbols = true;
+	if (lazy_fixture__init(&f, NR_SYMS))
+		goto out;
+	symbol_conf.max_symbol_bytes = symbol__bytes_used() + NR_SYMS / 4 * charge;
+
+	for (i = 0; i < NR_THREADS; i++) {
+		args[i] = (struct lazy_lookup_arg) {
+			.f = &f,
+			.by_name = i >= NR_ADDR_THREADS,
+		};
+		if (pthread_create(&threads[i], NULL, lazy_lookup, &args[i]))
+			break;
+		created++;
+	}
+	for (i = 0; i < created; i++)
+		pthread_join(threads[i], NULL);
+	if (created != NR_THREADS)
+		goto out;
+	for (i = 0; i < NR_THREADS; i++) {
+		if (args[i].failed) {
+			pr_debug("lazy lookup returned a wrong symbol\n");
+			goto out;
+		}
+	}
+
+	nr_symbols = lazy_nr_symbols(f.dso);
+	if (dso__ondemand(f.dso) || nr_symbols == 0 || nr_symbols > NR_SYMS / 4) {
+		pr_debug("unexpected lazy state: index %p, %d symbols\n",
+			 dso__ondemand(f.dso), nr_symbols);
+		goto out;
+	}
+
+	symbol_conf.max_symbol_bytes = 0;
+	for (i = 0; i < NR_SYMS; i++)
+		map__find_symbol(f.map, LAZY_SYM_START + i * LAZY_SYM_SIZE + 1);
+	if (lazy_nr_symbols(f.dso) != nr_symbols) {
+		pr_debug("DSO changed after its name array was built\n");
+		goto out;
+	}
+	ret = TEST_OK;
+out:
+	lazy_fixture__exit(&f);
+	symbol_conf.max_symbol_bytes = saved_max;
+	symbol_conf.lazy_load_symbols = saved_lazy;
+	if (symbol__bytes_used() != baseline)
+		ret = TEST_FAIL;
+	return ret;
+}
+struct sym_entry {
+	u64	start;
+	char	*name;
+};
+
+static int cmp_sym_entry(const void *a, const void *b)
+{
+	const struct sym_entry *sa = a, *sb = b;
+
+	if (sa->start != sb->start)
+		return sa->start < sb->start ? -1 : 1;
+	return strcmp(sa->name, sb->name);
+}
+
+static void free_sym_entries(struct sym_entry *entries, size_t nr)
+{
+	size_t i;
+
+	for (i = 0; i < nr; i++)
+		free(entries[i].name);
+	free(entries);
+}
+
+/*
+ * Load @filename on a fresh host machine and return the start and name of
+ * every symbol, sorted. In lazy mode, building the name-sorted array
+ * materializes the whole index.
+ */
+static int load_sym_entries(const char *filename, bool lazy,
+			    struct sym_entry **entries_p, size_t *nr_p)
+{
+	struct sym_entry *entries = NULL;
+	struct machine *machine = NULL;
+	struct thread *thread = NULL;
+	struct map *map = NULL;
+	struct perf_env env;
+	struct rb_node *nd;
+	struct dso *dso;
+	size_t nr = 0, alloc = 0;
+	int ret = TEST_FAIL;
+
+	perf_env__init(&env);
+	symbol_conf.lazy_load_symbols = lazy;
+	machine = machine__new_host(&env);
+	if (!machine)
+		goto out;
+	thread = machine__findnew_thread(machine, 100, 100);
+	if (!thread)
+		goto out;
+	map = map__new(machine, 0x100000, 0xffffffff, 0, &dso_id_empty,
+		       PROT_EXEC, /*flags=*/0, (char *)filename, thread);
+	if (!map)
+		goto out;
+
+	dso = map__dso(map);
+	if (dso__load(dso, map) <= 0) {
+		pr_debug("%s: no symbols loaded\n", filename);
+		ret = TEST_SKIP;
+		goto out;
+	}
+	if (lazy && !dso__ondemand(dso)) {
+		pr_debug("%s: no lazy index was built\n", filename);
+		ret = TEST_SKIP;
+		goto out;
+	}
+	dso__sort_by_name(dso);
+
+	for (nd = rb_first_cached(dso__symbols(dso)); nd; nd = rb_next(nd)) {
+		struct symbol *sym = rb_entry(nd, struct symbol, rb_node);
+
+		if (nr == alloc) {
+			struct sym_entry *tmp;
+
+			alloc = alloc ? alloc * 2 : 1024;
+			tmp = realloc(entries, alloc * sizeof(*entries));
+			if (!tmp)
+				goto out;
+			entries = tmp;
+		}
+		entries[nr].start = sym->start;
+		entries[nr].name = strdup(sym->name);
+		if (!entries[nr].name)
+			goto out;
+		nr++;
+	}
+	qsort(entries, nr, sizeof(*entries), cmp_sym_entry);
+	*entries_p = entries;
+	*nr_p = nr;
+	entries = NULL;
+	ret = TEST_OK;
+out:
+	if (entries)
+		free_sym_entries(entries, nr);
+	map__put(map);
+	thread__put(thread);
+	machine__delete(machine);
+	perf_env__exit(&env);
+	return ret;
+}
+
+/*
+ * Compare the symbols of a DSO (perf itself, or --dso) loaded eagerly and
+ * lazily. Addresses and names must match.
+ */
+static int test__symbol_bytes_lazy_parity(struct test_suite *test __maybe_unused,
+					  int subtest __maybe_unused)
+{
+	unsigned long saved_max = symbol_conf.max_symbol_bytes;
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	struct sym_entry *eager = NULL, *lazy = NULL;
+	size_t nr_eager = 0, nr_lazy = 0, i;
+	char filename[PATH_MAX];
+	int ret;
+
+	if (dso_to_test)
+		strlcpy(filename, dso_to_test, sizeof(filename));
+	else
+		perf_exe(filename, sizeof(filename));
+
+	symbol_conf.max_symbol_bytes = 0;
+	ret = load_sym_entries(filename, false, &eager, &nr_eager);
+	if (ret == TEST_OK)
+		ret = load_sym_entries(filename, true, &lazy, &nr_lazy);
+	if (ret != TEST_OK)
+		goto out;
+
+	pr_debug("%s: %zu eager and %zu lazy symbols\n", filename, nr_eager, nr_lazy);
+	for (i = 0; i < nr_eager && i < nr_lazy; i++) {
+		if (cmp_sym_entry(&eager[i], &lazy[i])) {
+			pr_debug("mismatch: eager %#" PRIx64 " %s, lazy %#" PRIx64 " %s\n",
+				 eager[i].start, eager[i].name, lazy[i].start, lazy[i].name);
+			ret = TEST_FAIL;
+			goto out;
+		}
+	}
+	if (nr_eager != nr_lazy)
+		ret = TEST_FAIL;
+out:
+	if (eager)
+		free_sym_entries(eager, nr_eager);
+	if (lazy)
+		free_sym_entries(lazy, nr_lazy);
+	symbol_conf.max_symbol_bytes = saved_max;
+	symbol_conf.lazy_load_symbols = saved_lazy;
+	return ret;
+}
+#endif
+
 static struct test_case tests__symbol_bytes[] = {
 	TEST_CASE("Concurrent strict reservations", symbol_bytes_reservation),
+	TEST_CASE("Shared duplicate selection", symbol_bytes_duplicate_selection),
+#ifdef HAVE_LIBELF_SUPPORT
+	TEST_CASE("Truncated lazy symbol names", symbol_bytes_truncated_name),
+	TEST_CASE("Lazy address and name lookup", symbol_bytes_lazy_name_lookup),
+	TEST_CASE("Lazy lookups racing a truncated name lookup", symbol_bytes_lazy_budget_race),
+	TEST_CASE("Lazy and eager symbol parity", symbol_bytes_lazy_parity),
+#endif
 	{ .name = NULL, }
 };
 

-- 
Git-157)

