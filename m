From: Mitchell Levy <levymitchell0@gmail.com>
Date: Thu, 08 Aug 2024 16:30:10 -0700
Subject: [PATCH] x86/fpu: Avoid writing LBR bit to IA32_XSS unless
 supported
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240808-xsave-lbr-fix-v1-1-a223806c83e7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAFVtWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDCwNz3YrixLJU3ZykIt20zApdA6MUU6M0MxNDM1NjJaCegqJUoDDYvOj
 Y2loA3RILWF8AAAA=
To: Thomas Gleixner <tglx@linutronix.de>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>
Cc: stable@vger.kernel.org, Borislav Petkov <bp@suse.de>, 
 linux-kernel@vger.kernel.org, Mitchell Levy <levymitchell0@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723159817; l=2576;
 i=levymitchell0@gmail.com; s=20240719; h=from:subject:message-id;
 bh=aD/HH3dzvhy4muD2Cy5M+AM0El/r97xW+eGKYw26zH0=;
 b=8zO+Sr3nZNkO0VBtBSMe+DEVkhL/JnpFkIRgRz9xwiRA3wosgdPgOjDqT7Jax6ZpKs639xRMp
 aN2VKMIWN6UDdqZWgjibE8iMOvub2REaomBJsAf1tRvpBT4MRsZaxem
X-Developer-Key: i=levymitchell0@gmail.com; a=ed25519;
 pk=n6kBmUnb+UNmjVkTnDwrLwTJAEKUfs2e8E+MFPZI93E=
X-Endpoint-Received: by B4 Relay for levymitchell0@gmail.com/20240719 with auth_id=188
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When computing which xfeatures are available, make sure that LBR is only
present if both LBR is supported in general, as well as by XSAVES.

There are two distinct CPU features related to the use of XSAVES as it
applies to LBR: whether LBR is itself supported (strictly speaking, I'm
not sure that this is necessary to check though it's certainly a good
sanity check), and whether XSAVES supports LBR (see sections 13.2 and
13.5.12 of the Intel 64 and IA-32 Architectures Software Developer's
Manual, Volume 1). Currently, the LBR subsystem correctly checks both
(see intel_pmu_arch_lbr_init), however the xstate initialization
subsystem does not.

When calculating what value to place in the IA32_XSS MSR,
xfeatures_mask_independent only checks whether LBR support is present,
not whether XSAVES supports LBR. If XSAVES does not support LBR, this
write causes #GP, leaving the state of IA32_XSS unchanged (i.e., set to
zero, as its not written with other values, and its default value is
zero out of RESET per section 13.3 of the arch manual).

Then, the next time XRSTORS is used to restore supervisor state, it will
fail with #GP (because the RFBM has zero for all supervisor features,
which does not match the XCOMP_BV field). In particular,
XFEATURE_MASK_FPSTATE includes supervisor features, so setting up the FPU
will cause a #GP. This results in a call to fpu_reset_from_exception_fixup,
which by the same process results in another #GP. Eventually this causes
the kernel to run out of stack space and #DF.

Fixes: d72c87018d00 ("x86/fpu/xstate: Move remaining xfeature helpers to core")
Cc: stable@vger.kernel.org

Signed-off-by: Mitchell Levy <levymitchell0@gmail.com>
---
 arch/x86/kernel/fpu/xstate.h | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/x86/kernel/fpu/xstate.h b/arch/x86/kernel/fpu/xstate.h
index 2ee0b9c53dcc..574d2c2ea227 100644
--- a/arch/x86/kernel/fpu/xstate.h
+++ b/arch/x86/kernel/fpu/xstate.h
@@ -61,7 +61,8 @@ static inline u64 xfeatures_mask_supervisor(void)
 
 static inline u64 xfeatures_mask_independent(void)
 {
-	if (!cpu_feature_enabled(X86_FEATURE_ARCH_LBR))
+	if (!cpu_feature_enabled(X86_FEATURE_ARCH_LBR) ||
+	    (fpu_kernel_cfg.max_features & XFEATURE_MASK_LBR) != XFEATURE_MASK_LBR)
 		return XFEATURE_MASK_INDEPENDENT & ~XFEATURE_MASK_LBR;
 
 	return XFEATURE_MASK_INDEPENDENT;

---
base-commit: de9c2c66ad8e787abec7c9d7eff4f8c3cdd28aed
change-id: 20240807-xsave-lbr-fix-02d52f641653

Best regards,
-- 
Mitchell Levy <levymitchell0@gmail.com>

