From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 05:29:35 +0000
Subject: [PATCH v2 2/2] arm64: dts: allwinner: orangepi-zero2/zero3: Read
 the SPI NOR over two lines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-zero2-spi-nor-dual-read-v2-2-185c87065e39@gmail.com>
References: <20261119-zero2-spi-nor-dual-read-v2-0-185c87065e39@gmail.com>
In-Reply-To: <20261119-zero2-spi-nor-dual-read-v2-0-185c87065e39@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: Andre Przywara <andre.przywara@arm.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795066173; l=857;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Q+r4zEIs6OoXjgWsTg14JRKlUB5idFqb5Wum5OUoLAI=;
 b=64RjdNiTWEOyc/imWHPnWirAAmWbU5eG2Y2HriNa1MjneBj8xG8+WssVODkJpJVzzZ/htz6eg
 diuEy0yHbMeAazMYr0kuIZMx51+JrXQYOltsFaCRx679k3Ai5zDXIAY
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

WP# and HOLD# are tied to VCC on the Zero2 (schematic v1.3), so read over
two lines. Andre Przywara pointed out that the Zero3 is the same.

Suggested-by: Andre Przywara <andre.przywara@arm.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
index 646d92e0f724..4a588c44d029 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
@@ -110,6 +110,7 @@ flash: flash@0 {
 		compatible = "jedec,spi-nor";
 		reg = <0>;
 		spi-max-frequency = <40000000>;
+		spi-rx-bus-width = <2>;
 	};
 };
 

-- 
2.55.0

