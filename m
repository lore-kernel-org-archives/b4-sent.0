From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 13 Nov 2026 21:09:09 -0800
Subject: [PATCH v7 4/4] perf test: Test lazy symbol name loading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-perf-symbol-memory-send-v7-4-d992eced9f9c@uber.com>
References: <20261113-perf-symbol-memory-send-v7-0-d992eced9f9c@uber.com>
In-Reply-To: <20261113-perf-symbol-memory-send-v7-0-d992eced9f9c@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=36388; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=q8zpr5T8z+a3MBz2/VNCdL3k9Og7cVXw+3r8Gs0R208=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBq9+0lx2OcGk2LM4Wy3SEPmmJ9GNNDkPNdk02yf
 uQ0TGFbBGmJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCavftJRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtg+hA//SsqyTG+uOzCmkCRh54WxRHAHUpGQFNq
 XkG1Bjbbh+Vdrofe5nhC6apA/mvVRQ6BRnAF8jziFkt5zO9+BASu+rlRG8K1JOVlOV6NFLutiEy
 s5oqygyj9YPSVT+8L8c/D4sxY38uYpBRoz3+Fh70ZKZmdy0DVYWjvWKDDtY7xH0Pexpliz/i6Z3
 2w7fZ+b0FQLU/wS1qvHz/cD+LeTOpy+8FeKprFtGzcgIuBuM7pGziuH+5GWZMe+eMhU8JJVz/ix
 uGrYf5WRU/ZxCZ0OmPGW6G9EnP1+0L6sRrf5UkJ1loa71nb512iI6Ec47zZhquk+Z6xvIj4LJyq
 bwyft3MQj6D6RdxUUQ/F3/3nCx5wW2VCprapednpIm1BlCiDhAJZY23ADLpURPGKcBOXPpSG/+k
 JEdelpyYJpGu+lpu1BFRrm51HYDn7Kh4qWhcxqgojaNEb+F5BdwRi9wMXvs53IfpEnusN3nuOm5
 3YprEMdLlsPNYgr3eLV2FGPvqoTBrSy6cFH8qZNKlltGSuUFA16IJpGhNaBsJlghVP3vtaRS0PU
 jbuqiDvFF4Gc4x4GZFxmRmUsIC0iRFgJtvKjuXFJGoPzFDYVNTAOKEn7uL9GqIZG9+0t0DZ+GuQ
 C3IEvxdraz9GgDOIM8WezsTpKD+taebjcXCYtAlOMB0kQoYHJji0=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a "Lazy symbol loading" unit test suite. It covers duplicate
selection without names, lazy names that take one or more reads or
cannot be read at all, lookups from several threads while another one
walks the symbols, eager and lazy parity on a real DSO (perf itself, or
the one given with --dso), and a symbol table file that is replaced
after the first name was read.

Add two shell tests. lazy_load_symbols_parity.sh runs the parity test
on four small binaries built for the loader's corner cases: split
debuginfo whose function section is NOBITS in the debug file, a shared
library with .dynsym-only symbols and aliases, a stripped library with
.gnu_debugdata, and on x86_64 an IFUNC behind an IRELATIVE PLT slot.
script_lazy_load_symbols.sh records a small callchain profile and checks
that perf script prints the same output with and without
--lazy-load-symbols. As root, it also checks that names are read from
the build-id cache when the profiled process is in another mount
namespace.

Both shell tests skip a case, rather than fail it, when the toolchain
produced a file whose names perf loads eagerly anyway (PPC64 ELFv1 .opd,
.gnu_debugdata or a compressed .strtab).

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/tests/Build                             |   1 +
 tools/perf/tests/builtin-test.c                    |   1 +
 tools/perf/tests/shell/lazy_load_symbols_parity.sh | 293 ++++++++++
 tools/perf/tests/shell/lib/lazy_names.sh           |  19 +
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 191 +++++++
 tools/perf/tests/symbol-lazy.c                     | 606 +++++++++++++++++++++
 tools/perf/tests/tests.h                           |   1 +
 7 files changed, 1112 insertions(+)

diff --git a/tools/perf/tests/Build b/tools/perf/tests/Build
index 5eebb2ec5dde..1377dd465586 100644
--- a/tools/perf/tests/Build
+++ b/tools/perf/tests/Build
@@ -69,6 +69,7 @@ perf-test-y += sigtrap.o
 perf-test-y += event_groups.o
 perf-test-y += hybrid-merge.o
 perf-test-y += symbols.o
