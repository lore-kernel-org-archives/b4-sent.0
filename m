From: David Heidelberg <david@ixit.cz>
Date: Tue, 15 Jul 2025 13:49:02 +0200
Subject: [PATCH RESEND v5 3/7] Input: synaptics-rmi4 - f12: use hardcoded
 values for aftermarket touch ICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250715-synaptics-rmi4-v5-3-ca255962c122@ixit.cz>
References: <20250715-synaptics-rmi4-v5-0-ca255962c122@ixit.cz>
In-Reply-To: <20250715-synaptics-rmi4-v5-0-ca255962c122@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Caleb Connolly <caleb.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6241; i=david@ixit.cz;
 h=from:subject:message-id; bh=wWX9Nwa4G4RJUBvdMkhnVjSL2oOd+Af8dSjqvQue9y8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBodkA06fTD/F1ed8dL4rjj2M77/9DJaD6zQ2zVj
 4hVbf71z5KJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaHZANAAKCRBgAj/E00kg
 cqTJD/9xeHnQPoBBD2AC8FW98wSScjx/2jl3hcquCeJZywvF9BKtKxcelbSg1tC3bxNov/DRulj
 bBjdo4FNrE/NL55wFUK3jIahfJchjW1zTlJNuU5wQxpjmjFS0KxqjlRvLwpjNBIHe0B567MZtqN
 J70kHztzdK3jy7wkGQudM5x7e6SvH2McPcbgvAtXyrb/hSGH+tOYypmQHVan9H51voXgxBYSUuM
 inXj5WFMX0MlnDuNEOTCtrWZPUEBvzRC5375YXAdjkjfJf0bfSiAyYAcA1SXXBOPIP5Myl55Ds7
 W/XRDYI4gvPe8dhv1F+x24q2NhKjBFLtHpZF3sPCG0K6YQ2gjDRaJvv+tVe++PocAVHCNceo76o
 ArQzN4VGJkZSxk5gMTm6reZQATU/G1zEQZUUHeCd0VOep9DF/Ht60pOpQGzV2nbtQSrRdlrQKsT
 jLg4LOrqf3PuKnB758J8G6yTCLPtiejIrrCUODuount6pfPDZdhW5WF5PDp7o4ow/mdCwJR2Pb9
 9vgqQgzZC3gRcEeFMxLfI0oJWsr6LaWvYLgn4krRXYcBEATiJRr9H1pibgR5N0rkuGaYEuwys/u
 W6MvSDPX9q70+Jl2hLZtOO0QHhefhu1jGkVUttZzRNQfw3QijIZyc5KKUsxMSFtJgq8nTIT17Wz
 mPZ8KsZVu06XX4w==
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
Signed-off-by: Caleb Connolly <caleb.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_f12.c | 117 +++++++++++++++++++++++++++++++++----------
 1 file changed, 91 insertions(+), 26 deletions(-)

diff --git a/drivers/input/rmi4/rmi_f12.c b/drivers/input/rmi4/rmi_f12.c
index 8246fe77114bbd8b795ba35d5a37ede8727fc7cb..1a103cc5f2235a6eafd7a3f5b89cbfc9e53203d2 100644
--- a/drivers/input/rmi4/rmi_f12.c
+++ b/drivers/input/rmi4/rmi_f12.c
@@ -218,6 +218,41 @@ static void rmi_f12_process_objects(struct f12_data *f12, u8 *data1, int size)
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
 	int retval;
@@ -338,6 +373,40 @@ static int rmi_f12_config(struct rmi_function *fn)
 	return 0;
 }
 
