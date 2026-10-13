From: Igor Velkov <iav@iav.lv>
Date: Tue, 13 Oct 2026 20:53:34 +0300
Subject: [PATCH] arm: dts: meson-sm1-odroid-hc4: power-cycle the SD card at
 init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-hc4-sd-power-cycle-v1-1-cde760a256a5@iav.lv>
X-B4-Tracking: v=1; b=H4sIAB1wzmoC/x3MTQqAIBBA4avErBtIM6GuEi1SxxyICoV+kO6et
 PwW72VIFJkSDFWGSCcn3rcCUVdgw7wthOyKQTZSi0a0aBQGqzA5PPaLItrHroTeSKV170zbd1D
 aI5Ln+/+O0/t+ToIaRWcAAAA=
To: Neil Armstrong <neil.armstrong@linaro.org>
Cc: u-boot-amlogic@groups.io, u-boot@lists.u-boot-project.org, 
 Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2119; i=iav@iav.lv;
 h=from:subject:message-id; bh=tR/RFYgAqbY87MOye/X3GfkLr/MIhX3x0TK79SL/+gg=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnnCuTebzBRkLR1C+N5XVVhc/bU4ePe07ObuXzd3DYfD
 hEXkFvTUcrCIMbFICumyDLhkMatjCVX//p7mD+AmcPKBDKEgYtTACbyfB0jw96599raVr42938l
 /P38ued23S8717Ov2G1X7tM7XyKnaCPDP7WE9T/32Rj0sXgUvgkozkn1C6q3y+M9t+zDFY02/6v
 7mAE=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mmc_get_op_cond() power-cycles the card, but both SD supplies,
TFLASH_VDD and TF_IO, are regulator-always-on in the Linux device tree,
so regulator_set_enable_if_allowed() leaves them on. After a watchdog
reset a UHS card is still at 1.8 V signalling and U-Boot fails with
"No partition table - mmc 0".

Drop regulator-always-on from both supplies for U-Boot, and keep
TFLASH_VDD off for 100 ms before it is turned back on. Linux has to
keep regulator-always-on: the boot ROM does not turn the supply back on,
see Linux commit dc7f2cb218b5 ("arm64: dts: amlogic: odroid-n2: keep SD
card regulator always on") for the same supply on ODROID-N2. TF_IO
keeps regulator-boot-on: after a reset a pull-up on the board enables
it at 3.3 V before U-Boot runs.

Tested on ODROID-HC4 with a UHS-I SDXC card and U-Boot in SPI flash:
after a watchdog reset 3/3 boots from SD (v2026.07 without this change:
0/3); cold boot, reboot and suspend to RAM unaffected.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
The card holds a btrfs root, so the main build under test also had
FS_BTRFS, CMD_BTRFS and ZSTD enabled; odroid-hc4_defconfig has none of
them.
---
 arch/arm/dts/meson-sm1-odroid-hc4-u-boot.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm/dts/meson-sm1-odroid-hc4-u-boot.dtsi b/arch/arm/dts/meson-sm1-odroid-hc4-u-boot.dtsi
index 963bf96b256..5f09ecc8f60 100644
--- a/arch/arm/dts/meson-sm1-odroid-hc4-u-boot.dtsi
+++ b/arch/arm/dts/meson-sm1-odroid-hc4-u-boot.dtsi
@@ -18,6 +18,16 @@
 	vref-supply = <&vddao_1v8>;
 };
 
+/*
+ * Let the MMC core power-cycle the SD card: after a watchdog reset a UHS card
+ * is still powered and at 1.8 V signalling, and U-Boot cannot read it.
+ */
 &tflash_vdd {
 	gpio = <&gpio_ao GPIOAO_3 GPIO_OPEN_DRAIN>;
+	/delete-property/ regulator-always-on;
+	u-boot,off-on-delay-us = <100000>;
+};
+
+&tf_io {
+	/delete-property/ regulator-always-on;
 };

---
base-commit: b871f72273c183ab557e29f9bc52d9065e0aacf3
change-id: 20261013-b4-hc4-sd-power-cycle-fb24669db395

Best regards,
-- 
Igor Velkov <iav@iav.lv>

