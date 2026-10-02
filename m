From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 02 Oct 2026 11:45:37 -0700
Subject: [PATCH v4 5/5] perf test: Test lazy symbol loading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-perf-symbol-memory-send-v4-5-0a592bb2539e@uber.com>
References: <20261002-perf-symbol-memory-send-v4-0-0a592bb2539e@uber.com>
In-Reply-To: <20261002-perf-symbol-memory-send-v4-0-0a592bb2539e@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=39798; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=wsw2YHdWKyAfhnu41UhttyVYg5pWqAryUPOp4afXf8s=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqv/vmG7szPs8dJzkk63n5XCHTQim9L9INFeVOG
 J4e+cR+s4KJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCar/75hsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthCCw/9Fj7NsH3NVTjgFo2L143ej3ZfnWi3LNp
 JmapTtN37nFLdPn+KxcnLOMIE6Lde0ThupgIvX62PQR53e3M5NTEF7YJQTcT9H0WFr0K5iM9Sl9
 HMQQwHks7YogcRc79PuPr5FOA/5ZJyWUQIDcn46eYMf+J5W/7ZaKSckI1FuIm/9Osd0OZB5E2xs
 eB+pAdPBxdGK9an1vOuQAJrOVsSFis+mJ6KD0n6ACdO6vLXv7pFsGstuNMnP8NN3ZMb95UZQ9ie
 AxOTFBZgIJFm+yC/gUF+dBoZatwpWV55S1wRVSPDpEObk0CVKT7R6aaF9TIpsgF+3ng+q/L1FGT
 mA0NgX0s9jOT2OKBhcl5M9HIHOV74vHLuqeZjtGw9ddYsq6Ewo+PhF7TxKVdmB7avy5RER6jr2D
 nNIbYbrnYovQWNKYJyZ711eSev21x3qNNoBXMl+BEPRPLakGERZyadgzzSPNES0053Llh71vgN8
 eF6tktTGlPW1ysOaAaWi5h/nlYJC4CLun/MM4C0u8KY2T8sIXDRSp/6qvrtI2ePz3wvGRggrebg
 Z8wEl+VG3jZoN5EWQLDh7SNyBVi6Q69XEKN9SBg7DZWBPH/sfR1WjTOewo42kGQrmF/D4vFHPJV
 Jjp4rFN3MOtcANV3Dbpg/bdaDbvA9CChAKdvZUP0rI/xjWgh8CYE=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a perf script shell test for --lazy-load-symbols.

Record a small callchain fixture, require evidence that the controlled
perf DSO built an on-demand index, and compare only extracted occurrences
of the controlled test_loop symbol. This avoids coupling the test to
addresses, diagnostics, or architecture-specific symbols for which the
eager and lazy loaders have documented differences. When run as root,
also profile perf in a private mount namespace whose build-id cache
directory is hidden by a tmpfs, so that names must be read from the
build-id cache in perf's own namespace.

Report unsupported recording, missing controlled output, and unavailable
libelf as skips without replacing a prior failure, and keep helper
returns safe under set -e.

Add a "Lazy symbol loading" unit test suite for the shared
duplicate-selection policy, truncated string-table reads, lazy address
and name lookup across a closed data descriptor, address lookups racing
name lookups, and lookups racing DSO data reads. The first race test
checks that every symbol is materialized exactly once, that the index is
freed, and that a DSO does not change once its name-sorted array has been
built. The second fails if lookups deadlock against the DSO data cache
lock.

Add a unit test that loads a DSO (perf itself, or the one given with
--dso) eagerly and lazily and compares every symbol range and name.
Before and after the lazy symbols are materialized, it also checks that
lazy lookups of each symbol's first and last address return the
innermost eager symbol containing it, with the same name. Run it from a
shell test on five hand-built binaries:

  - a split-debuginfo binary whose function section is NOBITS in the
    debug file and has no PT_LOAD in the runtime file, so both loaders
    must fall back to the runtime section header;
  - a binary with a function nested inside another;
  - a shared library with symbols present only in .dynsym, one of them
    an alias that duplicate selection prefers over its .symtab twin;
  - a stripped shared library whose local symbols are in .gnu_debugdata,
    one of them an alias of a .dynsym symbol, which must load eagerly;
  - on x86_64, a binary with an IRELATIVE PLT slot whose IFUNC loses
    duplicate selection to an alias that loses to another one in turn,
    so the PLT symbol name depends on how the IFUNC mark is passed on.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/tests/Build                             |   1 +
 tools/perf/tests/builtin-test.c                    |   1 +
 tools/perf/tests/shell/lazy_load_symbols_parity.sh | 326 ++++++++++
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 185 ++++++
 tools/perf/tests/symbol-lazy.c                     | 699 +++++++++++++++++++++
 tools/perf/tests/tests.h                           |   1 +
 6 files changed, 1213 insertions(+)

