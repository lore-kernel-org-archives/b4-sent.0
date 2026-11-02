From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 02 Nov 2026 15:12:47 +0100
Subject: [PATCH v2] arm64: dts: freescale: lx2160a-nbxv3: fix the TCA9539
 and 1588 line names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-for-upstream-nbxv3-dts-line-names-v2-1-58f234e478fb@free.fr>
X-B4-Tracking: v=1; b=H4sIAF6a6GoC/5WNSw6CMBBAr0K6dgxT8IMr72FYtDCVJtKSGWwwh
 LtbuYHL9xbvrUqIPYm6FatiSl58DBn0oVDdYMKTwPeZlS71GbFEcJHhPcnMZEYIdkkV9LPAywe
 CYEYSaCqLGs3J1nWpcmdicn7ZH4828+BljvzZlwl/9p96QkC4dFeizureNO7umOjoWLXbtn0Bv
 fftTdAAAAA=
To: Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vincent Jardin <vjardin@free.fr>
Cc: imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793628769; l=2803;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=hHUsd9bJRSMGNR0btcyRpbeMGj6quxgOVoYnLHWHvS8=;
 b=XVxrGbzLj2cVry+PSQYRRhZG1x8x3UrZVxwbTaBtdBhzXNMFdnb2kVkOfErzEd2FTDTgnz4HE
 yIovGfitqAKBx9UEb24BZjbAVkxYLcdVO+RCqW6EsWheUXFhTFYmLR2
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some gpio-line-names do not properly describe the board.

The board CPU's RCW sets EC2_PMUX = 2, which gives two GPIO4 pads to
the 1588 timer, so they are not GPIOs anymore. Name them using
lx2160 function with the altfn: prefix this file uses for every pad
muxed to another function:

- GPIO4[14] (ball M3, EC2_TXD1) is TSEC_1588_CLK_OUT, the CPU's 1588
  clock output to the DPLL's reference input.
- GPIO4[23] (ball P1, EC2_RX_DV) is TSEC_1588_TRIG_IN1, the CPU's 1588
  trigger input, driven by the DPLL's 1PPS.

The board-ID TCA9539 is a read-only 8 bit register:
 - P00..P07
 - a test point
 - P11..P17 are wired to GND
There is no 16-bit board ID.

Only the names are updated: the 1588 timer is already described by
the CPU's dtsi then the CPU's RCW muxes those at CPU reset.

Fixes: 565b6713a460 ("arm64: dts: freescale: add Nodebox v3 CPU Module")
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v2:
- Better explain changes (Sashiko).
- Link to v1: https://lore.kernel.org/r/20261101-for-upstream-nbxv3-dts-line-names-v1-1-7c8eecb2da9f@free.fr
---
 arch/arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/arch/arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi b/arch/arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi
index 9c5588a75cdd..34e02102c214 100644
--- a/arch/arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi
@@ -206,9 +206,9 @@ &gpio3 {
 		"altfn:ec1-rxd1", "altfn:ec1-rxd0",
 		"altfn:ec1-rx-clk", "altfn:ec1-rx-dv",
 		"", "",
-		"ptp-refclk-in",
+		"altfn:tsec1588-clk-out",
 		"", "", "", "", "", "", "", "",
-		"u1700-zl30733-pps-out",
+		"altfn:tsec1588-trig-in1",
 		"",
 		"ethsw-mdio-en",
 		"usb1-oc#",	/* USB1_PWRFAULT and USB2_PWRFAULT pads: one wired-OR net */
@@ -254,14 +254,14 @@ gpio@74 {
 		#gpio-cells = <2>;
 		gpio-controller;
 		gpio-line-names =
-			"boardid-0x0001", "boardid-0x0002",
-			"boardid-0x0004", "boardid-0x0008",
-			"boardid-0x0010", "boardid-0x0020",
-			"boardid-0x0040", "boardid-0x0080",
-			"boardid-0x0100", "boardid-0x0200",
-			"boardid-0x0400", "boardid-0x0800",
-			"boardid-0x1000", "boardid-0x2000",
-			"boardid-0x4000", "boardid-0x8000";
+			"boardid-0x01", "boardid-0x02",
+			"boardid-0x04", "boardid-0x08",
+			"boardid-0x10", "boardid-0x20",
+			"boardid-0x40", "boardid-0x80",
+			"test-mode-tp1500",
+			"gnd-p11", "gnd-p12", "gnd-p13",
+			"gnd-p14", "gnd-p15", "gnd-p16",
+			"gnd-p17";
 	};
 
 	u800: gpio@75 {

---
base-commit: cbbddb6b08cc9900a87cccaa9b22bbe06aa4f50a
change-id: 20261101-for-upstream-nbxv3-dts-line-names-93b121a5b440

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

