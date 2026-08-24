From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 24 Aug 2026 15:12:01 +0200
Subject: [PATCH v2 1/3] arm64: dts: lx2160a: fix incorrect pinmux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-for-upstream-lx2160a-pinmux-fix-v2-1-0a525d5f4cd5@free.fr>
References: <20260824-for-upstream-lx2160a-pinmux-fix-v2-0-0a525d5f4cd5@free.fr>
In-Reply-To: <20260824-for-upstream-lx2160a-pinmux-fix-v2-0-0a525d5f4cd5@free.fr>
To: Frank Li <Frank.Li@nxp.com>, Carlos Song <carlos.song@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Josua Mayer <josua@solid-run.com>
Cc: imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thibaut Collet <thbt.cllt@gmail.com>, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787577136; l=1626;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=cZfDHWxtn03VL7NNB13yIdWVRIXNDxo1MTtXhAgv4U8=;
 b=dHSEpwxeF9dhLwKyueWq+wokOc4uqkX0QwvIMBU7Ty2dsMST7A7Rn24MKI+ZUqoIEeVH/goLx
 WKgk3gOCBUzBv9OBRjRsCCsjhAfCQGBgKygWVieLawOiMoatUKi+UHR
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For gpio1 value set for pinctrl is outside the mask and so will do
nothing.

Add the missing offset for value field to be the same as the mask as
expected.

Fixes: 284ad7064aaa ("arm64: dts: lx2160a: complete pinmux for rcwsr12 configuration word")
Suggested-by: Thibaut Collet <thbt.cllt@gmail.com>
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi b/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
index ae6e37870c5e5..d4522a19405a9 100644
--- a/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
@@ -1622,7 +1622,7 @@ fspi_data74_pins: xspi1-data74-pins {
 			};
 
 			gpio1_31_28_pins: xspi1-data74-gpio-pins {
-				pinctrl-single,bits = <0x0 0x1 (0x7 << 15)>;
+				pinctrl-single,bits = <0x0 (0x1 << 15) (0x7 << 15)>;
 			};
 
 			fspi_data30_pins: xspi1-data30-pins {
@@ -1630,7 +1630,7 @@ fspi_data30_pins: xspi1-data30-pins {
 			};
 
 			gpio1_27_24_pins: xspi1-data30-gpio-pins {
-				pinctrl-single,bits = <0x0 0x1 (0x7 << 18)>;
+				pinctrl-single,bits = <0x0 (0x1 << 18) (0x7 << 18)>;
 			};
 
 			fspi_dqs_sck_cs10_pins: xspi1-base-pins {
@@ -1638,7 +1638,7 @@ fspi_dqs_sck_cs10_pins: xspi1-base-pins {
 			};
 
 			gpio1_23_20_pins: xspi1-base-gpio-pins {
-				pinctrl-single,bits = <0x0 0x1 (0x7 << 21)>;
+				pinctrl-single,bits = <0x0 (0x1 << 21) (0x7 << 21)>;
 			};
 
 			esdhc0_cmd_data30_clk_vsel_pins: sdhc1-base-sdhc-vsel-pins {

-- 
2.43.0

