From: George Chan <gchan9527@gmail.com>
Date: Mon, 07 Apr 2025 20:44:58 +0800
Subject: [PATCH RFC] bootm: ARM64 EL1 direct jump to kernel start
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250407-el1-boot-v1-1-f7c52499d9c5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMnI82cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEwNz3dQcQ92k/PwSXXNLI0sjs6REMwNLAyWg8oKi1LTMCrBR0bG1tQB
 eZCmVWgAAAA==
To: Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744029916; l=4102;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=GD1dScz1+CT+QozQ4RhYfOQiS9MdEXEF1nvNZ1X8uoU=;
 b=dKmKQr4FszUwY7svjFdvHov40lPlTPq6WV1qwHCdZnK0q5c8SQmFVQHGl1dYx3kJPqYWs0Sm4
 l8G2Y/Q7yOCBH5BUeIKl0S4F/xJWix7lKVETGXShNOvLb+gF9YBRp6a
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It was EL3->EL2 or EL2->EL1 when boot. But in many case such chain
loading from bootloader is already run in EL1.

There is no practically way to raise EL1 to EL2. Thus theonly way
to start kernel is direct jump. This apporach is similar to KEXEC
purgatory idea but do not need to make an extra bulk of binary blob.
This applied when current_el() is 1 only.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
U-Boot usually run in EL3 or EL2 mode so assumed kernel will start
at EL2, or switch from EL2 to enter EL1. Test shows in QCOM SM7125
phone environment chainloading U-Boot is already in EL1 so doing 
EL2 transition EL1 gone wrong.

This patch enable the EL1 chain loading kernel by direct jump to 
image->ep address. This calling convention apply to bootm only.

In short, borrow the logic from kexec-tool purgatory idea and issue
a direct jump when current_el() is EL1.
---
 arch/arm/cpu/armv8/Makefile |  2 +-
 arch/arm/cpu/armv8/entry.S  | 42 ++++++++++++++++++++++++++++++++++++++++++
 arch/arm/lib/bootm.c        | 18 ++++++++++++++++--
 3 files changed, 59 insertions(+), 3 deletions(-)

diff --git a/arch/arm/cpu/armv8/Makefile b/arch/arm/cpu/armv8/Makefile
index b4126c61df1..d5b0ffe8c87 100644
--- a/arch/arm/cpu/armv8/Makefile
+++ b/arch/arm/cpu/armv8/Makefile
@@ -5,7 +5,7 @@
 
 extra-y	:= start.o
 
-obj-y	+= cpu.o
+obj-y	+= cpu.o entry.o
 ifndef CONFIG_$(PHASE_)TIMER
 obj-$(CONFIG_SYS_ARCH_TIMER) += generic_timer.o
 endif
diff --git a/arch/arm/cpu/armv8/entry.S b/arch/arm/cpu/armv8/entry.S
new file mode 100644
index 00000000000..19a7da2438e
--- /dev/null
+++ b/arch/arm/cpu/armv8/entry.S
@@ -0,0 +1,42 @@
+/*
+ * ARM64 purgatory.
+ */
+#include <asm-offsets.h>
+#include <config.h>
+#include <linux/linkage.h>
+#include <asm/macro.h>
+
+.macro  size, sym:req
+        .size \sym, . - \sym
+.endm
+
+.pushsection .text.purgatory_start, "ax"
+ENTRY(purgatory_start)
+purgatory_start:
+
+//	adr	x19, .Lstack
+//	mov	sp, x19
+
+//	bl	purgatory
+
+	/* Start new image. */
+	ldr	x17, kernel_entry
+	ldr	x0, dtb_addr
+	mov	x1, xzr
+	mov	x2, xzr
+	mov	x3, xzr
+	br	x17
+ENDPROC(purgatory_start)
+.popsection
+.align 3
+
+.globl kernel_entry
+kernel_entry:
+        .quad   0
+size kernel_entry
+
+.globl dtb_addr
+dtb_addr:
+        .quad   0
+size dtb_addr
+.end
diff --git a/arch/arm/lib/bootm.c b/arch/arm/lib/bootm.c
index 974cbfe8400..5a15725317c 100644
--- a/arch/arm/lib/bootm.c
+++ b/arch/arm/lib/bootm.c
@@ -269,6 +269,10 @@ __weak void update_os_arch_secondary_cores(uint8_t os_arch)
 {
 }
 
+extern void (*kernel_entry)(void *fdt_addr, void *res0, void *res1,
+                            void *res2);
+extern void* dtb_addr;
+
 #ifdef CONFIG_ARMV8_SWITCH_TO_EL1
 static void switch_to_el1(void)
 {
@@ -290,13 +294,13 @@ static void switch_to_el1(void)
 static void boot_jump_linux(struct bootm_headers *images, int flag)
 {
 #ifdef CONFIG_ARM64
-	void (*kernel_entry)(void *fdt_addr, void *res0, void *res1,
-			void *res2);
 	int fake = (flag & BOOTM_STATE_OS_FAKE_GO);
 
 	kernel_entry = (void (*)(void *fdt_addr, void *res0, void *res1,
 				void *res2))images->ep;
 
+	dtb_addr = images->ft_addr;
+
 	debug("## Transferring control to Linux (at address %lx)...\n",
 		(ulong) kernel_entry);
 	bootstage_mark(BOOTSTAGE_ID_RUN_OS);
@@ -311,6 +315,16 @@ static void boot_jump_linux(struct bootm_headers *images, int flag)
 
 		update_os_arch_secondary_cores(images->os.arch);
 
+		/* right now switch_to_el1() is hanging the devlice
+		 * when it is already in EL1 so cant do anything about it.
+		 */
+		if (current_el() == 1) {
+			void purgatory_start(void);
+			purgatory_start();
+			panic("nothing to do...\n");
+			return;
+		}
+
 #ifdef CONFIG_ARMV8_SWITCH_TO_EL1
 		armv8_switch_to_el2((u64)images->ft_addr, 0, 0, 0,
 				    (u64)switch_to_el1, ES_TO_AARCH64);

---
base-commit: 848f7ffc64aa7c4cc2229095812625c12343c8c1
change-id: 20250407-el1-boot-792926ba6090

Best regards,
-- 
George Chan <gchan9527@gmail.com>

