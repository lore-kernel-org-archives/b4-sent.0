From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 02 Oct 2026 11:45:35 -0700
Subject: [PATCH v4 3/5] perf symbols: Factor out duplicate symbol selection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-perf-symbol-memory-send-v4-3-0a592bb2539e@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5684; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=Ky+OYrqZSHk+7lank2LYMaDOqGiz1W+4+DT3dXV1I8E=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqv/vld6VXq+SObwVGjyI+5i9UwSavV2vxHuSqz
 7JftRX58bSJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCar/75RsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtipyw/9HKcONTosS0nuQhDTjLy7i86B8oDAV6o
 k7/a/9FR7NdKLIPtvhja5CpOYzK3b6BV/A4NeA6xq8bjVRP+KXcr5dJw+MN/Ro8HBTDPSod8w4w
 tf+wAQ65snwlVMSbji3iOCV2D9+UGIv1RGgGtSBKm3gngrp3R29428EhwGZ0Kv6trCTS1uJaak2
 o0lh+A1W1sPYeWTf2Q809TEt6DGH4npnQi8GBtqAHx4bLwF0fnsfh/QeFjPOxRvaXapB7W4YdyY
 EfIIHJ/VtRjYgcuvMV8wKD6StOolupZt3M2ndnOoQcJMi3RDObrKSxvswT1iWc4UA3n+eAE5cMa
 Rsa1xAsIOYDmPRlsI769phW86wF5tcX9iWbFGGEbHGS98vcYOwdNV16hukr5MZWC7++JcGeZO5t
 cEmfkLqpbl1i8vQar9qBXUOSDVzwF1FIdiYdSFTnOjGVd5f4WoJqAa9zSshSNDHF89a4gi7rAB6
 /+E2ULL+seJ9RQJSuPlxBwNSZavmHUlOGOltd4NbTqrFtZkoaFpeYWklsaxhtcCLLfaY1Hs+EZu
 cosOEkLGNaYTZ0Wz9TQjc3bqQtixWlxl6y5XttncgBfygyX/AuUBhMff04IFQEHWgkVhfhSuygY
 qpJa1KVoq2n3dzCrnvod2C1uRUDdQWCRHLTeaoEH22vaxOY3AMs0=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

symbols__fixup_duplicate() chooses between symbols with the same start
address through choose_best_symbol(), which needs fully constructed
struct symbol objects. The lazy symbol loader added later in this series
selects among aliases from its index entries, before any struct symbol
exists, so it cannot use it.

This patch moves the policy into symbol__choose_best(), which compares
the size, name, type and binding of two candidates described by struct
symbol_candidate, and passes the same description to the
arch__choose_best_symbol() hook. choose_best_symbol() becomes a wrapper
that describes two struct symbols. No functional change intended.

symbol__choose_best() is not static so that the lazy loader can call it.
struct symbol_candidate stays in symbol.h because powerpc overrides the
weak arch__choose_best_symbol(), which takes it.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/arch/powerpc/util/sym-handling.c |  6 ++--
 tools/perf/util/symbol.c                    | 43 +++++++++++++++++++++--------
 tools/perf/util/symbol.h                    | 14 +++++++++-
 3 files changed, 47 insertions(+), 16 deletions(-)

diff --git a/tools/perf/arch/powerpc/util/sym-handling.c b/tools/perf/arch/powerpc/util/sym-handling.c
index 947bfad7aa59..c263cbfefba5 100644
--- a/tools/perf/arch/powerpc/util/sym-handling.c
+++ b/tools/perf/arch/powerpc/util/sym-handling.c
@@ -10,10 +10,10 @@
 #include "probe-event.h"
 #include "probe-file.h"
 
