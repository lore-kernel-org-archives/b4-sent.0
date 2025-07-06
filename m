From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:46:57 -0400
Subject: [PATCH 01/11] ARM: dts: lpc18xx: rename node name flash-controller
 to spi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-1-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=1063;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=6m2OSalDvDTCfCB99DCue/9d4bd3iaqflWbmUZP2bls=;
 b=rLn7PQwT/q0/86RMYLYAyz21Paf2qNzYr0Awx+18IxDv+lT+Z7/NDdAVYe/1Ny03d8O3hDaM5
 Z+UzuUf74cjAyS1ABs2+UZqZpriLfW3MgoT0Fe7cZk6mHJbfrZF9ERv
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Anyway it is SPI controller although intent to connect qspi flash.

Rename node name flash-controller to spi to fix below CHECK_DTB warning:
  arch/arm/boot/dts/nxp/lpc/lpc4337-ciaa.dtb: flash-controller@40003000 (nxp,lpc1773-spifi): $nodename:0: 'flash-controller@40003000' does not match '^spi(@.*|-([0-9]|[1-9][0-9]+))?$

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
index 6dd73290f0c6392a407e5115551cbbeaf654f94f..e17298e89eebf4fc7e3f135dd4a20e563db48ed3 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
+++ b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
@@ -100,7 +100,7 @@ dmac: dma-controller@40002000 {
 			memcpy-bus-width = <32>;
 		};
 
-		spifi: flash-controller@40003000 {
+		spifi: spi@40003000 {
 			compatible = "nxp,lpc1773-spifi";
 			reg = <0x40003000 0x1000>, <0x14000000 0x4000000>;
 			reg-names = "spifi", "flash";

-- 
2.34.1

