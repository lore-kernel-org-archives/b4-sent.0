From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 13 Feb 2023 13:23:51 -0600
Subject: [PATCH v2] powerpc/machdep: warn when machine_is() used too early
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230210-warn-on-machine-is-before-probe-machine-v2-1-b57f8243c51c@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAEaO6mMC/5WOwQ6CMBBEf4X07BJaJCSe/A/DoVu3som0ZIuII
 fy7hYN3j28meTOrSiRMSV2KVQnNnDiGDOZUKNfb8CDge2ZlKlNXRlfwthIgBhis6znkOgGSj0I
 wSkT65XXb6Aa1P9eIKtvQJgIUG1y/+wabJpK9GIU8L8eFW5e55zRF+RyPZr2n/4/PGjT4yqFtW
 m0aj9cnh9dSMg6li4Pqtm37Am6AbAj7AAAA
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1676316241; l=2389;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=U3ysgvX48P2OhQ8+xTLXW5puL0334RlB2L8QsGv/IKE=;
 b=xj6L8LjBONdygVBMhBaA2rb/K/eyTrNwMkG341NO9eCEME4hEsTrMAZSivJXcUOs4uP9AIc3k
 68arfJ7oESyBaEXqktpv7uDs6Uwra5cdA/HLJRftQWa6j7uzqt9tBBs
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

machine_is() can't provide correct results before probe_machine() has
run. Warn when it's used too early in boot, placing the WARN_ON() in a
helper function so the reported file:line indicates exactly what went
wrong.

checkpatch complains about __attribute__((weak)) in the patch, so
change that to __weak, and align the line continuations as well.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
Prompted by my attempts to do some pseries-specific setup during
rtas_initialize() and being puzzled for a while that it wasn't
working.

Changes in v2:
- Use WARN_ON(), not WARN().
- Introduce __machine_is() helper function so the line reported is
  accurate.
- Update __attribute__((weak)) to __weak for checkpatch's sake.
- Link to v1: https://lore.kernel.org/r/20230210-warn-on-machine-is-before-probe-machine-v1-1-f0cba57125fb@linux.ibm.com
---
 arch/powerpc/include/asm/machdep.h | 16 +++++++++++-----
 1 file changed, 11 insertions(+), 5 deletions(-)

diff --git a/arch/powerpc/include/asm/machdep.h b/arch/powerpc/include/asm/machdep.h
index 378b8d5836a7..459736d5e511 100644
--- a/arch/powerpc/include/asm/machdep.h
+++ b/arch/powerpc/include/asm/machdep.h
@@ -3,6 +3,7 @@
 #define _ASM_POWERPC_MACHDEP_H
 #ifdef __KERNEL__
 
+#include <linux/compiler.h>
 #include <linux/seq_file.h>
 #include <linux/init.h>
 #include <linux/dma-mapping.h>
@@ -220,11 +221,16 @@ extern struct machdep_calls *machine_id;
 	EXPORT_SYMBOL(mach_##name);				\
 	struct machdep_calls mach_##name __machine_desc =
 
-#define machine_is(name) \
-	({ \
-		extern struct machdep_calls mach_##name \
-			__attribute__((weak));		 \
-		machine_id == &mach_##name; \
+static inline bool __machine_is(const struct machdep_calls *md)
+{
+	WARN_ON(!machine_id); // complain if used before probe_machine()
+	return machine_id == md;
+}
+
+#define machine_is(name)                                        \
+	({                                                      \
+		extern struct machdep_calls mach_##name __weak; \
+		__machine_is(&mach_##name);                     \
 	})
 
 static inline void log_error(char *buf, unsigned int err_type, int fatal)

---
base-commit: 0bfb97203f5f300777624a2ad6f8f84aea3e8658
change-id: 20230210-warn-on-machine-is-before-probe-machine-37515b1f43bb

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

