From: Shashikirana H K <shashikiranah@chromium.org>
Date: Tue, 13 Oct 2026 06:46:32 +0000
Subject: [PATCH v2] HID: vivaldi: Extract feature report value directly in
 vivaldi_feature_mapping()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-upstream-vivaldi-fix-v2-1-ecc20329d24c@chromium.org>
X-B4-Tracking: v=1; b=H4sIAMfTzWoC/4WNQQ6CMBBFr0JmbU3baKWuvIdhUcoAkwglU2g0p
 He3cgGX7yX//R0iMmGEe7UDY6JIYS6gTxX40c0DCuoKg5baKCmN2Ja4MrpJJEru1ZHo6S3sVbb
 aelvr2kCZLoxFH9lnU3ikuAb+HC9J/eyfYFJCibb11t16dUFnHn7kMNE2nQMP0OScv21OMK27A
 AAA
X-Change-ID: 20261006-upstream-vivaldi-fix-950b29c98286
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Stephen Boyd <swboyd@chromium.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tzung-Bi Shih <tzungbi@chromium.org>, Sean O'Brien <seobrien@chromium.org>, 
 Shashikirana H K <shashikiranah@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791873997; l=5158;
 i=shashikiranah@chromium.org; s=20261006; h=from:subject:message-id;
 bh=Uerfha3eGEZ1SCVeNARcy7ol0qFI4FCN37EPZpgAXgY=;
 b=7GWizpMDZQvd9VbIJZdUXTY/VNUOgamzk2eSK5pR65NaySkpWGSCdAx7iABheqzssY3wTRLIj
 D9JANc4VRoxDzVNY28tfy55xuE0KTB/bBwyYSo5eeH3OAT6o8KUPtHU
X-Developer-Key: i=shashikiranah@chromium.org; a=ed25519;
 pk=bCw+8sjBcORxp4WEsvVPTz+Jb/+irkV4RK/8uR5xsYI=
X-Endpoint-Received: by B4 Relay for shashikiranah@chromium.org/20261006 with auth_id=1124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently vivaldi_feature_mapping() passes the raw buffer returned by
hid_hw_raw_request() to hid_report_raw_event() with the descriptor-declared
report_len just to populate field->value[usage->usage_index].

Since vivaldi_feature_mapping() already has the target report, field, and
usage in hand, and nothing else consumes field->value[] for this report,
verify that hid_hw_raw_request() returns the expected report_len, ensure
usage->usage_index is within field->report_count, and extract the value
directly using hid_field_extract(). Also use __free(kfree) to simplify
buffer cleanup.

Suggested-by: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Fixes: 33bbe04a15f2 ("HID: google: extract Vivaldi hid feature mapping for use in hid-hammer")
Cc: Tzung-Bi Shih <tzungbi@chromium.org>
Cc: Sean O'Brien <seobrien@chromium.org>
Signed-off-by: Shashikirana H K <shashikiranah@chromium.org>
---
Changes in v2:
- Drop hid_report_raw_event() call and extract feature value directly via
  hid_field_extract() after verifying ret != report_len, as suggested by
  Dmitry Torokhov.
- Check usage->usage_index >= field->report_count before extracting.
- Use __free(kfree) for automatic buffer cleanup.
- Link to v1: https://lore.kernel.org/r/20261006-upstream-vivaldi-fix-v1-1-bbc9a7f14ea6@chromium.org
---
 drivers/hid/hid-vivaldi-common.c | 72 +++++++++++++++-------------------------
 1 file changed, 26 insertions(+), 46 deletions(-)

diff --git a/drivers/hid/hid-vivaldi-common.c b/drivers/hid/hid-vivaldi-common.c
index b12bb5cc091aa..1359a107e63bd 100644
--- a/drivers/hid/hid-vivaldi-common.c
+++ b/drivers/hid/hid-vivaldi-common.c
@@ -5,11 +5,13 @@
  * Copyright (C) 2022 Google, Inc
  */
 
+#include <linux/cleanup.h>
 #include <linux/export.h>
 #include <linux/hid.h>
 #include <linux/input/vivaldi-fmap.h>
 #include <linux/kernel.h>
 #include <linux/module.h>
