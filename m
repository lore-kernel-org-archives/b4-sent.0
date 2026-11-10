From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 10 Nov 2026 21:22:23 +0200
Subject: [PATCH 3/3] arm64: dts: mediatek: mt6797: fix wdt compatible and
 add reset-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-6797-wdt-v1-3-7f07755b6074@protonmail.com>
References: <20261110-6797-wdt-v1-0-7f07755b6074@protonmail.com>
In-Reply-To: <20261110-6797-wdt-v1-0-7f07755b6074@protonmail.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Ben Grisdale <bengris32@protonmail.ch>, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794338551; l=1078;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=VuN0jtuD+HtYuy89pzuqnoMMbe8NyfZawjbjHy4rttU=;
 b=1dFuWL6ecSyhlJelauX7l708ej5nhN7koHbW5djy5P8rSYePuhYRr7HCqCh+s52bA/JpOHFCA
 tl2bQs0rJAWCiOmmz8br6jzFXPhadD5abjHTpCstLYM6xwkzO7Tr6+B
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TOPRGU reset bits on the mt6797 SoC do not match that of mt6589,
therefore they are not compatible [1].

Remove the deprecated mt6589 fallback for mt6797 and add reset-cells to
enable other peripherals to use the TOPRGU resets.

Link: https://www.96boards.org/documentation/consumer/mediatekx20/additional-docs/docs/MT6797_Register_Table_Part_1.pdf [1]
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 arch/arm64/boot/dts/mediatek/mt6797.dtsi | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/mediatek/mt6797.dtsi b/arch/arm64/boot/dts/mediatek/mt6797.dtsi
index 8ac98a378fd6..c0f98ae132dc 100644
--- a/arch/arm64/boot/dts/mediatek/mt6797.dtsi
+++ b/arch/arm64/boot/dts/mediatek/mt6797.dtsi
@@ -218,8 +218,9 @@ scpsys: power-controller@10006000 {
 	};
 
 	watchdog: watchdog@10007000 {
-		compatible = "mediatek,mt6797-wdt", "mediatek,mt6589-wdt";
+		compatible = "mediatek,mt6797-wdt";
 		reg = <0 0x10007000 0 0x100>;
+		#reset-cells = <1>;
 	};
 
 	apmixedsys: apmixed@1000c000 {

-- 
2.56.0

