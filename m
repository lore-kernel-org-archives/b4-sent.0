From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 20 Nov 2026 06:30:09 +0000
Subject: [PATCH v3 2/2] arm64: dts: allwinner: orangepi-zero2/zero3: Read
 the SPI NOR over two lines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-zero2-spi-nor-dual-read-v3-2-1cbb0caaed91@gmail.com>
References: <20261120-zero2-spi-nor-dual-read-v3-0-1cbb0caaed91@gmail.com>
In-Reply-To: <20261120-zero2-spi-nor-dual-read-v3-0-1cbb0caaed91@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: Andre Przywara <andre.przywara@arm.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795156207; l=912;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=OFC2RTSAEIuxlffHGnd62HFfopM0iDcm7zOUqP8Ye3s=;
 b=3TPkb/mogKB7+d2lLRxELbLqFT8QmXwfBqvA+b0x7Tq0Xvg1CXRsH6XCTUCfv/kctAr8msjod
 arVGTFtCRyhDJ8AgI00m7plFRPIFm4EMDFJLA4vttS1S5lNPVENED0H
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

WP# and HOLD# are tied to VCC on the Zero2 (schematic v1.3), so read over
two lines. Andre Przywara pointed out that the Zero3 is the same.

Reviewed-by: Andre Przywara <andre.przywara@arm.com>
Tested-by: Andre Przywara <andre.przywara@arm.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
index cd1f67ad7c2b..de05cbbd2cae 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
@@ -110,6 +110,7 @@ spi_flash: flash@0 {
 		compatible = "jedec,spi-nor";
 		reg = <0>;
 		spi-max-frequency = <40000000>;
+		spi-rx-bus-width = <2>;
 	};
 };
 

-- 
2.55.0

