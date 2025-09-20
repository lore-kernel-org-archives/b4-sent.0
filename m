From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sat, 20 Sep 2025 20:23:32 +0200
Subject: [PATCH 07/10] ARM: dts: mediatek: mt6582: add clock-names property
 to uart nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-mt6582-v1-7-b887720f577d@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=1434;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=IJ2WpBgydGyDmriFnyhyzls81B4aPjYb5NY6k/JiK2Y=;
 b=VAp6w9Z5osx1mLNbqsginU96nD8BYUh3ydYdVzHCMjEzRr/CrmZ2ZHQ8JbulRfNn5Th37kQyh
 n5+6W4naoVNCBrFrIuWqNaARBOwLiUqEpeQMwx9EANcZGw5ZhO4CPwF
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Other SoC DTSI files define this property for their uart nodes.
Do the same here too, to be consistent.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6582.dtsi | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/mt6582.dtsi b/arch/arm/boot/dts/mediatek/mt6582.dtsi
index 54d675ecb390c52c7ca0f406155bfc59e32137ec..82564c740c2182448f8f88bbc2b22c4fef1fdeef 100644
--- a/arch/arm/boot/dts/mediatek/mt6582.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt6582.dtsi
@@ -97,6 +97,7 @@ uart0: serial@11002000 {
 			reg = <0x11002000 0x400>;
 			interrupts = <GIC_SPI 51 IRQ_TYPE_LEVEL_LOW>;
 			clocks = <&uart_clk>;
+			clock-names = "baud";
 			status = "disabled";
 		};
 
@@ -105,6 +106,7 @@ uart1: serial@11003000 {
 			reg = <0x11003000 0x400>;
 			interrupts = <GIC_SPI 52 IRQ_TYPE_LEVEL_LOW>;
 			clocks = <&uart_clk>;
+			clock-names = "baud";
 			status = "disabled";
 		};
 
@@ -113,6 +115,7 @@ uart2: serial@11004000 {
 			reg = <0x11004000 0x400>;
 			interrupts = <GIC_SPI 53 IRQ_TYPE_LEVEL_LOW>;
 			clocks = <&uart_clk>;
+			clock-names = "baud";
 			status = "disabled";
 		};
 
@@ -121,6 +124,7 @@ uart3: serial@11005000 {
 			reg = <0x11005000 0x400>;
 			interrupts = <GIC_SPI 54 IRQ_TYPE_LEVEL_LOW>;
 			clocks = <&uart_clk>;
+			clock-names = "baud";
 			status = "disabled";
 		};
 	};

-- 
2.49.0

