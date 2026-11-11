From: Hunter Laux <hunterlaux@gmail.com>
Date: Tue, 10 Nov 2026 21:09:03 -0700
Subject: [PATCH] MIPS: ingenic: Let Config.VI tell whether the icache is
 virtual
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261110-mips-xburst-icache-vi-v1-1-efba689606dd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAF7q82oC/x3MPQqAMAxA4atIZgONgohXEYfaRM3gD42KULy7x
 fEb3ktgElUMuiJBlFtN9y2DygLC4rdZUDkbKlc1RORw1cPwGa9oJ2rwYRG8FXkk51t2NXMDuT2
 iTPr833543w+ofuiIZwAAAA==
To: Paul Cercueil <paul@crapouillou.net>, 
 Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Lars-Peter Clausen <lars@metafoo.de>, Hunter Laux <hunterlaux@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794370145; l=2681;
 i=hunterlaux@gmail.com; s=20261109; h=from:subject:message-id;
 bh=cXFr6wRPxVPgKvzA/Ve7zSz/KJTDwuu+N1xApA/N3xY=;
 b=UKlZ8oi6sWqvZJ0m3xZeRfzwO8CcyCPNgl6B2IiUpljtQGdiBROaXejpdWeYKhZKvsPCgwTZl
 uovwasrpm1wDmmpxs++CRRWRW1mguTLQ7oPxp8YAZeAAvOUpqYo7Rvp
X-Developer-Key: i=hunterlaux@gmail.com; a=ed25519;
 pk=Z5VTsE4CAwditt0CNeG+rpPk7xDUVh+oHWDZlNNm8FI=
X-Endpoint-Received: by B4 Relay for hunterlaux@gmail.com/20261109 with auth_id=1476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Ingenic CPU support treats every XBurst instruction cache as
virtually tagged: the feature overrides fix cpu_has_vtag_icache to 1,
and the probe sets MIPS_CACHE_VTAG. The setting came in with the JZ4740
feature overrides in commit 83ccf69d8f11 ("MIPS: JZ4740: Add base
support for Ingenic JZ4740 System-on-a-Chip") without a stated reason,
and Ingenic's own kernels treat the icache as physically tagged.

Neither XBurst1 nor XBurst II has a virtually tagged icache. Both
programming manuals describe a physically tagged one and hardwire
Config.VI to 0, which the cache probe already reads. On the X2600, code
at a virtual address remapped to another page through the TLB alone
runs the new page, while the old line is still in the icache. XBurst1
has not been tested. Treating the icache as virtually tagged is
incorrect and costs needless icache flushes.

Drop both and leave it to Config.VI.

Cc: Lars-Peter Clausen <lars@metafoo.de>
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Hunter Laux <hunterlaux@gmail.com>
---
Lars, the override came with your JZ4740 support in 2010. On the off
chance you remember a reason for setting cpu_has_vtag_icache to 1,
I'd like to hear it.
---
 arch/mips/include/asm/mach-ingenic/cpu-feature-overrides.h | 1 -
 arch/mips/kernel/cpu-probe.c                               | 3 ---
 2 files changed, 4 deletions(-)

diff --git a/arch/mips/include/asm/mach-ingenic/cpu-feature-overrides.h b/arch/mips/include/asm/mach-ingenic/cpu-feature-overrides.h
index 7ace50127f..71c03f1dd4 100644
--- a/arch/mips/include/asm/mach-ingenic/cpu-feature-overrides.h
+++ b/arch/mips/include/asm/mach-ingenic/cpu-feature-overrides.h
@@ -27,7 +27,6 @@
 #define cpu_has_mips3d 0
 #define cpu_has_smartmips 0
 #define kernel_uses_llsc	1
-#define cpu_has_vtag_icache	1
 #define cpu_has_dc_aliases	0
 #define cpu_has_ic_fills_f_dc	0
 #define cpu_has_pindexed_dcache 0
diff --git a/arch/mips/kernel/cpu-probe.c b/arch/mips/kernel/cpu-probe.c
index 489612ed9d..bef92e6cd6 100644
--- a/arch/mips/kernel/cpu-probe.c
+++ b/arch/mips/kernel/cpu-probe.c
@@ -1763,9 +1763,6 @@ static inline void cpu_probe_ingenic(struct cpuinfo_mips *c, unsigned int cpu)
 	c->options &= ~MIPS_CPU_COUNTER;
 	BUG_ON(__builtin_constant_p(cpu_has_counter) && cpu_has_counter);
 
-	/* XBurst has virtually tagged icache */
-	c->icache.flags |= MIPS_CACHE_VTAG;
-
 	switch (c->processor_id & PRID_IMP_MASK) {
 
 	/* XBurst®1 with MXU1.0/MXU1.1 SIMD ISA */

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-mips-xburst-icache-vi-db10a8d03dd6

Best regards,
-- 
Hunter Laux <hunterlaux@gmail.com>

