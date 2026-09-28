From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 28 Sep 2026 15:49:49 +0200
Subject: [PATCH] arm64: dts: lx2160a: set #pinctrl-cells on the pinmux node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-for-upstream-lx2160a-pinctrl-cells-v1-1-4faa8a341cdd@free.fr>
X-B4-Tracking: v=1; b=H4sIAHxwumoC/x3NwQrCMAyA4VcZORtoMzY7X0U81JppoHYlmTIYe
 3eLx+/y/zsYq7DBpdtB+SsmS2nwpw7SK5YnozyagRyNbqKA86L4qbYqxzfmjfzoIlYpadWMiXM
 2PNM09L0PdA8DtFBVnmX7T6634/gBemrjAXQAAAA=
To: Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790603391; l=1124;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=F0blJHgPfcv2wZhfmtzs3uZ/BwHnx9s7GUCpxGKKE58=;
 b=irunWbeaCOH99oscPjVx+F1HEvnbOdO2seB4xYU9BDCB3RpM5+MKE0iparZordCaXVEHrSPhv
 6zGF3LvVep2Bpkr1OqmwgSdKeL9pdVIwYWpV8D1vQJ/p3nUBcRWYG5M
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, we have this message at boot time:
  pinctrl-single 70010012c.pinmux: please update dts to use #pinctrl-cells = <2>

Let's declare it in the DT instead, the value is the one the
driver already uses, so nothing else changes.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi b/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
index bccf2d673023..2085362ab0ea 100644
--- a/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
@@ -1536,6 +1536,7 @@ pinmux_i2crv: pinmux@70010012c {
 			reg = <0x00000007 0x0010012c 0x0 0xc>;
 			#address-cells = <1>;
 			#size-cells = <0>;
+			#pinctrl-cells = <2>;
 			pinctrl-single,bit-per-mux;
 			pinctrl-single,register-width = <32>;
 			pinctrl-single,function-mask = <0x7>;

---
base-commit: bf184a29ad1b33bd8922029eb0ca3f2866007258
change-id: 20260928-for-upstream-lx2160a-pinctrl-cells-729533182b85

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

