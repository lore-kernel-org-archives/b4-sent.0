From: David Heidelberg <david@ixit.cz>
Date: Fri, 31 Jul 2026 20:40:46 +0200
Subject: [PATCH RESEND] Input: rmi4 - Move sensor initialization into own
 function for F12
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-synaptics-rmi4-fnsplit-v1-1-8175cec2ded1@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3732; i=david@ixit.cz;
 h=from:subject:message-id; bh=QDJN7B9WH2UFwNDJgEJB7okxE7kCxvUO/EcFvb1axfQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbOwupdhinibbJUHqJxPnWc7o1syaAsNMzPDAO
 BQoUuSQNhmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCamzsLgAKCRBgAj/E00kg
 ckjcEACynQ6oR5lfcRPLk52TvNhbYoJWzgSrjvrJzLGeO8OCa/O+kFkI8LKr558BY5owzzTa0e1
 zciknVqgOACyviiERsjyT/RHyx8U58gULB7KqDFW6hc/Pv8jLZ0s/PT1mcEaWF3pYhhyePAtpYG
 ownwmeGAeFbEYYiJ5bDlem4eqdyg9ERcSglXFg4USpSpJSvFuB4WBEybK8nIKoG5kKCePVn/JCQ
 hKZL/YliEEpktWCUy3/asQhYAF67Ccgi8gBzOxxYkrR+BPDri/Fx9kgBmu7E7WqPCpUSqNc2DKI
 iL5JLdvMVtP+9Va9DHzsqmQw+1ct1kvq8+70pV6WKDJpdhI/ahVZlp3c0xWAVJh8Ehtw3W9KcLf
 3ySYtZsmNgCkXEufRlvIfcMVyQHjsIjBF8ARgKO93NCm0BELwMI6AIQbMLUe1PuvZ4pPsEWfSAK
 ypl3ZX2c/Ej/CRTe67Q0/PD14J9eSfPwEjnYKslgNyJ1yYh27c/OKA2gil3d6DDf5JFYoylUfPf
 g29EMNuZDOTV+wry2f96AoChBCtPjucCKJrTg9INR3k6/6nWzD1yjvWZ/Gl8AGbNX3xHITDVy9l
 H5Md3FNem01zLr+ydGa/Ngz7VfPnbNXiwX4nKjrio61GUdyrZsiTRmGvdgxigwW1rOauUbOucry
 0qrcqVysaPDJJ8Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Makes rmi_f12_probe function a bit cleaner and more structured.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_f12.c | 58 ++++++++++++++++++++++++++------------------
 1 file changed, 35 insertions(+), 23 deletions(-)

diff --git a/drivers/input/rmi4/rmi_f12.c b/drivers/input/rmi4/rmi_f12.c
index 88c28089de993..333477bf0663e 100644
--- a/drivers/input/rmi4/rmi_f12.c
+++ b/drivers/input/rmi4/rmi_f12.c
@@ -364,29 +364,60 @@ static int rmi_f12_config(struct rmi_function *fn)
 	ret = rmi_f12_write_control_regs(fn);
 	if (ret)
 		dev_warn(&fn->dev,
 			 "Failed to write F12 control registers: %d\n", ret);
 
 	return 0;
 }
 
+static int rmi_f12_sensor_init(struct rmi_function *fn, struct f12_data *f12)
+{
+	struct rmi_2d_sensor *sensor = &f12->sensor;
+	size_t pkt_size;
+
+	sensor->fn = fn;
+	f12->data_addr = fn->fd.data_base_addr;
+	pkt_size = rmi_register_desc_calc_size(&f12->data_reg_desc);
+	if (pkt_size > SZ_1M) {
+		dev_err(&fn->dev, "Invalid data packet size: %zu\n", pkt_size);
+		return -EINVAL;
+	}
+	sensor->pkt_size = pkt_size;
+
+	sensor->axis_align = f12->sensor_pdata.axis_align;
+
+	sensor->x_mm = f12->sensor_pdata.x_mm;
+	sensor->y_mm = f12->sensor_pdata.y_mm;
+	sensor->dribble = f12->sensor_pdata.dribble;
+
+	if (sensor->sensor_type == rmi_sensor_default)
+		sensor->sensor_type = f12->sensor_pdata.sensor_type;
+
+	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s: data packet size: %u\n", __func__,
+		sensor->pkt_size);
+	sensor->data_pkt = devm_kmalloc(&fn->dev, sensor->pkt_size, GFP_KERNEL);
+	if (!sensor->data_pkt)
+		return -ENOMEM;
+
+	return 0;
+}
+
 static int rmi_f12_probe(struct rmi_function *fn)
 {
 	struct f12_data *f12;
 	int ret;
 	struct rmi_device *rmi_dev = fn->rmi_dev;
 	char buf;
 	u16 query_addr = fn->fd.query_base_addr;
 	const struct rmi_register_desc_item *item;
 	struct rmi_2d_sensor *sensor;
 	struct rmi_device_platform_data *pdata = rmi_get_platform_data(rmi_dev);
 	struct rmi_driver_data *drvdata = dev_get_drvdata(&rmi_dev->dev);
 	size_t data_offset = 0;
-	size_t pkt_size;
 	int irq_mask_size;
 	int i;
 
 	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s\n", __func__);
 
 	irq_mask_size = BITS_TO_LONGS(drvdata->irq_count);
 
 	ret = rmi_read(fn->rmi_dev, query_addr, &buf);
@@ -421,39 +452,20 @@ static int rmi_f12_probe(struct rmi_function *fn)
 		f12->sensor_pdata = pdata->sensor_pdata;
 	}
 
 	ret = rmi_f12_read_register_descs(fn, f12, query_addr);
 	if (ret)
 		return ret;
 
 	sensor = &f12->sensor;
-	sensor->fn = fn;
-	f12->data_addr = fn->fd.data_base_addr;
-	pkt_size = rmi_register_desc_calc_size(&f12->data_reg_desc);
-	if (pkt_size > SZ_1M) {
-		dev_err(&fn->dev, "Invalid data packet size: %zu\n", pkt_size);
-		return -EINVAL;
-	}
-	sensor->pkt_size = pkt_size;
-
-	sensor->axis_align = f12->sensor_pdata.axis_align;
 
-	sensor->x_mm = f12->sensor_pdata.x_mm;
-	sensor->y_mm = f12->sensor_pdata.y_mm;
-	sensor->dribble = f12->sensor_pdata.dribble;
-
-	if (sensor->sensor_type == rmi_sensor_default)
-		sensor->sensor_type = f12->sensor_pdata.sensor_type;
-
-	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s: data packet size: %u\n", __func__,
-		sensor->pkt_size);
-	sensor->data_pkt = devm_kmalloc(&fn->dev, sensor->pkt_size, GFP_KERNEL);
-	if (!sensor->data_pkt)
-		return -ENOMEM;
+	ret = rmi_f12_sensor_init(fn, f12);
+	if (ret)
+		return ret;
 
 	dev_set_drvdata(&fn->dev, f12);
 
 	ret = rmi_f12_read_sensor_tuning(f12);
 	if (ret)
 		return ret;
 
 	/*

---
base-commit: 3d5670d672ae08b8c534b7beed6f57c8b44e7b43
change-id: 20260627-synaptics-rmi4-fnsplit-3698a620b73c

Best regards,
-- 
David Heidelberg <david@ixit.cz>