-int arch__choose_best_symbol(struct symbol *syma,
-			     struct symbol *symb __maybe_unused)
+int arch__choose_best_symbol(const struct symbol_candidate *syma,
+			     const struct symbol_candidate *symb __maybe_unused)
 {
-	char *sym = syma->name;
+	const char *sym = syma->name;
 
 #if !defined(_CALL_ELF) || _CALL_ELF != 2
 	/* Skip over any initial dot */
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index 5d98888d068c..f590b69f9f01 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -145,8 +145,8 @@ int __weak arch__compare_symbol_names_n(const char *namea, const char *nameb,
 	return strncmp(namea, nameb, n);
 }
 
-int __weak arch__choose_best_symbol(struct symbol *syma,
-				    struct symbol *symb __maybe_unused)
+int __weak arch__choose_best_symbol(const struct symbol_candidate *syma,
+				    const struct symbol_candidate *symb __maybe_unused)
 {
 	/* Avoid "SyS" kernel syscall aliases */
 	if (strlen(syma->name) >= 3 && !strncmp(syma->name, "SyS", 3))
@@ -157,38 +157,39 @@ int __weak arch__choose_best_symbol(struct symbol *syma,
 	return SYMBOL_A;
 }
 
-static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
+int symbol__choose_best(const struct symbol_candidate *syma,
+			const struct symbol_candidate *symb)
 {
 	s64 a;
 	s64 b;
 	size_t na, nb;
 
 	/* Prefer a symbol with non zero length */
-	a = syma->end - syma->start;
-	b = symb->end - symb->start;
+	a = syma->size;
+	b = symb->size;
 	if ((b == 0) && (a > 0))
 		return SYMBOL_A;
 	else if ((a == 0) && (b > 0))
 		return SYMBOL_B;
 
-	if (symbol__type(syma) != symbol__type(symb)) {
-		if (symbol__type(syma) == STT_NOTYPE)
+	if (syma->type != symb->type) {
+		if (syma->type == STT_NOTYPE)
 			return SYMBOL_B;
-		if (symbol__type(symb) == STT_NOTYPE)
+		if (symb->type == STT_NOTYPE)
 			return SYMBOL_A;
 	}
 
 	/* Prefer a non weak symbol over a weak one */
-	a = symbol__binding(syma) == STB_WEAK;
-	b = symbol__binding(symb) == STB_WEAK;
+	a = syma->binding == STB_WEAK;
+	b = symb->binding == STB_WEAK;
 	if (b && !a)
 		return SYMBOL_A;
 	if (a && !b)
 		return SYMBOL_B;
 
 	/* Prefer a global symbol over a non global one */
-	a = symbol__binding(syma) == STB_GLOBAL;
-	b = symbol__binding(symb) == STB_GLOBAL;
+	a = syma->binding == STB_GLOBAL;
+	b = symb->binding == STB_GLOBAL;
 	if (a && !b)
 		return SYMBOL_A;
 	if (b && !a)
@@ -213,6 +214,24 @@ static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
 	return arch__choose_best_symbol(syma, symb);
 }
 
+static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
+{
+	struct symbol_candidate a = {
+		.size = syma->end - syma->start,
+		.name = syma->name,
+		.type = symbol__type(syma),
+		.binding = symbol__binding(syma),
+	};
+	struct symbol_candidate b = {
+		.size = symb->end - symb->start,
+		.name = symb->name,
+		.type = symbol__type(symb),
+		.binding = symbol__binding(symb),
+	};
+
+	return symbol__choose_best(&a, &b);
+}
+
 void symbols__fixup_duplicate(struct rb_root_cached *symbols)
 {
 	struct rb_node *nd;
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index 46b1649c64fc..b9fa722a9a14 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -299,10 +299,22 @@ const char *arch__normalize_symbol_name(const char *name);
 #define SYMBOL_A 0
 #define SYMBOL_B 1
 
+/* Attributes used to choose between symbols that share a start address. */
+struct symbol_candidate {
+	u64		size;
+	const char	*name;
+	u8		type;
+	u8		binding;
+};
+
+int symbol__choose_best(const struct symbol_candidate *a,
+			const struct symbol_candidate *b);
+
 int arch__compare_symbol_names(const char *namea, const char *nameb);
 int arch__compare_symbol_names_n(const char *namea, const char *nameb,
 				 unsigned int n);
-int arch__choose_best_symbol(struct symbol *syma, struct symbol *symb);
+int arch__choose_best_symbol(const struct symbol_candidate *a,
+			     const struct symbol_candidate *b);
 
 enum symbol_tag_include {
 	SYMBOL_TAG_INCLUDE__NONE = 0,

-- 
Git-157)

