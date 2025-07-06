From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:47:00 -0400
Subject: [PATCH 04/11] ARM: dts: lpc18xx: swap clock-names bic and cui
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-4-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=1266;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=UCsVuTJJb65oR4iDCkRHol36phtuS4BFYwUlRuaLl5E=;
 b=8tTDLVmaoeE+iXXsG2lnWevRaVivwYKePo3fWG6ADYnm7xCFTZ/mI/z+/WPC0lF9Qwv64tDDu
 3B2UYDsW8G6CMaArGFZdDqIT9Kmjv41kJrt6LOo2ZrJAF8GqPhoRR0g
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Swap clock-names bic and cui to fix below CHECK_DTB warnings:

/home/lizhi/source/linux-upstream-pci/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dtb: mmc@40004000 (snps,dw-mshc): clock-names:0: 'biu' was expected
	from schema $id: http://devicetree.org/schemas/mmc/synopsys-dw-mshc.yaml#
/home/lizhi/source/linux-upstream-pci/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dtb: mmc@40004000 (snps,dw-mshc): clock-names:1: 'ciu' was expected

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
index 80da477bae3d9dc45f0dcdedc275ac2ff09032bf..0be2486f07173c47bdc9d298a11ac9347f81cf02 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
+++ b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
@@ -115,8 +115,8 @@ mmcsd: mmc@40004000 {
 			compatible = "snps,dw-mshc";
 			reg = <0x40004000 0x1000>;
 			interrupts = <6>;
-			clocks = <&ccu2 CLK_SDIO>, <&ccu1 CLK_CPU_SDIO>;
-			clock-names = "ciu", "biu";
+			clocks = <&ccu1 CLK_CPU_SDIO>, <&ccu2 CLK_SDIO>;
+			clock-names = "biu", "ciu";
 			resets = <&rgu 20>;
 			status = "disabled";
 		};

-- 
2.34.1

