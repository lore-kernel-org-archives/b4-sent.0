From: David Heidelberg <david@ixit.cz>
Date: Fri, 31 Jul 2026 22:34:13 +0200
Subject: [PATCH v9 2/5] Input: synaptics-rmi4 - f12: use hardcoded values
 for aftermarket touch ICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-synaptics-rmi4-v9-2-f088c47af6c5@ixit.cz>
References: <20260731-synaptics-rmi4-v9-0-f088c47af6c5@ixit.cz>
In-Reply-To: <20260731-synaptics-rmi4-v9-0-f088c47af6c5@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Marcus Ramberg <marcus@means.no>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6682; i=david@ixit.cz;
 h=from:subject:message-id; bh=lj5joNi8om0GFyhh8zVBAWd6c5wifksQUnwqxhrVhqg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbQbLF3f7RuF8iobIeEz/9MnZ19e1tLihDJS9Q
 RtUU0KgMKeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam0GywAKCRBgAj/E00kg
 ckwkEADAeglHb+q595lfwBrIHV7imzJ4UHysCHlcT6ILvcAbnDuRXaA/MJRe7/P+cuqATrFGi7+
 61Q1crH5f3HZDsiPtwkZdF0fDKBVDJ+GhG3cNJcYNOCfUhR18Dr2o0kGR2o4YdZrShzqZJvYnar
 0FtKJq+oarORhKCa8iLOxK8MVox8mD9x9Oeh/tMh/BorqJETcmIRyHEnCWnZVd0bKtNodkOTgjY
 xtlEgNNgDJ2GLw+tFCj41438NByO6s+SH8FtXD/gyi2auambbE5Xvr0P5nDC+qaA0iqGiJHWzav
 xZqvUXD+OUUauBwEbVqSq20OTafN0/fLsMr0aub5GZgFbdDgQg/odZqk//WkmOd1a1Z/TryQlmI
 8f7iZDyjZWBT3kJDubCIx7WQUaizSNUeEv1hKdy855JkD0BaplO9pgGL47EkB/UCQNvBjeILycH
 Gg5j6AbZ292SKdmOewdowhpqRtMSl5SgHkwpNWGHgWuuRaLmfSipVLHv7UJMWuONH1ODzgR3Bwj
 4xbSCyX00z6h3CAvRpZiyphf5yvY27hFoIFqbJzGWvVUB84Vzie2P7JJuBxLsW0IrDkITUwvfEx
 mtFQA3xmXG0rU0LaueeOhTBBKhzoL77jvWb5FekKdNLY4jaxUDwoTH6jixoPSqDOSmEmvIT7uQR
 W0b5rbHKcoQTCXA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kaustabh Chakraborty <kauschluss@disroot.org>

Some replacement displays include third-party touch ICs which are
devoid of register descriptors. Create a fake data register descriptor
for such ICs and provide hardcoded default values.

It isn't possible to reliably determine if the touch IC is original or
not, so these fallback values are offered as an alternative to the error
path when register descriptors aren't available.

Signed-off-by: Kaustabh Chakraborty <kauschluss@disroot.org>
[changes for readability / codeflow, checkpatch fixes]
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_f12.c | 76 +++++++++++++++++++++++++++++++++++++-------
 1 file changed, 64 insertions(+), 12 deletions(-)

diff --git a/drivers/input/rmi4/rmi_f12.c b/drivers/input/rmi4/rmi_f12.c
index 333477bf0663e..ace97468b218d 100644
--- a/drivers/input/rmi4/rmi_f12.c
+++ b/drivers/input/rmi4/rmi_f12.c
@@ -240,16 +240,51 @@ static void rmi_f12_process_objects(struct f12_data *f12, u8 *data1, u32 size)
 				      sensor->tracking_pos,
 				      sensor->nbr_fingers,
 				      sensor->dmax);
 
 	for (i = 0; i < objects; i++)
 		rmi_2d_sensor_abs_report(sensor, &sensor->objs[i], i);
 }
 
