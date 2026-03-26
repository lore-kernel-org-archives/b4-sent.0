From: Roman Vivchar <rva333@protonmail.com>
Date: Thu, 26 Mar 2026 03:00:47 +0200
Subject: [PATCH] clocksource/drivers/timer-mediatek: initialize GPT6 as
 system counter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260326-archtimer-v1-1-5328574e5935@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYyNT3cSi5IySzNzUIl1jU/MkA6M0cxMDUwsloPqCotS0zAqwWdGxtbU
 AfxNdA1sAAAA=
X-Change-ID: 20260325-archtimer-357b02f74058
To: Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 Akari Tsuyukusa <akkun11.open@gmail.com>, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774486847; l=2040;
 i=rva333@protonmail.com; s=20260325; h=from:subject:message-id;
 bh=yXLTuLAUXSGAa9XhaQxQZMpIErABYX5VH7iq2PdHl/I=;
 b=CkjxoHpTP04gLssC28KwNiKO/2GD1L0djaFjsZPxG+Xdk1tr1Ar+H+0rQ8dlleGW5YWaDdQvz
 KXCJOx3HpXYB5CxlTCwQUDILFRGTPuOmHDxlW4PgJnhBEcsplRiSDro
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=euuVBZGtA2Cqb8Dju84qpQPhvwxyUirJlXpqEPQWKBM=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260325 with auth_id=695
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On certain MediaTek SoCs like mt6572 (likely before the CPUXGPT was
introduced), the generic arch timer is fed by the GPT6. Some bootloaders
don't initialize it properly, leading to dead arch timer.

Fix this by configuring GPT6 when the MediaTek timer is probed. This
makes arch timer work properly and removes IPI overhead from MediaTek
timer broadcast when arch timer is used.

If the timer was configured by the bootloader, this change is no-op.

Tested-by: Akari Tsuyukusa <akkun11.open@gmail.com> # MT6589
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
On certain MediaTek SoCs like mt6572 (likely before the CPUXGPT was
introduced), the generic arch timer is fed by the GPT6. Some bootloaders
don't initialize it properly, leading to dead arch timer.

Fix this by configuring GPT6 when the MediaTek timer is probed. This
makes arch timer work properly and removes IPI overhead from MediaTek
timer broadcast when arch timer is used.

If the timer was configured by the bootloader, this change is no-op.
---
 drivers/clocksource/timer-mediatek.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/clocksource/timer-mediatek.c b/drivers/clocksource/timer-mediatek.c
index 7bcb4a3f26fb..7de34cace572 100644
--- a/drivers/clocksource/timer-mediatek.c
+++ b/drivers/clocksource/timer-mediatek.c
@@ -22,6 +22,8 @@
 
 #define TIMER_SYNC_TICKS        (3)
 
+#define TIMER_SYSCNT            (6)
+
 /* gpt */
 #define GPT_IRQ_EN_REG          0x00
 #define GPT_IRQ_ENABLE(val)     BIT((val) - 1)
@@ -335,6 +337,9 @@ static int __init mtk_gpt_init(struct device_node *node)
 
 	mtk_gpt_enable_irq(&to, TIMER_CLK_EVT);
 
+	/* Configure GPT6 to feed arch timer */
+	mtk_gpt_setup(&to, TIMER_SYSCNT, GPT_CTRL_OP_FREERUN);
+
 	return 0;
 }
 TIMER_OF_DECLARE(mtk_mt6577, "mediatek,mt6577-timer", mtk_gpt_init);

---
base-commit: 05f7e89ab9731565d8a62e3b5d1ec206485eeb0b
change-id: 20260325-archtimer-357b02f74058

Best regards,
-- 
Roman Vivchar <rva333@protonmail.com>

