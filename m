From: Alireza Haghdoost <haghdoost@uber.com>
Date: Sat, 19 Sep 2026 19:33:59 -0700
Subject: [PATCH v2 4/4] perf test: Test lazy symbol loading and symbol
 memory limits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-perf-symbol-memory-send-v2-4-495b8f00ad7c@uber.com>
References: <20260919-perf-symbol-memory-send-v2-0-495b8f00ad7c@uber.com>
In-Reply-To: <20260919-perf-symbol-memory-send-v2-0-495b8f00ad7c@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=12656; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=FHwdij3JAUd6sWksHc6Bee53/mbFuKWZXUTNqN4o0n0=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqr0Y4pOLzWKOSXtxuTKXzVN6uWYDVyAMpjXaoR
 x/w08pB4D6JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCaq9GOBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthQqA//amo4LdKmAdSEWwtTJxTpy8OIw+diTme
 c61XgyXDh5EPuHm72HvxozcVFLAaLgfrwgChq+OdnoYcqWxIq97WECN6aFcErglpVIhaQa9BWrR
 6g3677Dv8v2iYlON9jda21zSvXSHw13b6VIIbLG2vsApF429qWXj4wmm8880DtPWgjE+N7ryfhv
 dlk6Y1vQy2MCpaSuNL5DA07NJq1FxK7FADAWlM6A1Jhtnr6DzAm7g06raisQC28oMC34qu9XusJ
 uLo4fBEpN5MEwpSQ4un4BsH391IUpgIgC5tbmRsuEsFL3MdFjoGTv8DnWZ1HqEE6alhwP1pibsz
 MGsU9IJA3h97IZuwa1hejDHYqPaxjoE3MP5jgELfUUfHBIpXGJQIxxv8rPViXixAb/z24vwwbuS
 s7hCT3RB9cXWfrmK6bTgpg0cpEyqyB1plvOQxLezkfFK164ZLD4+kfbmHDQ0KFtxpNIX115cNL8
 myzmWpxHk2nKeWKHh27dUT9Zyi6F0UL/U03IlGWvI3NGUM9BrtDDTM5nkgxiVM9JpsvuehRvk+1
 jXhgx4KfyWmLHSc5OgTBBZ0CyM+fpJve4k93JNHsTg5yO4KgpXAcIJL7EKy4AS2gZkDNnt4tRTS
 RWY/Ld3ORFHgLQxhHpMsPDZ62xv4yjSNUBa8LRdm/Cz5tbxL+6oA=
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
failure. Keep helper returns safe under set -e. Add focused coverage for
skip-status preservation and truncated string-table reads in the lazy
materialization path.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 278 +++++++++++++++++++++
 .../tests/shell/script_lazy_load_symbols_skip.sh   |  26 ++
 tools/perf/tests/symbol-bytes.c                    |  58 +++++
 3 files changed, 362 insertions(+)

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
index e5e2e6b9db97..0c9424fe4d1c 100644
--- a/tools/perf/tests/symbol-bytes.c
+++ b/tools/perf/tests/symbol-bytes.c
@@ -172,6 +172,63 @@ static int test__symbol_bytes_duplicate_selection(struct test_suite *test __mayb
 }
 
 #ifdef HAVE_LIBELF_SUPPORT
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
 static int test__symbol_bytes_lazy_name_lookup(struct test_suite *test __maybe_unused,
 					       int subtest __maybe_unused)
 {
@@ -271,6 +328,7 @@ static struct test_case tests__symbol_bytes[] = {
 	TEST_CASE("Concurrent strict reservations", symbol_bytes_reservation),
 	TEST_CASE("Shared duplicate selection", symbol_bytes_duplicate_selection),
 #ifdef HAVE_LIBELF_SUPPORT
+	TEST_CASE("Truncated lazy symbol names", symbol_bytes_truncated_name),
 	TEST_CASE("Lazy address and name lookup", symbol_bytes_lazy_name_lookup),
 #endif
 	{ .name = NULL, }

-- 
Git-157)

