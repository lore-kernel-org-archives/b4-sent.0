From: Jim Cromie <jim.cromie@gmail.com>
Date: Thu, 08 Oct 2026 17:19:12 -0600
Subject: [PATCH] kallsyms: copy constants from __KERNEL__ to user, drop the
 inclusion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-fix-kallsyms-v1-1-3339fdac2ab3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwML3bTMCt3sxJyc4srcYl1Di1TTRPO0FINUQ0sloJaColSgPNi46Nj
 aWgDLftQFXgAAAA==
X-Change-ID: 20261008-fix-kallsyms-18e5a7fd0e19
To: Nathan Chancellor <nathan@kernel.org>, 
 Denis Benato <denis.benato@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, linux-kbuild@vger.kernel.org, 
 nsc@kernel.org, thomas.weissschuh@linutronix.de, chewi@gentoo.org, 
 abelvesa@kernel.org, linux-kernel@vger.kernel.org, 
 Kees Cook <kees@kernel.org>
Cc: Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791501553; l=2787;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=z/zMb6gglj4i+RtKQgtFQzYsPU9iLgw6hWdsZL1e5CU=;
 b=3rQyAReRHr4iktxRBcBRvu5BizvjCeAWGLqZJ9wA4TRcvlI0ImgnY2xQtump+TtLidfYDSkVr
 665vA50YLZoBKntKjdPfhSgDoj7T2PRAGX3QjmaVbT/T9a4iVjfWoJU
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

commit 4fafd1165b33 replaced hardcoded values which determine marker
array size, with new values that accelerate symbol-name lookups.
These symbols are needed in user-space to generate the lookup tables,
and in kernel to read the generated table.

To avoid 2-defns problem, they were added to a kernel header (with
ifdef guards) and included by scripts/kallsyms.c.  But that creates
packaging problems elsewhere, so just add the 2nd defns, with an
explicit comment about the user-kernel coupling.

Fixes: 4fafd1165b33 ("kallsyms: increase marker density to 16:1 to accelerate lookups")

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 kernel/kallsyms_internal.h | 12 +++++-------
 scripts/kallsyms.c         |  9 ++++++++-
 2 files changed, 13 insertions(+), 8 deletions(-)

diff --git a/kernel/kallsyms_internal.h b/kernel/kallsyms_internal.h
index 6a781e4cc77f..8311cce21128 100644
--- a/kernel/kallsyms_internal.h
+++ b/kernel/kallsyms_internal.h
@@ -2,18 +2,17 @@
 #ifndef LINUX_KALLSYMS_INTERNAL_H_
 #define LINUX_KALLSYMS_INTERNAL_H_
 
+#include <linux/types.h>
+
 /*
- * Provide compile-constants for scripts/kallsyms.c
- * so it can build the corresponding kallsyms_marker[] table.
- * and wrap the rest in __KERNEL__
+ * These constants determine the size of the kallsyms_markers array
+ * written by scripts/kallsyms.c during the build.  The symbol values
+ * must be kept in sync.
  */
 #define KALLSYMS_MARKER_SHIFT 4
 #define KALLSYMS_MARKER_SIZE  (1U << KALLSYMS_MARKER_SHIFT)
 #define KALLSYMS_MARKER_MASK  (KALLSYMS_MARKER_SIZE - 1U)
 
-#ifdef __KERNEL__
-#include <linux/types.h>
-
 extern const int kallsyms_offsets[];
 extern const u8 kallsyms_names[];
 
@@ -24,6 +23,5 @@ extern const u16 kallsyms_token_index[];
 
 extern const unsigned int kallsyms_markers[];
 extern const u8 kallsyms_seqs_of_names[];
-#endif /* __KERNEL__ */
 
 #endif // LINUX_KALLSYMS_INTERNAL_H_
diff --git a/scripts/kallsyms.c b/scripts/kallsyms.c
index be42a9111350..d142f040ad92 100644
--- a/scripts/kallsyms.c
+++ b/scripts/kallsyms.c
@@ -29,7 +29,14 @@
 
 #include <xalloc.h>
 
-#include "../kernel/kallsyms_internal.h"
+/*
+ * These constants determine the size of the marker array filled here,
+ * and they're duplicated in kernel/kallsyms.c, where they're used in
+ * get_symbol_offset().  They must be kept in agreement.
+ */
+#define KALLSYMS_MARKER_SHIFT 4
+#define KALLSYMS_MARKER_SIZE  (1U << KALLSYMS_MARKER_SHIFT)
+#define KALLSYMS_MARKER_MASK  (KALLSYMS_MARKER_SIZE - 1U)
 
 #define ARRAY_SIZE(arr) (sizeof(arr) / sizeof(arr[0]))
 

---
base-commit: b9c9b9eb732aefcd02bbc211b2570a2315a889da
change-id: 20261008-fix-kallsyms-18e5a7fd0e19

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

