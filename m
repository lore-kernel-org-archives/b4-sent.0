From: Vincent Jardin <vjardin@free.fr>
Date: Sun, 01 Nov 2026 16:59:41 +0100
Subject: [PATCH] arm64: dts: freescale: lx2160a-nbxv3: fix 1588 and id line
 names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-for-upstream-nbxv3-dts-line-names-v1-1-7c8eecb2da9f@free.fr>
X-B4-Tracking: v=1; b=H4sIAOxh52oC/x3NQQqDQAxA0atI1g1MRivYq5QuZmqsAY2SWBHEu
 3fo8m3+P8HZhB0e1QnGu7gsWkC3Ct5j0g+j9MUQQ2yJAuGwGH5X34zTjJqPvcZ+c5xEGTXN7Nj
 VmSKle26aAKWzGg9y/B/P13X9AHbiLQZzAAAA
To: Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vincent Jardin <vjardin@free.fr>
Cc: imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793548796; l=2193;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=ISKcvjfV02vWOp4oL9uUzMIK04tsXq8YeCeMJLgxIRQ=;
 b=ZpoRWP4cOckBlkls/HAiGexv6R8q/Ujap61DCpqzW7toDGxkec9a0p0haztMsR1/0Wrm0qOy1
 TMyw/wzpTv/Ds+8XHmoHyhh6EriJoQdy8mNOryfZrfYMnO+gR86BtjP
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let's properly support 1588 on this board and fix the names.

Fixes: 565b6713a460 ("arm64: dts: freescale: add Nodebox v3 CPU Module")
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 .../boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi      | 22 ++++++++++------------
 1 file changed, 10 insertions(+), 12 deletions(-)

diff --git a/arch/arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi b/arch/arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi
index 9c5588a75cdd..5591ae262707 100644
--- a/arch/arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi
@@ -169,7 +169,6 @@ &gpio1 {
 
 	status = "okay";
 
-	/* Platform reset, no consumer node: released at boot */
 	pltrst-hog {
 		gpio-hog;
 		gpios = <29 GPIO_ACTIVE_LOW>;
@@ -206,9 +205,9 @@ &gpio3 {
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
@@ -247,21 +246,20 @@ eeprom@52 {
 		pagesize = <32>;
 	};
 
-	/* Board ID straps */
 	gpio@74 {
 		compatible = "ti,tca9539";
 		reg = <0x74>;
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