+static void rmi_f12_set_hardcoded_desc(struct rmi_function *fn, struct f12_data *f12)
+{
+	struct rmi_2d_sensor *sensor = &f12->sensor;
+	struct rmi_register_desc_item *reg_desc;
+
+	/* We have no f12->data_reg_desc, so the pkt_size is 0, override it with
+	 * a somewhat sensible default (this corresponds to 10 fingers).
+	 */
+	sensor->pkt_size = 88;
+
+	/*
+	 * There are no register descriptors to get these values from.
+	 * We set them to high values to either be overwritten by the clip
+	 * properties from devicetree, or to just not get in the way.
+	 */
+	sensor->max_x = 65535;
+	sensor->max_y = 65535;
+
+	/*
+	 * Create the Data1 register descriptor so that touch events
+	 * can work properly.
+	 */
+	reg_desc = devm_kcalloc(&fn->dev, 1,
+			sizeof(struct rmi_register_desc_item), GFP_KERNEL);
+	reg_desc->reg = 1;
+	reg_desc->reg_size = 80;
+	reg_desc->num_subpackets = 10;
+
+	f12->data1 = reg_desc;
+	f12->data1_offset = 0;
+	sensor->nbr_fingers = reg_desc->num_subpackets;
+	sensor->report_abs = 1;
+	sensor->attn_size += reg_desc->reg_size;
+}
+
 static irqreturn_t rmi_f12_attention(int irq, void *ctx)
 {
 	struct rmi_function *fn = ctx;
 	struct rmi_device *rmi_dev = fn->rmi_dev;
 	struct rmi_driver_data *drvdata = dev_get_drvdata(&rmi_dev->dev);
 	struct f12_data *f12 = dev_get_drvdata(&fn->dev);
 	struct rmi_2d_sensor *sensor = &f12->sensor;
 	u32 valid_bytes = sensor->pkt_size;
@@ -371,22 +406,27 @@ static int rmi_f12_config(struct rmi_function *fn)
 
 static int rmi_f12_sensor_init(struct rmi_function *fn, struct f12_data *f12)
 {
 	struct rmi_2d_sensor *sensor = &f12->sensor;
 	size_t pkt_size;
 
 	sensor->fn = fn;
 	f12->data_addr = fn->fd.data_base_addr;
-	pkt_size = rmi_register_desc_calc_size(&f12->data_reg_desc);
-	if (pkt_size > SZ_1M) {
-		dev_err(&fn->dev, "Invalid data packet size: %zu\n", pkt_size);
-		return -EINVAL;
+	/* On quirky devices that don't have a data_reg_desc we hardcode the packet
+	 * in rmi_f12_set_hardcoded_desc(). Make sure not to set it to 0 here.
+	 */
+	if (!sensor->pkt_size) {
+		pkt_size = rmi_register_desc_calc_size(&f12->data_reg_desc);
+		if (pkt_size > SZ_1M) {
+			dev_err(&fn->dev, "Invalid data packet size: %zu\n", pkt_size);
+			return -EINVAL;
+		}
+		sensor->pkt_size = pkt_size;
 	}
-	sensor->pkt_size = pkt_size;
 
 	sensor->axis_align = f12->sensor_pdata.axis_align;
 
 	sensor->x_mm = f12->sensor_pdata.x_mm;
 	sensor->y_mm = f12->sensor_pdata.y_mm;
 	sensor->dribble = f12->sensor_pdata.dribble;
 
 	if (sensor->sensor_type == rmi_sensor_default)
@@ -410,65 +450,76 @@ static int rmi_f12_probe(struct rmi_function *fn)
 	u16 query_addr = fn->fd.query_base_addr;
 	const struct rmi_register_desc_item *item;
 	struct rmi_2d_sensor *sensor;
 	struct rmi_device_platform_data *pdata = rmi_get_platform_data(rmi_dev);
 	struct rmi_driver_data *drvdata = dev_get_drvdata(&rmi_dev->dev);
 	size_t data_offset = 0;
 	int irq_mask_size;
 	int i;
+	bool hardcoded_desc_quirk = false;
 
 	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s\n", __func__);
 
 	irq_mask_size = BITS_TO_LONGS(drvdata->irq_count);
 
 	ret = rmi_read(fn->rmi_dev, query_addr, &buf);
 	if (ret < 0) {
 		dev_err(&fn->dev, "Failed to read general info register: %d\n",
 			ret);
 		return -ENODEV;
 	}
 	++query_addr;
 
 	if (!(buf & BIT(0))) {
-		dev_err(&fn->dev,
-			"Behavior of F12 without register descriptors is undefined.\n");
-		return -ENODEV;
+		rmi_dbg(RMI_DEBUG_FN, &fn->dev,
+			"No register descriptors defined for F12, using fallback\n");
+		hardcoded_desc_quirk = true;
 	}
 
 	f12 = devm_kzalloc(&fn->dev, struct_size(f12, irq_mask, irq_mask_size * 2),
 			   GFP_KERNEL);
 	if (!f12)
 		return -ENOMEM;
 
+	dev_set_drvdata(&fn->dev, f12);
+
 	set_bit(fn->irq_pos, f12->irq_mask);
 	set_bit(fn->irq_pos + 1, f12->irq_mask + irq_mask_size);
 
 	f12->has_dribble = !!(buf & BIT(3));
 
 	if (fn->dev.of_node) {
 		ret = rmi_2d_sensor_of_probe(&fn->dev, &f12->sensor_pdata);
 		if (ret)
 			return ret;
 	} else {
 		f12->sensor_pdata = pdata->sensor_pdata;
 	}
 
+	sensor = &f12->sensor;
+
+	if (hardcoded_desc_quirk) {
+		rmi_f12_set_hardcoded_desc(fn, f12);
+
+		ret = rmi_f12_sensor_init(fn, f12);
+		if (ret)
+			return ret;
+
+		goto skip_register_desc;
+	}
+
 	ret = rmi_f12_read_register_descs(fn, f12, query_addr);
 	if (ret)
 		return ret;
 
-	sensor = &f12->sensor;
-
 	ret = rmi_f12_sensor_init(fn, f12);
 	if (ret)
 		return ret;
 
-	dev_set_drvdata(&fn->dev, f12);
-
 	ret = rmi_f12_read_sensor_tuning(f12);
 	if (ret)
 		return ret;
 
 	/*
 	 * Identify available data registers and calculate their offsets within
 	 * the attention report. For HID devices, only Data1 and Data5 are
 	 * included in the report; other registers may be described but are
@@ -528,16 +579,17 @@ static int rmi_f12_probe(struct rmi_function *fn)
 			f12->data15 = item;
 			f12->data15_offset = data_offset;
 			break;
 		}
 
 		data_offset += item->reg_size;
 	}
 
+skip_register_desc:
 	/* allocate the in-kernel tracking buffers */
 	sensor->tracking_pos = devm_kcalloc(&fn->dev, sensor->nbr_fingers,
 					    sizeof(*sensor->tracking_pos),
 					    GFP_KERNEL);
 	if (!sensor->tracking_pos)
 		return -ENOMEM;
 
 	sensor->tracking_slots = devm_kcalloc(&fn->dev, sensor->nbr_fingers,

-- 
2.53.0

