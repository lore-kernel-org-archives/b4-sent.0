From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 23 Aug 2025 14:43:50 +0200
Subject: [PATCH 1/3] arm64: dts: rockchip: Fix the headphone detection on
 the orangepi 5 plus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250823-orangepi5-v1-1-ae77dd0e06d7@hotmail.com>
References: <20250823-orangepi5-v1-0-ae77dd0e06d7@hotmail.com>
In-Reply-To: <20250823-orangepi5-v1-0-ae77dd0e06d7@hotmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ondrej Jirman <megi@xff.cz>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755953033; l=1342;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=kGPjNY4n/uxG/MNPreW3TR8PtxdOfCOti3K91Nz2Q5M=;
 b=DIIVLpd0YMMUOmcU63vKLqzgA2GVop3tml6nsagnUg28WHgYFNVQa1U8unq2gIzeNRFYO+3xa
 zedfsD0szo3C/pGzsmbaED6YJPXVZCsHsZqCDvRN/JxRx91zW/Cx/Jk
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The logic of the headphone detect pin seems to be inverted, with this
change headphones actually output sound when plugged in.

Verified by checking /sys/kernel/debug/gpio and by listening.

Fixes: 236d225e1ee7 ("arm64: dts: rockchip: Add board device tree for rk3588-orangepi-5-plus")
Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
There was a big change at some point so it will take some effor to port
it back that far.
---
 arch/arm64/boot/dts/rockchip/rk3588-orangepi-5-plus.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-orangepi-5-plus.dts b/arch/arm64/boot/dts/rockchip/rk3588-orangepi-5-plus.dts
index 121e4d1c3fa5dab0d08edf7cba692a765b48f7b4..8222f1fae8fadc5cbb4ef16b3db5ed975ed43915 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-orangepi-5-plus.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588-orangepi-5-plus.dts
@@ -77,7 +77,7 @@ &analog_sound {
 	pinctrl-names = "default";
 	pinctrl-0 = <&hp_detect>;
 	simple-audio-card,aux-devs = <&speaker_amp>, <&headphone_amp>;
-	simple-audio-card,hp-det-gpios = <&gpio1 RK_PD3 GPIO_ACTIVE_LOW>;
+	simple-audio-card,hp-det-gpios = <&gpio1 RK_PD3 GPIO_ACTIVE_HIGH>;
 	simple-audio-card,widgets =
 		"Microphone", "Onboard Microphone",
 		"Microphone", "Microphone Jack",

-- 
2.50.1

