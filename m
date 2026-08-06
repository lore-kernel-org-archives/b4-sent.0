From: David Heidelberg <david@ixit.cz>
Date: Thu, 06 Aug 2026 19:17:46 +0200
Subject: [PATCH v2] Input: rmi4 - Use platform data instead of query, when
 available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-respect-x-y-mm-v2-1-e0681ed3d63c@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBBFf4XM2jGlFCus/A/DAuogY8IjLRKQ9
 N9tce3yJOeeu4Mjy+SgTHawtLDjcQggTwmYrh6ehPwIDFLIi9BZipbcRGbGFTfse2y1qmWhBRW
 NhjCaLLW8HsF79WP3bl5hESvR6NjNo92OxyWN3t/4kqLAjK55rRoyWuU3Xnk+mw9U3vsvXMfTb
 LwAAAA=
X-Change-ID: 20260731-respect-x-y-mm-f74a2970e9b7
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2890; i=david@ixit.cz;
 h=from:subject:message-id; bh=ijmilf0lpUcz+HkhDMLoUaxcl60QoPGzgv/0zCY5VNc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqdMG7Ffq6pa4IVMjy6UeJXqgjYDcNZmEzBLLaP
 6Z/JqSlkdOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCanTBuwAKCRBgAj/E00kg
 cq6TD/9sdGscujEVvbG6xWe4WCFC3Xr9RjpI+AuGMIvhNwB6MSo5O4lxD8DZiZ7Un9qAJT1coXt
 VFXolLPX3BVPOY+Xt/rsUxSyxoSr4ydCOgDRFsKk0VRh6I4YGIeUoGEJjE/vJbKgusoJmaZDZJI
 EmNXne1NwD5Kc9kBQ5+cD1C1r4uoSx2TgWSlgUwb4bABiG6Z0z6Kh5Ks2gIGH54+wYcTrhcuSpz
 T4+LRVEJZqfPuIYawv8Mp+iXkJtCzYSXL7ZOZcbvYNVmpgd+gHVRkHV/v2bA+Do7WM1IImNMhQx
 8GY0qJPHLZJWmPed9FrLyqwFex2u5QQm68trlqkVX94Z8UcbcV+G2eUgZVcx8bNzo1ot4E/V1tw
 U2FIbktuneRTvxJck1S/9zxGA/zrpynZpQOi8g3/1oH2MHb5hyK9l9w/pkG1tBZ0xo3oi3GmLOz
 bzRZn7hYEHsIhqJi856Clv8d1dpevKwVb4fqWd9ZcuWsidBuEs7HQoGMjFBsI5yD63whfzU8yET
 1fILoP1VLOJkcFb6tU1zqDzqrq+Ed/gn3SzXG/fHewJswdDuOqBVok9azijv5sNG0PNrj6JsNRx
 6zvfCZ2zXGLaCvcoFebgQHYKFlDsTANxzz6FA6Ro9RG+FxrFl1V7iK2DavzqWneOqHcvkooofc2
 2qWwkWtXd5USuhQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Platform data may define touchscreen-x-mm and touchscreen-y-mm, but
these were quietly overridden by data provided by sensor.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
This series ensures, that when invalid value is detected or mismatch
between value defined in the device-tree and the read from the
touchscreen is observed, the user is notified and zero is ignored.
---
Changes in v2:
- Reworked to use device-tree values, when available, but still detect
  when both or one is missing. (Dmitry)
- Link to v1: https://patch.msgid.link/20260731-respect-x-y-mm-v1-0-3e85a4bec745@ixit.cz
---
 drivers/input/rmi4/rmi_f12.c | 16 ++++++++++++----
 1 file changed, 12 insertions(+), 4 deletions(-)

diff --git a/drivers/input/rmi4/rmi_f12.c b/drivers/input/rmi4/rmi_f12.c
index 88c28089de993..841884d967a3d 100644
--- a/drivers/input/rmi4/rmi_f12.c
+++ b/drivers/input/rmi4/rmi_f12.c
@@ -150,47 +150,55 @@ static int rmi_f12_read_sensor_tuning(struct f12_data *f12)
 			"%s: Inactive Border xlo:%d xhi:%d ylo:%d yhi:%d\n",
 			__func__,
 			buf[offset], buf[offset + 1],
 			buf[offset + 2], buf[offset + 3]);
 
 		offset += 4;
 	}
 
+	/* When platform data are provided, we're done */
+	if (sensor->x_mm && sensor->y_mm)
+		return 0;
+
 	/*
 	 * Use the Query DPM feature when the resolution query register
 	 * exists.
 	 */
 	if (rmi_get_register_desc_item(&f12->query_reg_desc,
 				       RMI_F12_QUERY_RESOLUTION)) {
 		offset = rmi_register_desc_calc_reg_offset(&f12->query_reg_desc,
 							   RMI_F12_QUERY_RESOLUTION);
 		query_dpm_addr = fn->fd.query_base_addr	+ offset;
 		ret = rmi_read(fn->rmi_dev, query_dpm_addr, buf);
 		if (ret) {
 			dev_err(&fn->dev, "Failed to read DPM value: %d\n", ret);
 			return ret;
 		}
 		dpm_resolution = buf[0];
 
-		sensor->x_mm = sensor->max_x / dpm_resolution;
-		sensor->y_mm = sensor->max_y / dpm_resolution;
+		if (!sensor->x_mm)
+			sensor->x_mm = sensor->max_x / dpm_resolution;
+		if (!sensor->y_mm)
+			sensor->y_mm = sensor->max_y / dpm_resolution;
 	} else {
 		if (rmi_register_desc_has_subpacket(item, 3)) {
 			rx_receivers = buf[offset];
 			tx_receivers = buf[offset + 1];
 			offset += 2;
 		}
 
 		/* Skip over sensor flags */
 		if (rmi_register_desc_has_subpacket(item, 4))
 			offset += 1;
 
-		sensor->x_mm = (pitch_x * rx_receivers) >> 12;
-		sensor->y_mm = (pitch_y * tx_receivers) >> 12;
+		if (!sensor->x_mm)
+			sensor->x_mm = (pitch_x * rx_receivers) >> 12;
+		if (!sensor->y_mm)
+			sensor->y_mm = (pitch_y * tx_receivers) >> 12;
 	}
 
 	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s: x_mm: %d y_mm: %d\n", __func__,
 		sensor->x_mm, sensor->y_mm);
 
 	return 0;
 }
 

---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260731-respect-x-y-mm-f74a2970e9b7

Best regards,
--  
David Heidelberg <david@ixit.cz>

