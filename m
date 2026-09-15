From: Alireza Haghdoost <haghdoost@uber.com>
Date: Tue, 15 Sep 2026 11:42:43 -0700
Subject: [PATCH 1/4] perf symbols: Fix broken ELF_C_READ_MMAP fallback
 guard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-perf-symbol-memory-send-v1-1-1d3360e21f07@uber.com>
References: <20260915-perf-symbol-memory-send-v1-0-1d3360e21f07@uber.com>
In-Reply-To: <20260915-perf-symbol-memory-send-v1-0-1d3360e21f07@uber.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Andrii Nakryiko <andriin@fb.com>, 
 Alexei Starovoitov <ast@kernel.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1591; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=LDEl2QVI/AYSvnwqi8o+0DSPTV8sI0VoVdKogCTfNxc=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqqZHNgzZ/cAO9jMToADlL/aGKgYXyBbsp9BakV
 5moWgzgEWuJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCaqmRzRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtj3vg//bgjLUD0a+1mbY4GQoeHz8tP0yt8Y1ga
 DPd5KO7zFi2SKSwsK0o0ihKCjDVd3nKlRY/PDIBsLR8oEsxrwVHvEgjZRPj1Wve7JxFmLicVMfR
 wgp4eeQKuUUdpEgjpLXn9RQyhMQwzScdN3vDp61c11P3QKoU9Dclo5TV2Yrz8I7SdeOAnrzqp95
 XCEZ/RdvfZ5s3oNEs37vUtOzGEzX2rnZlwT7bzfK8geqoO+hmJZhPm+ujfcf8animO06VuuS9Ij
 OhmIiPS4ZfGt1OuKsnrqESGe2pjU+l2e6IDfFOhqdoosgzpXBUIguWVaNI5aztI0yzAyRrZqK2+
 BxHzhFMfHkzsAf3gaOrWTrQK8YzZWgndROKRQ3lLb8z/FWhF1i6xW/9vkdRWuV1xhjUU4NYtrXG
 KoCWe0OYjMZD0W8FcpCcjRS9uVAJniwGRrCm4oK4B6i2b5q7bMhP9ktzi44lGyKbbvhD22+AvMt
 Ahe4aqrN1BvT0DIRhUdijzNxIWggIHtaq16t8hZkaP3ofsz5BrS3hMIqxokHpGJgbgqhgppo8WI
 0e0DDUKyW7BKmDzxKecmxOdNdVuxaJJBtTh4FbIEzMmyOYWiGbZRsIAlqJycHv4KQMjtxYAMD9j
 arcBqvJk4BffF5iCV/AxuJODGqx8tf2TB/rPP+kTaA7ZqWYdYQ6c=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch makes perf mmap ELF files.  This was the intended behavior,
regressed by commit 22dd1ac91a77 ("tools: Remove feature-libelf-mmap
feature detection").  ELF_C_READ_MMAP is an Elf_Cmd enumerator, not a
preprocessor macro, so the #ifdef is false on every libelf that provides
it.  objtool uses ELF_C_READ_MMAP without an #ifdef guard and has been
fine for five years.

elf_getdata() still allocates when translation is needed (32-on-64 or
cross-endian), and libelf falls back to internal reads on non-seekable
fds.

Fixes: 22dd1ac91a77 ("tools: Remove feature-libelf-mmap feature detection")
Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
Assisted-by: Kimi:K3
---
 tools/perf/util/symbol.h | 11 ++---------
 1 file changed, 2 insertions(+), 9 deletions(-)

diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index d0bac824c79c..e5cef16b240d 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -57,15 +57,8 @@ static inline bool is_livepatch_symbol(const char *str)
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
+/* libelf falls back to internal reads when mmap fails (e.g. non-seekable fd). */
+#define PERF_ELF_C_READ_MMAP ELF_C_READ_MMAP
 
 #ifdef HAVE_LIBELF_SUPPORT
 Elf_Scn *elf_section_by_name(Elf *elf, GElf_Ehdr *ep,

-- 
Git-155)

