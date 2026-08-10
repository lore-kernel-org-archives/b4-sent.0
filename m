From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 10 Aug 2026 17:09:55 +0200
Subject: [PATCH] riscv: Add support for early boot errata application on
 MIPS chips
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-p8700-early-boot-v1-1-5c4aa08d500f@htecgroup.com>
X-B4-Tracking: v=1; b=H4sIAMLpeWoC/x3MOwqAMBBF0a3I1A4k8YtbEYuoTx0QI4mIIu7dY
 HmKex8K8IJATfKQxylB3Bah04SGxW4zWMZoMsqUqso073WlFMP69ebeuYPLHDCmQG31QDHbPSa
 5/mXbve8HdE+RLWIAAAA=
X-Change-ID: 20260731-p8700-early-boot-64ee225e8a1c
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: Djordje Todorovic <Djordje.Todorovic@htecgroup.com>, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jesse Taube <jtaubepe@redhat.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786374594; l=5406;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=tUGwxAGcsFQ15+ATXIx+CHK/q7aSrHKUk9gDaLGmkCg=;
 b=Ynj4unKHLA4MosNnr4wcm3X1PkwgJpF/JC+BJT0xFv6GSPOPbC3BnHymQxFqfTgqjchDJM+7g
 IXkh7QklV3pDRsXIjug2HRRl6kYC/4rHdIjMwZicbT/5oLf3JG+l+W9
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MIPS errata implementation previously skipped early boot application
entirely. Although the only currently existing MIPS erratum does not
require this, amending this now should make any future addition easier to
implement.

This commit was based on the existing T-Head implementation.

Suggested-by: Jesse Taube <jtaubepe@redhat.com>
Link: https://lore.kernel.org/linux-riscv/CADRr4bcbD57hmR0XGgo8BjgNp4shEADOondZEtwscCJ9-nxXRQ@mail.gmail.com/
Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
The patch was motivated by Jesse's suggestion to implement [2] as an early boot erratum.
However, since it's in conflict with [1] as well, I decided against sending this one and the ZALRSC patch as a series,
opting for rebasing [1] and [2] once it's clear we should move forward with this approach.

I tested this on an eight-hart QEMU config. The testing was done by rebasing [1] and [2] onto the patch
and running most of the same tests used to verify those patches. This includes: coremark testing, futex kselftests
and GDB to check errata application. The same tests were run on the Boston board, configured with a single P8700 core.

Links:
[1] https://lore.kernel.org/linux-riscv/20260608-p8700-wfi-v2-1-77efc7459f3d@htecgroup.com/
[2] https://lore.kernel.org/linux-riscv/20260723-p8700-zalrsc-v4-1-59c21b252e29@htecgroup.com/
---
 arch/riscv/Kconfig.errata       |  1 +
 arch/riscv/errata/mips/Makefile |  6 ++++++
 arch/riscv/errata/mips/errata.c | 38 +++++++++++++++++++++++---------------
 3 files changed, 30 insertions(+), 15 deletions(-)

diff --git a/arch/riscv/Kconfig.errata b/arch/riscv/Kconfig.errata
index 3c945d086c7d0266b685f9506d58b0662af071c4..45f3a4a7c9e234e1dc95ff4595a91922ce6176d1 100644
--- a/arch/riscv/Kconfig.errata
+++ b/arch/riscv/Kconfig.errata
@@ -24,6 +24,7 @@ config ERRATA_ANDES_CMO
 config ERRATA_MIPS
 	bool "MIPS errata"
 	depends on RISCV_ALTERNATIVE
+	select RISCV_ALTERNATIVE_EARLY
 	help
 	  All MIPS errata Kconfig depend on this Kconfig. Disabling
 	  this Kconfig will disable all MIPS errata. Please say "Y"
diff --git a/arch/riscv/errata/mips/Makefile b/arch/riscv/errata/mips/Makefile
index 6278c389b801ee6e54e808c80e6e236c026329c7..137e700d9d3f8ed79ac03f996934c54af99a56b3 100644
--- a/arch/riscv/errata/mips/Makefile
+++ b/arch/riscv/errata/mips/Makefile
@@ -1,5 +1,11 @@
 ifdef CONFIG_RISCV_ALTERNATIVE_EARLY
 CFLAGS_errata.o := -mcmodel=medany
