From: kvnshroom <kvnshroom@gmail.com>
Date: Fri, 06 Nov 2026 03:47:00 +0100
Subject: [PATCH] wifi: mt76: mt76x0: select the VGA gain from the RSSI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-mt76x0-rssi-agc-v1-1-9d2f3ad74096@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwMz3dwSc7MKA92i4uJM3cT0ZF3TVPNEC2MzS/PEpGQloK6CotS0zAq
 widGxtbUAHa7S42EAAAA=
X-Change-ID: 20261106-mt76x0-rssi-agc-5e7a83697abc
To: Felix Fietkau <nbd@nbd.name>, Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>, Shayne Chen <shayne.chen@mediatek.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 kvnshroom <kvnshroom@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793933291; l=4777;
 i=kvnshroom@gmail.com; s=20261106; h=from:subject:message-id;
 bh=GOUrR0SBzLl91iB01un4+ocyPS/13W2NZJubzZQmBUM=;
 b=u5iZ31sHOf1LNUdzPgpZzqWvjRaA3mYJPtptQvXyoEbww3yQIV9dtYYK4psF31FL6ZasMU6zF
 GhVWAqLvr/uDC+3Y+jAiie91KB5QWbRnMie1jQfhRTWOQRdUG1Duqk1
X-Developer-Key: i=kvnshroom@gmail.com; a=ed25519;
 pk=8lajK9/tD4YlPR/MOkqpgUU4drxTtsOnUfM8foTue/4=
X-Endpoint-Received: by B4 Relay for kvnshroom@gmail.com/20261106 with auth_id=1426
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit e1534fef1ae4 ("wifi: mt76: feed the station RSSI average
from the chain signals") mt76x0 gets the real station RSSI for its gain
control. On an MT7610U (ASUS USB-AC51, 5 GHz, 80 MHz, about -60 dBm)
this makes the false CCA based VGA loop worse: with low_gain 2 the gain
moves between 44 and 56 and stays at 56 most of the time, the false CCA
counter reads 30k-50k per calibration interval and the receiver is
overdriven.

Fixed gain (BBP AGC8 bits 14:8) against the false CCA counter, with a
ping to the AP every 200 ms during a download at the 50 Mbit/s line
rate:

  gain   false CCA   ping p95 / max     download
  24-48  0.9k-4k     2.5-3.8 / 5-27 ms  51 Mbit/s
  50     8k-11k      3.2-4.5 / 25-40 ms 51 Mbit/s
  56     46k-59k     164-299 / 400 ms   39-43 Mbit/s

The MediaTek Windows driver (netr28ux.sys 5.1.38) does not use the
false CCA counter on MT7610/MT7650. It selects the gain from the RSSI
in three steps, at -60 and -70 dBm. Do the same: reduce the calibrated
initial gain by 42, 26 or 2 depending on the RSSI, with 2 dB of
hysteresis between the steps. On this adapter the initial gain is 66,
which gives the 24/40/64 used by that driver. MT7630 keeps the current
behaviour.

Same setup, 60 s per run, two runs each:

             gain       false CCA  ping p95 / max     loss  download
  CCA loop   mostly 56  30k-50k    1.1-1.8 s / 3.4 s  0-9%  18-39 Mbit/s
  RSSI steps 40         ~300       3 ms / 8-15 ms     0%    46-51 Mbit/s

Not tested: weak signal (below -70 dBm), 2.4 GHz and MT7610E/MT7650E.

The Windows driver was analysed with Ghidra. The analysis, this change
and the changelog were prepared with the help of an AI coding assistant
(Claude); I reviewed and tested the result on my hardware.

Signed-off-by: kvnshroom <kvnshroom@gmail.com>
---
Tested on an ASUS USB-AC51 (MT7610U) with Linux 7.3 and e1534fef1ae4
backported. I can run more tests, for example with a weaker signal or
on 2.4 GHz, if that helps.
---
 drivers/net/wireless/mediatek/mt76/mt76x0/phy.c | 64 +++++++++++++++++++++++++
 1 file changed, 64 insertions(+)

diff --git a/drivers/net/wireless/mediatek/mt76/mt76x0/phy.c b/drivers/net/wireless/mediatek/mt76/mt76x0/phy.c
index ec554a059..d052d8619 100644
--- a/drivers/net/wireless/mediatek/mt76/mt76x0/phy.c
+++ b/drivers/net/wireless/mediatek/mt76/mt76x0/phy.c
@@ -1064,6 +1064,64 @@ static void mt76x0_phy_set_gain_val(struct mt76x02_dev *dev)
 		mt76x02_phy_dfs_adjust_agc(dev);
 }
 
