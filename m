From: Alireza Haghdoost <haghdoost@uber.com>
Date: Sat, 19 Sep 2026 19:33:56 -0700
Subject: [PATCH v2 1/4] perf symbols: Fix broken ELF_C_READ_MMAP fallback
 guard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-perf-symbol-memory-send-v2-1-495b8f00ad7c@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1452; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=jwkKCZxWR8rzu5laHR8MpSUN65pL8rVjbdfQdF2AFOU=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqr0Y30TXneuFp2Nqnsn7P9GUk0jF1J+LJFPOvL
 YZDQxyXx2+JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCaq9GNxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthhjA//fIXxYnl9RjKMgZTfBqkYrtJiatXJEfR
 kCyv0E3yuhbBn671Hwa8dZiaep3w+eRj6FigzAH19N5Ybe1of1eRWHRr3pmQKlIn8ExpiWySV0C
 f4Mb8VkKE3FIYJ01GyKREH6P2aVMex6UyOiU8wEeS6S1pV40bBhryDYXbG1ExejnbeB54BQmY2k
 gceJP+C82QuujAYoAbqXVjwBeIIg11byip0t2toPJHN7I1U7KNEEKLYOZ/wGRTHKx8K+4ii5Op0
 h3LLMNFiaNYySOIJjIBNDRDANg4RN2H6Gn+6++cYvUBGlSwzJ5H3h+iih4tYQ4BCah1Xh8cj8ln
 cmNvSSPLJtkQJJ3Mwk7i+30UnClWJvO5C/lvVpUzt7OsUFUi/Hodf6TS/H94W6L2q5USwNLIhGy
 l44UIqyaPXMI5OzCvCtNrIpS89xMv/Oi6SP/tIy6KD6Isf1l7oHAvIjxcQn3ayf40NGc9CSKiEt
 KpPZmtpAppW3Ka6GUsgbjrdT8401eVq7tc7tP8Rwi1AIOasHmBhXmUUVXGY3VoxUoLPVjCgBWdA
 Husc6fqGHji/HVX740iFsVbyoVbJoAYMrIyf5BTArlBU2yn3CP4Gs+RhIqz2SGEt7gKvm92Gr0H
 lWtc0NgeTmyhfZTKIbHL3AmF9WxYm3fQUqdSsQoOJUd9wFI6bGOU=
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

