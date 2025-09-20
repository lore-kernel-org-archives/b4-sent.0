From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sat, 20 Sep 2025 20:23:30 +0200
Subject: [PATCH 05/10] ARM: dts: mediatek: mt6582: remove compatible
 property from root node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-mt6582-v1-5-b887720f577d@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=662;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=LHxW1zi0DUMWIe5Lj8+bFJxdSQEdq66WG8h16b3dP4E=;
 b=TMvWA8WAGPT44mYP1vueAUHoVtdz+gB18NfVa5rTYKl9Nvrdu+N4bkMVEM0O20iu9Q/hAADvR
 nyg/7JLiZh/BjIexjLpZYiTP2vBK9Ll6QgIwFucLxYSOOgRikBzNpzI
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SoC's DTSI does not require compatible property. Drop that.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6582.dtsi | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm/boot/dts/mediatek/mt6582.dtsi b/arch/arm/boot/dts/mediatek/mt6582.dtsi
index 8ada8c6518661509ebee647367064187f4376ab9..8a14dc1759d6f65fa75accddab83c1b6424d1632 100644
--- a/arch/arm/boot/dts/mediatek/mt6582.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt6582.dtsi
@@ -9,7 +9,6 @@
 / {
 	#address-cells = <1>;
 	#size-cells = <1>;
-	compatible = "mediatek,mt6582";
 	interrupt-parent = <&sysirq>;
 
 	cpus {

-- 
2.49.0