+/*
+ * MT7610/MT7650: select the VGA gain from the RSSI only. The gain is
+ * reduced from the calibrated initial value by a fixed amount per RSSI
+ * step, with some hysteresis between the steps. The false CCA counter is
+ * not used, since on these chips it drives the gain into a range where
+ * the receiver is overdriven.
+ */
+#define MT76X0_RSSI_GAIN_STRONG		-60
+#define MT76X0_RSSI_GAIN_MEDIUM		-70
+#define MT76X0_RSSI_GAIN_HYST		2
+
+static int mt76x0_phy_rssi_gain_step(int rssi, int prev)
+{
+	int strong = MT76X0_RSSI_GAIN_STRONG;
+	int medium = MT76X0_RSSI_GAIN_MEDIUM;
+
+	if (prev == 2)
+		strong -= MT76X0_RSSI_GAIN_HYST;
+	else if (prev >= 0)
+		strong += MT76X0_RSSI_GAIN_HYST;
+	if (prev >= 1)
+		medium -= MT76X0_RSSI_GAIN_HYST;
+	else if (prev == 0)
+		medium += MT76X0_RSSI_GAIN_HYST;
+
+	if (rssi > strong)
+		return 2;
+	if (rssi > medium)
+		return 1;
+	return 0;
+}
+
+static void mt76x0_phy_update_rssi_gain(struct mt76x02_dev *dev)
+{
+	static const u8 gain_adjust[] = { 2, 26, 42 };
+	int step;
+	u8 adjust;
+
+	/* keep the counter visible in debugfs and clear it */
+	dev->cal.false_cca = FIELD_GET(MT_RX_STAT_1_CCA_ERRORS,
+				       mt76_rr(dev, MT_RX_STAT_1));
+
+	if (!dev->cal.avg_rssi_all)
+		step = 1;
+	else
+		step = mt76x0_phy_rssi_gain_step(dev->cal.avg_rssi_all,
+						 dev->cal.low_gain);
+
+	adjust = min_t(u8, gain_adjust[step], dev->cal.agc_gain_init[0]);
+	if (step == dev->cal.low_gain && adjust == dev->cal.agc_gain_adjust)
+		return;
+
+	dev->cal.low_gain = step;
+	dev->cal.agc_gain_adjust = adjust;
+	dev->cal.agc_gain_cur[0] = dev->cal.agc_gain_init[0];
+	mt76x0_phy_set_gain_val(dev);
+}
+
 static void
 mt76x0_phy_update_channel_gain(struct mt76x02_dev *dev)
 {
@@ -1072,6 +1130,12 @@ mt76x0_phy_update_channel_gain(struct mt76x02_dev *dev)
 	int low_gain;
 
 	dev->cal.avg_rssi_all = mt76_get_min_avg_rssi(&dev->mt76, 0);
+
+	if (!is_mt7630(dev)) {
+		mt76x0_phy_update_rssi_gain(dev);
+		return;
+	}
+
 	if (!dev->cal.avg_rssi_all)
 		dev->cal.avg_rssi_all = -75;
 

---
base-commit: b8e5b0ae8ff47240366d38e5d12c65f878724316
change-id: 20261106-mt76x0-rssi-agc-5e7a83697abc

Best regards,
-- 
kvnshroom <kvnshroom@gmail.com>

