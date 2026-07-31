From: David Heidelberg <david@ixit.cz>
Date: Fri, 31 Jul 2026 20:13:41 +0200
Subject: [PATCH 1/2] Input: rmi4 - report difference between platform data
 and detected coord in F12
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-respect-x-y-mm-v1-1-3e85a4bec745@ixit.cz>
References: <20260731-respect-x-y-mm-v1-0-3e85a4bec745@ixit.cz>
In-Reply-To: <20260731-respect-x-y-mm-v1-0-3e85a4bec745@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2648; i=david@ixit.cz;
 h=from:subject:message-id; bh=KcxlaadXI0sDygb4fMMOU6arV2orhy2zzcrNAiR0jQA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbOXWBzQlWNZ4k7e/PuXXPdS4g4A8HHOfc1etk
 AQeKgB0UPeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCamzl1gAKCRBgAj/E00kg
 ct0nEADDU1m0h5E1HySL4fEtbDGO537e4dzP4nDXxN1tR8B6iOdck8Y3p4BClpaMUMZaPlTeJmj
 hlvXT+OR8pHB9xUD3fWppLn/ktYcRRtzotow42fvRQFPzA9HXb/jEVCH87oeFNkscOR1K2joYJN
 ofHgEFktQUHUU06TeLAw3Fmzd1a6/hX8wHqf9Cx7XFmFKrLtHL6XrnncGkG2gCbNSn6dnkP9P9f
 SV3LRt4ReGw0DHAozsAwasya6vKZqBi4ZdK/VFRnRj1vOXifZVyTLdI3W1iIk8k7HYyROIj0eww
 OXZwQMkeeoVmE2ldAxM1wgpvTxfw9IqgyVP57+MNfhN0pCPfKcmW8Rw7mT6LRNQJL+wx7LhiqcR
 fAMkNtUXomJ8kLpuElBT47FDokCG6BIUbcovFsVVEqiFZHecbJi1FFKS7rPTd1fbDjLmwLGTVPs
 VkF/n8uUsjI6oEXLfe04H6bUx0YCwR++5yIouNSlIkK9DESCSaqr6HEhUJe7/F+DNlsJsS53I+N
 DFFO0uAUvkh7r3a+TJINsHiF5hitE6XwtDwEloPUhJgLNVrahDHVeDI0gU1XU43R8VGPpOS7BPn
 hDohvrLEiC1DXPGHrBUHWt/IKt3IpbzrF4IuxeV/UKWu37jCiLyVAMC4OMhroJtDWLFUTAMUNDG
 aS6OQfACqR0oH+Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Platform data may define touchscreen-x-mm and touchscreen-y-mm, but
these are quietly overridden by data provided by sensor.

Warn when detected data doesn't match the device-tree data.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_f12.c | 22 ++++++++++++++++++----
 1 file changed, 18 insertions(+), 4 deletions(-)

diff --git a/drivers/input/rmi4/rmi_f12.c b/drivers/input/rmi4/rmi_f12.c
index 88c28089de993..88797556e738c 100644
--- a/drivers/input/rmi4/rmi_f12.c
+++ b/drivers/input/rmi4/rmi_f12.c
@@ -95,16 +95,17 @@ static int rmi_f12_read_sensor_tuning(struct f12_data *f12)
 {
 	const struct rmi_register_desc_item *item;
 	struct rmi_2d_sensor *sensor = &f12->sensor;
 	struct rmi_function *fn = sensor->fn;
 	struct rmi_device *rmi_dev = fn->rmi_dev;
 	int ret;
 	int offset;
 	u8 buf[15];
+	u8 x_mm, y_mm;
 	int pitch_x = 0;
 	int pitch_y = 0;
 	int rx_receivers = 0;
 	int tx_receivers = 0;
 	u16 query_dpm_addr = 0;
 	int dpm_resolution = 0;
 
 	item = rmi_get_register_desc_item(&f12->control_reg_desc, 8);
@@ -166,33 +167,46 @@ static int rmi_f12_read_sensor_tuning(struct f12_data *f12)
 		query_dpm_addr = fn->fd.query_base_addr	+ offset;
 		ret = rmi_read(fn->rmi_dev, query_dpm_addr, buf);
 		if (ret) {
 			dev_err(&fn->dev, "Failed to read DPM value: %d\n", ret);
 			return ret;
 		}
 		dpm_resolution = buf[0];
 
-		sensor->x_mm = sensor->max_x / dpm_resolution;
-		sensor->y_mm = sensor->max_y / dpm_resolution;
+		x_mm = sensor->max_x / dpm_resolution;
+		y_mm = sensor->max_y / dpm_resolution;
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
+		x_mm = (pitch_x * rx_receivers) >> 12;
+		y_mm = (pitch_y * tx_receivers) >> 12;
 	}
 
+	if (sensor->x_mm && sensor->x_mm != x_mm)
+		dev_warn(&fn->dev,
+			 "platform data x_mm (%d) != detected x_mm: (%d)\n",
+			 sensor->x_mm, x_mm);
+
+	if (sensor->y_mm && sensor->y_mm != y_mm)
+		dev_warn(&fn->dev,
+			 "platform data y_mm (%d) != detected y_mm: (%d)\n",
+			 sensor->y_mm, y_mm);
+
+	sensor->x_mm = x_mm;
+	sensor->y_mm = y_mm;
+
 	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s: x_mm: %d y_mm: %d\n", __func__,
 		sensor->x_mm, sensor->y_mm);
 
 	return 0;
 }
 
 static void rmi_f12_process_objects(struct f12_data *f12, u8 *data1, u32 size)
 {

-- 
2.53.0

