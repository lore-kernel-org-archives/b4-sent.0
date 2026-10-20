From: Marco Peereboom <marco.peereboom@amd.com>
Date: Tue, 20 Oct 2026 15:19:27 +0530
Subject: [PATCH] x86/mm: Use a WB source mapping for early enc/dec when PAT
 has no WP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-x86-mm-pat-wp-v1-1-a3e604a77e95@amd.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyMD3QoLM93cXN2CxBLd8gJds+RkU0sTgxSLxBQjJaCegqLUtMwKsHn
 RsbW1AKJnoOdfAAAA
X-Change-ID: 20261020-x86-mm-pat-wp-6cc5940d8ad2
To: Dave Hansen <dave.hansen@linux.intel.com>, 
 Andy Lutomirski <luto@kernel.org>, Peter Zijlstra <peterz@infradead.org>, 
 Thomas Gleixner <tglx@kernel.org>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>
Cc: linux-kernel@vger.kernel.org, Tom Lendacky <thomas.lendacky@amd.com>, 
 stable@vger.kernel.org, Marco Peereboom <marco.peereboom@amd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792489774; l=5930;
 i=marco.peereboom@amd.com; h=from:subject:message-id;
 bh=PW798LdOY8CgdZ6XlCmQBOUoKatJ/5Tou6dw1/LkBlk=;
 b=iAIrq+qkaMhdNM0BHpr4HNG70miZpVv6nihFLoi0xBaEbFt95ylj34AnmNx5TPtOdRyOlthSp
 2pMeOIVI3kPBEAdmfWV6IbW+9Nt5pmrD1vKX0ex3Oy3hTWBWnboMZ3B
X-Developer-Key: i=marco.peereboom@amd.com; a=ed25519;
 pk=AXq71lLcEgQ4k5+wem4vJwVM7l9WTUkxZZz88KrUcNw=
X-Endpoint-Received: by B4 Relay for marco.peereboom@amd.com/default with auth_id=1179
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__sme_early_enc_dec() maps the source of the in-place copy with
early_memremap_{en,de}crypted_wp(). These helpers return NULL when the
PAT has no WP entry, and the BUG_ON(!src || !dst) then fires.

The PAT has no WP entry when PAT is disabled: with CONFIG_X86_PAT=n,
with the "nopat" boot option, with a CPU that has no PAT, or with a PAT
MSR of 0 from the firmware. The kernel then does not write its own PAT
value. It uses the firmware PAT value or the default WB, WT, UC-, UC
layout. These normally have no WP entry, so the WP cache mode falls
back to UC- and x86_has_pat_wp() returns false.

An SEV, SEV-ES, or SEV-SNP guest in this state stops in start_kernel()
when kvm_smp_prepare_boot_cpu() decrypts the per-CPU data through
sev_map_percpu_data(), __set_percpu_decrypted() and
early_set_memory_decrypted():

  kernel BUG at arch/x86/mm/mem_encrypt_amd.c:124!
  PANIC: early exception 0x06 IP 10:ffffffffa34f7368 error 0
  RIP: 0010:__sme_early_enc_dec+0x78/0x110
  Call Trace:
   ? __set_clr_pte_enc+0x51/0xb0
   ? early_set_memory_enc_dec+0x7c/0x150
   ? kvm_smp_prepare_boot_cpu+0x67/0xb0
   ? start_kernel+0x1ee/0x670

With CONFIG_KVM_GUEST=n, an SEV-ES or SEV-SNP guest hits the same
BUG_ON later in start_kernel(), when init_ghcb() decrypts the GHCB
pages.

Both paths run before the console is registered, so the guest stops
with no output unless earlyprintk or earlycon is enabled. The BUG fires
before trap_init() sets up the exception handlers, so
early_fixup_exception() halts the CPU. The guest does not panic, and
"panic=" does not reboot it.

The WP mapping makes sure that the source leaves no modified cache line
with the old encryption attribute. The copy only reads the source, and
for reads WP and WB are the same: both allocate clean cache lines.
Before the copy, prepare_pte_enc() flushes the whole range through the
old mapping with clflush_cache_range(). Also, the direct map already
maps the same page as WB with the old encryption attribute. So a WB
source mapping adds no new hazard: no modified line with the old
encryption attribute can later overwrite the destination.

