From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: daniel.lezcano@linaro.org, rafael@kernel.org, rui.zhang@intel.com, 
 lukasz.luba@arm.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-pm@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 0/4] thermal/drivers/mediatek/lvts_thermal: CALSCALE,
 overflow, locking, and IRQ NULL fixes
Date: Thu, 26 Nov 2026 00:53:21 +0000
Message-Id: <20261126005321.71799-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654401; l=1422;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=1leBQV0oOy+uaHay4Mtb/7QLKwo9KRyb8z4zbg9Ip+0=;
 b=DeRs6vSDkiq3HlMNkbRcNnW3B5O7KAkhffqnwDzmX6U2qhxHqi0eXsj9mhdRLyfXYaWKli22y
 GRhmRV3HisQCtTnGthdRZ2KmLygbd82pbzpxD0EvLttrM4wcePGGj9V
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This four-patch series fixes four bugs in
drivers/thermal/mediatek/lvts_thermal.c:

1. Write LVTS_CALSCALE_CONF (0x300) to the LVTS_CALSCALE register instead
   of overwriting a local variable and discarding it.
2. Avoid 32-bit overflow and unsigned truncation in
   lvts_temp_to_raw_mt7988(), and skip converting high == INT_MAX in
   lvts_set_trips() while masking high-offset IRQ.
3. Serialize lvts_set_trips() with a per-controller spinlock_t in
   struct lvts_ctrl so concurrent updates across thermal zones on the
   same controller cannot corrupt shared thresholds or LVTS_MONINT via
   unsynchronized RMW.
4. Check lvts_ctrl->sensors[i].tz before calling
   thermal_zone_device_update() in lvts_ctrl_irq_handler() for disabled
   or DT-absent sensor slots.

Found and drafted with an AI coding assistant while bringing up MT6789.

Ilia Snezhkov (4):
  thermal/drivers/mediatek/lvts_thermal: write LVTS_CALSCALE in
    lvts_ctrl_configure()
  thermal/drivers/mediatek/lvts_thermal: avoid 32-bit overflow in
    lvts_temp_to_raw_mt7988() and INT_MAX trips
  thermal/drivers/mediatek/lvts_thermal: serialize lvts_set_trips() per
    controller
  thermal/drivers/mediatek/lvts_thermal: skip sensors without a thermal
    zone in IRQ

 drivers/thermal/mediatek/lvts_thermal.c | 30 ++++++++++++++++---------
 1 file changed, 20 insertions(+), 10 deletions(-)

-- 
2.54.0 (Apple Git-157)


