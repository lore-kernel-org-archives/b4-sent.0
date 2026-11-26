From: Dmitry Safonov <dima@arista.com>
Date: Thu, 26 Nov 2026 06:08:35 +0000
Subject: [PATCH] perf/build: Include linux/string.h by jitdump.c for
 strlcpy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-perf-string-h-v1-1-8f5c39ff30f0@arista.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBBFr1Jm7UCTYhZeRVxM4rQZwVhmYhFK7
 26iy/f57+1grMIGl2EH5U1MXqWBOw2QMpWFUe6NwY8+OOcDrqwzWlUpC2YcKbhIU5g4nKE5q/I
 sn1/vevuzveODU+2R/ohkjFGppNynJ1llheP4AnTHBl+KAAAA
X-Change-ID: 20261126-perf-string-h-0a61ba363e65
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: Arnaldo Carvalho de Melo <acme@redhat.com>, 
 linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795673322; l=1805;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=g9y3VzWr2i/uTd9kE3tOPKSuvKsRe85S2o8Ykr74pG8=;
 b=MPmy2s67QLHmgUQymeQX9y6X8dAbiW1d4DWOxW1B2i8riTk56eTwXyUhMUhNJ5ywqB/mTcEFq
 XtVVRb29W8xACVOIvjt0fBS8nystM/maKHsW1eSR5vMJZyLC+NtIUqx
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

jit_open() now calls strlcpy(), but jitdump.c only includes the libc
<string.h>. With glibc older than 2.38, that header does not declare
strlcpy(), causing the build to fail:

util/jitdump.c:246:17: error: implicit declaration of function 'strlcpy'; did you mean 'strncpy'? [-Wimplicit-function-declaration]
  246 |                 strlcpy(jd->dir, dname, sizeof(jd->dir));
      |                 ^~~~~~~
      |                 strncpy

Current mainline gets the declaration indirectly through symbol.h after
commit 5a9dd835894c ("perf symbols: skip livepatch symbols when loading
kallsyms"). Stable trees are affected, in my case it's v6.12.119 with
stable backport/commit 649bf062b91d ("perf jitdump: Use dirname()
return value in jit_open()")

Replace <string.h> with <linux/string.h>, which includes the libc header
and declares the tools strlcpy() implementation.

Fixes: 4eddf7d9e341 ("perf jitdump: Use dirname() return value in jit_open()")
Signed-off-by: Dmitry Safonov <dima@arista.com>
---
 tools/perf/util/jitdump.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/perf/util/jitdump.c b/tools/perf/util/jitdump.c
index 45a05316b3ca..626a12280ca3 100644
--- a/tools/perf/util/jitdump.c
+++ b/tools/perf/util/jitdump.c
@@ -5,7 +5,6 @@
 #include <libgen.h>
 #include <stdio.h>
 #include <stdlib.h>
-#include <string.h>
 #include <fcntl.h>
 #include <unistd.h>
 #include <inttypes.h>
@@ -16,6 +15,7 @@
 #include <linux/stringify.h>
 #include <linux/kernel.h>
 #include <linux/unaligned.h>
+#include <linux/string.h>
 
 #include "event.h"
 #include "debug.h"

---
base-commit: 40212b29a6f718d4e7fb3275cede181cb8e137cf
change-id: 20261126-perf-string-h-0a61ba363e65

Best regards,
--  
Dmitry Safonov <dima@arista.com>

