From: Alireza Haghdoost <haghdoost@uber.com>
Date: Tue, 24 Nov 2026 11:28:30 -0800
Subject: [PATCH v9 7/7] perf test: Add lazy symbol loading shell tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-perf-symbol-memory-send-v9-7-56f298185eae@uber.com>
References: <20261124-perf-symbol-memory-send-v9-0-56f298185eae@uber.com>
In-Reply-To: <20261124-perf-symbol-memory-send-v9-0-56f298185eae@uber.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=24854; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=IJ/HFohuOMOgLqBpJ/fdyEkNFF8fh+D1ReEAoBm3ZQ8=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrBeWGW2G1eTVIDSY2q8vV/XErX34TWjRl4t9Al
 /+ZGTQ8/J+JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawXlhhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtj7rw//SHiUn/4gp4QX8q4oMyHwtfKP5cKekbV
 N3/1xhJQ0bOOxuvxW8aM0srqKnt1MNopvU/AXXmDFLGSOZecUBCRTDP+5WKR04hj834DlrydnS3
 5A96COnDGzUo/8KKweUOGJnZXDlYsx/3GoR/D3bnrUwGSRyW9eA6I3zkRd3iGUjOlcs5BdWoXs6
 5nQQ+chHEpjwl/s1Tfmf6NJuJZxn2F2CAQlvrMLjRWaqLSaT/lWQVmcobBbYfxFpDTl9pJJaqih
 6zQtf7T9/eSsVbCeiyJ8mK/7qwema8Z3QD3sci9qR+rm1Dk3OkENiH3lO8kQPJgQmJfbna7H4mv
 zWShS4PjMerH1vfFBFANzy8KTY4QS9HVaRv/T6AlmxtmXhEuxx5ugzzgmmcSyXGHrxazZ85gnw+
 Xo48NtAZg7TDoZ7yfvgLtU0XgL2fWGO+qFctConGBw3D/i3ZA6Kago/kNz2WcdYV716rTJGgd7c
 lHKDNp+38jzx++Cz67NPR+/6rLdWZwKZl0sOqKfyug/J9HdzpXDAjmfoUaMdzXcIbjFlGlxBqGI
 ir0hM6eSVtmc0RgUaRKgjTHP9Olg2ISkeUB11g8cT3+qT7cqhOKfGeP33Ocuz9NEcrxofnkcRnO
 OLvsP7eGYQ8IzhNavt2MSx+wo6dmCpKPXVzEvvL+oDrRWy/+YET8=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lazy_load_symbols_parity.sh runs the lazy and eager parity unit test on
seven small binaries built for the loader's corner cases: split
debuginfo whose function section is NOBITS in the debug file, a shared
library with .dynsym-only symbols and aliases, a stripped library with
.gnu_debugdata, and on x86_64 an IFUNC behind an IRELATIVE PLT slot, the
same with the IFUNC and its aliases exported, an exported function
followed in .symtab by a zero-size label at its address, and exported
functions with nested entry points.

lazy_load_symbols.sh records a small callchain profile and checks that
perf script and perf report, with and without call graphs, print the
same output with and without --lazy-load-symbols. As root, it also
compares perf script output for a process in another mount namespace,
with the binary added to the build-id cache.

Both tests skip a case, rather than fail it, when the toolchain produced
a file whose names perf loads eagerly anyway (PPC64 ELFv1 .opd,
.gnu_debugdata or a compressed .strtab).

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/tests/shell/lazy_load_symbols.sh        | 243 +++++++++++
 tools/perf/tests/shell/lazy_load_symbols_parity.sh | 462 +++++++++++++++++++++
 tools/perf/tests/shell/lib/lazy_names.sh           |  20 +
 3 files changed, 725 insertions(+)

