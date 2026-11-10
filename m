From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 06:19:36 +0000
Subject: [PATCH 1/2] sunxi: H6/H616: support the RSB bus for the SPL PMIC
 access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-h616-rsb-spl-v1-1-bf91cc26507e@gmail.com>
References: <20261110-h616-rsb-spl-v1-0-bf91cc26507e@gmail.com>
In-Reply-To: <20261110-h616-rsb-spl-v1-0-bf91cc26507e@gmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Andre Przywara <andre.przywara@arm.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Heiko Schocher <hs@nabladev.com>, Arun Iyengar <aiyengar1990@gmail.com>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794291575; l=5969;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=m5M2/DsDQHSwBRy2WZjZLXiCZIY3Sk5PDrr2qUnBUec=;
 b=dfkyduX/u7yG4Q8wubEl3rovjITicxRLc2bv1vz4cULrOOTgC3j72W/IfqkKBLWvYlclVqZwb
 h0FXd5g8ljJAhR/2RUJW5BXU1x+Lp1s6rBHbKi7TtD/IElecmyL4sTf
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On H6/H616 boards the AXP305/AXP805/AXP806 PMIC is described on the
R_RSB bus in the Linux device tree (e.g. pmic@745 on the OrangePi
Zero2). TF-A switches the PMIC into RSB mode (AXP "device mode" register
0x3e = 0x7c) and Linux talks RSB to it. The PMIC keeps that mode until
it loses power, so after every warm reboot the SPL, which can only use
R_I2C on these SoCs, gets no acknowledge from the PMIC, axp_init()
fails and the SPL prints

  Failed to set core voltage! Can't set CPU frequency

The CPU then stays at the 408 MHz clock_init_safe() value through the
SPL, TF-A and U-Boot proper.

Teach the SPL side of the sun8i RSB driver about the H6 generation:
- the controller is at 0x07083000, its gate and reset are bits 0 and 16
  of PRCM register 0x1bc (like the R_I2C one at 0x19c); R_PIO has no
  gate to open. PL0/PL1 use pin function 2 as on sun8i.
- pmic_bus: the AXP305/805/806 answer at the "secondary" RSB hardware
  address 0x745 (runtime address 0x3a), the other RSB AXPs at the
  primary 0x3a3/0x2d. The mapping is fixed, see drivers/bus/sunxi-rsb.c
  in Linux.

rsb_init() issues the device-mode switch itself, so a cold boot with the
PMIC still in I2C mode works as well. Nothing changes for boards that do
not select CONFIG_SYS_I2C_SUN8I_RSB.

Tested on an OrangePi Zero2 (H616, AXP305) together with the next patch:
cold boot and warm reboot both come up without the core voltage error,
TF-A still finds the AXP305 on RSB and Linux's sunxi-rsb driver probes
it; the SPL to TF-A time on a warm reboot dropped from 1.5 s to 1.0 s
(serial console timestamps).

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm/include/asm/arch-sunxi/cpu_sun50i_h6.h |  1 +
 arch/arm/include/asm/arch-sunxi/prcm_sun50i.h   |  3 +++
 arch/arm/mach-sunxi/pmic_bus.c                  | 22 ++++++++++++++++++----
 drivers/i2c/sun8i_rsb.c                         | 10 ++++++++++
 4 files changed, 32 insertions(+), 4 deletions(-)

diff --git a/arch/arm/include/asm/arch-sunxi/cpu_sun50i_h6.h b/arch/arm/include/asm/arch-sunxi/cpu_sun50i_h6.h
index 2a9b086991c..18ac118ca15 100644
--- a/arch/arm/include/asm/arch-sunxi/cpu_sun50i_h6.h
+++ b/arch/arm/include/asm/arch-sunxi/cpu_sun50i_h6.h
@@ -47,6 +47,7 @@
 #define SUNXI_PRCM_BASE			0x07010000
 #define SUNXI_R_WDOG_BASE		0x07020400
 #define SUNXI_R_TWI_BASE		0x07081400
+#define SUNXI_RSB_BASE			0x07083000
 
 #ifndef __ASSEMBLY__
 void sunxi_board_init(void);
diff --git a/arch/arm/include/asm/arch-sunxi/prcm_sun50i.h b/arch/arm/include/asm/arch-sunxi/prcm_sun50i.h
index d6653c3bb06..6e9bf587a55 100644
--- a/arch/arm/include/asm/arch-sunxi/prcm_sun50i.h
+++ b/arch/arm/include/asm/arch-sunxi/prcm_sun50i.h
@@ -11,6 +11,7 @@
 #ifndef __ASSEMBLY__
 
 #define CCU_PRCM_I2C_GATE_RESET		0x19c
+#define CCU_PRCM_RSB_GATE_RESET		0x1bc
 #define CCU_PRCM_PLL_LDO_CFG		0x244
 #define CCU_PRCM_SYS_PWROFF_GATING	0x250
 #define CCU_PRCM_RES_CAL_CTRL		0x310