+#include <linux/slab.h>
 #include <linux/types.h>
 
 #include "hid-vivaldi-common.h"
@@ -33,13 +35,14 @@ void vivaldi_feature_mapping(struct hid_device *hdev,
 {
 	struct vivaldi_data *data = hid_get_drvdata(hdev);
 	struct hid_report *report = field->report;
-	u8 *report_data, *buf;
-	u32 report_len;
 	unsigned int fn_key;
+	unsigned int offset;
+	u32 report_len;
 	int ret;
 
 	if (field->logical != HID_USAGE_FN_ROW_PHYSMAP ||
-	    (usage->hid & HID_USAGE_PAGE) != HID_UP_ORDINAL)
+	    (usage->hid & HID_USAGE_PAGE) != HID_UP_ORDINAL ||
+	    usage->usage_index >= field->report_count)
 		return;
 
 	fn_key = usage->hid & HID_USAGE;
@@ -49,54 +52,31 @@ void vivaldi_feature_mapping(struct hid_device *hdev,
 	if (fn_key > data->num_function_row_keys)
 		data->num_function_row_keys = fn_key;
 
-	report_data = buf = hid_alloc_report_buf(report, GFP_KERNEL);
-	if (!report_data)
+	u8 *buf __free(kfree) = hid_alloc_report_buf(report, GFP_KERNEL);
+	if (!buf)
 		return;
 
-	report_len = hid_report_len(report);
-	if (!report->id) {
-		/*
-		 * hid_hw_raw_request() will stuff report ID (which will be 0)
-		 * into the first byte of the buffer even for unnumbered
-		 * reports, so we need to account for this to avoid getting
-		 * -EOVERFLOW in return.
-		 * Note that hid_alloc_report_buf() adds 7 bytes to the size
-		 * so we can safely say that we have space for an extra byte.
-		 */
-		report_len++;
-	}
-
-	ret = hid_hw_raw_request(hdev, report->id, report_data,
-				 report_len, HID_FEATURE_REPORT,
-				 HID_REQ_GET_REPORT);
-	if (ret < 0) {
-		dev_warn(&hdev->dev, "failed to fetch feature %d\n",
-			 field->report->id);
-		goto out;
-	}
-
-	if (!report->id) {
-		/*
-		 * Undo the damage from hid_hw_raw_request() for unnumbered
-		 * reports.
-		 */
-		report_data++;
-		report_len--;
-	}
-
-	ret = hid_report_raw_event(hdev, HID_FEATURE_REPORT, report_data,
-				   report_len, report_len, 0);
-	if (ret) {
-		dev_warn(&hdev->dev, "failed to report feature %d\n",
-			 field->report->id);
-		goto out;
+	/*
+	 * hid_hw_raw_request() will stuff report ID (which will be 0)
+	 * into the first byte of the buffer even for unnumbered
+	 * reports, so we need to account for this to avoid getting
+	 * -EOVERFLOW in return.
+	 * Note that hid_alloc_report_buf() adds 7 bytes to the size
+	 * so we can safely say that we have space for an extra byte.
+	 */
+	report_len = hid_report_len(report) + !report->id;
+
+	ret = hid_hw_raw_request(hdev, report->id, buf, report_len,
+				 HID_FEATURE_REPORT, HID_REQ_GET_REPORT);
+	if (ret != report_len) {
+		dev_warn(&hdev->dev, "failed to fetch feature %d: %d\n",
+			 report->id, ret);
+		return;
 	}
 
+	offset = field->report_offset + usage->usage_index * field->report_size;
 	data->function_row_physmap[fn_key - MIN_FN_ROW_KEY] =
-		field->value[usage->usage_index];
-
-out:
-	kfree(buf);
+		hid_field_extract(hdev, buf + 1, offset, field->report_size);
 }
 EXPORT_SYMBOL_GPL(vivaldi_feature_mapping);
 

---
base-commit: 51f2727a01219375781e8912f994701b7c3bb36c
change-id: 20261006-upstream-vivaldi-fix-950b29c98286

Best regards,
-- 
Shashikirana H K <shashikiranah@chromium.org>

