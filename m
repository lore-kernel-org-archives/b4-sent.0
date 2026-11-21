From: Alireza Haghdoost <haghdoost@uber.com>
Date: Sat, 21 Nov 2026 08:41:01 -0800
Subject: [PATCH v8 1/7] perf symbols: Split out name-independent duplicate
 symbol selection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-perf-symbol-memory-send-v8-1-370561cbb5a7@uber.com>
References: <20261121-perf-symbol-memory-send-v8-0-370561cbb5a7@uber.com>
In-Reply-To: <20261121-perf-symbol-memory-send-v8-0-370561cbb5a7@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3028; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=VGrhvbBMlOezaIej0nQ/zA/IXFiLbKzeTc7elGOodLk=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrAcmt0Xkby2keCpXtfE7nzOqOHFa1/SpVOjDrh
 H5FxvVNhb6JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawHJrRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthd2w/8DvPTWAN9EW/zSErnaq9QLh0x8joZdMi
 ikZEQLuy8GsPxKefPLCwKSeoVDsTW7BDbLvBg4aqucPvdL5DImryrOk7t2wbaF1kSKhSHPL1oFN
 +8BlQ+6fEdJVnQfSSesn5pZ1HDzk1LV6OANDKoeCebJEmjhAMyV9ctgspCD8jNRNXJyibtzVlB6
 hIVxSK1TShS60jdgpRWxy+hgCHjR1CVFjx8/NkKnv8mruLz9DIdAvfAvN8UyLrGNsRA8GsR653K
 th8OQEo/saW1oIRuZJas8+KjmnJXd1UKku/7GPqEz/NTVsKre7WjBKJA+2ymkpPUEa+vytUI5ut
 4Ee5agEsaczzEJH3oszq2eEFCd8OgB35NxFUiCJ/VQbCbOyTvDREvYmYBd6N1PPwuO4WbTFD35J
 kpcCfzYMnjeEXshsA4WyY+uYrn9oZ3CErd3n9qI+ccJvezuuKlR9sQz6YboajScXhNVugY4UsxY
 m896Qbh9NZ+nu/BDQDQofpsxtYPCvREiujFLmfPV27TMVtEXGpFH2sg+9HdaMgvmeDsjmxvsFhr
 ynbJ7XtsBbYiBgufqqo/jTvpNda72/T1ddvSBNSsqhyNmEj2gVCJSZ4A+m9dfBqk0tzWGr/XPi1
 tn4Nzt/+kjkPNK3zUXRXuddw2pb9Ddt2r6JBoKc2k0f66cMEHY/c=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch is a refactoring and does not change behavior. It moves the
size, type and binding checks from choose_best_symbol() to
choose_best_symbol_by_attrs(), and adds symbol__choice_needs_names() to
tell whether choosing between two symbols needs their names.

symbols__fixup_duplicate() keeps one of the symbols that share a start
address. It compares size, type and binding first. If those are equal,
it compares leading underscores, name lengths and the result of
arch__choose_best_symbol().

An unresolved lazy symbol stores a file offset instead of a name
pointer, so the lazy loader cannot call choose_best_symbol() before it
has read both names. The new helper lets it leave the names unread when
the attributes already pick one of the symbols.

Reviewed-by: Ian Rogers <irogers@google.com>
Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/util/symbol.c | 26 ++++++++++++++++++++++++--
 tools/perf/util/symbol.h |  1 +
 2 files changed, 25 insertions(+), 2 deletions(-)

diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index a1ac1cd1d2e7..a5ed8a65986b 100644
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
index a6a2ab200f98..fc98fab1c8d0 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -295,6 +295,7 @@ int arch__compare_symbol_names(const char *namea, const char *nameb);
 int arch__compare_symbol_names_n(const char *namea, const char *nameb,
 				 unsigned int n);
 int arch__choose_best_symbol(struct symbol *syma, struct symbol *symb);
+bool symbol__choice_needs_names(const struct symbol *syma, const struct symbol *symb);
 
 enum symbol_tag_include {
 	SYMBOL_TAG_INCLUDE__NONE = 0,

-- 
Git-157)

