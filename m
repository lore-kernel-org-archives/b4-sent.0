From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sat, 20 Sep 2025 20:23:33 +0200
Subject: [PATCH 08/10] ARM: dts: mediatek: mt6582: add enable-method
 property to cpus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-mt6582-v1-8-b887720f577d@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=648;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=1pkXsToukeBtOjKTSGrlOrfz/vD1cenGodZl+YEjRIg=;
 b=z8G1Vkbhc61fkJqS5KiuPXS7HZ+UuQuceW7BHFe45IGZoQV7xXDPyf6dSKwRq66glu1joNL+D
 /ifwN9UQ/65CiUM/A038MER63r8hCTnzshmjl56uPBozEqeSy64GDfc
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add missing property for SMP.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6582.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/boot/dts/mediatek/mt6582.dtsi b/arch/arm/boot/dts/mediatek/mt6582.dtsi
index 82564c740c2182448f8f88bbc2b22c4fef1fdeef..f941ea44898a9f26d9742f31f4a667adcc77dfc8 100644
--- a/arch/arm/boot/dts/mediatek/mt6582.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt6582.dtsi
@@ -14,6 +14,7 @@ / {
 	cpus {
 		#size-cells = <0>;
 		#address-cells = <1>;
+		enable-method = "mediatek,mt6589-smp";
 
 		cpu@0 {
 			device_type = "cpu";

-- 
2.49.0

