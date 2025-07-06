From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:46:58 -0400
Subject: [PATCH 02/11] ARM: dts: lpc18xx: rename node name mmcsd to mmc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-2-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=864;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=F9o9Zz1l+QBlQQDM8Dn10ujNdmNzCrECB6a3juGDdlQ=;
 b=i5bDnkjDaXg3R+eMt4iPutUeGhKw+htNfKMzD/bm9mmqJ4e3wV/3xTWR2FlH8nL/edtRFfYXq
 j1J7oytr13sBtnFs95y15K4NQ/a+zK5LF5W8wNnfAEjga6b+Wx81fqe
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change node name mmcsd to mmc to fix CHECK_DTB warnings:
  arch/arm/boot/dts/nxp/lpc/lpc4337-ciaa.dtb: mmcsd@40004000 (snps,dw-mshc): $nodename:0: 'mmcsd@40004000' does not match '^mmc(@.*)?$'

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
index e17298e89eebf4fc7e3f135dd4a20e563db48ed3..80da477bae3d9dc45f0dcdedc275ac2ff09032bf 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
+++ b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
@@ -111,7 +111,7 @@ spifi: spi@40003000 {
 			status = "disabled";
 		};
 
-		mmcsd: mmcsd@40004000 {
+		mmcsd: mmc@40004000 {
 			compatible = "snps,dw-mshc";
 			reg = <0x40004000 0x1000>;
 			interrupts = <6>;

-- 
2.34.1

