From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 13 Nov 2026 21:09:06 -0800
Subject: [PATCH v7 1/4] perf symbols: Split out name-independent duplicate
 symbol selection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-perf-symbol-memory-send-v7-1-d992eced9f9c@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3028; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=DQuKAcc/eg1Lh4Q4w9Z+uaojSWSxiLMNYdq0w6yVHrM=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBq9+0k1kqf2Do+wX6uJQRiiBZfDFhqQ80oxmnN/
 uq7oNIRXhmJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCavftJBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtgKQg/+IWL+2AbqKWl60cRWmq8gxWwUmNMVQSu
 iHSduKWCllyivQo7DxrJQToN6d9+HHYYWGFT2ECOrL6cPXRqrx3/HU2kjm23Ox4A8s3XPb2W/9j
 I0bi4BYbcQD2gKCkDg+UODhu9sqk9c8OmiF+BLPb6I7UDgjmfBhK0XE+OMoSBfmWP/bgtydaQPQ
 JfUpgw3jbP/822Yz8j22AdVdY9xN1SwDRMpPflei/WBDaR8o+UkorEpjzlfuBJb2nK84WXr0xfz
 D8jwjwgwnGwScSTPYC0RdfSqfIsXqq/ZRR6gc+WQjilEOWyK2i/gUm+CEED3ldnMKNp8bda4yEP
 stVWrTKYXyM6u3DSE/y8F1hYvgqZ/UhNr2x5lehCHBOPFoT2pLV4OVQimsGAj8jxGcfV26fcdAc
 KM5v47wyvEJfWxf1NqQa2ee3eN0VVJGxEKiojGuT//m3RPXP0pIZLeJ45i4z1MawkKKJuBbUAc6
 9CE6eM7CdEO/fi1OmeVorxQhFb/S3AuaRMbjyoeDuEN/nixXBGNjQiubYUxDdBzkvxaUDAoBM6i
 7t2aclThmSx/Sa8PnwJtio853wf7kYAaXH54WDcwTV7ySzlI4zGiO1gAo9pni6cv5Bq/3KAr9aE
 /mMy7UnnrjyI9j9p6BrEl9yYxZC26OGxCoaRy9Vs4bHHhvWV87BA=
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
index 6347bd218ad5..ae7ede8f6070 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -301,6 +301,7 @@ int arch__compare_symbol_names(const char *namea, const char *nameb);
 int arch__compare_symbol_names_n(const char *namea, const char *nameb,
 				 unsigned int n);
 int arch__choose_best_symbol(struct symbol *syma, struct symbol *symb);
+bool symbol__choice_needs_names(const struct symbol *syma, const struct symbol *symb);
 
 enum symbol_tag_include {
 	SYMBOL_TAG_INCLUDE__NONE = 0,

-- 
Git-157)

