From: Brett Mastbergen <bmastbergen@ciq.com>
Date: Tue, 15 Apr 2025 14:59:53 -0400
Subject: [PATCH REGRESSION-FIX] x86/paravirt: Move halt paravirt calls
 under CONFIG_PARAVIRT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250415-stable_fixup-v1-1-0bea1b5f583c@ciq.com>
X-B4-Tracking: v=1; b=H4sIAKis/mcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0NT3eKSxKSc1Pi0zIrSAt1k8yRLYzMTc+M0U2MloJaColSgBNi46Nj
 aWgDM1KX9XgAAAA==
X-Change-ID: 20250415-stable_fixup-c7b936473f53
To: stable@vger.kernel.org
Cc: Thomas Gleixner <tglx@linutronix.de>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>, 
 Juergen Gross <jgross@suse.com>, Ajay Kaher <ajay.kaher@broadcom.com>, 
 Alexey Makhalov <alexey.amakhalov@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 "Kirill A. Shutemov" <kirill.shutemov@linux.intel.com>, 
 Tony Luck <tony.luck@intel.com>, 
 Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>, 
 Andi Kleen <ak@linux.intel.com>, linux-kernel@vger.kernel.org, 
 virtualization@lists.linux.dev, regressions@lists.linux.dev, 
 Vishal Annapurve <vannapurve@google.com>, Ingo Molnar <mingo@kernel.org>, 
 Ryan Afranji <afranji@google.com>, Andy Lutomirski <luto@kernel.org>, 
 Brian Gerst <brgerst@gmail.com>, 
 Linus Torvalds <torvalds@linux-foundation.org>, stable@kernel.org, 
 Brett Mastbergen <bmastbergen@ciq.com>, 
 Josh Poimboeuf <jpoimboe@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744743638; l=7817;
 i=bmastbergen@ciq.com; s=20250415; h=from:subject:message-id;
 bh=nfdTL9dMpc7u6M9sFod5SqMNA326684hq87+QJyATs8=;
 b=+t5fxrpGcEx5x+umwsUmc9j7PdY5seiSW08bQ2eIx6c6HOhRuigDDLzT+Ai4hQmRuNogfIQjg
 kGWz7WJjpTDCiYyzXgKseZJrgTjcepcZEfn5yRQuzZ6RFwpHCmzaEu2
X-Developer-Key: i=bmastbergen@ciq.com; a=ed25519;
 pk=cjlR63i7BVF/7E0Yr3hTlnxYS/pC3WTR15UQusOZio4=
X-Endpoint-Received: by B4 Relay for bmastbergen@ciq.com/20250415 with auth_id=379
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Kirill A. Shutemov" <kirill.shutemov@linux.intel.com>

CONFIG_PARAVIRT_XXL is mainly defined/used by XEN PV guests. For
other VM guest types, features supported under CONFIG_PARAVIRT
are self sufficient. CONFIG_PARAVIRT mainly provides support for
TLB flush operations and time related operations.

For TDX guest as well, paravirt calls under CONFIG_PARVIRT meets
most of its requirement except the need of HLT and SAFE_HLT
paravirt calls, which is currently defined under
CONFIG_PARAVIRT_XXL.

Since enabling CONFIG_PARAVIRT_XXL is too bloated for TDX guest
like platforms, move HLT and SAFE_HLT paravirt calls under
CONFIG_PARAVIRT.

Moving HLT and SAFE_HLT paravirt calls are not fatal and should not
break any functionality for current users of CONFIG_PARAVIRT.

Fixes: bfe6ed0c6727 ("x86/tdx: Add HLT support for TDX guests")
Co-developed-by: Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>
Signed-off-by: Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>
Signed-off-by: Kirill A. Shutemov <kirill.shutemov@linux.intel.com>
Signed-off-by: Vishal Annapurve <vannapurve@google.com>
Signed-off-by: Ingo Molnar <mingo@kernel.org>
Reviewed-by: Andi Kleen <ak@linux.intel.com>
Reviewed-by: Tony Luck <tony.luck@intel.com>
Reviewed-by: Juergen Gross <jgross@suse.com>
Tested-by: Ryan Afranji <afranji@google.com>
Cc: Andy Lutomirski <luto@kernel.org>
Cc: Brian Gerst <brgerst@gmail.com>
Cc: H. Peter Anvin <hpa@zytor.com>
Cc: Linus Torvalds <torvalds@linux-foundation.org>
Cc: Josh Poimboeuf <jpoimboe@redhat.com>
Cc: stable@kernel.org
Link: https://lore.kernel.org/r/20250228014416.3925664-2-vannapurve@google.com
---
6.12.23 fails to build with the following error if CONFIG_XEN_PV is
not set:

