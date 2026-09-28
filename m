From: Alireza Haghdoost <haghdoost@uber.com>
Date: Mon, 28 Sep 2026 16:32:27 -0700
Subject: [PATCH] perf symbols: Don't let a module's last symbol overlap the
 next module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-haghdoost-perf-symbols-fixup-module-end-v1-1-0a70d1edd401@uber.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQrDIBCF4auEWXdApQ22VyldJDpGS6LixNASc
 vfadvnB4387MJVADLduh0Jb4JBigzx1YPwQJ8Jgm0EJ1Yur0uiHyduUeMVMxSG/lzHNjC68asY
 l2ToTUrQopaFeX7QT5gytlgu1ze/p/vib6/gks37zcBwflWA28YsAAAA=
X-Change-ID: 20260928-haghdoost-perf-symbols-fixup-module-end-11ce6858f0c4
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Leo Yan <leo.yan@linux.dev>
Cc: Arnaldo Carvalho de Melo <acme@redhat.com>, 
 linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5404; i=haghdoost@uber.com;
 s=default; h=from:subject:message-id;
 bh=hia/nfZ1zuUJnWSPH+AZ1ROrZNOW1F7P2g4qzsbVvN0=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBquvkXzsNtM9CIYz+V1Yn3HJxo/5h3utZP6pi1j
 fNM2cH9GXqJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCarr5FxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtid9RAAnguw0wHX6y31vnGEDIWYcGS/nP0eHeC
 u9LwcRJYGAKG9Be2Dm8gZGWJxE72l8xaXldTh4eHGk8YjDAC+AlqMQHhzS+zShOq0Kw7SOKgHAi
 fWjLkPtBdc3hKY5lIQnv2+CxYWHX3z1mCvR+I3WIC0Mrce7W90XAbeACN/KjHGTL6PFs85IMu6B
 N4IWCiTHRKrmZeIG8R2Jg5yqJes3/MLjF8OGl60+QwqwrKtu48Q0l0rYIkXKfEnL0/Lbc7yso68
 T75JFI8BaGjo//lSaM58fvKsTP0IW8yZw/pjTFR70z96EXDwHVcZ2hA9BaXx989GVGnMMWex08F
 TFeTNiTJOnHcQYqVivPXRQuj1pgXVcoD7FrbrQgIIS2s1GenkBaYiRA1fVTBm30dYCkzVA7QF4l
 5h+kZOXOXPiTPAlJX5H6UEOT3HlPs6RArzN8qKJrguwrd3GQiz+1GqWZsF3Y1Rl76kzySXDAC6A
 aIv1xm/ZUNGUHZ4MUeFxoS7o2khc81+a4dG5JzMUl4t0/b0lrZYiMuOuLG6U9z1KhdLwrxHvnfL
 KqXBRmjNr9fQJifsoRhLi0Tclm5unpjcqLjHa3v2yUOmFNs3dqIZ0igEDSA2awfJlo5pittxwo7
 Ls5g0jIR/uBdB9URtR4eArl//IVvpyjuGPLeDk/bPgb0I7qoU3jk=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

symbols__fixup_end() extends a zero-size symbol that is the last one in
the kernel or in a module to the end of the next page. On x86 the next
module can start in that page, so the stretched symbol overlaps it, and
a lookup can return the wrong symbol. For example:

  ffffffffc0c4aa50 t dca_sysfs_exit    [dca]
  ffffffffc0c4b000 t __nft_trace_packet [nf_tables]
  ffffffffc0c4b0b0 t nft_do_chain      [nf_tables]

dca_sysfs_exit gets end 0xffffffffc0c4c000, and samples in nft_do_chain
are reported as dca_sysfs_exit.

This patch clamps the end to the next symbol's start. The ARM case this
code was added for, where the next module is far away, is unchanged.

Add a "Kallsyms symbol ends" test case to the Symbols suite that covers
the kernel/module boundary, adjacent modules and a distant module.

Fixes: 8799ebce84d6 ("perf symbol: Update symbols__fixup_end()")
Fixes: bacefe0c7b77 ("perf tools: Fixup module symbol end address properly")
Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/util/symbol.c   |  4 ++
 tools/perf/tests/symbols.c | 96 +++++++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 99 insertions(+), 1 deletion(-)

diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index 163652f071c6f..f0a7f5a30e696 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -302,6 +302,10 @@ void symbols__fixup_end(struct rb_root_cached *symbols, bool is_kallsyms)
 			else
 				prev->end = curr->start;
 
+			/* The next module can start within that page */
+			if (prev->end > curr->start)
+				prev->end = curr->start;
+
 			pr_debug4("%s sym:%s end:%#" PRIx64 "\n",
 				  __func__, prev->name, prev->end);
 		}
