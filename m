From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 28 Sep 2026 23:08:28 +0200
Subject: [PATCH v2] arm64: dts: lx2160a: set #pinctrl-cells on the pinmux
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-for-upstream-lx2160a-pinctrl-cells-v2-1-1227b2e897d3@free.fr>
X-B4-Tracking: v=1; b=H4sIAEvXumoC/5WNSw6CMBBAr0K6dgwdPhZX3sOwqGUqk1QgUyQYw
 t2t3MDle4v3NhVJmKK6ZpsSWjjyOCTAU6Zcb4cnAXeJFeZY5w0a8KPAe4qzkH1BWFHXuYWJBzd
 LAEchRLhgUxWFNvgwlUqhScjzekzubeKe4zzK53gu+mf/yi8aNJTeWmOLUruuu3khOntR7b7vX
 ySey0bSAAAA
To: Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790629711; l=1258;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=MLG+A3X72Uzk7Ufcvox/+HKIq9Wjjn1mtqOgeCdt28M=;
 b=Kg5Dd4el+o3eMbJo2GVlTwYzVEDdR0ZdS9fQGXKBUZ0xTpYc1C8lDtrgVM07nHcjhgFnBKUlJ
 +PQXpdJPPEPCf6JomddSRVqbGzuQO4hkdwxruh1kqSVsU6J4+eG2jIl
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The below message shows at boot time:
  pinctrl-single 70010012c.pinmux: please update dts to use #pinctrl-cells = <2>

Add missing #pinctrl-cells = <2> to fix it.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v2:
- Reword the commit message (thanks Frank Li)
- Rebased on imx/for-next
- Link to v1: https://lore.kernel.org/r/20260928-for-upstream-lx2160a-pinctrl-cells-v1-1-4faa8a341cdd@free.fr
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
base-commit: 5d034f17b24642b2a764c0e3a68b4c6937c9ba75
change-id: 20260928-for-upstream-lx2160a-pinctrl-cells-729533182b85

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

