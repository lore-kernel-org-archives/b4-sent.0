From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sat, 20 Sep 2025 20:23:31 +0200
Subject: [PATCH 06/10] ARM: dts: mediatek: mt6582: add mt6582 compatible to
 timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-mt6582-v1-6-b887720f577d@protonmail.com>
References: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
In-Reply-To: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=1128;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=r6SXHQbEHcaMnuM7G635DvBb4GqKr2d885SMc7iqSiQ=;
 b=z6YTtrGMN5Tgfi5hnkCwEdqfPbpmjia5G5oRbA2+IRGF5mPfUNLHlgAQk0ZuNJvauGoo5Me3t
 R8K3WtIxkAJCQdUJ9uVrnv16xY0b3iunHZm/GNJ2V73/uCjtEtDAHBq
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bindings already have mt6582 compatible for timer, so add that to DTSI.
While at it, remove clock-names property (which is not required by timer
node) and fix node address.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6582.dtsi | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/arch/arm/boot/dts/mediatek/mt6582.dtsi b/arch/arm/boot/dts/mediatek/mt6582.dtsi
index 8a14dc1759d6f65fa75accddab83c1b6424d1632..54d675ecb390c52c7ca0f406155bfc59e32137ec 100644
--- a/arch/arm/boot/dts/mediatek/mt6582.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt6582.dtsi
@@ -66,12 +66,11 @@ watchdog: watchdog@10007000 {
 			reg = <0x10007000 0x100>;
 		};
 
-		timer: timer@11008000 {
-			compatible = "mediatek,mt6577-timer";
+		timer: timer@10008000 {
+			compatible = "mediatek,mt6582-timer", "mediatek,mt6577-timer";
 			reg = <0x10008000 0x80>;
 			interrupts = <GIC_SPI 112 IRQ_TYPE_LEVEL_LOW>;
 			clocks = <&system_clk>, <&rtc_clk>;
-			clock-names = "system-clk", "rtc-clk";
 		};
 
 		sysirq: interrupt-controller@10200100 {

-- 
2.49.0