+static int rmi_f12_sensor_init(struct rmi_function *fn, struct f12_data *f12)
+{
+	struct rmi_2d_sensor *sensor = &f12->sensor;
+
+	sensor->fn = fn;
+	f12->data_addr = fn->fd.data_base_addr;
+
+	/* On quirky devices that don't have a data_reg_desc we hardcode the packet
+	 * in rmi_f12_set_hardcoded_desc(). Make sure not to set it to 0 here.
+	 */
+	if (!sensor->pkt_size)
+		sensor->pkt_size = rmi_register_desc_calc_size(&f12->data_reg_desc);
+
+	sensor->axis_align =
+		f12->sensor_pdata.axis_align;
+
+	sensor->x_mm = f12->sensor_pdata.x_mm;
+	sensor->y_mm = f12->sensor_pdata.y_mm;
+	sensor->dribble = f12->sensor_pdata.dribble;
+
+	if (sensor->sensor_type == rmi_sensor_default)
+		sensor->sensor_type =
+			f12->sensor_pdata.sensor_type;
+
+	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s: data packet size: %d\n", __func__,
+		sensor->pkt_size);
+
+	sensor->data_pkt = devm_kzalloc(&fn->dev, sensor->pkt_size, GFP_KERNEL);
+	if (!sensor->data_pkt)
+		return -ENOMEM;
+
+	return 0;
+}
+
 static int rmi_f12_probe(struct rmi_function *fn)
 {
 	struct f12_data *f12;
@@ -351,6 +420,7 @@ static int rmi_f12_probe(struct rmi_function *fn)
 	struct rmi_driver_data *drvdata = dev_get_drvdata(&rmi_dev->dev);
 	u16 data_offset = 0;
 	int mask_size;
+	bool hardcoded_desc_quirk = false;
 
 	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s\n", __func__);
 
@@ -365,9 +435,9 @@ static int rmi_f12_probe(struct rmi_function *fn)
 	++query_addr;
 
 	if (!(buf & BIT(0))) {
-		dev_err(&fn->dev,
-			"Behavior of F12 without register descriptors is undefined.\n");
-		return -ENODEV;
+		rmi_dbg(RMI_DEBUG_FN, &fn->dev,
+			"No register descriptors defined for F12, using fallback\n");
+		hardcoded_desc_quirk = true;
 	}
 
 	f12 = devm_kzalloc(&fn->dev, sizeof(struct f12_data) + mask_size * 2,
@@ -375,6 +445,8 @@ static int rmi_f12_probe(struct rmi_function *fn)
 	if (!f12)
 		return -ENOMEM;
 
+	dev_set_drvdata(&fn->dev, f12);
+
 	f12->abs_mask = (unsigned long *)((char *)f12
 			+ sizeof(struct f12_data));
 	f12->rel_mask = (unsigned long *)((char *)f12
@@ -393,6 +465,18 @@ static int rmi_f12_probe(struct rmi_function *fn)
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
 	ret = rmi_read_register_desc(rmi_dev, query_addr,
 					&f12->query_reg_desc);
 	if (ret) {
@@ -423,29 +507,9 @@ static int rmi_f12_probe(struct rmi_function *fn)
 	}
 	query_addr += 3;
 
-	sensor = &f12->sensor;
-	sensor->fn = fn;
-	f12->data_addr = fn->fd.data_base_addr;
-	sensor->pkt_size = rmi_register_desc_calc_size(&f12->data_reg_desc);
-
-	sensor->axis_align =
-		f12->sensor_pdata.axis_align;
-
-	sensor->x_mm = f12->sensor_pdata.x_mm;
-	sensor->y_mm = f12->sensor_pdata.y_mm;
-	sensor->dribble = f12->sensor_pdata.dribble;
-
-	if (sensor->sensor_type == rmi_sensor_default)
-		sensor->sensor_type =
-			f12->sensor_pdata.sensor_type;
-
-	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s: data packet size: %d\n", __func__,
-		sensor->pkt_size);
-	sensor->data_pkt = devm_kzalloc(&fn->dev, sensor->pkt_size, GFP_KERNEL);
-	if (!sensor->data_pkt)
-		return -ENOMEM;
-
-	dev_set_drvdata(&fn->dev, f12);
+	ret = rmi_f12_sensor_init(fn, f12);
+	if (ret)
+		return ret;
 
 	ret = rmi_f12_read_sensor_tuning(f12);
 	if (ret)
@@ -543,6 +607,7 @@ static int rmi_f12_probe(struct rmi_function *fn)
 		data_offset += item->reg_size;
 	}
 
+skip_register_desc:
 	/* allocate the in-kernel tracking buffers */
 	sensor->tracking_pos = devm_kcalloc(&fn->dev,
 			sensor->nbr_fingers, sizeof(struct input_mt_pos),

-- 
2.50.0

