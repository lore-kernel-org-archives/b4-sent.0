From: Alireza Haghdoost <haghdoost@uber.com>
Date: Wed, 28 Oct 2026 16:42:33 -0700
Subject: [PATCH v6 2/5] perf symbols: Split out name-independent duplicate
 symbol selection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-perf-symbol-memory-send-v6-2-7e90415f0101@uber.com>
References: <20261028-perf-symbol-memory-send-v6-0-7e90415f0101@uber.com>
In-Reply-To: <20261028-perf-symbol-memory-send-v6-0-7e90415f0101@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3083; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=UFacskGEBu0XEz3nvj7QOau6UP9nsBYAYWQ+E7Nz3js=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBq4oh2tWOhJUiFDWi4yQZNya/JlXoiWvKSy0z0g
 Xmh32y/1N+JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCauKIdhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtiQQQ/+OgLAXIXP4L/3YiuXilobQUOBhQRAViT
 ulCpV/5ik8ZeNccLISGDCCa/0GAK+DkUs2NmTpQrH83p90bP/1wCCIqH8/BnL1AGecCc2/w8wMf
 Xb0KqXCc6MrGBeEbWqx07Ld3r76dnB/NdzE4zRodO3thk1KZSgKI4LSoZ8BdvMVGddktk2GQtf3
 G6De6qKezufavVgrAT7k2USVJNdxLYBs2U3DNnkLz5IZixaGaLu9FRSIC06RFPyjzdgHdRtGtIG
 8Tkio534MKsOsCphpSWb+oI0jCx7bbL6FeMlSdaJyDiU+RvSocKg63WuJDcU9UHO8y7bBl4acHI
 iHuHPLFKWSDoZKLP+CizVfluafU5dsCM/jhb7f+CgY7MsFGF87pFSWMsxJVYl2SLwKINOKjoTrW
 J4ZrAqymGYVx+Xz5KtINXLsMwMndZO1Is3l4umnQ/D0IFsa2UoIR8jmrbXJfnewzsgFvbtPV5Fp
 dHAUkNAgVzd9ofWX4zKUGQfd8ibzDBDmjzLvS/G5mth0C6gsSJUEMmOvhuWAUqVLtCzZn58n4bM
 R29iSQRBlXKXlTqtwKzmFOeI0ms2rGdwYt0Ef3JcySpYoxpoCK/999tSlDk2zJR08c/Ak08BXr7
 L9ar+AjI13Z4RSGzqNDKZRJO44NA8RWKEmmNXh5765lMIp8lMjug=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch is a refactoring and does not change behavior. It moves the
size, type and binding checks from choose_best_symbol() to
choose_best_symbol_by_attrs(). It also adds symbol__choice_needs_names()
to report whether choosing between two symbols requires their names.

symbols__fixup_duplicate() keeps one of the symbols that share a start
address. It compares size, type and binding first. If those attributes
are equal, it compares leading underscores, name lengths and the result
of arch__choose_best_symbol().

An unresolved lazy symbol stores a file offset instead of a name
pointer. Thus, the lazy loader cannot call choose_best_symbol() until it
loads both names. The new helper lets the loader keep the names
unresolved when the attributes select a winner. It loads names only when
the attributes are equal and duplicate selection needs them.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/util/symbol.c | 26 ++++++++++++++++++++++++--
 tools/perf/util/symbol.h |  1 +
 2 files changed, 25 insertions(+), 2 deletions(-)

diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index b61a574ce9a3..2d611c05d000 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -157,11 +157,15 @@ int __weak arch__choose_best_symbol(struct symbol *syma,
 	return SYMBOL_A;
 }
 
-static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
+/*
+ * Choose between two symbols at the same address by size, type and binding.
+ * Returns SYMBOL_A or SYMBOL_B, or -1 if only their names can decide.
+ */
+static int choose_best_symbol_by_attrs(const struct symbol *syma,
+				       const struct symbol *symb)
 {
 	s64 a;
 	s64 b;
-	size_t na, nb;
 
 	/* Prefer a symbol with non zero length */
 	a = syma->end - syma->start;
@@ -194,6 +198,24 @@ static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
 	if (b && !a)
 		return SYMBOL_B;
 
+	return -1;
+}
+
+bool symbol__choice_needs_names(const struct symbol *syma, const struct symbol *symb)
+{
+	return choose_best_symbol_by_attrs(syma, symb) < 0;
+}
+
+static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
+{
+	int ret = choose_best_symbol_by_attrs(syma, symb);
+	s64 a;
+	s64 b;
+	size_t na, nb;
+
+	if (ret >= 0)
+		return ret;
+
 	/* Prefer a symbol with less underscores */
 	a = prefix_underscores_count(syma->name);
 	b = prefix_underscores_count(symb->name);
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index 46b1649c64fc..d8386c4a7fc5 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -303,6 +303,7 @@ int arch__compare_symbol_names(const char *namea, const char *nameb);
 int arch__compare_symbol_names_n(const char *namea, const char *nameb,
 				 unsigned int n);
 int arch__choose_best_symbol(struct symbol *syma, struct symbol *symb);
+bool symbol__choice_needs_names(const struct symbol *syma, const struct symbol *symb);
 
 enum symbol_tag_include {
 	SYMBOL_TAG_INCLUDE__NONE = 0,

-- 
Git-157)

