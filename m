From: David Heidelberg <david@ixit.cz>
Date: Mon, 14 Sep 2026 20:14:17 +0200
Subject: [PATCH v3 4/4] backlight: qcom-wled: Read back the programmed
 brightness at probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-qcom-wled-backlight-v3-4-d69fe9843841@ixit.cz>
References: <20260914-qcom-wled-backlight-v3-0-d69fe9843841@ixit.cz>
In-Reply-To: <20260914-qcom-wled-backlight-v3-0-d69fe9843841@ixit.cz>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Helge Deller <deller@gmx.de>, 
 Kiran Gunda <quic_kgunda@quicinc.com>, 
 Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-fbdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=6845; i=david@ixit.cz;
 h=from:subject:message-id; bh=Nidh9qw4K//eY6dG1HyoeNGnuAFJH6nbVwPXrtUb50U=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqqDl4V+pJrmV2561jKJU01TGxU8vgcqrIh5X2a
 PlsSuXv6ESJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqg5eAAKCRBgAj/E00kg
 ckUyD/4kelPr0O/PIMcfSR+A8dfZvlicHAnRvsnN+cmtuK0OC3QRHLcyZnmSMxYm52OmlJ9g6Bo
 clOpYrBCRKVkkwqPYtRFTwb76dByJqUHR8uSPhY6YQpWXdLxJqM73lHsgCDC52dxoFs5Vv3DZC8
 RvdzYWpI6rDCsQ5vQIWPXWfkLe7z0cORtgAUXYW7ZFV4vHMKXZJy9owHFFcDLMDpHZx6IRM/r/g
 3T5vTeFsGj8kX0DgRjBMFiwX6NnYyGCiXCrJ9Jq2/+Vf5ovJv0qcJJvthTagR6Gqs9NswdJI8WL
 bNoG2P/5Z87z5Lk+DojHqExxLYHnL7S+BNSRrfPmiA1cS/8SXyOgiIW6X2lEjdCxmKVnsb0aF7E
 YX1RNRn6fmo8ZihYxi6oH17H+fwmq1tE5Dv4Agg3DxDKlOjHhcM1LQ0DQESZOeo126EZBiFqSFx
 BsKhQy5mew9AMTiDiliXS2mKzwZaVuZqj2HYSuAbgrMuffuL21bvV2ShwAGVexqCgKvgwKbQ7M/
 svmTCV+tgboZauA8PxBt6wu6HRfenR11R/RL2f8QK/GW0O5G7zmjCWbsfjIyOXV9RYHjXyc6sOV
 3knegkXTvUi1fdGjMaE7wYTKPn3jgWgiLA/9/bQRLfk9HhXQouMTUbrUmSym6c3tbrkZMb/DrnB
 7+0Ax2FRYsLpz3w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the previous change wled_probe() seeds wled->brightness from
MOD_EN, but with default-brightness rather than the level the hardware
is actually driving, so a backlight left lit by the bootloader still
visibly steps on the first update, and actual_brightness reports the
last value written rather than what the panel shows.

Add wled_read_brightness(), which returns 0 when MOD_EN is clear and
otherwise reads the brightness register the matching
wledN_set_brightness() writes: the first enabled string on WLED3 and
WLED4, the selected modulator on WLED5. Use it to seed both
wled->brightness and the initial backlight property, and expose it as
backlight_ops.get_brightness so that actual_brightness reflects the
hardware too.

A module that is enabled with the brightness registers at zero, which
wled4_setup() and wled_auto_string_detection() can leave behind on a
cold boot, now reads back as off. The OVP interrupt is then armed by the
first brightness update rather than from probe, which is what happens
on every other board where the module starts out disabled.

Suggested-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/video/backlight/qcom-wled.c | 76 +++++++++++++++++++++++++++++++------
 1 file changed, 64 insertions(+), 12 deletions(-)

diff --git a/drivers/video/backlight/qcom-wled.c b/drivers/video/backlight/qcom-wled.c
index eb742a6598173..471a0cb2b81f6 100644
--- a/drivers/video/backlight/qcom-wled.c
+++ b/drivers/video/backlight/qcom-wled.c
@@ -54,17 +54,17 @@
 #define WLED3_SINK_REG_SYNC				0x47
 #define  WLED3_SINK_REG_SYNC_CLEAR			0x00
 
 #define WLED3_SINK_REG_CURR_SINK			0x4f
 #define  WLED3_SINK_REG_CURR_SINK_MASK			GENMASK(7, 5)
 #define  WLED3_SINK_REG_CURR_SINK_SHFT			5
 
 /* WLED3 specific per-'string' registers below */
-#define WLED3_SINK_REG_BRIGHT(n)			(0x40 + (n * 0x10))
+#define WLED3_SINK_REG_BRIGHT(n)			(0x40 + (n * 0x2))
 
 #define WLED3_SINK_REG_STR_MOD_EN(n)			(0x60 + (n * 0x10))
 #define  WLED3_SINK_REG_STR_MOD_MASK			BIT(7)
 
 #define WLED3_SINK_REG_STR_FULL_SCALE_CURR(n)		(0x62 + (n * 0x10))
 #define  WLED3_SINK_REG_STR_FULL_SCALE_CURR_MASK	GENMASK(4, 0)
 
 #define WLED3_SINK_REG_STR_MOD_SRC(n)			(0x63 + (n * 0x10))
@@ -285,16 +285,60 @@ static int wled5_set_brightness(struct wled *wled, u16 brightness)
 		  WLED5_SINK_REG_MOD_A_BRIGHTNESS_LSB :
 		  WLED5_SINK_REG_MOD_B_BRIGHTNESS_LSB;
 
 	rc = regmap_bulk_write(wled->regmap, wled->sink_addr + offset,
 			       &v, sizeof(v));
 	return rc;
 }
 
