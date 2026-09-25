From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 25 Sep 2026 12:09:38 -0700
Subject: [PATCH v3 1/6] perf symbols: Fix broken ELF_C_READ_MMAP fallback
 guard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-perf-symbol-memory-send-v3-1-3e4e234c363b@uber.com>
References: <20260925-perf-symbol-memory-send-v3-0-3e4e234c363b@uber.com>
In-Reply-To: <20260925-perf-symbol-memory-send-v3-0-3e4e234c363b@uber.com>
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
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqtshCpzsrTy68JCej2jYNxVbsTcbi9zZ25Pb6+
 hUmrGve/3CJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCarbIQhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthXcxAAkX0bsj8EiGS+gGJ/fOI1ADGjhU7dwcE
 ITVR2blrWPqv2/wipl49gq6ThcRqIKHHjUylBNmAiPx+fOpZU9dZYYxPpc9Jo/5eY0qZ4oTwg6C
 zp+7Vdenb5HsCSMLcWtHBUtidU+36fgai34dEg9WTXW6RkXDbwc1vjHrBu44sAy6KQVP0w6yaai
 N1yl+4Mq3N6YGOby6ZMCOriDasBMeJQBv7eKyeKxV+EtGoGLgrad2SOh46BCEpfUobuHFku4FXC
 82ZSh9mZrTNsLuUuckCu3hl9C05a2rLcsY4SzUzgM//kv54IQHGvC1+/2re2Qe6aUtjIo9S3Y9U
 BaxfBJNMPj3m4CpDt2bCH1Jwpmat5LdRb3sjtPY/R+qOiMXH9HnoGgmjMINJ5kV6+CNY/IEKriL
 Bz6mAwNQ+gHsFB5n8jf9dyQxA+esJzAZ2f4rN3Ku+eT5cxG9M6EeWy0fuAzqF2J//j67NSXoW0u
 sDZaOauaCyuryPYzKUdQ7j9y6u+Gq2RHZoLteiBxgVipDBK2eyk8W3Pwkxh5ymFgnLuQBo4WnkC
 ANIr76Irv0yuKsmnbJUmo5rDFj4ns/ZkL8FiLlQZriXRoRtarg2T4PogO7TIMLqxrD9fTcYeTDQ
 nYsbhvfg8LV/ekki7nTXxiPT9QpEoqvxy0mr6fdYc0rTnyAz3jEI=
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