+ifdef CONFIG_FTRACE
+CFLAGS_REMOVE_errata.o = $(CC_FLAGS_FTRACE)
+endif
+ifdef CONFIG_KASAN
+KASAN_SANITIZE_errata.o := n
+endif
 endif
 
 obj-y += errata.o
diff --git a/arch/riscv/errata/mips/errata.c b/arch/riscv/errata/mips/errata.c
index 2c3dc2259e93e9e5181d60843e66da5625bda56f..ac9a12d0a30c9d2bf5d4920d5f6e9d2ed22fe0e5 100644
--- a/arch/riscv/errata/mips/errata.c
+++ b/arch/riscv/errata/mips/errata.c
@@ -7,12 +7,13 @@
 #include <linux/module.h>
 #include <asm/text-patching.h>
 #include <asm/alternative.h>
+#include <asm/cacheflush.h>
 #include <asm/errata_list.h>
 #include <asm/vendorid_list.h>
 #include <asm/vendor_extensions.h>
 #include <asm/vendor_extensions/mips.h>
 
-static inline bool errata_probe_pause(void)
+static inline bool errata_probe_pause(unsigned int stage)
 {
 	if (!IS_ENABLED(CONFIG_ERRATA_MIPS_P8700_PAUSE_OPCODE))
 		return false;
@@ -20,14 +21,17 @@ static inline bool errata_probe_pause(void)
 	if (!riscv_isa_vendor_extension_available(MIPS_VENDOR_ID, XMIPSEXECTL))
 		return false;
 
+	if (stage == RISCV_ALTERNATIVES_EARLY_BOOT)
+		return false;
+
 	return true;
 }
 
-static u32 mips_errata_probe(void)
+static u32 mips_errata_probe(unsigned int stage)
 {
 	u32 cpu_req_errata = 0;
 
-	if (errata_probe_pause())
+	if (errata_probe_pause(stage))
 		cpu_req_errata |= BIT(ERRATA_MIPS_P8700_PAUSE_OPCODE);
 
 	return cpu_req_errata;
@@ -38,30 +42,34 @@ void mips_errata_patch_func(struct alt_entry *begin, struct alt_entry *end,
 			    unsigned int stage)
 {
 	struct alt_entry *alt;
-	u32 cpu_req_errata = mips_errata_probe();
+	u32 cpu_req_errata = mips_errata_probe(stage);
 	u32 tmp;
+	void *oldptr, *altptr;
 
 	BUILD_BUG_ON(ERRATA_MIPS_NUMBER >= RISCV_VENDOR_EXT_ALTERNATIVES_BASE);
 
-	if (stage == RISCV_ALTERNATIVES_EARLY_BOOT)
-		return;
-
 	for (alt = begin; alt < end; alt++) {
 		if (alt->vendor_id != MIPS_VENDOR_ID)
 			continue;
 
-		if (alt->patch_id >= ERRATA_MIPS_NUMBER) {
-			WARN(1, "MIPS errata id:%d not in kernel errata list\n",
-			     alt->patch_id);
+		if (alt->patch_id >= ERRATA_MIPS_NUMBER)
 			continue;
-		}
 
 		tmp = (1U << alt->patch_id);
 		if (cpu_req_errata & tmp) {
-			mutex_lock(&text_mutex);
-			patch_text_nosync(ALT_OLD_PTR(alt), ALT_ALT_PTR(alt),
-					  alt->alt_len);
-			mutex_unlock(&text_mutex);
+			oldptr = ALT_OLD_PTR(alt);
+			altptr = ALT_ALT_PTR(alt);
+
+			if (stage == RISCV_ALTERNATIVES_EARLY_BOOT) {
+				memcpy(oldptr, altptr, alt->alt_len);
+			} else {
+				mutex_lock(&text_mutex);
+				patch_text_nosync(oldptr, altptr, alt->alt_len);
+				mutex_unlock(&text_mutex);
+			}
 		}
 	}
+
+	if (stage == RISCV_ALTERNATIVES_EARLY_BOOT)
+		local_flush_icache_all();
 }

---
base-commit: f5098b6bae761e346ebcd9da7f95622c04733cff
change-id: 20260731-p8700-early-boot-64ee225e8a1c

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