+static int wled_read_brightness(struct wled *wled)
+{
+	u16 addr, mask;
+	__le16 v;
+	u32 val;
+	int rc;
+
+	rc = regmap_read(wled->regmap, wled->ctrl_addr + WLED3_CTRL_REG_MOD_EN,
+			 &val);
+	if (rc < 0)
+		return rc;
+
+	if (!(val & WLED3_CTRL_REG_MOD_EN_MASK))
+		return 0;
+
+	switch (wled->version) {
+	case 3:
+		addr = wled->sink_addr +
+		       WLED3_SINK_REG_BRIGHT(wled->cfg.enabled_strings[0]);
+		mask = WLED3_SINK_REG_BRIGHT_MAX;
+		break;
+	case 4:
+		addr = wled->sink_addr +
+		       WLED4_SINK_REG_BRIGHT(wled->cfg.enabled_strings[0]);
+		mask = WLED3_SINK_REG_BRIGHT_MAX;
+		break;
+	case 5:
+		addr = wled->sink_addr + (wled->cfg.mod_sel == MOD_A ?
+					  WLED5_SINK_REG_MOD_A_BRIGHTNESS_LSB :
+					  WLED5_SINK_REG_MOD_B_BRIGHTNESS_LSB);
+		mask = WLED5_SINK_REG_BRIGHT_MAX_15B;
+		break;
+	default:
+		dev_err(wled->dev, "Invalid WLED version\n");
+		return -EINVAL;
+	}
+
+	rc = regmap_bulk_read(wled->regmap, addr, &v, sizeof(v));
+	if (rc < 0)
+		return rc;
+
+	return min_t(u32, le16_to_cpu(v) & mask, wled->max_brightness);
+}
+
 static void wled_ovp_work(struct work_struct *work)
 {
 	struct wled *wled = container_of(work,
 					 struct wled, ovp_work.work);
 	enable_irq(wled->ovp_irq);
 }
 
 static int wled_module_enable(struct wled *wled, int val)
@@ -475,16 +519,28 @@ static int wled_update_status(struct backlight_device *bl)
 	wled->brightness = brightness;
 
 unlock_mutex:
 	mutex_unlock(&wled->lock);
 
 	return rc;
 }
 
+static int wled_get_brightness(struct backlight_device *bl)
+{
+	struct wled *wled = bl_get_data(bl);
+	int rc;
+
+	mutex_lock(&wled->lock);
+	rc = wled_read_brightness(wled);
+	mutex_unlock(&wled->lock);
+
+	return rc;
+}
+
 static int wled4_cabc_config(struct wled *wled, bool enable)
 {
 	int i, j, rc;
 	u8 val;
 
 	for (i = 0; i < wled->cfg.num_strings; i++) {
 		j = wled->cfg.enabled_strings[i];
 
@@ -1646,25 +1702,25 @@ static int wled_configure_ovp_irq(struct wled *wled,
 	if (!wled->brightness)
 		disable_irq(wled->ovp_irq);
 
 	return 0;
 }
 
 static const struct backlight_ops wled_ops = {
 	.update_status = wled_update_status,
+	.get_brightness = wled_get_brightness,
 };
 
 static int wled_probe(struct platform_device *pdev)
 {
 	struct backlight_properties props;
 	struct backlight_device *bl;
 	struct wled *wled;
 	struct regmap *regmap;
-	u32 mod_en;
 	u32 val;
 	int rc;
 
 	regmap = dev_get_regmap(pdev->dev.parent, NULL);
 	if (!regmap) {
 		dev_err(&pdev->dev, "Unable to get regmap\n");
 		return -EINVAL;
 	}
@@ -1728,41 +1784,37 @@ static int wled_probe(struct platform_device *pdev)
 	}
 
 	INIT_DELAYED_WORK(&wled->ovp_work, wled_ovp_work);
 
 	val = WLED_DEFAULT_BRIGHTNESS;
 	of_property_read_u32(pdev->dev.of_node, "default-brightness", &val);
 
 	/*
-	 * The module may already be enabled, either by a bootloader that left
-	 * the backlight lit or by the setup above. Record that, so that the
-	 * first brightness update does not enable an already enabled module,
-	 * and so that the OVP irq is armed from probe rather than from that
-	 * first update.
+	 * The module may already be lit, either by the bootloader or by the
+	 * setup above. Start from what the hardware is driving, so that the
+	 * first brightness update does not step the brightness.
 	 */
-	rc = regmap_read(wled->regmap, wled->ctrl_addr + WLED3_CTRL_REG_MOD_EN,
-			 &mod_en);
+	rc = wled_read_brightness(wled);
 	if (rc < 0)
 		return rc;
 
-	if (mod_en & WLED3_CTRL_REG_MOD_EN_MASK)
-		wled->brightness = val;
+	wled->brightness = rc;
 
 	rc = wled_configure_short_irq(wled, pdev);
 	if (rc < 0)
 		return rc;
 
 	rc = wled_configure_ovp_irq(wled, pdev);
 	if (rc < 0)
 		return rc;
 
 	memset(&props, 0, sizeof(struct backlight_properties));
 	props.type = BACKLIGHT_RAW;
-	props.brightness = val;
+	props.brightness = wled->brightness ?: val;
 	props.max_brightness = wled->max_brightness;
 	bl = devm_backlight_device_register(&pdev->dev, wled->name,
 					    &pdev->dev, wled,
 					    &wled_ops, &props);
 	platform_set_drvdata(pdev, bl);
 	return PTR_ERR_OR_ZERO(bl);
 };
 

-- 
2.55.0

