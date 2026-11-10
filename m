From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 06:20:10 +0000
Subject: [PATCH 1/2] sunxi: H616: dram: DDR3: use the JEDEC reset and CKE
 init delays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-h616-dram-retry-v1-1-ccaa6d7a6ef1@gmail.com>
References: <20261110-h616-dram-retry-v1-0-ccaa6d7a6ef1@gmail.com>
In-Reply-To: <20261110-h616-dram-retry-v1-0-ccaa6d7a6ef1@gmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Andre Przywara <andre.przywara@arm.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Arun Iyengar <aiyengar1990@gmail.com>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794291609; l=2506;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Gp0CFoCjE4ys9lGql82Eeni5Jp82PDQ13jSEqGWKAYo=;
 b=wvdPtDLw5kDKVzjTzCqpKN77epuBHFJTSDpCB3vsVCQu2eLXtKMfxxkbDy06MJ1o0oICZX9Xj
 hYBWqjZ9MlJAQdWapQd8qR7ozyRN7m+0YXT+N0lxMo7AQMjmB2YeTjM
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DDR3 init sequence of the controller is timed by
INIT0.pre_cke_x1024 (RESET# deasserted to CKE high) and
INIT1.dram_rstn_x1024 (RESET# low time), both in units of 1024
controller clock cycles. The H616 DDR3 code keeps the pre_cke reset
value 0x4e (about 222 us with the 360 MHz controller clock of a
720 MHz DRAM clock) and programs dram_rstn = 0x42 (about 188 us).
JEDEC (JESD79-3F, 4.6.1) asks for RESET# low for at least 200 us at
power-up and at least 500 us from RESET# high to CKE high. The A523
DDR3 timings already program much longer values.

Derive both from the DRAM clock: 550 us (10 % margin) before CKE and
200 us of RESET#. At 720 MHz this gives 0xc2 and 0x47. It costs about
0.33 ms per controller init, about 2.5 ms per boot on a board that
goes through the usual rank/width and size detection.

Tested on an OrangePi Zero2 (H616, 1 GiB DDR3, 720 MHz) together with
the next patch: reboots and cold boots come up with 1 GiB, and 60
hardware watchdog resets taken while the DRAM was saturated (the case
the next patch is about) all came up with 1 GiB. That test does not
show a measurable effect of this patch on its own; it is a compliance
fix.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm/mach-sunxi/dram_timings/h616_ddr3_1333.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/arch/arm/mach-sunxi/dram_timings/h616_ddr3_1333.c b/arch/arm/mach-sunxi/dram_timings/h616_ddr3_1333.c
index 3faf8d5bd97..44c2018790d 100644
--- a/arch/arm/mach-sunxi/dram_timings/h616_ddr3_1333.c
+++ b/arch/arm/mach-sunxi/dram_timings/h616_ddr3_1333.c
@@ -86,8 +86,15 @@ void mctl_set_timing_params(const struct dram_para *para)
 	writel(0xA100002, &mctl_ctl->dramtmg[13]);
 	writel(txsr, &mctl_ctl->dramtmg[14]);
 
-	clrbits_le32(&mctl_ctl->init[0], 3 << 30);
-	writel(0x420000, &mctl_ctl->init[1]);
+	/*
+	 * JEDEC DDR3 power-up/reset sequence: RESET# low for >= 200 us, then
+	 * >= 500 us until CKE goes high. The INIT0.pre_cke_x1024 reset value
+	 * (0x4e) is only about 220 us at 720 MHz, so program both (with 10%
+	 * margin on the CKE delay). Units are 1024 controller clock cycles.
+	 */
+	clrsetbits_le32(&mctl_ctl->init[0], (3 << 30) | 0xfff,
+			DIV_ROUND_UP(ns_to_t(550000), 1024));
+	writel(DIV_ROUND_UP(ns_to_t(200000), 1024) << 16, &mctl_ctl->init[1]);
 	writel(5, &mctl_ctl->init[2]);
 	writel(0x1f140004, &mctl_ctl->init[3]);
 	writel(0x00200000, &mctl_ctl->init[4]);

-- 
2.55.0

