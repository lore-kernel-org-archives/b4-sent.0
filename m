From: David Heidelberg <david@ixit.cz>
Date: Mon, 21 Sep 2026 12:46:25 +0200
Subject: [PATCH v4 4/4] backlight: qcom-wled: Read back the programmed
 brightness at probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-qcom-wled-backlight-v4-4-bab8c7ef73cb@ixit.cz>
References: <20260921-qcom-wled-backlight-v4-0-bab8c7ef73cb@ixit.cz>
In-Reply-To: <20260921-qcom-wled-backlight-v4-0-bab8c7ef73cb@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6134; i=david@ixit.cz;
 h=from:subject:message-id; bh=Vd0mK0QtPcwQRIQctDNdJy4/aT9MYS6AbqA9R9Lgs7M=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqsQr/SPXXhzir5slfNf//B0RQVNzZfsL8bCu40
 sNHQe0OfyqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarEK/wAKCRBgAj/E00kg
 cohSD/43ZwcZK12PiDRqLFQ1BSQj/qpvka/d9RpoDqvnRgqK4kf2y0NM4dS2TQK/FdW5WZ+/Yi6
 y31aalt+YjK/Bq+IGnkO6rBIQHuRhNA6r3pDZKFVV2t0IG8sYVENY97njnDu2/NTvsBQ3UsSv4j
 pK9l2rU88hLobLSxO1zzEYAUrApOR/ibpYipJ12A7jwGrVUeJNF5eKYaLAudIO7AZv+B7UUms/h
 ssYYHA8EeTaukyFUvWw8PDd0KJsuEHa8GqolTOJxdQND6CJdl5Lx0Mlg7jWry/2wZZmtxPMjVBR
 JBZBXFs+8EeMXM9QapCVLV/aIgVeO+xUcOoQbMyQBMauFfXF0e/YDW/PR7Qhk4SlpHW8TMCvPWg
 ZYbG23sGon4Qo54P9PNe9IAQuwaHXq3eQJWZxkmfL0ExRhPhas0EUGledpjCjvTuiOOSNBnl4jW
 E6VPMZpoTLa1X5wUymOunEKw1tq8BWTDaw8Ic0mdjY0UhOahKxEhQ9AhiaJxPa9nouVdKZJnGSt
 rRS1pntI1oWsfwPcJClyNmXPLt51XZygdR1JLCUo65JPn5rqBWvMQLba4eXLY7xSCSKNToM1/2K
 BJMD71JkHf15/fCsvsPbv1dPF0z71Z2d1YZZTa5AoRBjjg6sTfUal+29YX7AOYBax7jxN95Hlzv
 F3B9oCckP7WZJdg==
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
 drivers/video/backlight/qcom-wled.c | 74 +++++++++++++++++++++++++++++++------
 1 file changed, 63 insertions(+), 11 deletions(-)

diff --git a/drivers/video/backlight/qcom-wled.c b/drivers/video/backlight/qcom-wled.c
index 3ce3bade3b8dd..ca350f320e177 100644
--- a/drivers/video/backlight/qcom-wled.c
+++ b/drivers/video/backlight/qcom-wled.c
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
@@ -1729,41 +1785,37 @@ static int wled_probe(struct platform_device *pdev)
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
 	return PTR_ERR_OR_ZERO(bl);
 };
 
 static void wled_remove(struct platform_device *pdev)

-- 
2.55.0