@@ -18,6 +19,8 @@
 
 #define PRCM_TWI_GATE		(1 << 0)
 #define PRCM_TWI_RESET		(1 << 16)
+#define PRCM_RSB_GATE		(1 << 0)
+#define PRCM_RSB_RESET		(1 << 16)
 
 #endif /* __ASSEMBLY__ */
 #endif /* _PRCM_H */
diff --git a/arch/arm/mach-sunxi/pmic_bus.c b/arch/arm/mach-sunxi/pmic_bus.c
index c77dc538456..8c72d773601 100644
--- a/arch/arm/mach-sunxi/pmic_bus.c
+++ b/arch/arm/mach-sunxi/pmic_bus.c
@@ -18,6 +18,20 @@
 
 #define AXP221_CHIP_ADDR		0x68
 
+/*
+ * RSB hardware/runtime address pair of the PMIC. AXP305/AXP805/AXP806
+ * sit at the "secondary" address (0x745/0x3a), every other RSB AXP at
+ * the primary one (0x3a3/0x2d); the mapping is fixed, see Linux's
+ * drivers/bus/sunxi-rsb.c.
+ */
+#ifdef CONFIG_AXP305_POWER
+#define AXP_PMIC_RSB_DEVICE_ADDR	AXP_PMIC_SEC_DEVICE_ADDR
+#define AXP_PMIC_RSB_RUNTIME_ADDR	AXP_PMIC_SEC_RUNTIME_ADDR
+#else
+#define AXP_PMIC_RSB_DEVICE_ADDR	AXP_PMIC_PRI_DEVICE_ADDR
+#define AXP_PMIC_RSB_RUNTIME_ADDR	AXP_PMIC_PRI_RUNTIME_ADDR
+#endif
+
 #if CONFIG_IS_ENABLED(PMIC_AXP)
 static struct udevice *pmic;
 #endif
@@ -45,8 +59,8 @@ int pmic_bus_init(void)
 		if (ret)
 			return ret;
 
-		ret = rsb_set_device_address(AXP_PMIC_PRI_DEVICE_ADDR,
-					     AXP_PMIC_PRI_RUNTIME_ADDR);
+		ret = rsb_set_device_address(AXP_PMIC_RSB_DEVICE_ADDR,
+					     AXP_PMIC_RSB_RUNTIME_ADDR);
 	}
 #endif
 
@@ -63,7 +77,7 @@ int pmic_bus_read(u8 reg, u8 *data)
 	if (IS_ENABLED(CONFIG_SYS_I2C_SUN6I_P2WI))
 		return p2wi_read(reg, data);
 	if (IS_ENABLED(CONFIG_SYS_I2C_SUN8I_RSB))
-		return rsb_read(AXP_PMIC_PRI_RUNTIME_ADDR, reg, data);
+		return rsb_read(AXP_PMIC_RSB_RUNTIME_ADDR, reg, data);
 
 	return i2c_read(CONFIG_AXP_I2C_ADDRESS, reg, 1, data, 1);
 #endif
@@ -77,7 +91,7 @@ int pmic_bus_write(u8 reg, u8 data)
 	if (IS_ENABLED(CONFIG_SYS_I2C_SUN6I_P2WI))
 		return p2wi_write(reg, data);
 	if (IS_ENABLED(CONFIG_SYS_I2C_SUN8I_RSB))
-		return rsb_write(AXP_PMIC_PRI_RUNTIME_ADDR, reg, data);
+		return rsb_write(AXP_PMIC_RSB_RUNTIME_ADDR, reg, data);
 
 	return i2c_write(CONFIG_AXP_I2C_ADDRESS, reg, 1, &data, 1);
 #endif
diff --git a/drivers/i2c/sun8i_rsb.c b/drivers/i2c/sun8i_rsb.c
index 2197f180566..4a0903ff869 100644
--- a/drivers/i2c/sun8i_rsb.c
+++ b/drivers/i2c/sun8i_rsb.c
@@ -159,8 +159,18 @@ int rsb_init(void)
 {
 	struct sunxi_rsb_reg *base = (struct sunxi_rsb_reg *)SUNXI_RSB_BASE;
 
+#if defined(CONFIG_SUN50I_GEN_H6)
+	/*
+	 * H6/H616: the R_PIO clock is always on, the RSB module has its own
+	 * gate/reset register in the PRCM (like the R_I2C one used by
+	 * clock_twi_onoff()).
+	 */
+	setbits_le32((void *)SUNXI_PRCM_BASE + CCU_PRCM_RSB_GATE_RESET,
+		     PRCM_RSB_GATE | PRCM_RSB_RESET);
+#else
 	/* Enable RSB and PIO clk, and de-assert their resets */
 	prcm_apb0_enable(PRCM_APB0_GATE_PIO | PRCM_APB0_GATE_RSB);
+#endif
 
 	if (IS_ENABLED(CONFIG_MACH_SUN9I)) {
 		sunxi_gpio_set_cfgpin(SUNXI_GPN(0), SUN9I_GPN_R_RSB);

-- 
2.55.0

