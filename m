From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 02 Oct 2026 11:45:33 -0700
Subject: [PATCH v4 1/5] perf symbols: Fix broken ELF_C_READ_MMAP fallback
 guard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-perf-symbol-memory-send-v4-1-0a592bb2539e@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1501; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=Fie+m8uDrnEku3C9hTHPEiLsQANbwK1zFduANx60M6s=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqv/vkFLIf4inrlYhbSjNrLcejy/dUHW7jHb3DY
 MtjWy68uzCJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCar/75BsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtj7sw//QG/Td0j0BGXRT2vPRe/HJeSG+Hl84Qb
 nuqrP4uB86oV7rlLrPdjrwL4xdY4mlVKmQBKE5Dbtm1rCGocKj3XnonvDFhWHUZok/cnSEJteDv
 jc30hlEf+9yW75ICbhOaFHHTjBPFkitBE2VUXI6rjlx5nbFl+QBQkSyZANEq37Y072v6sdxeEuf
 YzUGrN+qbufdVT4a9E/n7aKD42XyR8c7sYFk42r221HeV/ksEAByaAUAuSR0hN39IVMqCpXWAwj
 orQ0LR5EUfAr2NazAk0aVdei6wwNNNMUIqaOh2IA1kOhUW/nlelFykMFpyI0rhG7+fGWBsZk9B8
 D2+8jbYRqv1soVIxD8wWFXSsYYJvLQYCpqaOlE29rbY2EXNvZopEfmk6jLYNW+PfHvAkIqe8QKK
 lu8KOTuwVeK6S75afgLvqxMrkYoXf5+U4a4QtqLCiAhw/v66CCoDJvdIqcl8YChyWxKc6yOTBfY
 cuvCOfY92IIYKu8D/SgGI6Bsh812Z9TffmEL4GRba2E71J0zLamyD9pSgUdMGYe//E7XZmY65+k
 yq34XAohenh29OxgNghZCZGxGuB+MtBWxaToHA8YI6OH58fI4KaUbL3wwhwIIAtnBRQnYM6qOs1
 uNyoZ5w3oH+/PpddiB5sJxgC8ncK/rRRu95+I4r/SHvQMJuXlqWY=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 22dd1ac91a77 ("tools: Remove feature-libelf-mmap feature
detection") replaced perf's compile-time feature test with an #ifdef on
ELF_C_READ_MMAP. ELF_C_READ_MMAP is an Elf_Cmd enumerator rather than a
preprocessor macro, so the condition is always false and perf silently
uses ELF_C_READ.

Perf already requires a sufficiently recent elfutils version that
provides ELF_C_READ_MMAP. Use the enumerator directly instead of
restoring a feature probe or retaining an unreachable fallback.

Fixes: 22dd1ac91a77 ("tools: Remove feature-libelf-mmap feature detection")
Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
Reviewed-by: Namhyung Kim <namhyung@kernel.org>
---
 tools/perf/util/symbol.h | 10 +---------
 1 file changed, 1 insertion(+), 9 deletions(-)

diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index d0bac824c79c..46b1649c64fc 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -57,15 +57,7 @@ static inline bool is_livepatch_symbol(const char *str)
 	return strstarts(str, KLP_SYM_PREFIX);
 }
 
-/*
- * libelf 0.8.x and earlier do not support ELF_C_READ_MMAP;
- * for newer versions we can use mmap to reduce memory usage:
- */
-#ifdef ELF_C_READ_MMAP
-# define PERF_ELF_C_READ_MMAP ELF_C_READ_MMAP
-#else
-# define PERF_ELF_C_READ_MMAP ELF_C_READ
-#endif
+#define PERF_ELF_C_READ_MMAP ELF_C_READ_MMAP
 
 #ifdef HAVE_LIBELF_SUPPORT
 Elf_Scn *elf_section_by_name(Elf *elf, GElf_Ehdr *ep,

-- 
Git-157)