The hypervisor can make an SEV guest take the WB path, for example
when it hides the PAT CPUID bit. This adds no exposure, because nothing
writes through the source mapping. Before this change, the hypervisor
could use the same condition only to stop the guest.

Use a WB mapping for the source when x86_has_pat_wp() is false. Keep
the WP mapping when the PAT has a WP entry. That is the Encrypt-in-Place
procedure in APM Volume 2, Section 7.10.8. Also, with WP an accidental
write through the source mapping goes to memory and leaves no modified
cache line. Only the path that hit the BUG_ON changes.

A Kconfig dependency of AMD_MEM_ENCRYPT on X86_PAT is not sufficient.
It does not cover "nopat", a CPU without PAT, or a PAT MSR of 0 from
the firmware. Also, "select X86_PAT" would bypass the dependency of
X86_PAT on MTRR.

Fixes: 7f8b7e7f4ccb ("x86/mm: Add support for early encryption/decryption of memory")
Cc: Tom Lendacky <thomas.lendacky@amd.com>
Cc: stable@vger.kernel.org
Signed-off-by: Marco Peereboom <marco.peereboom@amd.com>
---
- Tested on tip/master c803a3f00 (2026-10-19) with SEV-SNP guests on
  AMD EPYC 9755 (Turin), QEMU 10.2.2, OVMF edk2-ovmf-20260812
  (OVMF.amdsev.fd). Without the fix, CONFIG_X86_PAT=n and "nopat" hit
  the BUG_ON. With the fix, both boot to user space. CONFIG_X86_PAT=y
  without "nopat" boots with and without the fix, and the PAT is
  unchanged.
- Also tested with plain SEV guests on the same host and kernels. The
  guest reports "SEV: Status: SEV", so the memcpy() branch runs.
  Without the fix, CONFIG_X86_PAT=n and "nopat" hit the BUG_ON. With
  the fix, the guest boots to user space. CONFIG_X86_PAT=y without
  "nopat" boots without the fix.
- Not tested: SEV-ES. With SEV-SNP initialized, this SEV firmware
  rejects SEV-ES guests (AMD-SB-3023): LAUNCH_START fails with
  SEV_RET_UNSUPPORTED. SEV-ES takes the same memcpy() branch as SEV.
- The test host has SME_COHERENT. Tom, please confirm the WB argument
  for CPUs without it.
- Reproduce: boot any SEV-SNP guest kernel with "nopat".
---
 arch/x86/mm/mem_encrypt_amd.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/arch/x86/mm/mem_encrypt_amd.c b/arch/x86/mm/mem_encrypt_amd.c
index 2f8c32173..3ba2af176 100644
--- a/arch/x86/mm/mem_encrypt_amd.c
+++ b/arch/x86/mm/mem_encrypt_amd.c
@@ -28,6 +28,7 @@
 #include <asm/cacheflush.h>
 #include <asm/processor-flags.h>
 #include <asm/msr.h>
+#include <asm/memtype.h>
 #include <asm/cmdline.h>
 #include <asm/sev.h>
 #include <asm/ia32.h>
@@ -108,10 +109,19 @@ static void __init __sme_early_enc_dec(resource_size_t paddr,
 
 		/*
 		 * Create mappings for the current and desired format of
-		 * the memory. Use a write-protected mapping for the source.
+		 * the memory. Use a write-protected mapping for the source
+		 * if the PAT has a WP entry, else a write-back mapping. The
+		 * source is only read, so neither mapping creates modified
+		 * cache lines. Modified lines with the old attribute were
+		 * flushed before this call (see prepare_pte_enc()).
 		 */
-		src = enc ? early_memremap_decrypted_wp(paddr, len) :
-			    early_memremap_encrypted_wp(paddr, len);
+		if (x86_has_pat_wp()) {
+			src = enc ? early_memremap_decrypted_wp(paddr, len) :
+				    early_memremap_encrypted_wp(paddr, len);
+		} else {
+			src = enc ? early_memremap_decrypted(paddr, len) :
+				    early_memremap_encrypted(paddr, len);
+		}
 
 		dst = enc ? early_memremap_encrypted(paddr, len) :
 			    early_memremap_decrypted(paddr, len);

---
base-commit: c803a3f002ec36285d15c462ac3519198207bb3a
change-id: 20261020-x86-mm-pat-wp-6cc5940d8ad2

Best regards,
-- 
Marco Peereboom <marco.peereboom@amd.com>