diff --git a/tools/perf/tests/shell/lazy_load_symbols.sh b/tools/perf/tests/shell/lazy_load_symbols.sh
new file mode 100755
index 000000000000..19f0b3c0e9f1
--- /dev/null
+++ b/tools/perf/tests/shell/lazy_load_symbols.sh
@@ -0,0 +1,243 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Lazy symbol loading tests (exclusive)
+#
+# Verifies that perf script and perf report print the same output with
+# --lazy-load-symbols as with the default eager loader.
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
+# Printed with -vv for each symbol table loaded with lazy names.
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
+	if ! command -v readelf > /dev/null
+	then
+		echo "$1 [Skipped no readelf to check perf's symbol table]"
+	elif lazy_names_disabled "${perf_path}"
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
+	if ! perf script -vv -i "${perfdata}" 2> /dev/null > "${eager_out}" || \
+	   ! perf script -vv --lazy-load-symbols -i "${perfdata}" \
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
+	if ! cmp -s "${eager_out}" "${lazy_out}"
+	then
+		echo "Lazy-load identical [Failed output differs from eager]"
+		err=1
+		return
+	fi
+	if ! check_lazy_names "Lazy-load identical"
+	then
+		return
+	fi
+	echo "Lazy-load identical [Success]"
+	passed=$((passed + 1))
+}
+
+test_lazy_load_report() {
+	local eager_report="${temp_dir}/eager.report"
+	local lazy_report="${temp_dir}/lazy.report"
+	local mode
+
+	echo "Lazy-load perf report output matches eager loader"
+
+	if ! grep -qs "${testsym}" "${eager_out}"
+	then
+		echo "Lazy-load report [Skipped no ${testsym} resolved]"
+		return 0
+	fi
+	for mode in "--no-children -g none" "--children"
+	do
+		# shellcheck disable=SC2086
+		if ! perf report -vv --stdio ${mode} -i "${perfdata}" \
+			2> /dev/null > "${eager_report}" ||
+		   ! perf report -vv --stdio ${mode} --lazy-load-symbols \
+			-i "${perfdata}" 2> "${lazy_err}" > "${lazy_report}"
+		then
+			echo "Lazy-load report [Failed perf report ${mode} error]"
+			err=1
+			return
+		fi
+		# -q would turn off the debug output, so drop the header,
+		# which has a random tip.
+		if ! cmp -s <(grep -v '^#' "${eager_report}") \
+			    <(grep -v '^#' "${lazy_report}")
+		then
+			echo "Lazy-load report [Failed ${mode} output differs from eager]"
+			err=1
+			return
+		fi
+		if ! check_lazy_names "Lazy-load report"
+		then
+			return
+		fi
+	done
+	echo "Lazy-load report [Success]"
+	passed=$((passed + 1))
+}
+
+# perf script output for a process in another mount namespace, with the
+# binary in the build-id cache, must not change with lazy names.
+test_lazy_load_mount_ns() {
+	echo "Lazy-load parity for a process in another mount namespace"
+
+	if [ "$(id -u)" != 0 ] || ! command -v unshare > /dev/null
+	then
+		echo "Lazy-load mount namespace [Skipped needs root and unshare]"
+		return 0
+	fi
+
+	local buildid_dir="${temp_dir}/buildid"
+	local nsdata="${temp_dir}/ns.data"
+
+	# The workload sees an empty build-id cache; perf sees the real one.
+	mkdir -p "${buildid_dir}"
+	unshare -m --propagation private sh -c \
+		"mount -t tmpfs none '${buildid_dir}' && exec perf test -w thloop 30" &
+	ns_pid=$!
+	for _ in $(seq 50)
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
+	if ! perf --buildid-dir "${buildid_dir}" script -vv -i "${nsdata}" \
+		2> /dev/null > "${eager_out}" ||
+	   ! perf --buildid-dir "${buildid_dir}" script -vv --lazy-load-symbols \
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
+	if ! cmp -s "${eager_out}" "${lazy_out}"
+	then
+		echo "Lazy-load mount namespace [Failed output differs from eager]"
+		err=1
+		return
+	fi
+	# For a process in another mount namespace, only a symbol table from
+	# the build-id cache (origin B or D in perf report -v) has lazy names.
+	if ! perf --buildid-dir "${buildid_dir}" report -v --stdio --sort sym \
+		-i "${nsdata}" 2> /dev/null | grep -Eq " [BD] \[\.\] ${testsym}( |$)"
+	then
+		echo "Lazy-load mount namespace [Skipped perf symbols not from the build-id cache]"
+		return 0
+	fi
+	if ! check_lazy_names "Lazy-load mount namespace"
+	then
+		return
+	fi
+	echo "Lazy-load mount namespace [Success]"
+	passed=$((passed + 1))
+}
+
+test_lazy_load_identical
+test_lazy_load_report
+test_lazy_load_mount_ns
+
+cleanup
+if [ "${err}" -eq 0 ] && [ "${passed}" -eq 0 ]
+then
+	err=2
+fi
+exit $err
diff --git a/tools/perf/tests/shell/lazy_load_symbols_parity.sh b/tools/perf/tests/shell/lazy_load_symbols_parity.sh
new file mode 100755
index 000000000000..a55a73560db2
--- /dev/null
+++ b/tools/perf/tests/shell/lazy_load_symbols_parity.sh
@@ -0,0 +1,462 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Lazy symbol loading parity with eager loading
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
+#    to an alias that loses to another one in turn;
+#  - on x86_64, an exported function followed in .symtab by a zero-size
+#    label at its address;
+#  - on x86_64, a shared library of exported functions with nested entry
+#    points, where lazy and eager lookups past the end of each inner one
+#    must agree;
+#  - on x86_64, an IRELATIVE PLT slot whose IFUNC and its aliases are
+#    exported, so that the .dynsym copy of the IFUNC passes on its mark.
+
+set -e
+export LC_ALL=C
+
+shelldir=$(dirname "$0")
+# shellcheck source=lib/lazy_names.sh
+. "${shelldir}"/lib/lazy_names.sh
+
+err=0
+passed=0
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
+		passed=$((passed + 1))
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
+	if ! objcopy --only-keep-debug "${prog}" "${prog}.debug" ||
+	   ! strip -s "${prog}" ||
+	   ! objcopy --add-gnu-debuglink="${prog}.debug" "${prog}"; then
+		echo "Lazy-load parity split debuginfo [Skipped: cannot split]"
+		return
+	fi
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
+	if ! objcopy --strip-symbol=dyn_only --strip-symbol=dyn_and_symtab_alias \
+		"${lib}"; then
+		echo "Lazy-load parity .dynsym-only symbol [Skipped: cannot strip]"
+		return
+	fi
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
+test_dynsym_copy_zero_size() {
+	local prog="${tmpdir}/zero"
+	local order
+
+	if [ "$(uname -m)" != x86_64 ]; then
+		echo "Lazy-load parity zero-size label [Skipped: x86_64 only]"
+		return
+	fi
+	# If end fixup gave the label a size, its longer name would win
+	# duplicate selection over the function.
+	cat > "${prog}.S" << EOF
+	.text
+	.globl	lazy_sized
+	.type	lazy_sized, @function
+lazy_sized:
+	.globl	lazy_sized_label
+	.type	lazy_sized_label, @function
+lazy_sized_label:
+	nop
+	ret
+	.size	lazy_sized, .-lazy_sized
+	.p2align 4
+	.globl	main
+	.type	main, @function
+main:
+	call	lazy_sized
+	xor	%eax, %eax
+	ret
+	.size	main, .-main
+	.section .note.GNU-stack,"",@progbits
+EOF
+	if ! cc -o "${prog}" "${prog}.S" \
+		-Wl,--export-dynamic-symbol=lazy_sized 2> /dev/null ||
+	   ! readelf --dyn-syms -W "${prog}" | grep -qw lazy_sized ||
+	   readelf --dyn-syms -W "${prog}" | grep -qw lazy_sized_label; then
+		echo "Lazy-load parity zero-size label [Skipped: cannot build]"
+		return
+	fi
+	# The label must follow the function in .symtab.
+	order=$(readelf -sW "${prog}" | \
+		awk '/\.symtab/ { s = 1 } s && $8 ~ /^lazy_sized(_label)?$/ { printf "%s ", $8 }')
+	if [ "${order}" != "lazy_sized lazy_sized_label " ]; then
+		echo "Lazy-load parity zero-size label [Skipped: unexpected symbol order]"
+		return
+	fi
+	check_parity "zero-size label" "${prog}"
+}
+
+test_nested_entry() {
+	local lib="${tmpdir}/libnested.so"
+	local i
+
+	if [ "$(uname -m)" != x86_64 ]; then
+		echo "Lazy-load parity nested entry [Skipped: x86_64 only]"
+		return
+	fi
+	# Lookups past the end of each inner entry point must agree. Every
+	# exported function has its name read for duplicate selection, so the
+	# local function keeps a name unread.
+	{
+		echo "	.text"
+		echo "	.type	lazy_local, @function"
+		echo "lazy_local:"
+		echo "	ret"
+		echo "	.size	lazy_local, .-lazy_local"
+		for i in 0 1 2; do
+			echo "	.globl	lazy_pad_${i}"
+			echo "	.type	lazy_pad_${i}, @function"
+			echo "lazy_pad_${i}:"
+			echo "	ret"
+			echo "	.size	lazy_pad_${i}, .-lazy_pad_${i}"
+		done
+		for i in 0 1 2 3 4 5 6; do
+			echo "	.globl	lazy_outer_${i}, lazy_inner_${i}"
+			echo "	.type	lazy_outer_${i}, @function"
+			echo "	.type	lazy_inner_${i}, @function"
+			echo "lazy_outer_${i}:"
+			echo "	nop"
+			echo "lazy_inner_${i}:"
+			echo "	nop"
+			echo "	.size	lazy_inner_${i}, .-lazy_inner_${i}"
+			echo "	ret"
+			echo "	.size	lazy_outer_${i}, .-lazy_outer_${i}"
+		done
+		echo '	.section .note.GNU-stack,"",@progbits'
+	} > "${tmpdir}/nested.S"
+	if ! cc -shared -nostdlib -o "${lib}" "${tmpdir}/nested.S" 2> /dev/null ||
+	   ! readelf --dyn-syms -W "${lib}" | grep -qw lazy_outer_0; then
+		echo "Lazy-load parity nested entry [Skipped: cannot build]"
+		return
+	fi
+	check_parity "nested entry" "${lib}"
+}
+
+test_exported_ifunc_alias() {
+	local lib="${tmpdir}/libifunc.so"
+
+	if [ "$(uname -m)" != x86_64 ]; then
+		echo "Lazy-load parity exported IFUNC alias [Skipped: x86_64 only]"
+		return
+	fi
+	# At the resolver's address, lazy_exp_ifunc_y wins duplicate selection
+	# over __lazy_exp_ifunc and _lazy_exp_ifunc_x, and an alias that lost
+	# after it took the IFUNC mark does not pass the mark on. The PLT slot
+	# of the local IFUNC __lazy_exp_call is named after lazy_exp_ifunc_y
+	# only if the .dynsym copy of __lazy_exp_ifunc marks it.
+	cat > "${tmpdir}/libifunc.c" << EOF
+static int impl(void)
+{
+	return 42;
+}
+
+__attribute__((used, noinline)) static void *lazy_exp_resolver(void)
+{
+	return (void *)impl;
+}
+
+asm(".globl __lazy_exp_ifunc, _lazy_exp_ifunc_x, lazy_exp_ifunc_y\n"
+    ".type __lazy_exp_ifunc, @gnu_indirect_function\n"
+    ".set __lazy_exp_ifunc, lazy_exp_resolver\n"
+    ".size __lazy_exp_ifunc, 1\n"
+    ".type _lazy_exp_ifunc_x, @function\n"
+    ".set _lazy_exp_ifunc_x, lazy_exp_resolver\n"
+    ".size _lazy_exp_ifunc_x, 1\n"
+    ".type lazy_exp_ifunc_y, @function\n"
+    ".set lazy_exp_ifunc_y, lazy_exp_resolver\n"
+    ".size lazy_exp_ifunc_y, 1\n");
+asm(".local __lazy_exp_call\n"
+    ".type __lazy_exp_call, @gnu_indirect_function\n"
+    ".set __lazy_exp_call, lazy_exp_resolver\n");
+
+int __lazy_exp_call(void);
+
+int lazy_exp_main(void)
+{
+	return __lazy_exp_call();
+}
+EOF
+	if ! cc -O1 -shared -fPIC -o "${lib}" "${tmpdir}/libifunc.c" 2> /dev/null ||
+	   ! readelf -rW "${lib}" | grep -q R_X86_64_IRELATIVE ||
+	   ! readelf --dyn-syms -W "${lib}" | grep -q 'IFUNC .* __lazy_exp_ifunc$'; then
+		echo "Lazy-load parity exported IFUNC alias [Skipped: cannot build]"
+		return
+	fi
+	check_parity "exported IFUNC alias" "${lib}"
+}
+
+test_split_debug
+test_dynsym_only
+test_gnu_debugdata
+test_ifunc_alias
+test_dynsym_copy_zero_size
+test_nested_entry
+test_exported_ifunc_alias
+
+cleanup
+if [ "${err}" -eq 0 ] && [ "${passed}" -eq 0 ]; then
+	err=2
+fi
+exit ${err}
diff --git a/tools/perf/tests/shell/lib/lazy_names.sh b/tools/perf/tests/shell/lib/lazy_names.sh
new file mode 100644
index 000000000000..0358a039b4d2
--- /dev/null
+++ b/tools/perf/tests/shell/lib/lazy_names.sh
@@ -0,0 +1,20 @@
+#!/bin/bash
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

-- 
Git-157)

