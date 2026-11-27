From: Igor Velkov <iav@iav.lv>
Date: Sat, 28 Nov 2026 01:29:18 +0200
Subject: [PATCH] arm: dts: meson-g12b-odroid-n2-u-boot: limit the eMMC to
 40 MHz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-n2-emmc-40mhz-v1-1-fbfa199affdd@iav.lv>
X-B4-Tracking: v=1; b=H4sIAE0SCmsC/x3MQQqAIBBA0avErBtoVDK6SrQIm3IWWihEJN09a
 fkW/xfInIQzjE2BxJdkOWIFtQ04v8SdUdZqUJ3qidSAUSGH4NB0wT+oedicJXLWaKjNmXiT+/9
 N8/t+sV22IV8AAAA=
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Sean Anderson <sanderson@brivo.com>, u-boot-amlogic@groups.io, 
 u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Nick Xie <nick@khadas.com>, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1977; i=iav@iav.lv;
 h=from:subject:message-id; bh=zSkjLbhWCVDhiJZZwds1KL7JCuIcaS4Ezoeg897SLYs=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNlcQv6f9x67foVvz/UXbOtk1z/wmC+lJrr/nj4vR6NlK
 u/1I/PtO0pZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBEQj4wMmzI67B8tNHen81w
 wZX9E6Ye+HHq/8UGeaXAjB0i7h0bp2YxMvxNVBJismuTr7vbE35a1sn4/6L1qhEela58pQXdS5R
 mMgEA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit f7e3eaebd300 ("mmc: meson: Parse devicetree properties")
the max-frequency of 200 MHz from the Linux DT replaces the 40 MHz
limit of the driver, and U-Boot runs the ODROID-N2 eMMC in High Speed
mode at 52 MHz, 50 MHz after the clock divider. The meson_gx_mmc
driver has no tuning and uses a fixed clock phase, and the defconfig
has no HS200.

On an ODROID-N2+ with a Kingston 128 GB eMMC (Y29128) the EXT_CSD
read-back after the bus width switch then fails with CRC errors on
DAT0-2 and DAT5 in 8-bit mode and on DAT0-2 in 4-bit mode. U-Boot falls
back to 1-bit, where multi-block reads fail too. At 40 MHz the same
board runs 8-bit and a 256 MiB read matches the crc32 from Linux. The
same module in an ODROID-N2 ran 15 of 15 starts at 40 MHz and had one
failed session in about 120 starts at 50 MHz.

Limit the eMMC to 40 MHz again, the limit from commit 8fa0db145f6b
("mmc: meson_gx_mmc: reduce maximum frequency"), which is also what
the Hardkernel U-Boot for the board uses without HS200; the ODROID-N2
and N2+ share this DT. The limit goes into the board DT rather than
the driver, since the DT describes the hardware.

Fixes: f7e3eaebd300 ("mmc: meson: Parse devicetree properties")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested by starting the builds with load + go from U-Boot v2026.07.
---
 arch/arm/dts/meson-g12b-odroid-n2-u-boot.dtsi | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm/dts/meson-g12b-odroid-n2-u-boot.dtsi b/arch/arm/dts/meson-g12b-odroid-n2-u-boot.dtsi
index a92f9e9ff13..d6cb2f3c245 100644
--- a/arch/arm/dts/meson-g12b-odroid-n2-u-boot.dtsi
+++ b/arch/arm/dts/meson-g12b-odroid-n2-u-boot.dtsi
@@ -11,3 +11,7 @@
 	status = "okay";
 	vref-supply = <&vddao_1v8>;
 };
+
+&sd_emmc_c {
+	max-frequency = <40000000>;
+};

---
base-commit: 40bafcab3bea0511eb3925da2f0fdc1df9758e3d
change-id: 20261128-n2-emmc-40mhz-3e8fc711c743

Best regards,
-- 
Igor Velkov <iav@iav.lv>

