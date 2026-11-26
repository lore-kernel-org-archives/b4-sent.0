From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: daniel.lezcano@linaro.org, rafael@kernel.org, rui.zhang@intel.com, 
 lukasz.luba@arm.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-pm@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 3/4] thermal/drivers/mediatek/lvts_thermal: serialize
 lvts_set_trips() per controller
Date: Thu, 26 Nov 2026 00:53:24 +0000
Message-Id: <20261126005321.71799-4-iasnezhkov@gmail.com>
In-Reply-To: <20261126005321.71799-1-iasnezhkov@gmail.com>
References: <20261126005321.71799-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654402; l=2401;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=gkAgfTt9QdjOaikRkLcp8sO69zHNfxvhjZ7a53W/8uU=;
 b=gviRhqdPcdcSYCl9gslZUIi4rn5/AomBFOAcPTeJ4yvj3U6BZZYu7oXI5SNCljFJdopSgeIOa
 2TFeAVSlGCvAJREN01iav2aYknFNmG7w3D3FtqAUmwFXwUm6t7rbhV4
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each struct lvts_ctrl manages up to four sensors, each registered as an
independent thermal_zone_device with its own tz->lock. Concurrent
lvts_set_trips() calls for sensors sharing a controller therefore run
without mutual exclusion while updating lvts_ctrl->{low,high}_thresh,
performing a read-modify-write on LVTS_MONINT in lvts_update_irq_mask(),
and writing LVTS_OFFSETL/LVTS_OFFSETH.

Two concurrent callers can lose each other's LVTS_MONINT enable bits or
leave the programmed threshold registers inconsistent with the stored
controller thresholds.

Add a per-controller spinlock_t to struct lvts_ctrl and serialize
lvts_set_trips() with guard(spinlock)(&lvts_ctrl->lock).

Found and drafted with an AI coding assistant.

Fixes: 2bba1acf7a4c ("thermal/drivers/mediatek/lvts_thermal: Manage threshold between sensors")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/thermal/mediatek/lvts_thermal.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/thermal/mediatek/lvts_thermal.c b/drivers/thermal/mediatek/lvts_thermal.c
index 9b8b653..f0b7caa 100644
--- a/drivers/thermal/mediatek/lvts_thermal.c
+++ b/drivers/thermal/mediatek/lvts_thermal.c
@@ -4,6 +4,7 @@
  * Author: Balsam CHIHI <bchihi@baylibre.com>
  */
 
+#include <linux/cleanup.h>
 #include <linux/clk.h>
 #include <linux/clk-provider.h>
 #include <linux/delay.h>
@@ -16,6 +17,7 @@
 #include <linux/of.h>
 #include <linux/platform_device.h>
 #include <linux/reset.h>
+#include <linux/spinlock.h>
 #include <linux/thermal.h>
 #include <dt-bindings/thermal/mediatek,lvts-thermal.h>
 
@@ -181,6 +183,7 @@ struct lvts_ctrl {
 	void __iomem *base;
 	int low_thresh;
 	int high_thresh;
+	spinlock_t lock; /* protects thresholds and LVTS_MONINT */
 };
 
 struct lvts_domain {
@@ -453,6 +456,8 @@ static int lvts_set_trips(struct thermal_zone_device *tz, int low, int high)
 	u32 raw_high = high != INT_MAX ? lvts_temp_to_raw(high, lvts_data) : 0;
 	bool should_update_thresh;
 
+	guard(spinlock)(&lvts_ctrl->lock);
+
 	lvts_sensor->low_thresh = low;
 	lvts_sensor->high_thresh = high;
 
@@ -989,6 +994,7 @@ static int lvts_ctrl_init(struct device *dev, struct lvts_domain *lvts_td,
 
 		lvts_ctrl[i].low_thresh = INT_MIN;
 		lvts_ctrl[i].high_thresh = INT_MIN;
+		spin_lock_init(&lvts_ctrl[i].lock);
 	}
 
 	/*
-- 
2.54.0 (Apple Git-157)


