From: Shashikirana H K <shashikiranah@chromium.org>
Date: Tue, 06 Oct 2026 15:06:59 +0000
Subject: [PATCH] HID: vivaldi: Validate Report ID and length in feature
 mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-upstream-vivaldi-fix-v1-1-bbc9a7f14ea6@chromium.org>
X-B4-Tracking: v=1; b=H4sIAJIOxWoC/x2MWwqAIBAAryL73YIJSXaV6MN0q4UeoiVBdPekz
 xmYeSBRZErQiQciZU587AXqSoBb7D4Tsi8MSipdS6nxCumMZDfMnO3qGSe+0TRyVMaZVrUaSho
 iFf1v++F9P2ZpSF9mAAAA
X-Change-ID: 20261006-upstream-vivaldi-fix-950b29c98286
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Stephen Boyd <swboyd@chromium.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tzung-Bi Shih <tzungbi@chromium.org>, Sean O'Brien <seobrien@chromium.org>, 
 Shashikirana H K <shashikiranah@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791299229; l=2360;
 i=shashikiranah@chromium.org; s=20261006; h=from:subject:message-id;
 bh=uAkI2tjfGATd6F6F8iPXHLDEZi+ZRl+aVUmYMofx0kI=;
 b=ueu7dpcwaxS7DUKnNMIqB9NbKhf3V7YFPhuMO2Cr41iJS0zivr3GaHpR8KorQ6XDKYpMI6Rum
 HpvsCMrqL7IB3Jh0y7GnPTGMMQ64vgnty9Y8O4sbDBvqhzUlNvS2c3t
X-Developer-Key: i=shashikiranah@chromium.org; a=ed25519;
 pk=bCw+8sjBcORxp4WEsvVPTz+Jb/+irkV4RK/8uR5xsYI=
X-Endpoint-Received: by B4 Relay for shashikiranah@chromium.org/20261006 with auth_id=1124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vivaldi_feature_mapping() currently passes the descriptor-declared
report_len as the received data size to hid_report_raw_event() instead
of the actual number of bytes returned by hid_hw_raw_request(). It also
does not verify that the returned Report ID matches the requested
report->id, or handle a zero-byte return before decrementing the length
for unnumbered reports.

Validate that hid_hw_raw_request() returns at least one byte and that
the returned Report ID matches report->id, and pass the actual received
byte count (ret) to hid_report_raw_event().

Fixes: 33bbe04a15f2 ("HID: google: extract Vivaldi hid feature mapping for use in hid-hammer")
Cc: Tzung-Bi Shih <tzungbi@chromium.org>
Cc: Sean O'Brien <seobrien@chromium.org>
Signed-off-by: Shashikirana H K <shashikiranah@chromium.org>
---
Change-Id: I3cf03bd2457f44c6ed47835f3d603f235f5993de
---
 drivers/hid/hid-vivaldi-common.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/hid/hid-vivaldi-common.c b/drivers/hid/hid-vivaldi-common.c
index b12bb5cc091aa..ea2c661e623d1 100644
--- a/drivers/hid/hid-vivaldi-common.c
+++ b/drivers/hid/hid-vivaldi-common.c
@@ -69,12 +69,18 @@ void vivaldi_feature_mapping(struct hid_device *hdev,
 	ret = hid_hw_raw_request(hdev, report->id, report_data,
 				 report_len, HID_FEATURE_REPORT,
 				 HID_REQ_GET_REPORT);
-	if (ret < 0) {
+	if (ret <= 0) {
 		dev_warn(&hdev->dev, "failed to fetch feature %d\n",
 			 field->report->id);
 		goto out;
 	}
 
+	if (report->id && report_data[0] != report->id) {
+		dev_warn(&hdev->dev, "report ID mismatch: expected %d got %d\n",
+			 report->id, report_data[0]);
+		goto out;
+	}
+
 	if (!report->id) {
 		/*
 		 * Undo the damage from hid_hw_raw_request() for unnumbered
@@ -82,10 +88,11 @@ void vivaldi_feature_mapping(struct hid_device *hdev,
 		 */
 		report_data++;
 		report_len--;
+		ret--;
 	}
 
 	ret = hid_report_raw_event(hdev, HID_FEATURE_REPORT, report_data,
-				   report_len, report_len, 0);
+				   report_len, ret, 0);
 	if (ret) {
 		dev_warn(&hdev->dev, "failed to report feature %d\n",
 			 field->report->id);

---
base-commit: 388b607d107c07aaade04c7f22f344cab6bdccd3
change-id: 20261006-upstream-vivaldi-fix-950b29c98286

Best regards,
-- 
Shashikirana H K <shashikiranah@chromium.org>

