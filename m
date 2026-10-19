From: Cunhao Lu <1579567540@qq.com>
Date: Mon, 19 Oct 2026 15:31:14 +0800
Subject: [PATCH] rockchip: ram: Fix LPDDR5X size decoding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-lpddr5x-size-fix-v1-1-3688217baaa2@qq.com>
X-B4-Tracking: v=1; b=H4sIAELH1WoC/yXMQQqDQBBE0atIr22whUjMVSQLnSljixiZjiIR7
 +6oy1dQfyNDUBi9ko0CFjX9jhGSJuS6evyA1UdTnuWFZFLyMHkfHiub/sGtrtw2ECe1FE8Pirc
 pIM5Xsnrftrnp4X5nh/b9AIm7Afl0AAAA
X-Change-ID: 20261019-lpddr5x-size-fix-fbe1c1a168de
To: Simon Glass <sjg@chromium.org>, u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Quentin Schulz <u-boot@0leil.net>, Kever Yang <kever.yang@rock-chips.com>, 
 Anshul Dalal <anshuld@ti.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792395082; l=2803;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=uoV5703LbUklS2lJ/0yaFsSZJhHH9ohGZItMvS3T4MI=;
 b=OwlMi7Oox5Q027sA4pWfN2ECgwJ6HC9eKx+Z+CtY4NrkhD+cM2XvViZ3DrYQjYlWDL/2TbCPN
 ulKj2h3auTxCfmu0Qz902eEU6ZLnFX3zt2t6XZgZ5P7Ez2PMONtFaJj
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The shared SDRAM decoder treats type 10 as DDR5 and uses the wrong
bank count for LPDDR5X. On the 4 GiB OK3572-C, register values
0x100043c1 and 0x30001001 therefore produce a size of 1 GiB.

Define LPDDR5X as type 10 and DDR5 as type 11. Apply the existing
LPDDR5 bank decoding to LPDDR5X so the same register values yield
4 GiB. The type values match include/soc/rockchip/rockchip_grf.h in
the kernel-6.12 sources of Forlinx OK3572-C BSP Alpha1.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
This patch fixes LPDDR5X capacity decoding in Rockchip's shared SDRAM
decoder.

The geometry registers captured on a Forlinx OK3572-C with 4 GiB of
LPDDR5X are 0x100043c1 and 0x30001001. The current decoder labels type
10 as DDR5 and uses the generic bank calculation. With the bank bit
set, it assumes four banks instead of 16 and reports only 1 GiB.

Define LPDDR5X as type 10 and DDR5 as type 11, following the Rockchip
type definitions in Forlinx OK3572-C BSP Alpha1. Use the existing
LPDDR5 bank calculation for LPDDR5X so the captured register values
decode to the correct 4 GiB capacity.

The fix applies to mainline independently of the RK3572 SoC and board
support.

Host-side validation of the decoder with the captured register values
reproduced 1 GiB before the fix and returned 4 GiB after it. Regression
checks for eight other memory type codes produced the same results
before and after the fix, with no UBSan errors.
---
 arch/arm/include/asm/arch-rockchip/sdram.h | 3 ++-
 arch/arm/mach-rockchip/sdram.c             | 4 ++--
 2 files changed, 4 insertions(+), 3 deletions(-)

diff --git a/arch/arm/include/asm/arch-rockchip/sdram.h b/arch/arm/include/asm/arch-rockchip/sdram.h
index 476fc1c4e..f5a213fde 100644
--- a/arch/arm/include/asm/arch-rockchip/sdram.h
+++ b/arch/arm/include/asm/arch-rockchip/sdram.h
@@ -14,7 +14,8 @@ enum {
 	LPDDR4 = 7,
 	LPDDR4X = 8,
 	LPDDR5 = 9,
-	DDR5 = 10,
+	LPDDR5X = 10,
+	DDR5 = 11,
 	UNUSED = 0xFF
 };
 
diff --git a/arch/arm/mach-rockchip/sdram.c b/arch/arm/mach-rockchip/sdram.c
index 2e404df1b..b58919137 100644
--- a/arch/arm/mach-rockchip/sdram.c
+++ b/arch/arm/mach-rockchip/sdram.c
@@ -403,8 +403,8 @@ size_t rockchip_sdram_size(phys_addr_t reg)
 		cs0_col = 9 + (sys_reg2 >> SYS_REG_COL_SHIFT(ch) &
 			  SYS_REG_COL_MASK);
 		cs1_col = cs0_col;
-		if (dram_type == LPDDR5)
-			/* LPDDR5: 0:8bank(bk=3), 1:16bank(bk=4) */
+		if (dram_type == LPDDR5 || dram_type == LPDDR5X)
+			/* LPDDR5/LPDDR5X: 0:8bank(bk=3), 1:16bank(bk=4) */
 			bk = 3 + ((sys_reg2 >> SYS_REG_BK_SHIFT(ch)) &
 			SYS_REG_BK_MASK);
 		else

---
base-commit: 8d534cec0cc0109a37c0ded8854da03f1526dc0e
change-id: 20261019-lpddr5x-size-fix-fbe1c1a168de

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

