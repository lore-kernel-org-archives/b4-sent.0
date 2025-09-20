From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sat, 20 Sep 2025 20:23:27 +0200
Subject: [PATCH 02/10] ARM: mediatek: add MT6582 smp bring up code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-mt6582-v1-2-b887720f577d@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=1555;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=6uGXxS/2ULG475fJT7BkyoFxyDRGMUY7v8S8MSscjII=;
 b=0BSKMlESDh0HSgKA66zOwG/vKXy8rumfTbKH0/oBaj0WYfPac5Dr3DPsPO7BXsVTtuPGbzNcu
 6MV2oVqGHcxB08BzovBXSx3YPLnOAlJR9v3yh/Jm2NO5zhidVkE4axn
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for booting secondary CPUs on MT6582.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 arch/arm/mach-mediatek/Kconfig   | 4 ++++
 arch/arm/mach-mediatek/platsmp.c | 1 +
 2 files changed, 5 insertions(+)

diff --git a/arch/arm/mach-mediatek/Kconfig b/arch/arm/mach-mediatek/Kconfig
index 638eabad2dd37ee56244fc036cb76af135aee416..64ec487c13abd81dd9a866d29b8f47d9ed42490e 100644
--- a/arch/arm/mach-mediatek/Kconfig
+++ b/arch/arm/mach-mediatek/Kconfig
@@ -19,6 +19,10 @@ config MACH_MT6572
 	bool "MediaTek MT6572 SoCs support"
 	default ARCH_MEDIATEK
 
+config MACH_MT6582
+	bool "MediaTek MT6582 SoCs support"
+	default ARCH_MEDIATEK
+
 config MACH_MT6589
 	bool "MediaTek MT6589 SoCs support"
 	default ARCH_MEDIATEK
diff --git a/arch/arm/mach-mediatek/platsmp.c b/arch/arm/mach-mediatek/platsmp.c
index bbd26d423bdef23629ec5ca9d9c61903748988b7..6b0943d95555afa52d134183c61ab6d5c1495ff1 100644
--- a/arch/arm/mach-mediatek/platsmp.c
+++ b/arch/arm/mach-mediatek/platsmp.c
@@ -56,6 +56,7 @@ static const struct of_device_id mtk_tz_smp_boot_infos[] __initconst = {
 
 static const struct of_device_id mtk_smp_boot_infos[] __initconst = {
 	{ .compatible   = "mediatek,mt6572", .data = &mtk_mt6572_boot },
+	{ .compatible   = "mediatek,mt6582", .data = &mtk_mt7623_boot },
 	{ .compatible   = "mediatek,mt6589", .data = &mtk_mt6589_boot },
 	{ .compatible   = "mediatek,mt7623", .data = &mtk_mt7623_boot },
 	{ .compatible   = "mediatek,mt7629", .data = &mtk_mt7623_boot },

-- 
2.49.0

