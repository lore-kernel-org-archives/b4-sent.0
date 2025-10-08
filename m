From: Maud Spierings <maudspierings@gocontroll.com>
Date: Wed, 08 Oct 2025 14:25:13 +0200
Subject: [PATCH] ARM: imx: add ddr3 ram support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251008-ddr3-v1-1-8fe874a12878@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIAChY5mgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDAwML3ZSUImNdQ3PzNDOLVAOzRGNDJaDSgqLUtMwKsDHRsbW1AHv2E/p
 WAAAA
X-Change-ID: 20251008-ddr3-177f68e06a31
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759926314; l=4199;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=o82eVy6DzFF0oKEpcJDJ/aDJ2Y8KjKmtjSUq7cJKdGk=;
 b=i5SuiIvXmEI++sOzKnqxVnfrPMspvNkhp6d+dZs1OuJZcR8OQS8rjypEt8Mu2R3E7kj5vz/H+
 lwmp9jaar1FAkebjhYU2DJC6uh9qkHHf0GwKNCxizENoPjItHdNMmRb
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the necessary bits to use DDR3 on imx platforms.

Tested on Ka-Ro tx8m-1610 (imx8mm) based platform with DDR3L memory.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 drivers/ddr/imx/ddrphy_train.c | 18 ++++++++++++++++++
 firmware/Kconfig               |  3 +++
 firmware/Makefile              |  4 ++++
 include/soc/imx/ddr.h          | 10 ++++++++++
 4 files changed, 35 insertions(+)

diff --git a/drivers/ddr/imx/ddrphy_train.c b/drivers/ddr/imx/ddrphy_train.c
index 24997a6f36676b61b548e08c330dbfdcf336abc0..3185aaf61e494a72ecfac5760fa06f6c39b398ce 100644
--- a/drivers/ddr/imx/ddrphy_train.c
+++ b/drivers/ddr/imx/ddrphy_train.c
@@ -52,6 +52,19 @@ void ddr_get_firmware_ddr4(void)
 			     &ddr4_dmem_2d_size);
 }
 
+static const u16 *ddr3_imem_1d;
+static size_t ddr3_imem_1d_size;
+static const u16 *ddr3_dmem_1d;
+static size_t ddr3_dmem_1d_size;
+
+void ddr_get_firmware_ddr3(void)
+{
+	get_builtin_firmware(ddr3_imem_1d_bin, &ddr3_imem_1d,
+			     &ddr3_imem_1d_size);
+	get_builtin_firmware(ddr3_dmem_1d_bin, &ddr3_dmem_1d,
+			     &ddr3_dmem_1d_size);
+}
+
 void ddr_load_train_code(struct dram_controller *dram, enum dram_type dram_type,
 			 enum fw_type fw_type)
 {
@@ -82,6 +95,11 @@ void ddr_load_train_code(struct dram_controller *dram, enum dram_type dram_type,
 			dmem = ddr4_dmem_2d;
 			dsize = ddr4_dmem_2d_size;
 		}
+	} else if (dram_is_ddr3(dram_type)) {
+		imem = ddr3_imem_1d;
+		isize = ddr3_imem_1d_size;
+		dmem = ddr3_dmem_1d;
+		dsize = ddr3_dmem_1d_size;
 	} else {
 		panic("No matching DDR PHY firmware found");
 	}
diff --git a/firmware/Kconfig b/firmware/Kconfig
index 14a1c3d3a84407029e576e8e46993f828784f48b..a97a1e0dd324fa2ff95a0e77d1057bc45aa1ad07 100644
--- a/firmware/Kconfig
+++ b/firmware/Kconfig
@@ -22,6 +22,9 @@ config MISSING_FIRMWARE_ERROR
 	  If in doubt, say Y and refer to the documentation on where to acquire the
 	  needed firmware.
 
+config FIRMWARE_IMX_DDR3_PMU_TRAIN
+	bool
+
 config FIRMWARE_IMX_LPDDR4_PMU_TRAIN
 	bool
 
diff --git a/firmware/Makefile b/firmware/Makefile
index 1fe770a2d900f216dd457d88aee761df4ada26c6..163055554d51b0cc9547f4a43f97c39d23f8eb65 100644
--- a/firmware/Makefile
+++ b/firmware/Makefile
@@ -12,6 +12,10 @@ pbl-firmware-$(CONFIG_FIRMWARE_IMX_DDR4_PMU_TRAIN) += \
 	ddr4_imem_1d.bin \
 	ddr4_imem_2d.bin
 
+pbl-firmware-$(CONFIG_FIRMWARE_IMX_DDR3_PMU_TRAIN) += \
+	ddr3_dmem_1d.bin \
+	ddr3_imem_1d.bin
+
 pbl-firmware-$(CONFIG_FIRMWARE_IMX8MM_ATF) += imx8mm-bl31.bin$(if $(CONFIG_FIRMWARE_IMX8MM_OPTEE),-optee,)
 pbl-firmware-$(CONFIG_FIRMWARE_IMX8MN_ATF) += imx8mn-bl31.bin$(if $(CONFIG_FIRMWARE_IMX8MN_OPTEE),-optee,)
 pbl-firmware-$(CONFIG_FIRMWARE_IMX8MP_ATF) += imx8mp-bl31.bin$(if $(CONFIG_FIRMWARE_IMX8MP_OPTEE),-optee,)
diff --git a/include/soc/imx/ddr.h b/include/soc/imx/ddr.h
index 1e64613895d1b0bcfd5f48a55e0a8bcabd4d96c5..642606290082643dfed9fbeb283652b877d28639 100644
--- a/include/soc/imx/ddr.h
+++ b/include/soc/imx/ddr.h
@@ -18,6 +18,7 @@ enum dram_type {
 #define DRAM_TYPE_MASK	0x00ff
 	DRAM_TYPE_LPDDR4	= 0 << 0,
 	DRAM_TYPE_DDR4		= 1 << 0,
+	DRAM_TYPE_DDR3		= 2 << 0,
 };
 
 static inline enum dram_type get_dram_type(unsigned type)
@@ -115,11 +116,14 @@ struct dram_controller {
 
 void ddr_get_firmware_lpddr4(void);
 void ddr_get_firmware_ddr4(void);
+void ddr_get_firmware_ddr3(void);
 
 static inline void ddr_get_firmware(enum dram_type dram_type)
 {
 	if (dram_type == DRAM_TYPE_LPDDR4)
 		ddr_get_firmware_lpddr4();
+	else if (dram_type == DRAM_TYPE_DDR3)
+		ddr_get_firmware_ddr3();
 	else
 		ddr_get_firmware_ddr4();
 }
@@ -188,6 +192,12 @@ static inline bool dram_is_ddr4(enum dram_type dram_type)
 		dram_type == DRAM_TYPE_DDR4;
 }
 
+static inline bool dram_is_ddr3(enum dram_type dram_type)
+{
+	return IS_ENABLED(CONFIG_FIRMWARE_IMX_DDR3_PMU_TRAIN) &&
+		dram_type == DRAM_TYPE_DDR3;
+}
+
 #define DDRC_PHY_REG(x)	((x) * 4)
 
 #endif /* __SOC_IMX_DDR_H */

---
base-commit: 8785a6ad7467b6f1f70b6e12aa2ceb2fdd5d8546
change-id: 20251008-ddr3-177f68e06a31

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

