From: Alireza Haghdoost <haghdoost@uber.com>
Date: Tue, 24 Nov 2026 11:28:28 -0800
Subject: [PATCH v9 5/7] perf report/top: Add --lazy-load-symbols
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-perf-symbol-memory-send-v9-5-56f298185eae@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4380; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=ppNlZ3VOcLClwa+EW9IutebfWNly9+u9DmMSRGXy758=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrBeWGZh4iQF23SP/Y42mypuFVMFz9EAybh/V5y
 hjctM41xl6JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawXlhhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtizlw/+O2YceLqSGMpr4EXoCF1/P86+mBZY3AE
 4c7ar5wUoEjUVE6ghOGrlA+GIEZWtixn6jYxnWVKEIBq+6sB/V9WonqZ0G3O90SMKCKF3PJkG5b
 8mJSS6m9AyqN48PPeQyGyZsUs/FzpH9FQDiDCBCkpPEPvT/8aE6Fv1lhWBB+AYT/53u/53b3nRD
 jFYr+YILHh/EQu/bfUcKLqA8zS/XzE8yClE/0dvX/aUqh0v8hJubeaJl+Ku25GP+99fYi5hSIMB
 MeNFEXdbidsYmbBg1HYmnTB/F2qd2mM4eWSsOaratdB42RmXRBDxySF6Jy/idO6803UXd3U9SDx
 jlQbJTte8r03r3IsBfvFhRw3DnwYkn2KWGnZTvKBN8TlTrxKi6ZOXJkRq2Ixv35rxBFWtF85nz2
 V4TSyegQqUIQzfQvw3Rxilol7g+xS5UHYVcchF5vLaziGpewi2OYLP8zZ4mS1+jfyNh2ZzmkK/0
 Bs8t6AokLhZAL9vlzVqXvcOidEhfe0EhXemVa9tDtppc2HK6l9GKGMpB9rt/atlkXgLXWTfzl7y
 xluLmf7lnp+krOYS+Z2PWKcEFjtNKtpCnJDBWGbr/3DFhjOjJV+L6TKSNppULp1bQeAVN93+MlW
 yb8UIBeE3ek+pcSIEleyVUaVymzz3MF6vHWl634IalBc35mjdz+o=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds the --lazy-load-symbols option of perf script to perf
report and perf top. Like perf script, they load the whole symbol table
of every DSO that appears in a sample and keep every name until exit.

The symbol code already handles both tools. The address lookups that
build the histogram entries and call chains load the names of the
symbols they return, and the TUI map browser gets all names from
dso__named_symbols().

perf top reads the names while it runs, which can be long, so a binary
that is updated in the meantime can show wrong names. The documentation
of perf top says so.

Suggested-by: Namhyung Kim <namhyung@kernel.org>
Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/Documentation/perf-report.txt |  9 +++++++++
 tools/perf/Documentation/perf-top.txt    | 10 ++++++++++
 tools/perf/builtin-report.c              |  2 ++
 tools/perf/builtin-top.c                 |  2 ++
 4 files changed, 23 insertions(+)

diff --git a/tools/perf/Documentation/perf-report.txt b/tools/perf/Documentation/perf-report.txt
index e145124d6c9a..b8c34bb4cd74 100644
--- a/tools/perf/Documentation/perf-report.txt
+++ b/tools/perf/Documentation/perf-report.txt
@@ -347,6 +347,15 @@ OPTIONS
 
 	Default: 127
 
+--lazy-load-symbols::
+	Read and demangle userspace ELF symbol names only when perf needs
+	them. By default, perf reads every symbol name from each binary
+	referenced by a sample. This option reduces memory use when samples
+	reference only a small fraction of a large binary's symbols. The
+	names are read from the binaries while perf report runs, so the
+	binaries must not change in the meantime. If a binary cannot be
+	opened when a name is needed, perf shows that symbol as unknown.
+
 -G::
 --inverted::
         alias for inverted caller based call graph.
diff --git a/tools/perf/Documentation/perf-top.txt b/tools/perf/Documentation/perf-top.txt
index c5e96da6ed82..9ec039c8e0b9 100644
--- a/tools/perf/Documentation/perf-top.txt
+++ b/tools/perf/Documentation/perf-top.txt
@@ -218,6 +218,16 @@ Default is to monitor all CPUS.
 
 	Default: /proc/sys/kernel/perf_event_max_stack when present, 127 otherwise.
 
+--lazy-load-symbols::
+	Read and demangle userspace ELF symbol names only when perf needs
+	them. By default, perf reads every symbol name from each binary
+	referenced by a sample. This option reduces memory use when samples
+	reference only a small fraction of a large binary's symbols. The
+	names are read from the binaries while perf top runs, so a binary
+	that is updated in the meantime can show wrong names. If a binary
+	cannot be opened when a name is needed, perf shows that symbol as
+	unknown.
+
 --ignore-callees=<regex>::
         Ignore callees of the function(s) matching the given regex.
         This has the effect of collecting the callers of each such
diff --git a/tools/perf/builtin-report.c b/tools/perf/builtin-report.c
index 6672a4d16529..8ca54463a84b 100644
--- a/tools/perf/builtin-report.c
+++ b/tools/perf/builtin-report.c
@@ -1414,6 +1414,8 @@ int cmd_report(int argc, const char **argv)
 		    "Set the maximum stack depth when parsing the callchain, "
 		    "anything beyond the specified depth will be ignored. "
 		    "Default: kernel.perf_event_max_stack or " __stringify(PERF_MAX_STACK_DEPTH)),
+	OPT_BOOLEAN(0, "lazy-load-symbols", &symbol_conf.lazy_load_symbols,
+		    "Read symbol names only when they are needed"),
 	OPT_BOOLEAN('G', "inverted", &report.inverted_callchain,
 		    "alias for inverted call graph"),
 	OPT_CALLBACK(0, "ignore-callees", NULL, "regex",
diff --git a/tools/perf/builtin-top.c b/tools/perf/builtin-top.c
index a79230b81300..02363e5c6460 100644
--- a/tools/perf/builtin-top.c
+++ b/tools/perf/builtin-top.c
@@ -1589,6 +1589,8 @@ int cmd_top(int argc, const char **argv)
 	OPT_INTEGER(0, "max-stack", &top.max_stack,
 		    "Set the maximum stack depth when parsing the callchain. "
 		    "Default: kernel.perf_event_max_stack or " __stringify(PERF_MAX_STACK_DEPTH)),
+	OPT_BOOLEAN(0, "lazy-load-symbols", &symbol_conf.lazy_load_symbols,
+		    "Read symbol names only when they are needed"),
 	OPT_CALLBACK(0, "ignore-callees", NULL, "regex",
 		   "ignore callees of these functions in call graphs",
 		   report_parse_ignore_callees_opt),

-- 
Git-157)

