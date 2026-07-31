From: David Heidelberg <david@ixit.cz>
Date: Fri, 31 Jul 2026 20:13:42 +0200
Subject: [PATCH 2/2] Input: rmi4 - fallback to platform data for x/y-mm in
 F12
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-respect-x-y-mm-v1-2-3e85a4bec745@ixit.cz>
References: <20260731-respect-x-y-mm-v1-0-3e85a4bec745@ixit.cz>
In-Reply-To: <20260731-respect-x-y-mm-v1-0-3e85a4bec745@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1349; i=david@ixit.cz;
 h=from:subject:message-id; bh=FHkjKLPSxXK4iS4yiWmJ/MFTnc2JaT4CfcKwjt/EYzk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbOXWzlXUJRaASEN9halIiggO1xueDsO71jPpA
 SVyrkG0wXKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCamzl1gAKCRBgAj/E00kg
 cv5OEACEXcIpioN0gy0GimILBfxT0MBmMM1g67cEX+Mp6G+zGgPDV33FddT1ZiQe5xJcDiK7ZN0
 dXgxHIZ+e6BVPI2708brv8GvDnNCUNQock4bvxQ9K3gmU7p8bgLO2C8qI0JaDsndWXUoZx3uI3R
 3mGhiP6Ijva99By/1MQzyRDkgym1yyi2lzmqvfH4/eAT/USZMBCOGXUZlupeoNbZq/N36rz2SPg
 x2xKpSD3pfKM3BEaTfmcBEv++kaj8iNPqGFsPk+JwIFoTZAQR88CRZpbmOeyc9yGgPTEiOX7Ikq
 a1qHqDeMDsRUUFfAmk21QId/jpyuYLUlg6UrLrd9bSuyztfNNNDE5XwlRaj7emLATe75+l0zg7h
 KDnEDBivGv0QvDEgRoUewiDQ8ecSJhRHCvWv+WL288joZF+mqLR+mn6jdUD54N3gk/S11F80EzS
 AETXWwZ8noHXnhQ0Hu/exB3+CeuI7yz4ja5pextQFm9k+EGa7b7bc4+4xG0CYolDXqowlQGTcsr
 W4Ony28qAQlWl2epBxfN5t1FFnKrNtzmaaz/kVFcGdbpmVuST5cKOCwGUadJpeLhofzZth8FWig
 G8/XFTTiYMWcCHa0piHA7ZJRyBUpVu5uDFLwcWbou4L4MKUcGn/nFG4vyS7vhlPDdIyVPl3NV9V
 kxTDhhSFC1zr3fQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When detection for touchscreen-x-mm / y-mm returns 0, fallback to the
platform data, so we get meaningful values.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_f12.c | 15 +++++++++++++--
 1 file changed, 13 insertions(+), 2 deletions(-)

diff --git a/drivers/input/rmi4/rmi_f12.c b/drivers/input/rmi4/rmi_f12.c
index 88797556e738c..6f2e98c3a3499 100644
--- a/drivers/input/rmi4/rmi_f12.c
+++ b/drivers/input/rmi4/rmi_f12.c
@@ -194,18 +194,29 @@ static int rmi_f12_read_sensor_tuning(struct f12_data *f12)
 			 "platform data x_mm (%d) != detected x_mm: (%d)\n",
 			 sensor->x_mm, x_mm);
 
 	if (sensor->y_mm && sensor->y_mm != y_mm)
 		dev_warn(&fn->dev,
 			 "platform data y_mm (%d) != detected y_mm: (%d)\n",
 			 sensor->y_mm, y_mm);
 
-	sensor->x_mm = x_mm;
-	sensor->y_mm = y_mm;
+	if (x_mm)
+		sensor->x_mm = x_mm;
+	else
+		dev_warn(&fn->dev,
+			 "x_mm detection returned 0, keeping %d\n",
+			 sensor->x_mm);
+
+	if (y_mm)
+		sensor->y_mm = y_mm;
+	else
+		dev_warn(&fn->dev,
+			 "y_mm detection returned 0, keeping %d\n",
+			 sensor->y_mm);
 
 	rmi_dbg(RMI_DEBUG_FN, &fn->dev, "%s: x_mm: %d y_mm: %d\n", __func__,
 		sensor->x_mm, sensor->y_mm);
 
 	return 0;
 }
 
 static void rmi_f12_process_objects(struct f12_data *f12, u8 *data1, u32 size)

-- 
2.53.0

