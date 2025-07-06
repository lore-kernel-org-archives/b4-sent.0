From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:47:06 -0400
Subject: [PATCH 10/11] ARM: dts: lpc18xx: add #address-cell and #szie-cell
 for spi flash controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-10-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=1223;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=WCpBHug6OhCx+F6FwrsLIok14DKpKGEdTCJ2N0cYh2o=;
 b=OJ8NeXc+Sqhu96qL4Qg1+6+w1CRKspkU6ekemGGOFTsHZJWrnMsc2VVMLiLLFD9RhIBJO5ANF
 uSNdZPA0Gv6DTsKnqjNyxLoTmXMYnhG7xuWJ9r0IOSAaXekfJ+jDZLR
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add #address-cells and #szie-cells for spi flash controller to fix below
CHECK_DTB warning:
arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi:103.23-112.5: Warning (spi_bus_bridge): /soc/spi@40003000: incorrect #address-cells for SPI bus
  also defined at arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts:452.8-479.3
arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi:103.23-112.5: Warning (spi_bus_bridge): /soc/spi@40003000: incorrect #size-cells for SPI bus
  also defined at arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts:452.8-479.3

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
index 0be2486f07173c47bdc9d298a11ac9347f81cf02..d212ca252b06dc97a0cdbe5ecff42780b51a02dd 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
+++ b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
@@ -107,6 +107,8 @@ spifi: spi@40003000 {
 			interrupts = <30>;
 			clocks = <&ccu1 CLK_SPIFI>, <&ccu1 CLK_CPU_SPIFI>;
 			clock-names = "spifi", "reg";
+			#address-cells = <1>;
+			#size-cells = <0>;
 			resets = <&rgu 53>;
 			status = "disabled";
 		};

-- 
2.34.1