diff --git a/tools/perf/tests/symbols.c b/tools/perf/tests/symbols.c
index c09e04f36035a..b644d95c6be9a 100644
--- a/tools/perf/tests/symbols.c
+++ b/tools/perf/tests/symbols.c
@@ -2,6 +2,7 @@
 #include <linux/compiler.h>
 #include <linux/string.h>
 #include <sys/mman.h>
+#include <inttypes.h>
 #include <limits.h>
 #include "debug.h"
 #include "dso.h"
@@ -223,4 +224,97 @@ static int test__symbols(struct test_suite *test __maybe_unused, int subtest __m
 	return ret;
 }
 
-DEFINE_SUITE("Symbols", symbols);
+struct kallsyms_sym {
+	u64 start;
+	const char *name;
+};
+
+/*
+ * kallsyms from an x86 host where nf_tables was loaded in the page right
+ * after the last symbol of dca, plus a kernel symbol followed closely by a
+ * module and a module far away from the others.
+ */
+static const struct kallsyms_sym kallsyms_syms[] = {
+	{ 0xffffffff81000000, "_stext" },
+	{ 0xffffffff81000ff0, "last_kernel_symbol" },
+	{ 0xffffffff81001000, "near_module_symbol\t[near]" },
+	{ 0xffffffffc0c4aa40, "dca_exit\t[dca]" },
+	{ 0xffffffffc0c4aa50, "dca_sysfs_exit\t[dca]" },
+	{ 0xffffffffc0c4b000, "__nft_trace_packet\t[nf_tables]" },
+	{ 0xffffffffc0c4b0b0, "nft_do_chain\t[nf_tables]" },
+	{ 0xffffffffc0c4b4e0, "nf_tables_core_module_exit\t[nf_tables]" },
+	{ 0xffffffffc2000000, "far_module_symbol\t[far]" },
+};
+
+static int check_symbol(struct dso *dso, u64 addr, const char *name, u64 end)
+{
+	struct symbol *sym = dso__find_symbol_nocache(dso, addr);
+
+	if (!sym || strcmp(sym->name, name)) {
+		pr_debug("%#" PRIx64 ": expected %s, got %s\n", addr, name,
+			 sym ? sym->name : "no symbol");
+		return TEST_FAIL;
+	}
+	if (sym->end != end) {
+		pr_debug("%s: expected end %#" PRIx64 ", got %#" PRIx64 "\n",
+			 name, end, sym->end);
+		return TEST_FAIL;
+	}
+	return TEST_OK;
+}
+
+static int test__kallsyms_fixup_end(struct test_suite *test __maybe_unused,
+				    int subtest __maybe_unused)
+{
+	struct dso *dso = dso__new("[kernel.kallsyms]");
+	int ret = TEST_FAIL;
+
+	if (!dso)
+		return TEST_FAIL;
+
+	for (unsigned int i = 0; i < ARRAY_SIZE(kallsyms_syms); i++) {
+		struct symbol *sym = symbol__new(kallsyms_syms[i].start, 0, 0, 0,
+						 kallsyms_syms[i].name);
+
+		if (!sym)
+			goto out;
+		symbols__insert(dso__symbols(dso), sym);
+	}
+
+	symbols__fixup_end(dso__symbols(dso), true);
+
+	ret = TEST_OK;
+	/* The next symbol is too close for the end of the page. */
+	if (check_symbol(dso, 0xffffffff81000ff8, "last_kernel_symbol",
+			 0xffffffff81001000))
+		ret = TEST_FAIL;
+	if (check_symbol(dso, 0xffffffffc0c4aa58, "dca_sysfs_exit\t[dca]",
+			 0xffffffffc0c4b000))
+		ret = TEST_FAIL;
+	if (check_symbol(dso, 0xffffffffc0c4b280, "nft_do_chain\t[nf_tables]",
+			 0xffffffffc0c4b4e0))
+		ret = TEST_FAIL;
+
+	/* Far from the next module, the end of the page is still used. */
+	if (check_symbol(dso, 0xffffffffc0c4b4f0,
+			 "nf_tables_core_module_exit\t[nf_tables]",
+			 0xffffffffc0c4d000))
+		ret = TEST_FAIL;
+	if (check_symbol(dso, 0xffffffff81001008, "near_module_symbol\t[near]",
+			 0xffffffff81002000))
+		ret = TEST_FAIL;
+out:
+	dso__put(dso);
+	return ret;
+}
+
+static struct test_case tests__symbols[] = {
+	TEST_CASE("Symbols", symbols),
+	TEST_CASE("Kallsyms symbol ends", kallsyms_fixup_end),
+	{ .name = NULL, }
+};
+
+struct test_suite suite__symbols = {
+	.desc = "Symbols",
+	.test_cases = tests__symbols,
+};

---
base-commit: 0ae6fc78c5ce0dfd18d8712a50f0fd4602eff103
change-id: 20260928-haghdoost-perf-symbols-fixup-module-end-11ce6858f0c4

Best regards,
--  
Alireza Haghdoost <haghdoost@uber.com>

