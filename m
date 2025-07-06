From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:47:05 -0400
Subject: [PATCH 09/11] ARM: dts: lpc4357-myd-lpc4357: change node name
 mdio0 to mdio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-9-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=1000;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=VS6QxcZGgSn5HvNmNyuuSrNEq64C8Es5AmiMzl1zdLo=;
 b=4rX0XHMxOOfRXW4fpgytGVAkbcqD5zWSdAnSlBa6GhhPIEbPyK3TmaGo+4MtCAtwpa72qi5hm
 nQRBAf7Om1tA5f86QTzU1qEk1SqEmJRMBi1Lc2dwFA3IoQzH/bfWwN3
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change node name mdio0 to mdio to fix below CHECK_DTB warning:
arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dtb: ethernet@40010000 (nxp,lpc1850-dwmac): Unevaluated properties are not allowed ('mdio0' was unexpected)
        from schema $id: http://devicetree.org/schemas/net/nxp,lpc1850-dwmac.yaml

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts b/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts
index ca91bb8f6ada6c4c3e74d4d76a2382f667bd2649..d18f2b2caf687f58fc330d6049e0dc6f3c393f4e 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts
@@ -544,7 +544,7 @@ &mac {
 	pinctrl-0 = <&enet_rmii_pins>;
 	phy-handle = <&phy1>;
 
-	mdio0 {
+	mdio {
 		#address-cells = <1>;
 		#size-cells = <0>;
 		compatible = "snps,dwmac-mdio";

-- 
2.34.1

