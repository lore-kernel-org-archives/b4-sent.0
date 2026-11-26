From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: daniel.lezcano@linaro.org, rafael@kernel.org, rui.zhang@intel.com, 
 lukasz.luba@arm.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-pm@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 1/4] thermal/drivers/mediatek/lvts_thermal: write
 LVTS_CALSCALE in lvts_ctrl_configure()
Date: Thu, 26 Nov 2026 00:53:22 +0000
Message-Id: <20261126005321.71799-2-iasnezhkov@gmail.com>
In-Reply-To: <20261126005321.71799-1-iasnezhkov@gmail.com>
References: <20261126005321.71799-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654401; l=1283;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=DfpU2QqoC6gb2t4TCCBuYupqgxwpLO6QVGeUXzAFNXc=;
 b=2bySduS9R3VaEm073Or1qqjPHuTmVrGNaFcC5OQ3+Hzxz0rBhNpPxGJrdIyjy0OFVMdrBP23H
 VOVIOeoOk4oA+ttzyrJlMXKFNcbVolhIaKRP+68BAlRlYpSfVYocuvB
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lvts_ctrl_configure() assigns 0x300 and LVTS_CALSCALE_CONF (0x300) to
the local variable `value`, then immediately overwrites `value` with the
LVTS_MSRCTL0 filter setting without ever writing LVTS_CALSCALE (0x0048).

Remove the dead duplicate assignment and write LVTS_CALSCALE_CONF to
LVTS_CALSCALE(lvts_ctrl->base), matching the comment above it and
MediaTek's downstream soc_temp_lvts initialization sequence.

Found and drafted with an AI coding assistant.

Fixes: f5f633b18234 ("thermal/drivers/mediatek: Add the Low Voltage Thermal Sensor driver")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/thermal/mediatek/lvts_thermal.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/thermal/mediatek/lvts_thermal.c b/drivers/thermal/mediatek/lvts_thermal.c
index 350fffd..e034c6c 100644
--- a/drivers/thermal/mediatek/lvts_thermal.c
+++ b/drivers/thermal/mediatek/lvts_thermal.c
@@ -1197,8 +1197,8 @@ static int lvts_ctrl_configure(struct device *dev, struct lvts_ctrl *lvts_ctrl)
 	/*
 	 * LVTS_CALSCALE : ADC voltage round
 	 */
-	value = 0x300;
 	value = LVTS_CALSCALE_CONF;
+	writel(value, LVTS_CALSCALE(lvts_ctrl->base));
 
 	/*
 	 * LVTS_MSRCTL0 : Sensor filtering strategy
-- 
2.54.0 (Apple Git-157)