+perf-test-y += symbol-lazy.o
 perf-test-y += util.o
 perf-test-y += hwmon_pmu.o
 perf-test-y += tool_pmu.o
diff --git a/tools/perf/tests/builtin-test.c b/tools/perf/tests/builtin-test.c
index 327483f96401..f50f5e0af8be 100644
--- a/tools/perf/tests/builtin-test.c
+++ b/tools/perf/tests/builtin-test.c
@@ -189,6 +189,7 @@ static struct test_suite *generic_tests[] = {
 	&suite__event_groups,
 	&suite__hybrid_merge,
 	&suite__symbols,
+	&suite__symbol_lazy,
 	&suite__util,
 	&suite__subcmd_help,
 	&suite__kallsyms_split,
diff --git a/tools/perf/tests/shell/lazy_load_symbols_parity.sh b/tools/perf/tests/shell/lazy_load_symbols_parity.sh
new file mode 100755
index 000000000000..d6b2b97d956e
--- /dev/null
+++ b/tools/perf/tests/shell/lazy_load_symbols_parity.sh
@@ -0,0 +1,293 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# lazy symbol loading parity with eager loading
+
+# Build small ELF files whose symbols are hard to get right without their
+# names, and check that lazy and eager loading agree on their address lookups,
+# ranges and names:
+#  - split debuginfo, where a function's section is NOBITS (with a different
+#    sh_offset) in the debug file and has no PT_LOAD in the runtime ELF;
+#  - a shared library with symbols that are only in .dynsym, one of them a
+#    longer-named alias of a .symtab symbol;
+#  - a stripped shared library whose local symbols are in .gnu_debugdata,
+#    one of them an alias of a .dynsym symbol, which must load eagerly;
+#  - on x86_64, an IRELATIVE PLT slot whose IFUNC loses duplicate selection
+#    to an alias that loses to another one in turn.
+
+set -e
+
+shelldir=$(dirname "$0")
+# shellcheck source=lib/lazy_names.sh
+. "${shelldir}"/lib/lazy_names.sh
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
+# Lazy loading must leave names of FILE unread, or none if "eager" is given.
+check_parity() {
+	local out="${tmpdir}/parity.out"
+	local lazy="[0-9][0-9]* symbols with lazy names"
+
+	if [ "$3" = eager ]; then
+		lazy="no lazy names"
+	fi
+	perf test --dso "$2" -vv "Lazy and eager symbol parity" > "${out}" 2>&1 || true
+	if grep -q ': Ok$' "${out}" && grep -q "^$2: ${lazy}$" "${out}"; then
+		echo "Lazy-load parity $1 [Success]"
+		return
+	fi
+	if [ "$3" != eager ] && grep -q ': Ok$' "${out}" &&
+	   grep -q "^$2: no lazy names$" "${out}" && lazy_names_disabled "$2" "$2.debug"; then
+		echo "Lazy-load parity $1 [Skipped: names load eagerly on this toolchain]"
+		return
+	fi
+	grep -E 'symbols$|names$|mismatch|lookup|no symbols' "${out}" || true
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
+test_dynsym_only
+test_gnu_debugdata
+test_ifunc_alias
+
+cleanup
+exit ${err}
diff --git a/tools/perf/tests/shell/lib/lazy_names.sh b/tools/perf/tests/shell/lib/lazy_names.sh
new file mode 100644
index 000000000000..f16d56c3ac86
--- /dev/null
+++ b/tools/perf/tests/shell/lib/lazy_names.sh
@@ -0,0 +1,19 @@
+# SPDX-License-Identifier: GPL-2.0
+
+# lazy_names_disabled FILE...
+# Return whether one of FILE has a PPC64 ELFv1 .opd, a .gnu_debugdata symbol
+# table or a compressed .strtab, for which perf loads symbol names eagerly.
+lazy_names_disabled() {
+	local f
+
+	command -v readelf > /dev/null || return 1
+	for f in "$@"; do
+		[ -e "${f}" ] || continue
+		if readelf -SW "${f}" 2> /dev/null |
+		   grep -Eq ' \.(opd|gnu_debugdata) | \.strtab +STRTAB( +[0-9a-f]+){4} +[A-Z]*C'
+		then
+			return 0
+		fi
+	done
+	return 1
+}
diff --git a/tools/perf/tests/shell/script_lazy_load_symbols.sh b/tools/perf/tests/shell/script_lazy_load_symbols.sh
new file mode 100755
index 000000000000..76744f84237a
--- /dev/null
+++ b/tools/perf/tests/shell/script_lazy_load_symbols.sh
@@ -0,0 +1,191 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# perf script lazy symbol loading tests (exclusive)
+#
+# Verifies that --lazy-load-symbols matches the default eager loader for a
+# controlled symbol.
+
+set -e
+
+shelldir=$(dirname "$0")
+# shellcheck source=lib/perf_has_symbol.sh
+. "${shelldir}"/lib/perf_has_symbol.sh
+# shellcheck source=lib/lazy_names.sh
+. "${shelldir}"/lib/lazy_names.sh
+
+testsym="test_loop"
+# Printed with -v for each symbol table loaded with lazy names.
+lazy_names=': [1-9][0-9]* \.(symtab|dynsym) symbols with lazy names$'
+
+skip_test_missing_symbol ${testsym}
+
+if ! perf check feature -q libelf
+then
+	echo "Lazy symbol loading [Skipped no libelf support]"
+	exit 2
+fi
+
+perf_path=$(readlink -f "$(command -v perf)")
+err=0
+passed=0
+temp_dir=$(mktemp -d /tmp/__perf_test.lazy_load.XXXXX)
+perfdata="${temp_dir}/perf.data"
+eager_out="${temp_dir}/eager.out"
+lazy_out="${temp_dir}/lazy.out"
+lazy_err="${temp_dir}/lazy.err"
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
+# check_lazy_names CASE
+# Return whether perf was loaded with lazy names. If not, report CASE as
+# skipped when perf's symbol table cannot have them, and as failed otherwise.
+check_lazy_names() {
+	if grep -F "${perf_path}: " "${lazy_err}" | grep -Eq "${lazy_names}"
+	then
+		return 0
+	fi
+	if lazy_names_disabled "${perf_path}"
+	then
+		echo "$1 [Skipped perf loads its symbol names eagerly]"
+	else
+		echo "$1 [Failed perf has no lazy names]"
+		err=1
+	fi
+	return 1
+}
+
+test_lazy_load_identical() {
+	echo "Lazy-load output matches eager loader"
+
+	if ! perf record -o "${perfdata}" -g -- perf test -w thloop 2> /dev/null
+	then
+		echo "Lazy-load identical [Skipped record not supported]"
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
+	# The comparison is only meaningful if something actually resolved;
+	# two all-[unknown] outputs would also match. Without samples in perf,
+	# perf is not loaded and has no lazy names either.
+	if ! grep -q "${testsym}" "${eager_out}"
+	then
+		echo "Lazy-load identical [Skipped no ${testsym} resolved]"
+		return 0
+	fi
+	if ! check_lazy_names "Lazy-load identical"
+	then
+		return
+	fi
+	if ! cmp -s "${eager_out}" "${lazy_out}"
+	then
+		echo "Lazy-load identical [Failed output differs from eager]"
+		err=1
+		return
+	fi
+	echo "Lazy-load identical [Success]"
+	passed=$((passed + 1))
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
+		return 0
+	fi
+
+	if ! perf record -N -o "${nsdata}" -p "${ns_pid}" -- sleep 1 2> /dev/null ||
+	   ! perf --buildid-dir "${buildid_dir}" buildid-cache -a "${perf_path}" \
+		2> /dev/null ||
+	   [ -z "$(ls -A "${buildid_dir}/.build-id" 2> /dev/null)" ]
+	then
+		echo "Lazy-load mount namespace [Skipped record or build-id cache failed]"
+		return 0
+	fi
+	if ! perf --buildid-dir "${buildid_dir}" script -i "${nsdata}" \
+		2> /dev/null > "${eager_out}" ||
+	   ! perf --buildid-dir "${buildid_dir}" script -v --lazy-load-symbols \
+		-i "${nsdata}" 2> "${lazy_err}" > "${lazy_out}"
+	then
+		echo "Lazy-load mount namespace [Failed perf script error]"
+		err=1
+		return
+	fi
+
+	if ! grep -q "${testsym}" "${eager_out}"
+	then
+		echo "Lazy-load mount namespace [Skipped no ${testsym} resolved]"
+		return 0
+	fi
+	if ! check_lazy_names "Lazy-load mount namespace"
+	then
+		return
+	fi
+	if ! cmp -s "${eager_out}" "${lazy_out}"
+	then
+		echo "Lazy-load mount namespace [Failed output differs from eager]"
+		err=1
+		return
+	fi
+	echo "Lazy-load mount namespace [Success]"
+	passed=$((passed + 1))
+}
+
+test_lazy_load_identical
+test_lazy_load_mount_ns
+
+cleanup
+# Report a skip only if no test case ran.
+if [ "${err}" -eq 0 ] && [ "${passed}" -eq 0 ]
+then
+	err=2
+fi
+exit $err
diff --git a/tools/perf/tests/symbol-lazy.c b/tools/perf/tests/symbol-lazy.c
new file mode 100644
index 000000000000..e633debba644
--- /dev/null
+++ b/tools/perf/tests/symbol-lazy.c
@@ -0,0 +1,606 @@
+// SPDX-License-Identifier: GPL-2.0
+#include <elf.h>
+#include <inttypes.h>
+#include <limits.h>
+#include <pthread.h>
+#include <stdbool.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <sys/mman.h>
+#include <unistd.h>
+#include <linux/kernel.h>
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
+static int test__symbol_lazy_choice(struct test_suite *test __maybe_unused,
+				    int subtest __maybe_unused)
+{
+	struct choice_case {
+		u64 len;
+		u8 type, binding;
+		bool needs_names;
+	} cases[] = {
+		{ 0x10, STT_FUNC, STB_GLOBAL, true },
+		{ 0, STT_FUNC, STB_GLOBAL, false },
+		{ 0x10, STT_NOTYPE, STB_GLOBAL, false },
+		{ 0x10, STT_GNU_IFUNC, STB_GLOBAL, true },
+		{ 0x10, STT_FUNC, STB_WEAK, false },
+		{ 0x10, STT_FUNC, STB_LOCAL, false },
+	};
+	struct symbol *a, *b;
+	int ret = TEST_OK;
+	size_t i;
+
+	a = symbol__new(0x1000, 0x10, STB_GLOBAL, STT_FUNC, "a");
+	if (!a)
+		return TEST_FAIL;
+	for (i = 0; i < ARRAY_SIZE(cases) && ret == TEST_OK; i++) {
+		b = symbol__new(0x1000, cases[i].len, cases[i].binding,
+				cases[i].type, "b");
+		if (!b ||
+		    symbol__choice_needs_names(a, b) != cases[i].needs_names ||
+		    symbol__choice_needs_names(b, a) != cases[i].needs_names) {
+			pr_debug("case %zu\n", i);
+			ret = TEST_FAIL;
+		}
+		if (b)
+			symbol__delete(b);
+	}
+	symbol__delete(a);
+	return ret;
+}
+
+#ifdef HAVE_LIBELF_SUPPORT
+#define LAZY_SYM_START	0x1000
+#define LAZY_SYM_SIZE	0x100
+
+struct lazy_fixture {
+	char path[PATH_MAX];
+	struct dso *dso;
+	char **names;
+	size_t nr;
+};
+
+static void lazy_fixture__exit(struct lazy_fixture *f)
+{
+	size_t i;
+
+	dso__put(f->dso);
+	for (i = 0; f->names && i < f->nr; i++)
+		free(f->names[i]);
+	free(f->names);
+	unlink(f->path);
+}
+
+/*
+ * Write @nr names to a file and add a lazy symbol for each to a new DSO,
+ * whose symbol table file is that file. Name i is @len[i] characters long,
+ * or has no terminating NUL before the end of the file if @len[i] is 0.
+ */
+static int lazy_fixture__init(struct lazy_fixture *f, const size_t *len, size_t nr)
+{
+	u64 off = 1;
+	size_t i;
+	FILE *fp;
+	int fd;
+
+	memset(f, 0, sizeof(*f));
+	strlcpy(f->path, "/tmp/perf-test-lazy-names-XXXXXX", sizeof(f->path));
+	fd = mkstemp(f->path);
+	if (fd < 0)
+		return -1;
+	fp = fdopen(fd, "w");
+	if (!fp) {
+		close(fd);
+		unlink(f->path);
+		return -1;
+	}
+	fputc('\0', fp);
+
+	f->names = calloc(nr, sizeof(*f->names));
+	f->dso = dso__new(f->path);
+	if (!f->names || !f->dso)
+		goto out_close;
+	f->nr = nr;
+	dso__set_symtab_type(f->dso, DSO_BINARY_TYPE__SYSTEM_PATH_DSO);
+
+	for (i = 0; i < nr; i++) {
+		size_t n = len[i] ?: 32;
+		struct symbol *sym;
+
+		f->names[i] = malloc(n + 1);
+		if (!f->names[i])
+			goto out_close;
+		for (size_t j = 0; j < n; j++)
+			f->names[i][j] = 'a' + (i + j) % 26;
+		f->names[i][n] = '\0';
+		if (fwrite(f->names[i], 1, n + !!len[i], fp) != n + !!len[i])
+			goto out_close;
+
+		sym = symbol__new_lazy(LAZY_SYM_START + i * LAZY_SYM_SIZE,
+				       LAZY_SYM_SIZE, STB_GLOBAL, STT_FUNC, off);
+		if (!sym)
+			goto out_close;
+		symbols__insert(dso__symbols(f->dso), sym);
+		off += n + !!len[i];
+	}
+	if (fflush(fp) || dso__set_lazy_file(f->dso, fileno(fp)))
+		goto out_close;
+	dso__set_loaded(f->dso);
+	if (fclose(fp)) {
+		lazy_fixture__exit(f);
+		return -1;
+	}
+	return 0;
+
+out_close:
+	fclose(fp);
+	lazy_fixture__exit(f);
+	return -1;
+}
+
+/* Add a lazy symbol at index @i whose name is past the end of the file. */
+static int lazy_fixture__add_unreadable(struct lazy_fixture *f, size_t i)
+{
+	struct symbol *sym = symbol__new_lazy(LAZY_SYM_START + i * LAZY_SYM_SIZE,
+					      LAZY_SYM_SIZE, STB_GLOBAL, STT_FUNC,
+					      1 << 30);
+
+	if (!sym)
+		return -1;
+	symbols__insert(dso__symbols(f->dso), sym);
+	return 0;
+}
+
+static bool lazy_symbol_ok(const struct symbol *sym, const struct lazy_fixture *f,
+			   size_t i)
+{
+	return sym && sym->start == LAZY_SYM_START + i * LAZY_SYM_SIZE &&
+	       !symbol__needs_lazy_name(sym) && !strcmp(sym->name, f->names[i]) &&
+	       sym->namelen == strlen(f->names[i]);
+}
+
+static bool lazy_symbol_unknown(const struct symbol *sym, size_t i)
+{
+	return sym && sym->start == LAZY_SYM_START + i * LAZY_SYM_SIZE &&
+	       !symbol__needs_lazy_name(sym) && !strcmp(sym->name, "[unknown]");
+}
+
+static size_t lazy_nr_symbols(struct dso *dso)
+{
+	struct rb_node *nd;
+	size_t nr = 0;
+
+	for (nd = rb_first_cached(dso__symbols(dso)); nd; nd = rb_next(nd))
+		nr++;
+	return nr;
+}
+
+/*
+ * Names of 10, 300 and 1000 characters, which take one, two and three
+ * reads, a name with no NUL before the end of the file, and an offset past
+ * the end of the file.
+ */
+static int test__symbol_lazy_names(struct test_suite *test __maybe_unused,
+				   int subtest __maybe_unused)
+{
+	static const size_t len[] = { 10, 300, 1000, 0 };
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	struct lazy_fixture f;
+	struct symbol *sym;
+	struct rb_node *nd;
+	int ret = TEST_FAIL;
+	size_t i;
+
+	symbol_conf.lazy_load_symbols = true;
+	if (lazy_fixture__init(&f, len, ARRAY_SIZE(len)))
+		goto out;
+	if (lazy_fixture__add_unreadable(&f, 4))
+		goto out_exit;
+
+	for (i = 0; i < 4; i++) {
+		sym = dso__find_symbol(f.dso, LAZY_SYM_START + i * LAZY_SYM_SIZE + 1);
+		if (!(i < 3 ? lazy_symbol_ok(sym, &f, i) : !sym)) {
+			pr_debug("lookup of name %zu failed\n", i);
+			goto out_exit;
+		}
+	}
+
+	/*
+	 * Sorting by name loads every name, and keeps the symbols whose name
+	 * cannot be read, named "[unknown]". Lookups still do not return them.
+	 */
+	dso__sort_by_name(f.dso);
+	i = 0;
+	dso__for_each_symbol(f.dso, sym, nd) {
+		if (!(i < 3 ? lazy_symbol_ok(sym, &f, i) : lazy_symbol_unknown(sym, i))) {
+			pr_debug("walk of name %zu failed\n", i);
+			goto out_exit;
+		}
+		i++;
+	}
+	if (i != 5)
+		goto out_exit;
+	for (i = 3; i < 5; i++) {
+		if (dso__find_symbol_nocache(f.dso, LAZY_SYM_START + i * LAZY_SYM_SIZE)) {
+			pr_debug("unreadable name %zu was found\n", i);
+			goto out_exit;
+		}
+	}
+	sym = dso__find_symbol_by_name(f.dso, f.names[1], NULL);
+	if (!lazy_symbol_ok(sym, &f, 1))
+		goto out_exit;
+	ret = TEST_OK;
+out_exit:
+	lazy_fixture__exit(&f);
+out:
+	symbol_conf.lazy_load_symbols = saved_lazy;
+	return ret;
+}
+
+/*
+ * After the file is replaced, as a deploy replaces a binary, names must not
+ * be read from the new file, even if it has the same contents. A name loaded
+ * before stays.
+ */
+static int test__symbol_lazy_replaced(struct test_suite *test __maybe_unused,
+				      int subtest __maybe_unused)
+{
+	static const size_t len[] = { 10, 20, 30 };
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	struct lazy_fixture f, new;
+	struct symbol *sym;
+	int ret = TEST_FAIL;
+	size_t i;
+	int err;
+
+	symbol_conf.lazy_load_symbols = true;
+	if (lazy_fixture__init(&f, len, ARRAY_SIZE(len)))
+		goto out;
+	sym = dso__find_symbol(f.dso, LAZY_SYM_START);
+	if (!lazy_symbol_ok(sym, &f, 0) || lazy_fixture__init(&new, len, ARRAY_SIZE(len)))
+		goto out_exit;
+	err = rename(new.path, f.path);
+	lazy_fixture__exit(&new);
+	if (err)
+		goto out_exit;
+	for (i = 1; i < ARRAY_SIZE(len); i++) {
+		sym = dso__find_symbol_nocache(f.dso, LAZY_SYM_START + i * LAZY_SYM_SIZE);
+		if (sym) {
+			pr_debug("name %zu read from the replaced file: %s\n", i, sym->name);
+			goto out_exit;
+		}
+	}
+	sym = dso__find_symbol_nocache(f.dso, LAZY_SYM_START);
+	if (lazy_symbol_ok(sym, &f, 0))
+		ret = TEST_OK;
+out_exit:
+	lazy_fixture__exit(&f);
+out:
+	symbol_conf.lazy_load_symbols = saved_lazy;
+	return ret;
+}
+
+#define NR_RACE_SYMS		256
+#define NR_RACE_UNREADABLE	16
+#define NR_RACE_ALL		(NR_RACE_SYMS + NR_RACE_UNREADABLE)
+#define NR_RACE_THREADS		4
+
+struct lazy_race {
+	struct lazy_fixture *f;
+	int id;
+	bool failed;
+};
+
+/*
+ * Look the symbols up in a different order in each thread. The symbols
+ * after the readable ones have names that cannot be read.
+ */
+static void *lazy_race_lookups(void *data)
+{
+	struct lazy_race *race = data;
+	struct lazy_fixture *f = race->f;
+	size_t i;
+
+	if (race->id == NR_RACE_THREADS - 1) {
+		struct symbol *pos;
+		struct rb_node *nd;
+
+		i = 0;
+		dso__for_each_symbol(f->dso, pos, nd) {
+			if (!(i < f->nr ? lazy_symbol_ok(pos, f, i) : lazy_symbol_unknown(pos, i)))
+				race->failed = true;
+			i++;
+		}
+		return NULL;
+	}
+	for (i = 0; i < NR_RACE_ALL; i++) {
+		size_t k = (i * (2 * race->id + 1) + race->id * 17) % NR_RACE_ALL;
+		struct symbol *sym;
+
+		sym = dso__find_symbol_nocache(f->dso, LAZY_SYM_START + k * LAZY_SYM_SIZE);
+		if (!(k < f->nr ? lazy_symbol_ok(sym, f, k) : !sym))
+			race->failed = true;
+	}
+	return NULL;
+}
+
+static int test__symbol_lazy_race(struct test_suite *test __maybe_unused,
+				  int subtest __maybe_unused)
+{
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	struct lazy_race race[NR_RACE_THREADS];
+	pthread_t threads[NR_RACE_THREADS];
+	size_t len[NR_RACE_SYMS];
+	struct lazy_fixture f;
+	int ret = TEST_FAIL;
+	int i, nr_threads = 0;
+
+	for (i = 0; i < NR_RACE_SYMS; i++)
+		len[i] = 8 + i % 300;
+	symbol_conf.lazy_load_symbols = true;
+	if (lazy_fixture__init(&f, len, NR_RACE_SYMS))
+		goto out;
+	for (i = NR_RACE_SYMS; i < NR_RACE_ALL; i++) {
+		if (lazy_fixture__add_unreadable(&f, i))
+			goto out_exit;
+	}
+
+	for (i = 0; i < NR_RACE_THREADS; i++) {
+		race[i] = (struct lazy_race){ .f = &f, .id = i };
+		if (pthread_create(&threads[i], NULL, lazy_race_lookups, &race[i]))
+			break;
+		nr_threads++;
+	}
+	for (i = 0; i < nr_threads; i++)
+		pthread_join(threads[i], NULL);
+	if (nr_threads != NR_RACE_THREADS)
+		goto out_exit;
+	for (i = 0; i < NR_RACE_THREADS; i++) {
+		if (race[i].failed) {
+			pr_debug("thread %d failed\n", i);
+			goto out_exit;
+		}
+	}
+	if (lazy_nr_symbols(f.dso) != NR_RACE_ALL)
+		goto out_exit;
+	ret = TEST_OK;
+out_exit:
+	lazy_fixture__exit(&f);
+out:
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
+static int check_lazy_lookups(struct map *map, struct map *eager_map,
+			      const struct sym_entry *eager, size_t nr_eager)
+{
+	size_t i;
+	int k;
+
+	for (i = 0; i < nr_eager; i++) {
+		if (eager[i].end <= eager[i].start)
+			continue;
+		for (k = 0; k < 2; k++) {
+			u64 addr = k ? eager[i].end - 1 : eager[i].start;
+			struct symbol *want = map__find_symbol(eager_map, addr);
+			struct symbol *sym = map__find_symbol(map, addr);
+
+			if (!want != !sym ||
+			    (sym && (sym->start != want->start || sym->end != want->end ||
+				     strcmp(sym->name, want->name)))) {
+				pr_debug("lookup %#" PRIx64 ": eager %s, lazy %s\n", addr,
+					 want ? want->name : "[none]",
+					 sym ? sym->name : "[none]");
+				return TEST_FAIL;
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
+struct sym_loader {
+	struct perf_env env;
+	struct machine *machine;
+	struct thread *thread;
+	struct map *map;
+};
+
+static void sym_loader__exit(struct sym_loader *l)
+{
+	map__put(l->map);
+	thread__put(l->thread);
+	machine__delete(l->machine);
+	perf_env__exit(&l->env);
+}
+
+static int sym_loader__init(struct sym_loader *l, const char *filename, bool lazy)
+{
+	struct dso *dso = NULL;
+	bool kernel;
+
+	memset(l, 0, sizeof(*l));
+	perf_env__init(&l->env);
+	symbol_conf.lazy_load_symbols = lazy;
+	l->machine = machine__new_host(&l->env);
+	if (l->machine)
+		l->thread = machine__findnew_thread(l->machine, 100, 100);
+	if (l->thread)
+		dso = machine__findnew_dso(l->machine, filename);
+	/* map__new() cannot map a loaded kernel module, which has no lazy names. */
+	kernel = dso && dso__kernel(dso) != DSO_SPACE__USER;
+	dso__put(dso);
+	if (kernel) {
+		pr_debug("%s: kernel DSO\n", filename);
+		sym_loader__exit(l);
+		return TEST_SKIP;
+	}
+	if (l->thread)
+		l->map = map__new(l->machine, 0x100000, 0xffffffff, 0, &dso_id_empty,
+				  PROT_EXEC, /*flags=*/0, (char *)filename, l->thread);
+	if (!l->map) {
+		sym_loader__exit(l);
+		return TEST_FAIL;
+	}
+	if (dso__load(map__dso(l->map), l->map) <= 0) {
+		pr_debug("%s: no symbols loaded\n", filename);
+		sym_loader__exit(l);
+		return TEST_SKIP;
+	}
+	return TEST_OK;
+}
+
+static int get_sym_entries(struct dso *dso, struct sym_entry **entries_p, size_t *nr_p)
+{
+	struct sym_entry *entries = NULL;
+	size_t nr = 0, alloc = 0;
+	struct symbol *pos;
+	struct rb_node *nd;
+
+	dso__for_each_symbol(dso, pos, nd) {
+		if (nr == alloc) {
+			struct sym_entry *tmp;
+
+			alloc = alloc ? alloc * 2 : 1024;
+			tmp = realloc(entries, alloc * sizeof(*entries));
+			if (!tmp)
+				goto out_free;
+			entries = tmp;
+		}
+		entries[nr].start = pos->start;
+		entries[nr].end = pos->end;
+		entries[nr].name = strdup(pos->name);
+		if (!entries[nr].name)
+			goto out_free;
+		nr++;
+	}
+	qsort(entries, nr, sizeof(*entries), cmp_sym_entry);
+	*entries_p = entries;
+	*nr_p = nr;
+	return 0;
+out_free:
+	free_sym_entries(entries, nr);
+	return -1;
+}
+
+/*
+ * Compare the symbols of a DSO (perf itself, or --dso) loaded eagerly and
+ * lazily. Lazy address lookups must agree with eager ones, and once every
+ * name is loaded, the ranges and names must match.
+ */
+static int test__symbol_lazy_parity(struct test_suite *test __maybe_unused,
+				    int subtest __maybe_unused)
+{
+	bool saved_lazy = symbol_conf.lazy_load_symbols;
+	struct sym_entry *eager = NULL, *lazy = NULL;
+	size_t nr_eager = 0, nr_lazy = 0, nr_names = 0, i;
+	struct sym_loader eager_l, lazy_l;
+	char filename[PATH_MAX];
+	struct symbol *pos;
+	struct rb_node *nd;
+	int ret;
+
+	if (dso_to_test)
+		strlcpy(filename, dso_to_test, sizeof(filename));
+	else
+		perf_exe(filename, sizeof(filename));
+
+	ret = sym_loader__init(&eager_l, filename, false);
+	if (ret != TEST_OK)
+		goto out;
+	ret = sym_loader__init(&lazy_l, filename, true);
+	if (ret != TEST_OK)
+		goto out_eager;
+
+	ret = TEST_FAIL;
+	symbols__for_each_entry(dso__symbols(map__dso(lazy_l.map)), pos, nd)
+		nr_names += symbol__needs_lazy_name(pos);
+	if (nr_names)
+		pr_debug("%s: %zu symbols with lazy names\n", filename, nr_names);
+	else
+		pr_debug("%s: no lazy names\n", filename);
+
+	/* Look up before and after dso__for_each_symbol() loads every name. */
+	if (get_sym_entries(map__dso(eager_l.map), &eager, &nr_eager) ||
+	    check_lazy_lookups(lazy_l.map, eager_l.map, eager, nr_eager) != TEST_OK ||
+	    get_sym_entries(map__dso(lazy_l.map), &lazy, &nr_lazy) ||
+	    check_lazy_lookups(lazy_l.map, eager_l.map, eager, nr_eager) != TEST_OK)
+		goto out_lazy;
+
+	pr_debug("%s: %zu eager and %zu lazy symbols\n", filename, nr_eager, nr_lazy);
+	for (i = 0; i < nr_eager && i < nr_lazy; i++) {
+		if (cmp_sym_entry(&eager[i], &lazy[i])) {
+			pr_debug("mismatch: eager %#" PRIx64 "-%#" PRIx64 " %s, lazy %#"
+				 PRIx64 "-%#" PRIx64 " %s\n",
+				 eager[i].start, eager[i].end, eager[i].name,
+				 lazy[i].start, lazy[i].end, lazy[i].name);
+			goto out_lazy;
+		}
+	}
+	if (nr_eager == nr_lazy)
+		ret = TEST_OK;
+out_lazy:
+	sym_loader__exit(&lazy_l);
+out_eager:
+	sym_loader__exit(&eager_l);
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
+	TEST_CASE("Duplicate selection without names", symbol_lazy_choice),
+#ifdef HAVE_LIBELF_SUPPORT
+	TEST_CASE("Lazy symbol names", symbol_lazy_names),
+	TEST_CASE("Lazy symbol names loaded concurrently", symbol_lazy_race),
+	TEST_CASE("Lazy and eager symbol parity", symbol_lazy_parity),
+	TEST_CASE("Lazy symbol names from a replaced file", symbol_lazy_replaced),
+#endif
+	{ .name = NULL, }
+};
+
+struct test_suite suite__symbol_lazy = {
+	.desc = "Lazy symbol loading",
+	.test_cases = tests__symbol_lazy,
+};
diff --git a/tools/perf/tests/tests.h b/tools/perf/tests/tests.h
index af822885890d..d9e0b5ad92a2 100644
--- a/tools/perf/tests/tests.h
+++ b/tools/perf/tests/tests.h
@@ -199,6 +199,7 @@ DECLARE_SUITE(sigtrap);
 DECLARE_SUITE(event_groups);
 DECLARE_SUITE(hybrid_merge);
 DECLARE_SUITE(symbols);
+DECLARE_SUITE(symbol_lazy);
 DECLARE_SUITE(util);
 DECLARE_SUITE(uncore_event_sorting);
 DECLARE_SUITE(subcmd_help);

-- 
Git-157)

