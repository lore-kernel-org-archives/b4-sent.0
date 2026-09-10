From: Zakariya Hadrami <zkh@mailbox.org>
Date: Thu, 10 Sep 2026 15:29:14 +0200
Subject: [PATCH v5 3/4] ARM: dts: mediatek: mt8127: Add watchdog support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-mt8127-amazon-ford-basic-v5-3-3cb9eeaffd5c@mailbox.org>
References: <20260910-mt8127-amazon-ford-basic-v5-0-3cb9eeaffd5c@mailbox.org>
In-Reply-To: <20260910-mt8127-amazon-ford-basic-v5-0-3cb9eeaffd5c@mailbox.org>
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, zkh1@proton.me, 
 Zakariya Hadrami <zkh@mailbox.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789047024; l=946;
 i=zkh@mailbox.org; s=20260908; h=from:subject:message-id;
 bh=rS6D92PxCdmOuwt2bs95T+mGttnr+N31hBdnrfYmhjI=;
 b=WzS9g1XKg6ATeApnvLuhMIwY0EkbHusHCzcPlKpXj7IJ/nhfYzHhlAAmNFwo8WxsLAwhHVfrW
 pUzwelPvzq1BA2zE7X3R/uL/NQcrKdfV+NEJDsGiI/6ZJAD29CoOm/9
X-Developer-Key: i=zkh@mailbox.org; a=ed25519;
 pk=up24Xn4ScFKugfT4EJru/UQAS7JOIN+DSQqro+a05T4=
X-Endpoint-Received: by B4 Relay for zkh@mailbox.org/20260908 with auth_id=1015
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add watchdog node and disable it by default as it was not present
initially.

Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Signed-off-by: Zakariya Hadrami <zkh@mailbox.org>
---
 arch/arm/boot/dts/mediatek/mt8127.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/mt8127.dtsi b/arch/arm/boot/dts/mediatek/mt8127.dtsi
index bd61ec7e70c0..9bdf55d2da47 100644
--- a/arch/arm/boot/dts/mediatek/mt8127.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt8127.dtsi
@@ -99,6 +99,13 @@ soc {
 		compatible = "simple-bus";
 		ranges;
 
+		watchdog: watchdog@10007000 {
+			compatible = "mediatek,mt8127-wdt", "mediatek,mt6589-wdt";
+			reg = <0 0x10007000 0 0x100>;
+			interrupts = <GIC_SPI 88 IRQ_TYPE_LEVEL_LOW>;
+			status = "disabled";
+		};
+
 		timer: timer@10008000 {
 			compatible = "mediatek,mt8127-timer",
 					"mediatek,mt6577-timer";

-- 
2.54.0

