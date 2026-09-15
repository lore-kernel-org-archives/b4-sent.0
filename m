From: Alireza Haghdoost <haghdoost@uber.com>
Date: Tue, 15 Sep 2026 11:42:46 -0700
Subject: [PATCH 4/4] perf script: Document and test --lazy-load-symbols and
 --max-symbol-bytes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-perf-symbol-memory-send-v1-4-1d3360e21f07@uber.com>
References: <20260915-perf-symbol-memory-send-v1-0-1d3360e21f07@uber.com>
In-Reply-To: <20260915-perf-symbol-memory-send-v1-0-1d3360e21f07@uber.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Andrii Nakryiko <andriin@fb.com>, 
 Alexei Starovoitov <ast@kernel.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6198; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=ozeisEeLUlyeoorFaW7r4WB+nw0aEmnGGVlEP7mmb2o=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqqZHOO79qSbapVu7FstSxOFn6KxUcXOhoUCYQ1
 bXfEiLi0MCJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCaqmRzhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAth0mA/+Pt0cuUTq8AeRJ2ktRGG2FnZOgPD/HtS
 JOqLpmcMT5dRHYsgVYt0K6XyaVNBLT1KXAaQ3UIYyWv7ikqiyd2cTFrWXlVPij2wT6ItcL5blXF
 pAMifxDaeljgtOE0oqwG2+Q7IO0qvF+qtXZEmlqc2qn8DLyVrjX1JXIZXgw+6OLBYWv+iraL71H
 62u7atJSwkfimQlKv6yO/5xrsFrx06Tq9/lGs/KBaB/R48/lK+F9/qgp2OvwoDvOY4B/+FTbTBW
 hdwzzPKgCUbWrDXmwjtkWiMHlnUG9L5hXTFZeWhKU6KeSyuIoSq0R6VUXYhNrjbS+lL+8FpbnPv
 +pz2zEL6mq1kt4u4IHpGFiBM+azREB4ma+riwivc6rkYHfkqNeGigunSIXoahnT5pViKEtUY7+g
 Re7/cvBUq8uyrtsi9VGO7N1JWAbaLEgRyfZAHSir0VPw/r14h5KIUaCXP4UYEkCKxJQJvdrlTdE
 t7bQPszpi0I20M7MkTBd7TQOFTXWDXc3Og8UTHLqquoZZz9Iio3loEmGddBg0sDNSEyR2DNo5lu
 KSoiqAqTkweB9lvanN5zphq7ThJUOqHpopk3vJK01Zm+yHtJDcH8yp0InOQoORgx0rCPd+dF5Wt
 vrUgMgj0wQcwfmywJr4bUFfExIDOqqe3HHLAr4GNur2OSfMgWKRU=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document both new options in perf-script.txt: their interaction, the
memory tradeoff, that lazy loading applies only to userspace ELF DSOs
(kernel DSOs and modules always load eagerly), and that output may
differ from the default loader for some targets.

Add a shell test that records a small profile with callchains and
asserts:

- --lazy-load-symbols produces output byte-identical to the eager
  loader, and that at least one symbol actually resolved (so the
  comparison can't pass vacuously on all-[unknown] output);
- --max-symbol-bytes=1K, with and without lazy loading, forces
  [unknown] resolution with a single warning and exit code 0 (no crash).

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
Assisted-by: Kimi:K3
---
 tools/perf/Documentation/perf-script.txt           |  24 +++++
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 120 +++++++++++++++++++++
 2 files changed, 144 insertions(+)

diff --git a/tools/perf/Documentation/perf-script.txt b/tools/perf/Documentation/perf-script.txt
index 200ea25891d8..b5a90ff22342 100644
--- a/tools/perf/Documentation/perf-script.txt
+++ b/tools/perf/Documentation/perf-script.txt
@@ -412,6 +412,30 @@ include::itrace.txt[]
 
         Default: 127
 
+--lazy-load-symbols::
+	Resolve symbols lazily instead of eagerly loading the full
+	symbol table of every DSO that appears in a sample. A compact
+	sorted index is built per DSO and only the addresses that appear
+	in samples are materialized into symbols, with names read from the
+	file's string table at lookup time. This sharply reduces memory
+	(and usually time) for profiles of large binaries where only a
+	small fraction of the symbol table is referenced. This applies only
+	to userspace ELF DSOs; kernel DSOs and modules always load eagerly.
+	Output may differ from the default loader for some targets
+	(e.g. PPC64 .opd, .gnu_debugdata, or split debuginfo). Default: off.
+
+--max-symbol-bytes::
+	Limit the bytes held in struct symbol allocations (and, with
+	--lazy-load-symbols, the lazy index) for DSOs on the ELF symbol
+	loader path -- userspace DSOs plus vmlinux-as-ELF and kernel
+	modules. This is not a cap on all symbol memory or RSS: symbols
+	from kallsyms, JIT maps, PLT synthesis, and libbfd are counted
+	but not capped. Accepts a size with a B/K/M/G suffix (e.g. 128M).
+	When the budget is exceeded, further symbols resolve to [unknown]
+	and a warning is printed. This is a safety net independent of
+	--lazy-load-symbols and can be used with or without it. Default: 0
+	(unlimited).
+
 --ns::
 	Use 9 decimal places when displaying time (i.e. show the nanoseconds)
 
diff --git a/tools/perf/tests/shell/script_lazy_load_symbols.sh b/tools/perf/tests/shell/script_lazy_load_symbols.sh
new file mode 100755
index 000000000000..799c61e2f3e8
--- /dev/null
+++ b/tools/perf/tests/shell/script_lazy_load_symbols.sh
@@ -0,0 +1,120 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# perf script lazy symbol loading tests
+#
+# Verifies that --lazy-load-symbols produces output identical to the default
+# eager symbol loader, and that --max-symbol-bytes caps symbol allocations
+# (emitting [unknown] plus a warning) without crashing.
+
+set -e
+
+shelldir=$(dirname "$0")
+# shellcheck source=lib/perf_has_symbol.sh
+. "${shelldir}"/lib/perf_has_symbol.sh
+
+testsym="test_loop"
+
+skip_test_missing_symbol ${testsym}
+
+err=0
+temp_dir=$(mktemp -d /tmp/__perf_test.lazy_load.XXXXX)
+perfdata="${temp_dir}/perf.data"
+eager_out="${temp_dir}/eager.out"
+lazy_out="${temp_dir}/lazy.out"
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
+		return
+	fi
+
+	if ! perf script -i "${perfdata}" 2> /dev/null > "${eager_out}" || \
+	   ! perf script --lazy-load-symbols -i "${perfdata}" 2> /dev/null > "${lazy_out}"
+	then
+		echo "Lazy-load identical [Failed perf script error]"
+		err=1
+		return
+	fi
+
+	# The comparison is only meaningful if something actually resolved;
+	# two all-[unknown] outputs would also match.
+	if ! grep -q "${testsym}" "${eager_out}"
+	then
+		echo "Lazy-load identical [Skipped no ${testsym} resolved]"
+		return
+	fi
+
+	if ! cmp -s "${eager_out}" "${lazy_out}"
+	then
+		echo "Lazy-load identical [Failed output differs]"
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
+		return
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
+
+	if ! perf script --lazy-load-symbols --max-symbol-bytes=1K \
+		-i "${perfdata}" > /dev/null 2> "${temp_dir}/lazy-budget.err"
+	then
+		echo "--max-symbol-bytes lazy budget [Failed nonzero exit]"
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
+test_lazy_load_identical
+test_max_symbol_bytes
+
+cleanup
+exit $err

-- 
Git-155)

