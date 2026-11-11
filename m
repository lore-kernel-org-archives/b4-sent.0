From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Wed, 11 Nov 2026 06:00:07 +0000
Subject: [PATCH v2 1/8] arm64: dts: allwinner: h616: Cover the codec RAMP
 register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-h616-zero2-dt-v2-1-88d8030fc975@gmail.com>
References: <20261111-h616-zero2-dt-v2-0-88d8030fc975@gmail.com>
In-Reply-To: <20261111-h616-zero2-dt-v2-0-88d8030fc975@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Ryan Walklin <ryan@testtoast.com>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794376807; l=1252;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=BSR+K6Y2s3B1U4tlKARegXXjsMuZ0Bl9ncjh06Y7t+g=;
 b=NDlrnKc/h1AS5iFoQAkz7jUnVgC/2x7mhMyCCIwtF8u/92Q5tpWsWp9vt0qa3fjW2MQrC6fgN
 IekD6SeMC4TAyQX1cmo5Ued7idQR5sfk1v0cHbALV6wmfUD0dAVH8I5
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The codec node maps 0x31c bytes, but the H616 codec has its DAC
RAMP control register at offset 0x31c (H616 user manual v1.0,
section 8.4.6.56), and the sun4i-codec driver uses it: the H616
regmap has max_register = SUN50I_H616_DAC_AC_RAMP_REG (0x31c). The
access only works because ioremap() rounds the mapping up to a page.

Grow the region to 0x320 bytes so that it covers the register.

Fixes: 3eef85034c96 ("arm64: dts: allwinner: h616: Add audio codec node")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h616.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-h616.dtsi
index e4e0b999473e..68bd6137c316 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616.dtsi
@@ -806,7 +806,7 @@ spdif: spdif@5093000 {
 		codec: codec@5096000 {
 			#sound-dai-cells = <0>;
 			compatible = "allwinner,sun50i-h616-codec";
-			reg = <0x05096000 0x31c>;
+			reg = <0x05096000 0x320>;
 			interrupts = <GIC_SPI 58 IRQ_TYPE_LEVEL_HIGH>;
 			clocks = <&ccu CLK_BUS_AUDIO_CODEC>,
 				 <&ccu CLK_AUDIO_CODEC_1X>;

-- 
2.55.0

