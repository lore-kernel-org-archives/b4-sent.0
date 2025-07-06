From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:47:03 -0400
Subject: [PATCH 07/11] ARM: dts: lpc4357-myd-lpc4357: add power-supply for
 innolux,at070tn92
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-7-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=832;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=Mj33KBqJ8qYPhYbxScfAHy2wCR1k2Cd/+ykWat59/P0=;
 b=4Oj/Af4XMkSutzkLenURHXGc8DMsWE7llQckfUU1wwfdGDUarn6oCy17H3FQKmVuIweGR9BDU
 8eJZtjwEViFAf12UnwD1ycbElA7uadkpJJB1DWYoAXOSkmgKkfCu9wV
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power-supply for innolux,at070tn92 to fix below CHECK_DTB warning:
  arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dtb: panel (innolux,at070tn92): 'power-supply' is a required property

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts b/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts
index 22f7dd671c90d56cc4295151583fd4135c8b707b..ca91bb8f6ada6c4c3e74d4d76a2382f667bd2649 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts
@@ -63,6 +63,7 @@ led6 {
 
 	panel: panel {
 		compatible = "innolux,at070tn92";
+		power-supply = <&vcc>;
 
 		port {
 			panel_input: endpoint {

-- 
2.34.1

