From: Sven Peter <sven@kernel.org>
Date: Tue, 10 Jun 2025 19:19:24 +0000
Subject: [PATCH] arm64: dts: apple: Drop {address,size}-cells from SPI NOR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250610-apple-dts-warnings-v1-1-70b53e8108a0@kernel.org>
X-B4-Tracking: v=1; b=H4sIADuFSGgC/x3MQQ5AMBBA0avIrE1SqoiriEXLYBKppiNIxN01l
 m/x/wNCkUmgyx6IdLLw7hOKPINxtX4h5CkZSlUaZbRCG8JGOB2Cl42e/SLYOqcbrevGmQpSGCL
 NfP/TfnjfD0gomXdkAAAA
X-Change-ID: 20250530-apple-dts-warnings-8bb373367b54
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1243; i=sven@kernel.org;
 h=from:subject:message-id; bh=I7LIFG9CUURK/xCFq/gHrynuB0+CqswX9qvQ7HEglvA=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4ZHq73vyvzpddl7Td89/J323EP/7satR+MffagOLGIOf
 jJHK21xRykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiWVGMDGe4rxsafox+V3e5
 TNBZWf31hBIWH7fSc+c/vTaed+N7yW6GX0znghs1Xjwy+cx0J03vVqF8p0DsrLf1FQnLPJ3fXuC
 fwAEA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warning by dropping #{address,size}-cells from the SPI
NOR node which only has a single child node without reg property:

spi1-nvram.dtsi:19.10-38.4: Warning (avoid_unnecessary_addr_size): /soc/spi@235104000/flash@0: unnecessary #address-cells/#size-cells without "ranges", "dma-ranges" or child "reg" property

Fixes: 3febe9de5ca5 ("arm64: dts: apple: Add SPI NOR nvram partition to all devices")
Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/spi1-nvram.dtsi | 2 --
 1 file changed, 2 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/spi1-nvram.dtsi b/arch/arm64/boot/dts/apple/spi1-nvram.dtsi
index 3df2fd3993b52884d7c00b65099c88d830a7a4c3..9740fbf200f0bcd0e7d1b81885fe9d9ff8f04fdc 100644
--- a/arch/arm64/boot/dts/apple/spi1-nvram.dtsi
+++ b/arch/arm64/boot/dts/apple/spi1-nvram.dtsi
@@ -20,8 +20,6 @@ flash@0 {
 		compatible = "jedec,spi-nor";
 		reg = <0x0>;
 		spi-max-frequency = <25000000>;
-		#address-cells = <1>;
-		#size-cells = <1>;
 
 		partitions {
 			compatible = "fixed-partitions";

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250530-apple-dts-warnings-8bb373367b54

Best regards,
-- 
Sven Peter <sven@kernel.org>

