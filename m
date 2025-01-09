From: "Vasiliy Doylov (NekoCWD)" <nekodevelopper@gmail.com>
Date: Fri, 10 Jan 2025 00:37:50 +0300
Subject: [PATCH v3 4/4] input: cyttsp5: add startup retry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250110-nekocwd-upstreaming-cyttsp5-v3-4-b33659c8effc@gmail.com>
References: <20250110-nekocwd-upstreaming-cyttsp5-v3-0-b33659c8effc@gmail.com>
In-Reply-To: <20250110-nekocwd-upstreaming-cyttsp5-v3-0-b33659c8effc@gmail.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 James Hilliard <james.hilliard1@gmail.com>, 
 "Vasiliy Doylov (NekoCWD)" <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2675;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=X51YJwi8tEku39ZDVrFKacvBYHetK/hiRJthYLceyxE=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNIbHM80Rk/+2NYxW+mLiUXIiv9N2bqGbyaqFmyamf3if
 OWSvS7RHaUsDGJcDLJiiiw2Gz1mi+WHS06a9lQBZg4rE8gQBi5OAZjIxhaG/3lXj65WMjpsay/H
 9c2jaHcbz5SSl+o6f9X7Wvv+X8qqLWH4H/zl3cRHYXWX77PNmpY1zU7knoJLteSsS7O/aNrzHVp
 qzAQA
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some firmware/configuration variants fails to start with first attempt.
Vendors drivers tries to start multiple times.

Co-developed-by: James Hilliard <james.hilliard1@gmail.com>
Signed-off-by: James Hilliard <james.hilliard1@gmail.com>
Signed-off-by: Vasiliy Doylov (NekoCWD) <nekodevelopper@gmail.com>
---
 drivers/input/touchscreen/cyttsp5.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/input/touchscreen/cyttsp5.c b/drivers/input/touchscreen/cyttsp5.c
index 4860ce751c913c605d5f72dad66d1eba9825a900..c8771f44b8e35fcdbf278034f25b0be2bb392869 100644
--- a/drivers/input/touchscreen/cyttsp5.c
+++ b/drivers/input/touchscreen/cyttsp5.c
@@ -29,6 +29,7 @@
 #define CY_PIP_1P7_EMPTY_BUF			0xFF00
 #define CYTTSP5_PREALLOCATED_CMD_BUFFER		32
 #define CY_BITS_PER_BTN				1
+#define CY_CORE_STARTUP_RETRY_COUNT		10
 #define CY_NUM_BTN_EVENT_ID			GENMASK(CY_BITS_PER_BTN - 1, 0)
 
 #define MAX_AREA				255
@@ -824,8 +825,10 @@ static int cyttsp5_fill_all_touch(struct cyttsp5 *ts)
 
 static int cyttsp5_startup(struct cyttsp5 *ts)
 {
+	int retry = CY_CORE_STARTUP_RETRY_COUNT;
 	int error;
 
+reset:
 	error = cyttsp5_deassert_int(ts);
 	if (error) {
 		dev_err(ts->dev, "Error on deassert int r=%d\n", error);
@@ -834,6 +837,8 @@ static int cyttsp5_startup(struct cyttsp5 *ts)
 	error = cyttsp5_get_hid_descriptor(ts, &ts->hid_desc);
 	if (error < 0) {
 		dev_err(ts->dev, "Error on getting HID descriptor r=%d\n", error);
+		if (retry--)
+			goto reset;
 		return error;
 	}
 
@@ -845,17 +850,23 @@ static int cyttsp5_startup(struct cyttsp5 *ts)
 		error = cyttsp5_hid_output_bl_launch_app(ts);
 		if (error < 0) {
 			dev_err(ts->dev, "Error on launch app r=%d\n", error);
+			if (retry--)
+				goto reset;
 			return error;
 		}
 
 		error = cyttsp5_get_hid_descriptor(ts, &ts->hid_desc);
 		if (error < 0) {
 			dev_err(ts->dev, "Error on getting HID descriptor r=%d\n", error);
+			if (retry--)
+				goto reset;
 			return error;
 		}
 
 		if (ts->hid_desc.packet_id == HID_BL_REPORT_ID) {
 			dev_err(ts->dev, "Error on launch app still in bootloader\n");
+			if (retry--)
+				goto reset;
 			return -EPROTO;
 		}
 	}
@@ -863,12 +874,16 @@ static int cyttsp5_startup(struct cyttsp5 *ts)
 	error = cyttsp5_fill_all_touch(ts);
 	if (error < 0) {
 		dev_err(ts->dev, "Error on report descriptor r=%d\n", error);
+		if (retry--)
+			goto reset;
 		return error;
 	}
 
 	error = cyttsp5_hid_output_get_sysinfo(ts);
 	if (error) {
 		dev_err(ts->dev, "Error on getting sysinfo r=%d\n", error);
+		if (retry--)
+			goto reset;
 		return error;
 	}
 

-- 
2.47.1

