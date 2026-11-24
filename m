From: Alireza Haghdoost <haghdoost@uber.com>
Date: Tue, 24 Nov 2026 11:28:25 -0800
Subject: [PATCH v9 2/7] perf symbols: Point to the symbol name instead of
 embedding it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-perf-symbol-memory-send-v9-2-56f298185eae@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2133; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=hjmLft94/FwnngU1dtok/b0G4S8C46g9Nqo2+F/0V0Q=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrBeWEUjAKuepLsRNdrYPGyY1QfqA+oD+U/ZNAv
 VVit144baGJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawXlhBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthltg//c5ZN+p7t+CGUbFgeRGXAoBm968Rlw+y
 zCwHkM2Izoj4oRsGO/pEkJQnBJ9mQ5vut6buuhjXim6GI9fVpQRzUIJuzGhC6kt+XT+xmpd9VUx
 p0F9YvMk9Sqfe5e1tnqlYRlBjuYAIG+iDUkZJnrj9A6/EKxbmxGU3DJBeEzIvuEe4T3LgixlDUx
 X1a8hYsS1fRkGY38HDuMQV96MtBt7WsBmnIsllHDv6RqxsIZoHSM6i5ZETP0z/R8aDBwYH3LDYz
 r76eUuJw2jpBL/273LAfMNSVWlupoz9+fsHbYmnUNp3OYm7Tecnt/5chdDUvRAnQD4L1J9RrbQw
 Cg/AN/JBOtlfN+YtedMapFEXLQTpZvkSUystnqCUiqsgtwRvF0GnFMZa8QFdK9NOTxUPjgMvOsg
 eV4HRCJ4fFlNayr2DuvYSqlpHby0SEZzRony8c2ofUIBrhcAYzpTYiN7sAUWu6gdoKLrWD6T4ui
 cAlQvhCbcjEY4ZDN8AZEGTWCKxpQyaWHGPkSYp3P6KL4/lXtaTgZF++mzJl3yQNkHAVth9T7s7O
 a4VdJN+zQwT3grEgw6cJmKb19z7tBqap0nIfHDzjN3ceGzU0x2fv6OETMm6jCX1x/TlB0h91mH3
 7xOQEAeR3vNr+XSd8SJ8B6OQQuKY0L+HNcWOBb0Ho2lJs3rV/xGc=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch changes the name field of struct symbol from a flexible
array (char name[]) to a pointer (char *name). It does not change
behavior, but each symbol allocation grows by 8 bytes on 64-bit hosts.

The next patch creates symbols whose names are read only when needed.
perf does not know the length of such a name when it creates the symbol,
so it cannot allocate the name after the symbol. It cannot reallocate
the symbol later either, because the symbol array and the callers hold
pointers to it. With a pointer, the name is allocated separately and set
when it is read.

Reviewed-by: Ian Rogers <irogers@google.com>
Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/ui/stdio/hist.c | 1 +
 tools/perf/util/symbol.c   | 1 +
 tools/perf/util/symbol.h   | 2 +-
 3 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/tools/perf/ui/stdio/hist.c b/tools/perf/ui/stdio/hist.c
index 3240c39bd025..45841eac6f52 100644
--- a/tools/perf/ui/stdio/hist.c
+++ b/tools/perf/ui/stdio/hist.c
@@ -106,6 +106,7 @@ static void init_rem_hits(void)
 		return;
 	}
 
+	rem_sq_bracket->name = (char *)(rem_sq_bracket + 1);
 	strcpy(rem_sq_bracket->name, "[...]");
 	rem_hits.ms.sym = rem_sq_bracket;
 }
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index d9866916fe9a..25efc05c2c7a 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -634,6 +634,7 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
 
 	pr_debug4("%s: %s %#" PRIx64 "-%#" PRIx64 "\n",
 		  __func__, name, start, sym->end);
+	sym->name = (char *)(sym + 1);
 	memcpy(sym->name, name, namelen);
 
 	return sym;
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index 41417bc85bb9..8abf6ec05bd6 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -92,7 +92,7 @@ struct symbol {
 	/** Architecture specific. Unused except on PPC where it holds st_other. */
 	u8		arch_sym;
 	/** The name of length namelen associated with the symbol. */
-	char		name[];
+	char		*name;
 };
 
 /**

-- 
Git-157)

