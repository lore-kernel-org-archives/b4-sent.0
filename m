From: Max Shevchenko <wctrl@proton.me>
Date: Tue, 01 Jul 2025 09:07:02 +0300
Subject: [PATCH v3 08/11] ARM: mediatek: add MT6572 smp bring up code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250701-mt6572-v3-8-8937cfa33f95@proton.me>
References: <20250701-mt6572-v3-0-8937cfa33f95@proton.me>
In-Reply-To: <20250701-mt6572-v3-0-8937cfa33f95@proton.me>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Thomas Gleixner <tglx@linutronix.de>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Sean Wang <sean.wang@mediatek.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-watchdog@vger.kernel.org, 
 Max Shevchenko <wctrl@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751350015; l=1940;
 i=wctrl@proton.me; s=20250603; h=from:subject:message-id;
 bh=PSE9MkQgZmOqgXgkbRv8mf/3whMKOtrk3zwWFrj3c7Q=;
 b=KWkSJeZfxusTPI4uIF19+84KsqxhE+OptOVcoVaBekTd7CikI1o6vPYPps+1GacT+silks3LQ
 BSELHxQkamLDGKlPj47Gk1eMmDJifYWAVEE0Mesd6OyTvUm/ufnjYfT
X-Developer-Key: i=wctrl@proton.me; a=ed25519;
 pk=JXUx3mL/OrnRvbK57HXgugBjEBKq4QgDKJqp7BALm74=
X-Endpoint-Received: by B4 Relay for wctrl@proton.me/20250603 with auth_id=421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for booting the secondary CPU on the MT6572 SoC.

Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Signed-off-by: Max Shevchenko <wctrl@proton.me>
---
 arch/arm/mach-mediatek/Kconfig   | 4 ++++
 arch/arm/mach-mediatek/platsmp.c | 7 +++++++
 2 files changed, 11 insertions(+)

diff --git a/arch/arm/mach-mediatek/Kconfig b/arch/arm/mach-mediatek/Kconfig
index 35a3430c7942d897106bb32916df78347113798a..638eabad2dd37ee56244fc036cb76af135aee416 100644
--- a/arch/arm/mach-mediatek/Kconfig
+++ b/arch/arm/mach-mediatek/Kconfig
@@ -15,6 +15,10 @@ config MACH_MT2701
 	bool "MediaTek MT2701 SoCs support"
 	default ARCH_MEDIATEK
 
+config MACH_MT6572
+	bool "MediaTek MT6572 SoCs support"
+	default ARCH_MEDIATEK
+
 config MACH_MT6589
 	bool "MediaTek MT6589 SoCs support"
 	default ARCH_MEDIATEK
diff --git a/arch/arm/mach-mediatek/platsmp.c b/arch/arm/mach-mediatek/platsmp.c
index 16a4ee6c959050474c5535ac6a65d92b29482d53..bbd26d423bdef23629ec5ca9d9c61903748988b7 100644
--- a/arch/arm/mach-mediatek/platsmp.c
+++ b/arch/arm/mach-mediatek/platsmp.c
@@ -29,6 +29,12 @@ static const struct mtk_smp_boot_info mtk_mt8135_tz_boot = {
 	{ 0x3f8, 0x3f8, 0x3f8 },
 };
 
+static const struct mtk_smp_boot_info mtk_mt6572_boot = {
+	0x10001400, 0x08,
+	{ 0x534c4131 },
+	{ 0x0c },
+};
+
 static const struct mtk_smp_boot_info mtk_mt6589_boot = {
 	0x10002000, 0x34,
 	{ 0x534c4131, 0x4c415332, 0x41534c33 },
@@ -49,6 +55,7 @@ static const struct of_device_id mtk_tz_smp_boot_infos[] __initconst = {
 };
 
 static const struct of_device_id mtk_smp_boot_infos[] __initconst = {
+	{ .compatible   = "mediatek,mt6572", .data = &mtk_mt6572_boot },
 	{ .compatible   = "mediatek,mt6589", .data = &mtk_mt6589_boot },
 	{ .compatible   = "mediatek,mt7623", .data = &mtk_mt7623_boot },
 	{ .compatible   = "mediatek,mt7629", .data = &mtk_mt7623_boot },

-- 
2.50.0

