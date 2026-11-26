From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: daniel.lezcano@linaro.org, rafael@kernel.org, rui.zhang@intel.com, 
 lukasz.luba@arm.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-pm@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 4/4] thermal/drivers/mediatek/lvts_thermal: skip sensors
 without a thermal zone in IRQ
Date: Thu, 26 Nov 2026 00:53:25 +0000
Message-Id: <20261126005321.71799-5-iasnezhkov@gmail.com>
In-Reply-To: <20261126005321.71799-1-iasnezhkov@gmail.com>
References: <20261126005321.71799-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654402; l=1531;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=GQljtqYQ6lcHw8R3VtJICUMkx+Xq1lALWiNrkmGHLgg=;
 b=DH/AUAWu5lnGqPy8+N3l9XPuuvdXd1jikIKHLwpyiWTax2zPR9JKcsvnhDQ2Z0kSFmJa1+W52
 S6YPolMrjUSAe9bNSFd6DBmtwUbgjzO1f7yZdbaIP+h96n3Oxg60u20
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lvts_ctrl_start() skips sensors absent from valid_sensor_mask as well as
sensors whose thermal zone is not present in the device tree (-ENODEV),
leaving lvts_ctrl->sensors[i].tz as NULL.

lvts_ctrl_irq_handler(), however, loops over all four sensor slots and
passes lvts_ctrl->sensors[i].tz unconditionally to
thermal_zone_device_update(), which dereferences tz immediately if a
status bit for an unpopulated sensor slot is set in LVTS_MONINTSTS.

Check lvts_ctrl->sensors[i].tz before calling
thermal_zone_device_update() while still acknowledging the status bit
with W1C.

Found and drafted with an AI coding assistant.

Fixes: f5f633b18234 ("thermal/drivers/mediatek: Add the Low Voltage Thermal Sensor driver")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/thermal/mediatek/lvts_thermal.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/thermal/mediatek/lvts_thermal.c b/drivers/thermal/mediatek/lvts_thermal.c
index f0b7caa..5fc87a8 100644
--- a/drivers/thermal/mediatek/lvts_thermal.c
+++ b/drivers/thermal/mediatek/lvts_thermal.c
@@ -588,8 +588,9 @@ static irqreturn_t lvts_ctrl_irq_handler(struct lvts_ctrl *lvts_ctrl)
 		if (!(value & masks[i]))
 			continue;
 
-		thermal_zone_device_update(lvts_ctrl->sensors[i].tz,
-					   THERMAL_TRIP_VIOLATED);
+		if (lvts_ctrl->sensors[i].tz)
+			thermal_zone_device_update(lvts_ctrl->sensors[i].tz,
+						   THERMAL_TRIP_VIOLATED);
 		iret = IRQ_HANDLED;
 	}
 
-- 
2.54.0 (Apple Git-157)