arch/x86/coco/tdx/tdx.c: In function ‘tdx_early_init’:
arch/x86/coco/tdx/tdx.c:1080:19: error: ‘struct pv_irq_ops’ has no member
named ‘safe_halt’
 1080 |         pv_ops.irq.safe_halt = tdx_safe_halt;
      |                   ^
arch/x86/coco/tdx/tdx.c:1081:19: error: ‘struct pv_irq_ops’ has no member
named ‘halt’
 1081 |         pv_ops.irq.halt = tdx_halt;
      |                   ^

This is because XEN_PV selects PARAVIRT_XXL, and 'safe_halt' and
'halt' are only defined for pv_irq_ops if PARAVIRT_XXL is defined.

The build breakage was introduced in 6.12.23 by stable commit
805e3ce5e0e3 which is a backport of 9f98a4f4e721 ("x86/tdx: Fix
arch_safe_halt() execution for TDX VMs").

Consider picking up upstream commit 22cc5ca5de52 ("x86/paravirt:
Move halt paravirt calls under CONFIG_PARAVIRT") for stable 6.12.y
which fixes the build regression by moving 'safe_halt' and 'halt'
out from under the PARAVIRT_XXL config.

This patch is 22cc5ca5de52 backported to 6.12.23.  There were a
couple of merge conflicts due to the missing upstream commits below:

29188c160061 ("x86/paravirt: Remove the WBINVD callback")
3101900218d7 ("x86/paravirt: Remove unused paravirt_disable_iospace()")

I wasn't sure if it was appropriate to pull those to stable as well
and the merge conflicts were trivial.

Thanks!

Signed-off-by: Brett Mastbergen <bmastbergen@ciq.com>
---
 arch/x86/include/asm/irqflags.h       | 40 +++++++++++++++++++----------------
 arch/x86/include/asm/paravirt.h       | 20 +++++++++---------
 arch/x86/include/asm/paravirt_types.h |  3 +--
 arch/x86/kernel/paravirt.c            | 13 +++++++-----
 4 files changed, 41 insertions(+), 35 deletions(-)

diff --git a/arch/x86/include/asm/irqflags.h b/arch/x86/include/asm/irqflags.h
index cf7fc2b8e3ce1f4e5f5703ae9fbb5a7e1182ad4f..1c2db11a2c3cb9a289d80d4900b9933275d1eea6 100644
--- a/arch/x86/include/asm/irqflags.h
+++ b/arch/x86/include/asm/irqflags.h
@@ -76,6 +76,28 @@ static __always_inline void native_local_irq_restore(unsigned long flags)
 
 #endif
 
+#ifndef CONFIG_PARAVIRT
+#ifndef __ASSEMBLY__
+/*
+ * Used in the idle loop; sti takes one instruction cycle
+ * to complete:
+ */
+static __always_inline void arch_safe_halt(void)
+{
+	native_safe_halt();
+}
+
+/*
+ * Used when interrupts are already enabled or to
+ * shutdown the processor:
+ */
+static __always_inline void halt(void)
+{
+	native_halt();
+}
+#endif /* __ASSEMBLY__ */
+#endif /* CONFIG_PARAVIRT */
+
 #ifdef CONFIG_PARAVIRT_XXL
 #include <asm/paravirt.h>
 #else
@@ -97,24 +119,6 @@ static __always_inline void arch_local_irq_enable(void)
 	native_irq_enable();
 }
 
-/*
- * Used in the idle loop; sti takes one instruction cycle
- * to complete:
- */
-static __always_inline void arch_safe_halt(void)
-{
-	native_safe_halt();
-}
-
-/*
- * Used when interrupts are already enabled or to
- * shutdown the processor:
- */
-static __always_inline void halt(void)
-{
-	native_halt();
-}
-
 /*
  * For spinlocks, etc:
  */
diff --git a/arch/x86/include/asm/paravirt.h b/arch/x86/include/asm/paravirt.h
index d4eb9e1d61b8ef8a3fc3a2510b0615ea93c11cb8..75d4c994f5e2a5dcbc2edbf7eed617de4a141fa0 100644
--- a/arch/x86/include/asm/paravirt.h
+++ b/arch/x86/include/asm/paravirt.h
@@ -107,6 +107,16 @@ static inline void notify_page_enc_status_changed(unsigned long pfn,
 	PVOP_VCALL3(mmu.notify_page_enc_status_changed, pfn, npages, enc);
 }
 
+static __always_inline void arch_safe_halt(void)
+{
+	PVOP_VCALL0(irq.safe_halt);
+}
+
+static inline void halt(void)
+{
+	PVOP_VCALL0(irq.halt);
+}
+
 #ifdef CONFIG_PARAVIRT_XXL
 static inline void load_sp0(unsigned long sp0)
 {
@@ -170,16 +180,6 @@ static inline void __write_cr4(unsigned long x)
 	PVOP_VCALL1(cpu.write_cr4, x);
 }
 
-static __always_inline void arch_safe_halt(void)
-{
-	PVOP_VCALL0(irq.safe_halt);
-}
-
-static inline void halt(void)
-{
-	PVOP_VCALL0(irq.halt);
-}
-
 extern noinstr void pv_native_wbinvd(void);
 
 static __always_inline void wbinvd(void)
diff --git a/arch/x86/include/asm/paravirt_types.h b/arch/x86/include/asm/paravirt_types.h
index 8d4fbe1be489549ad33c968c2132bdbaf739b871..9334fdd1f6350231af7089802dfb94daa1653965 100644
--- a/arch/x86/include/asm/paravirt_types.h
+++ b/arch/x86/include/asm/paravirt_types.h
@@ -122,10 +122,9 @@ struct pv_irq_ops {
 	struct paravirt_callee_save save_fl;
 	struct paravirt_callee_save irq_disable;
 	struct paravirt_callee_save irq_enable;
-
+#endif
 	void (*safe_halt)(void);
 	void (*halt)(void);
-#endif
 } __no_randomize_layout;
 
 struct pv_mmu_ops {
diff --git a/arch/x86/kernel/paravirt.c b/arch/x86/kernel/paravirt.c
index fec38153355581215eb93b6301ae90b6f0bd06c5..0c1b915d7efac895b2c8be67eb3b84b998d00fbc 100644
--- a/arch/x86/kernel/paravirt.c
+++ b/arch/x86/kernel/paravirt.c
@@ -100,6 +100,11 @@ int paravirt_disable_iospace(void)
 	return request_resource(&ioport_resource, &reserve_ioports);
 }
 
+static noinstr void pv_native_safe_halt(void)
+{
+	native_safe_halt();
+}
+
 #ifdef CONFIG_PARAVIRT_XXL
 static noinstr void pv_native_write_cr2(unsigned long val)
 {
@@ -121,10 +126,6 @@ noinstr void pv_native_wbinvd(void)
 	native_wbinvd();
 }
 
-static noinstr void pv_native_safe_halt(void)
-{
-	native_safe_halt();
-}
 #endif
 
 struct pv_info pv_info = {
@@ -182,9 +183,11 @@ struct paravirt_patch_template pv_ops = {
 	.irq.save_fl		= __PV_IS_CALLEE_SAVE(pv_native_save_fl),
 	.irq.irq_disable	= __PV_IS_CALLEE_SAVE(pv_native_irq_disable),
 	.irq.irq_enable		= __PV_IS_CALLEE_SAVE(pv_native_irq_enable),
+#endif /* CONFIG_PARAVIRT_XXL */
+
+	/* Irq HLT ops. */
 	.irq.safe_halt		= pv_native_safe_halt,
 	.irq.halt		= native_halt,
-#endif /* CONFIG_PARAVIRT_XXL */
 
 	/* Mmu ops. */
 	.mmu.flush_tlb_user	= native_flush_tlb_local,

---
base-commit: 83b4161a63b87ce40d9f24f09b5b006f63d95b7c
change-id: 20250415-stable_fixup-c7b936473f53

Best regards,
-- 
Brett Mastbergen <bmastbergen@ciq.com>