diff --git a/tools/perf/tests/Build b/tools/perf/tests/Build
index 05c545aac732..fa19a33dacbe 100644
--- a/tools/perf/tests/Build
+++ b/tools/perf/tests/Build
@@ -67,6 +67,7 @@ perf-test-y += sigtrap.o
 perf-test-y += event_groups.o
 perf-test-y += hybrid-merge.o
 perf-test-y += symbols.o
+perf-test-y += symbol-lazy.o
 perf-test-y += util.o
 perf-test-y += hwmon_pmu.o
 perf-test-y += tool_pmu.o
diff --git a/tools/perf/tests/builtin-test.c b/tools/perf/tests/builtin-test.c
index d2f594921e25..217ab701150e 100644
--- a/tools/perf/tests/builtin-test.c
+++ b/tools/perf/tests/builtin-test.c
@@ -154,6 +154,7 @@ static struct test_suite *generic_tests[] = {
 	&suite__event_groups,
 	&suite__hybrid_merge,
 	&suite__symbols,
+	&suite__symbol_lazy,
 	&suite__util,
 	&suite__subcmd_help,
 	&suite__kallsyms_split,
diff --git a/tools/perf/tests/shell/lazy_load_symbols_parity.sh b/tools/perf/tests/shell/lazy_load_symbols_parity.sh
new file mode 100755
index 000000000000..933c19b013a2
--- /dev/null
+++ b/tools/perf/tests/shell/lazy_load_symbols_parity.sh
@@ -0,0 +1,326 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# lazy symbol loading parity with eager loading
+
+# Build small ELF files whose symbols are hard for an index to get right, and
+# check that lazy and eager loading agree on their address lookups, ranges and
+# names:
+#  - split debuginfo, where a function's section is NOBITS (with a different
+#    sh_offset) in the debug file and has no PT_LOAD in the runtime ELF;
+#  - a function containing another function symbol;
+#  - a shared library with symbols that are only in .dynsym, one of them a
+#    longer-named alias of a .symtab symbol;
+#  - a stripped shared library whose local symbols are in .gnu_debugdata,
+#    one of them an alias of a .dynsym symbol, which must load eagerly;
+#  - on x86_64, an IRELATIVE PLT slot whose IFUNC loses duplicate selection
+#    to an alias that loses to another one in turn.
+
+set -e
+
+err=0
+tmpdir=$(mktemp -d /tmp/__perf_test.lazy_parity.XXXXX)
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
+	echo "Lazy-load parity [Skipped: $1]"
+	cleanup
+	exit 2
+}
+
+if ! perf check feature -q libelf; then
+	skip "no libelf support"
+fi
+
+for tool in cc objcopy strip readelf nm dd; do
+	if ! command -v "${tool}" > /dev/null; then
+		skip "${tool} not found"
+	fi
+done
+
+# check_parity NAME FILE [eager]
+# Lazy loading must build an index for FILE, or none if "eager" is given.
+check_parity() {
+	local out="${tmpdir}/parity.out"
+	local index="on-demand index:"
+
+	if [ "$3" = eager ]; then
+		index="no lazy index was built"
+	fi
+	perf test --dso "$2" -vv "Lazy and eager symbol parity" > "${out}" 2>&1 || true
+	if grep -q ': Ok$' "${out}" && grep -Fq "$2: ${index}" "${out}"; then
+		echo "Lazy-load parity $1 [Success]"
+		return
+	fi
+	grep -E 'symbols$|mismatch|lookup|no symbols|index' "${out}" || true
+	echo "Lazy-load parity $1 [Failed]"
+	err=1
+}
+
+test_split_debug() {
+	local prog="${tmpdir}/split"
+
+	cat > "${prog}.c" << EOF
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
+	if ! cc -O1 -g -o "${prog}" "${prog}.c" \
+		-Wl,--section-start=splittext=0x800000 2> /dev/null; then
+		echo "Lazy-load parity split debuginfo [Skipped: cannot build]"
+		return
+	fi
+	objcopy --only-keep-debug "${prog}" "${prog}.debug"
+	strip -s "${prog}"
+	objcopy --add-gnu-debuglink="${prog}.debug" "${prog}"
+
+	# The debug file must keep splittext as NOBITS at a stale offset.
+	local debug_sec run_sec debug_off run_off
+	debug_sec=$(readelf -SW "${prog}.debug" 2> /dev/null | grep ' splittext ' || true)
+	run_sec=$(readelf -SW "${prog}" | grep ' splittext ' || true)
+	if ! echo "${debug_sec}" | grep -q NOBITS; then
+		echo "Lazy-load parity split debuginfo [Skipped: splittext is not NOBITS]"
+		return
+	fi
+	debug_off=$(echo "${debug_sec}" | sed 's/.*splittext *//' | awk '{print $3}')
+	run_off=$(echo "${run_sec}" | sed 's/.*splittext *//' | awk '{print $3}')
+	if [ -z "${run_off}" ] || [ "${debug_off}" = "${run_off}" ]; then
+		echo "Lazy-load parity split debuginfo [Skipped: offsets do not differ]"
+		return
+	fi
+
+	# Drop the PT_LOAD covering splittext so program header lookup fails.
+	local phoff phentsize idx
+	phoff=$(readelf -hW "${prog}" | awk '/Start of program headers/ {print $5}')
+	phentsize=$(readelf -hW "${prog}" | awk '/Size of program headers/ {print $5}')
+	idx=$(readelf -lW "${prog}" 2> /dev/null | awk '
+		/^Program Headers:/ { in_ph = 1; next }
+		in_ph && /^  Type/ { next }
+		in_ph && /^ *$/ { exit }
+		in_ph && /^  [A-Z]/ {
+			if ($1 == "LOAD" && $3 ~ /^0x0*800000$/) { print n; exit }
+			n++
+		}')
+	if [ -z "${phoff}" ] || [ -z "${phentsize}" ] || [ -z "${idx}" ]; then
+		echo "Lazy-load parity split debuginfo [Skipped: no PT_LOAD for splittext]"
+		return
+	fi
+	dd if=/dev/zero of="${prog}" bs=1 seek=$((phoff + idx * phentsize)) \
+		count=4 conv=notrunc 2> /dev/null
+	if readelf -lW "${prog}" 2> /dev/null | grep -q 'LOAD .*0x0*800000 '; then
+		echo "Lazy-load parity split debuginfo [Failed to drop PT_LOAD]"
+		err=1
+		return
+	fi
+	check_parity "split debuginfo" "${prog}"
+}
+
+test_nested_symbol() {
+	local prog="${tmpdir}/nested"
+
+	# inner covers 4 bytes in the middle of outer, so outer's addresses
+	# after inner belong to outer alone.
+	cat > "${prog}.c" << EOF
+__attribute__((noinline, used))
+int outer(int x)
+{
+	int i, s = 0;
+
+	for (i = 0; i < x; i++)
+		s += i * x + (s >> 3);
+	return s;
+}
+
+asm(".globl inner\n"
+    ".type inner, STT_FUNC\n"
+    ".set inner, outer + 8\n"
+    ".size inner, 4\n");
+
+int main(int argc, char **argv)
+{
+	(void)argv;
+	return outer(argc * 100);
+}
+EOF
+	if ! cc -O1 -o "${prog}" "${prog}.c" 2> /dev/null; then
+		echo "Lazy-load parity nested symbol [Skipped: cannot build]"
+		return
+	fi
+	local outer_size
+	outer_size=$(nm -S "${prog}" | awk '$4 == "outer" { print $2 }')
+	if [ -z "${outer_size}" ] || [ $((16#${outer_size})) -lt 16 ]; then
+		echo "Lazy-load parity nested symbol [Skipped: outer is too small]"
+		return
+	fi
+	check_parity "nested symbol" "${prog}"
+}
+
+test_dynsym_only() {
+	local lib="${tmpdir}/libdyn.so"
+
+	cat > "${tmpdir}/libdyn.c" << EOF
+int dyn_only(int x)
+{
+	return x + 1;
+}
+
+int dyn_and_symtab(int x)
+{
+	return x * 2;
+}
+
+/* Same range as dyn_and_symtab; duplicate selection prefers the longer name. */
+int dyn_and_symtab_alias(int x) __attribute__((alias("dyn_and_symtab")));
+EOF
+	if ! cc -O1 -shared -fPIC -o "${lib}" "${tmpdir}/libdyn.c" 2> /dev/null; then
+		echo "Lazy-load parity .dynsym-only symbol [Skipped: cannot build]"
+		return
+	fi
+	# --strip-symbol leaves .dynsym untouched.
+	objcopy --strip-symbol=dyn_only --strip-symbol=dyn_and_symtab_alias \
+		"${lib}"
+	for sym in dyn_only dyn_and_symtab_alias; do
+		if readelf -sW "${lib}" | \
+			awk '/Symbol table .\.symtab/ { s = 1 } s' | \
+			grep -qw "${sym}" || \
+		   ! readelf --dyn-syms -W "${lib}" | grep -qw "${sym}"; then
+			echo "Lazy-load parity .dynsym-only symbol [Skipped: cannot strip]"
+			return
+		fi
+	done
+	check_parity ".dynsym-only symbol" "${lib}"
+}
+
+test_gnu_debugdata() {
+	local lib="${tmpdir}/libgdd.so"
+	local dir="${tmpdir}/gdd"
+
+	if ! perf check feature -q lzma || ! command -v xz > /dev/null; then
+		echo "Lazy-load parity .gnu_debugdata [Skipped: no lzma support or xz]"
+		return
+	fi
+	mkdir "${dir}"
+	cat > "${dir}/libgdd.c" << EOF
+int exported(int x)
+{
+	return x * 3 + 1;
+}
+
+/* Same range as exported; duplicate selection prefers the global symbol. */
+static int local_alias(int x) __attribute__((alias("exported"), used));
+
+__attribute__((noinline)) static int local_helper(int x)
+{
+	return x + 7;
+}
+
+int call_local(int x)
+{
+	return local_helper(x) * 2;
+}
+EOF
+	if ! cc -O1 -shared -fPIC -o "${lib}" "${dir}/libgdd.c" 2> /dev/null; then
+		echo "Lazy-load parity .gnu_debugdata [Skipped: cannot build]"
+		return
+	fi
+	# Build MiniDebugInfo the way distributions do: the function symbols
+	# that are not in .dynsym, xz-compressed into .gnu_debugdata.
+	nm -D --format=posix --defined-only "${lib}" | awk '{ print $1 }' | \
+		sort > "${dir}/dynsyms"
+	nm --format=posix --defined-only "${lib}" | \
+		awk '$2 == "T" || $2 == "t" { print $1 }' | sort > "${dir}/funcsyms"
+	comm -13 "${dir}/dynsyms" "${dir}/funcsyms" > "${dir}/keep"
+	if ! grep -qx local_alias "${dir}/keep" ||
+	   ! objcopy --only-keep-debug "${lib}" "${dir}/debug" ||
+	   ! objcopy -S --remove-section .comment \
+		--keep-symbols="${dir}/keep" "${dir}/debug" "${dir}/mini" ||
+	   ! xz "${dir}/mini" || ! strip --strip-all "${lib}" ||
+	   ! objcopy --add-section .gnu_debugdata="${dir}/mini.xz" "${lib}" ||
+	   readelf -SW "${lib}" | grep -qw '\.symtab'; then
+		echo "Lazy-load parity .gnu_debugdata [Skipped: cannot build MiniDebugInfo]"
+		return
+	fi
+	check_parity ".gnu_debugdata" "${lib}" eager
+}
+
+test_ifunc_alias() {
+	local prog="${tmpdir}/ifunc"
+	local order
+
+	if [ "$(uname -m)" != x86_64 ]; then
+		echo "Lazy-load parity IFUNC alias [Skipped: IRELATIVE naming is x86_64 only]"
+		return
+	fi
+	# Duplicate selection prefers fewer leading underscores, so at the
+	# resolver's address __lazy_ifunc loses to _lazy_ifunc_x, which loses
+	# to lazy_ifunc_y. Whether the PLT slot is named after lazy_ifunc_y
+	# depends on how that passes on the IFUNC mark.
+	cat > "${prog}.c" << EOF
+static int impl(void)
+{
+	return 42;
+}
+
+__attribute__((used, noinline)) static void *___lazy_ifunc_resolver(void)
+{
+	return (void *)impl;
+}
+
+asm(".type __lazy_ifunc, @gnu_indirect_function\n"
+    ".set __lazy_ifunc, ___lazy_ifunc_resolver\n"
+    ".size __lazy_ifunc, 1\n"
+    ".type _lazy_ifunc_x, @function\n"
+    ".set _lazy_ifunc_x, ___lazy_ifunc_resolver\n"
+    ".size _lazy_ifunc_x, 1\n"
+    ".type lazy_ifunc_y, @function\n"
+    ".set lazy_ifunc_y, ___lazy_ifunc_resolver\n"
+    ".size lazy_ifunc_y, 1\n");
+
+int __lazy_ifunc(void);
+
+int main(void)
+{
+	return __lazy_ifunc();
+}
+EOF
+	if ! cc -O1 -fno-pie -no-pie -o "${prog}" "${prog}.c" 2> /dev/null ||
+	   ! readelf -rW "${prog}" | grep -q R_X86_64_IRELATIVE; then
+		echo "Lazy-load parity IFUNC alias [Skipped: cannot build]"
+		return
+	fi
+	# The outcome depends on the order of the aliases in .symtab.
+	order=$(readelf -sW "${prog}" | \
+		awk '$8 ~ /^_*lazy_ifunc(_x|_y)?$/ { printf "%s ", $8 }')
+	if [ "${order}" != "__lazy_ifunc _lazy_ifunc_x lazy_ifunc_y " ]; then
+		echo "Lazy-load parity IFUNC alias [Skipped: unexpected symbol order]"
+		return
+	fi
+	check_parity "IFUNC alias" "${prog}"
+}
+
+test_split_debug
+test_nested_symbol
+test_dynsym_only
+test_gnu_debugdata
+test_ifunc_alias
+
+cleanup
+exit ${err}
diff --git a/tools/perf/tests/shell/script_lazy_load_symbols.sh b/tools/perf/tests/shell/script_lazy_load_symbols.sh
new file mode 100755
index 000000000000..00c2fb84a565
--- /dev/null
+++ b/tools/perf/tests/shell/script_lazy_load_symbols.sh
@@ -0,0 +1,185 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# perf script lazy symbol loading tests (exclusive)
+#
+# Verifies that --lazy-load-symbols matches the default eager loader for a
+# controlled symbol.
+
+mark_skip() {
+	if [ "${err}" -eq 0 ]; then
+		err=2
+	fi
+	return 0
+}
+
+set -e
+
+shelldir=$(dirname "$0")
+# shellcheck source=lib/perf_has_symbol.sh
+. "${shelldir}"/lib/perf_has_symbol.sh
+
+testsym="test_loop"
+perf_path=$(readlink -f "$(command -v perf)")
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
+ns_pid=
+
+cleanup() {
+	if [ -n "${ns_pid}" ]; then
+		kill "${ns_pid}" 2> /dev/null || true
+		wait "${ns_pid}" 2> /dev/null || true
+	fi
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
+	if ! grep -Fq "${perf_path}: on-demand index:" "${lazy_err}"
+	then
+		echo "Lazy-load identical [Failed controlled DSO has no index]"
+		err=1
+		return
+	fi
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
+# A build-id cache file is opened outside the target's mount namespace, so
+# lazy name reads must open it there too.
+test_lazy_load_mount_ns() {
+	echo "Lazy-load build-id cache source of a process in a mount namespace"
+
+	if [ "$(id -u)" != 0 ] || ! command -v unshare > /dev/null
+	then
+		echo "Lazy-load mount namespace [Skipped needs root and unshare]"
+		mark_skip
+		return 0
+	fi
+
+	local buildid_dir="${temp_dir}/buildid"
+	local nsdata="${temp_dir}/ns.data"
+	local i
+
+	# The workload sees an empty build-id cache; perf sees the real one.
+	mkdir -p "${buildid_dir}"
+	unshare -m --propagation private sh -c \
+		"mount -t tmpfs none '${buildid_dir}' && exec perf test -w thloop 30" &
+	ns_pid=$!
+	for i in $(seq 50)
+	do
+		if [ "$(readlink "/proc/${ns_pid}/exe" 2> /dev/null)" = "${perf_path}" ]
+		then
+			break
+		fi
+		sleep 0.1
+	done
+	if [ "$(readlink "/proc/${ns_pid}/exe" 2> /dev/null)" != "${perf_path}" ]
+	then
+		echo "Lazy-load mount namespace [Skipped cannot start workload]"
+		mark_skip
+		return 0
+	fi
+
+	if ! perf record -N -o "${nsdata}" -p "${ns_pid}" -- sleep 1 2> /dev/null ||
+	   ! perf --buildid-dir "${buildid_dir}" buildid-cache -a "${perf_path}" \
+		2> /dev/null ||
+	   [ -z "$(ls -A "${buildid_dir}/.build-id" 2> /dev/null)" ]
+	then
+		echo "Lazy-load mount namespace [Skipped record or build-id cache failed]"
+		mark_skip
+		return 0
+	fi
+	perf --buildid-dir "${buildid_dir}" script -i "${nsdata}" 2> /dev/null \
+		> "${eager_out}" || true
+	perf --buildid-dir "${buildid_dir}" script -v --lazy-load-symbols \
+		-i "${nsdata}" 2> "${lazy_err}" > "${lazy_out}" || true
+
+	if ! grep -Fq "${perf_path}: on-demand index:" "${lazy_err}"
+	then
+		echo "Lazy-load mount namespace [Failed no index for the build-id cache source]"
+		err=1
+		return
+	fi
+	if ! grep -q "${testsym}" "${eager_out}" ||
+	   ! cmp -s "${eager_out}" "${lazy_out}"
+	then
+		echo "Lazy-load mount namespace [Failed output differs from eager]"
+		err=1
+		return
+	fi
+	echo "Lazy-load mount namespace [Success]"
+}
+
+test_lazy_load_identical
+test_lazy_load_mount_ns
+
+cleanup
+exit $err
diff --git a/tools/perf/tests/symbol-lazy.c b/tools/perf/tests/symbol-lazy.c
new file mode 100644
index 000000000000..9c7f8b23b641
--- /dev/null
+++ b/tools/perf/tests/symbol-lazy.c
@@ -0,0 +1,699 @@
+// SPDX-License-Identifier: GPL-2.0
+#include <inttypes.h>
+#include <limits.h>
+#include <stdbool.h>
+#include <stdint.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <time.h>
+
+#include <fcntl.h>
+#include <linux/kernel.h>
+#include <linux/zalloc.h>
+#include <pthread.h>
+#include <sys/mman.h>
+#include <unistd.h>
+
+#include "debug.h"
+#include "dso.h"
+#include "env.h"
+#include "machine.h"
+#include "map.h"
+#include "symbol.h"
+#include "symbol_conf.h"
+#include "tests.h"
+#include "thread.h"
+#include "util.h"
+
+static int test__symbol_lazy_duplicate_selection(struct test_suite *test __maybe_unused,
+						 int subtest __maybe_unused)
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
+static int test__symbol_lazy_truncated_name(struct test_suite *test __maybe_unused,
+					    int subtest __maybe_unused)
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
+ * functions named lazy_sym_NNN, with names @stride bytes apart in a
+ * string-table file read through a private data DSO.
+ */
+static int lazy_fixture__init(struct lazy_fixture *f, u32 nr, u32 stride)
+{
+	struct dso_ondemand *od = NULL;
+	size_t strtab_size = (size_t)nr * stride;
+	char *strtab;
+	int fd, ret = -1;
+	u32 i;
+
+	memset(f, 0, sizeof(*f));
+	f->nr = nr;
+	strcpy(f->path, "/tmp/perf-lazy-names-XXXXXX");
+
+	strtab = calloc(1, strtab_size);
+	if (!strtab)
+		return -1;
+	for (i = 0; i < nr; i++)
+		lazy_name(strtab + (size_t)i * stride, i);
+
+	fd = mkstemp(f->path);
+	if (fd < 0) {
+		f->path[0] = '\0';
+		goto out;
+	}
+	if (write(fd, strtab, strtab_size) != (ssize_t)strtab_size) {
+		close(fd);
+		goto out;
+	}
+	close(fd);
+
+	f->dso = dso__new("/not/the/symbol/source");
+	od = dso_ondemand__new();
+	if (!f->dso || !od)
+		goto out;
+	od->sorted = calloc(nr, sizeof(*od->sorted));
+	od->data_dso = dso__new(f->path);
+	if (!od->sorted || !od->data_dso ||
+	    dso__data_set_path(od->data_dso, f->path) < 0)
+		goto out;
+	dso__set_binary_type(od->data_dso, DSO_BINARY_TYPE__SYSTEM_PATH_DSO);
+	od->strtab[0].size = strtab_size;
+	od->nr_sorted = nr;
+	for (i = 0; i < nr; i++) {
+		od->sorted[i] = (struct sym_idx) {
+			.start = LAZY_SYM_START + i * LAZY_SYM_SIZE,
+			.end = LAZY_SYM_START + (i + 1) * LAZY_SYM_SIZE,
+			.name_off = i * stride,
+			.binding = STB_GLOBAL,
+			.type = STT_FUNC,
+		};
+	}
+	dso__set_ondemand(f->dso, od);
+	od = NULL;
+	dso__set_loaded(f->dso);
+	f->map = map__new2(0, f->dso);
+	if (f->map)
+		ret = 0;
+out:
+	dso_ondemand__free(od);
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
+static int test__symbol_lazy_name_lookup(struct test_suite *test __maybe_unused,
+					 int subtest __maybe_unused)
+{
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	struct lazy_fixture f;
+	struct symbol *sym;
+	int ret = TEST_FAIL;
+
+	symbol_conf.lazy_load_symbols = true;
+	if (lazy_fixture__init(&f, 2, LAZY_NAME_LEN))
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
+	symbol_conf.lazy_load_symbols = saved_lazy;
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
+			if (!sym || !lazy_symbol_ok(sym, i))
+				arg->failed = true;
+		}
+	}
+	return NULL;
+}
+
+/*
+ * Address lookups race with name lookups, which materialize the whole index
+ * and free it. Every symbol must be materialized exactly once, and the DSO
+ * must not change once its name array exists.
+ */
+static int test__symbol_lazy_lookup_race(struct test_suite *test __maybe_unused,
+					 int subtest __maybe_unused)
+{
+	enum { NR_SYMS = 256, NR_ADDR_THREADS = 4, NR_THREADS = NR_ADDR_THREADS + 2 };
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	struct lazy_lookup_arg args[NR_THREADS];
+	pthread_t threads[NR_THREADS];
+	struct lazy_fixture f;
+	int created = 0, nr_symbols, i;
+	int ret = TEST_FAIL;
+
+	symbol_conf.lazy_load_symbols = true;
+	if (lazy_fixture__init(&f, NR_SYMS, LAZY_NAME_LEN))
+		goto out;
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
+	if (dso__ondemand(f.dso) || nr_symbols != NR_SYMS) {
+		pr_debug("unexpected lazy state: index %p, %d symbols\n",
+			 dso__ondemand(f.dso), nr_symbols);
+		goto out;
+	}
+
+	for (i = 0; i < NR_SYMS; i++)
+		map__find_symbol(f.map, LAZY_SYM_START + i * LAZY_SYM_SIZE + 1);
+	if (lazy_nr_symbols(f.dso) != nr_symbols) {
+		pr_debug("DSO changed after its name array was built\n");
+		goto out;
+	}
+	ret = TEST_OK;
+out:
+	lazy_fixture__exit(&f);
+	symbol_conf.lazy_load_symbols = saved_lazy;
+	return ret;
+}
+
+struct lazy_io_arg {
+	struct lazy_fixture	*f;
+	pthread_mutex_t		*done_lock;
+	pthread_cond_t		*done_cond;
+	int			*nr_done;
+	bool			by_name;
+	bool			data_reader;
+	bool			failed;
+};
+
+static void *lazy_io(void *data)
+{
+	struct lazy_io_arg *arg = data;
+	struct lazy_fixture *f = arg->f;
+	u32 i;
+
+	for (i = 0; i < f->nr; i++) {
+		struct symbol *sym;
+		int fd;
+
+		if (arg->data_reader) {
+			/* Reopening the parent takes its lock under the data-open lock. */
+			dso__data_close(f->dso);
+			if (dso__data_get_fd(f->dso, NULL, &fd))
+				dso__data_put_fd(f->dso);
+			else
+				arg->failed = true;
+			continue;
+		}
+		if (arg->by_name) {
+			char name[LAZY_NAME_LEN];
+
+			lazy_name(name, i);
+			sym = map__find_symbol_by_name(f->map, name);
+		} else {
+			sym = map__find_symbol(f->map, LAZY_SYM_START +
+					       i * LAZY_SYM_SIZE + 1);
+		}
+		if (!sym || !lazy_symbol_ok(sym, i))
+			arg->failed = true;
+	}
+
+	pthread_mutex_lock(arg->done_lock);
+	(*arg->nr_done)++;
+	pthread_cond_signal(arg->done_cond);
+	pthread_mutex_unlock(arg->done_lock);
+	return NULL;
+}
+
+/*
+ * Lazy lookups read symbol names through the DSO data cache, which takes the
+ * global data-open lock and then the lock of the DSO being opened. They must
+ * not hold the lock of the looked-up DSO while doing so, or they deadlock
+ * against threads reading that DSO's own data. Each name sits on its own
+ * cache page so that every materialization misses the data cache.
+ */
+static int test__symbol_lazy_lookup_vs_data_read(struct test_suite *test __maybe_unused,
+						 int subtest __maybe_unused)
+{
+	enum { NR_SYMS = 1000, NR_THREADS = 4 };
+	pthread_mutex_t done_lock = PTHREAD_MUTEX_INITIALIZER;
+	pthread_cond_t done_cond = PTHREAD_COND_INITIALIZER;
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	struct lazy_io_arg args[NR_THREADS];
+	pthread_t threads[NR_THREADS];
+	struct lazy_fixture f;
+	struct timespec deadline;
+	int created = 0, nr_done = 0, i;
+	int ret = TEST_FAIL;
+
+	symbol_conf.lazy_load_symbols = true;
+	if (lazy_fixture__init(&f, NR_SYMS, 4096) ||
+	    dso__data_set_path(f.dso, f.path) < 0)
+		goto out;
+
+	for (i = 0; i < NR_THREADS; i++) {
+		args[i] = (struct lazy_io_arg) {
+			.f = &f,
+			.done_lock = &done_lock,
+			.done_cond = &done_cond,
+			.nr_done = &nr_done,
+			.by_name = i == 2,
+			.data_reader = i == 3,
+		};
+		if (pthread_create(&threads[i], NULL, lazy_io, &args[i]))
+			break;
+		created++;
+	}
+
+	clock_gettime(CLOCK_REALTIME, &deadline);
+	deadline.tv_sec += 60;
+	pthread_mutex_lock(&done_lock);
+	while (nr_done < created) {
+		if (pthread_cond_timedwait(&done_cond, &done_lock, &deadline))
+			break;
+	}
+	pthread_mutex_unlock(&done_lock);
+	if (nr_done < created) {
+		/*
+		 * The stuck threads still use this stack frame and hold the
+		 * global data-open lock, so returning is not safe.
+		 */
+		pr_err("lazy lookups deadlocked against DSO data reads\n");
+		fflush(NULL);
+		_exit(-TEST_FAIL);
+	}
+
+	for (i = 0; i < created; i++)
+		pthread_join(threads[i], NULL);
+	if (created != NR_THREADS)
+		goto out;
+	for (i = 0; i < NR_THREADS; i++) {
+		if (args[i].failed) {
+			pr_debug("thread %d: wrong lookup or data read failure\n", i);
+			goto out;
+		}
+	}
+	if (dso__ondemand(f.dso) || lazy_nr_symbols(f.dso) != NR_SYMS) {
+		pr_debug("unexpected lazy state: index %p, %d symbols\n",
+			 dso__ondemand(f.dso), lazy_nr_symbols(f.dso));
+		goto out;
+	}
+	ret = TEST_OK;
+out:
+	lazy_fixture__exit(&f);
+	symbol_conf.lazy_load_symbols = saved_lazy;
+	return ret;
+}
+
+struct sym_entry {
+	u64	start;
+	u64	end;
+	char	*name;
+};
+
+static int cmp_sym_entry(const void *a, const void *b)
+{
+	const struct sym_entry *sa = a, *sb = b;
+
+	if (sa->start != sb->start)
+		return sa->start < sb->start ? -1 : 1;
+	if (sa->end != sb->end)
+		return sa->end < sb->end ? -1 : 1;
+	return strcmp(sa->name, sb->name);
+}
+
+/* Return the last-starting entry of sorted @entries that contains @addr. */
+static const struct sym_entry *innermost_sym_entry(const struct sym_entry *entries,
+						   size_t nr, u64 addr)
+{
+	size_t lo = 0, hi = nr;
+
+	while (lo < hi) {
+		size_t mid = lo + (hi - lo) / 2;
+
+		if (entries[mid].start <= addr)
+			lo = mid + 1;
+		else
+			hi = mid;
+	}
+	while (lo-- > 0) {
+		if (entries[lo].end > addr)
+			return &entries[lo];
+	}
+	return NULL;
+}
+
+/*
+ * Look up the first and last address of every eager symbol lazily, before
+ * and after the symbols are materialized. Each must resolve to the innermost
+ * eager symbol containing it, which is the one an unambiguous lookup has to
+ * return.
+ */
+static int check_lazy_lookups(struct map *map, const struct sym_entry *eager,
+			      size_t nr_eager)
+{
+	size_t i;
+	int pass, k;
+
+	for (pass = 0; pass < 2; pass++) {
+		for (i = 0; i < nr_eager; i++) {
+			if (eager[i].end <= eager[i].start)
+				continue;
+			for (k = 0; k < 2; k++) {
+				u64 addr = k ? eager[i].end - 1 : eager[i].start;
+				const struct sym_entry *want;
+				struct symbol *sym;
+
+				want = innermost_sym_entry(eager, nr_eager, addr);
+				sym = map__find_symbol(map, addr);
+				if (!sym || sym->start != want->start ||
+				    strcmp(sym->name, want->name) ||
+				    addr < sym->start || addr >= sym->end) {
+					pr_debug("lookup %#" PRIx64 ": eager %#" PRIx64
+						 "-%#" PRIx64 " %s, lazy %s\n", addr,
+						 want->start, want->end, want->name,
+						 sym ? sym->name : "[none]");
+					return TEST_FAIL;
+				}
+			}
+		}
+	}
+	return TEST_OK;
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
+ * Load @filename on a fresh host machine and return the range and name of
+ * every symbol, sorted. If lazy mode built an index, first check lookups
+ * against @eager, then build the name-sorted array, which materializes the
+ * whole index.
+ */
+static int load_sym_entries(const char *filename, bool lazy,
+			    const struct sym_entry *eager, size_t nr_eager,
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
+	if (lazy && !dso__ondemand(dso))
+		pr_debug("%s: no lazy index was built\n", filename);
+	else if (lazy && check_lazy_lookups(map, eager, nr_eager) != TEST_OK)
+		goto out;
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
+		entries[nr].end = sym->end;
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
+ * lazily. Lazy address lookups must agree with the eager symbols, and the
+ * fully materialized ranges and names must match.
+ */
+static int test__symbol_lazy_parity(struct test_suite *test __maybe_unused,
+				    int subtest __maybe_unused)
+{
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
+	ret = load_sym_entries(filename, false, NULL, 0, &eager, &nr_eager);
+	if (ret == TEST_OK)
+		ret = load_sym_entries(filename, true, eager, nr_eager, &lazy, &nr_lazy);
+	if (ret != TEST_OK)
+		goto out;
+
+	pr_debug("%s: %zu eager and %zu lazy symbols\n", filename, nr_eager, nr_lazy);
+	for (i = 0; i < nr_eager && i < nr_lazy; i++) {
+		if (cmp_sym_entry(&eager[i], &lazy[i])) {
+			pr_debug("mismatch: eager %#" PRIx64 "-%#" PRIx64 " %s, lazy %#"
+				 PRIx64 "-%#" PRIx64 " %s\n",
+				 eager[i].start, eager[i].end, eager[i].name,
+				 lazy[i].start, lazy[i].end, lazy[i].name);
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
+	symbol_conf.lazy_load_symbols = saved_lazy;
+	return ret;
+}
+#endif
+
+static struct test_case tests__symbol_lazy[] = {
+	TEST_CASE("Shared duplicate selection", symbol_lazy_duplicate_selection),
+#ifdef HAVE_LIBELF_SUPPORT
+	TEST_CASE("Truncated lazy symbol names", symbol_lazy_truncated_name),
+	TEST_CASE("Lazy address and name lookup", symbol_lazy_name_lookup),
+	TEST_CASE("Lazy address lookups racing name lookups", symbol_lazy_lookup_race),
+	TEST_CASE("Lazy lookups racing DSO data reads", symbol_lazy_lookup_vs_data_read),
+	TEST_CASE("Lazy and eager symbol parity", symbol_lazy_parity),
+#endif
+	{ .name = NULL, }
+};
+
+struct test_suite suite__symbol_lazy = {
+	.desc = "Lazy symbol loading",
+	.test_cases = tests__symbol_lazy,
+};
diff --git a/tools/perf/tests/tests.h b/tools/perf/tests/tests.h
index 9c96f33483d1..93ba2bd0879a 100644
--- a/tools/perf/tests/tests.h
+++ b/tools/perf/tests/tests.h
@@ -179,6 +179,7 @@ DECLARE_SUITE(sigtrap);
 DECLARE_SUITE(event_groups);
 DECLARE_SUITE(hybrid_merge);
 DECLARE_SUITE(symbols);
+DECLARE_SUITE(symbol_lazy);
 DECLARE_SUITE(util);
 DECLARE_SUITE(uncore_event_sorting);
 DECLARE_SUITE(subcmd_help);

-- 
Git-157)

