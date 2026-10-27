From: Daniel Schaefer <dhs@frame.work>
Date: Tue, 27 Oct 2026 18:58:39 +0800
Subject: [PATCH] iio: light: hid-sensor-als: Don't read past the end of
 short fields
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261027-iio-als-overread-v1-1-e47e2706368b@frame.work>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MSwqAMAwA0atI1gZsxe9VxEWoqQaklRREkN7d4
 vItZl5IrMIJ5uoF5VuSxFBg6grcQWFnlK0YbGN709gBRSLSmTDerMq0oZu4a0dPvfEEJbuUvTz
 /cllz/gAIkYvKYgAAAA==
X-Change-ID: 20261027-iio-als-overread-c9e538fa61fa
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: srinivas pandruvada <srinivas.pandruvada@intel.com>, 
 linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daniel Schaefer <dhs@frame.work>, 
 =?utf-8?q?Sven_Vaink=C3=BCla?= <sven@xn--vainkla-r2a.ee>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793098731; l=1879;
 i=dhs@frame.work; s=20260705; h=from:subject:message-id;
 bh=HbHuBMAJPm4/X1qXGCMYOxlRvxnQ4Q+ym/c/16zMV7Y=;
 b=hNWK6KU9FNsC+SmMsb+DoSpOCyteg/p4oNS7Z6kAHJRdxscCJyuLk7DJM3oE/Xsd/yq3H+sbb
 VNQqTddW9FYDRCIKWlZ+Xut5xDwHppXVKYz0tyVIqs32kOpEi5+06sy
X-Developer-Key: i=dhs@frame.work; a=ed25519;
 pk=O1zF7VDnmz6EZNc7sEiawR+KK650uRg1XteQ8jHwScw=
X-Endpoint-Received: by B4 Relay for dhs@frame.work/20260705 with auth_id=852
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reports are not guaranteed to be 4 bytes.
On color ALS sensors there are fields that can be shorter than 4 bytes:
16-bit illuminance, color temperature and chromaticity x/y.

I don't have such a sensor right now, but I have emulated one in
firmware. With this patch, no garbage data is read from the next report:

  before: 05dc02bc 05dc02bc 190005dc 0ce41900 00000ce4
  after:  000002bc 000002bc 000005dc 00001900 00000ce4

Same fix as commit ad02ca57e44e ("iio: hid-sensor-prox: Add support for
16-bit report size").

Fixes: ed5514c925a0 ("iio: hid-sensors: Added ALS")
Signed-off-by: Daniel Schaefer <dhs@frame.work>
---
Tested on an emulated sensor with 2 byte reports that is correctly recognized
by Windows.

Cc: Sven Vainküla <sven@xn--vainkla-r2a.ee>
---
 drivers/iio/light/hid-sensor-als.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/light/hid-sensor-als.c b/drivers/iio/light/hid-sensor-als.c
index 929343e42d83..00dfc2037c19 100644
--- a/drivers/iio/light/hid-sensor-als.c
+++ b/drivers/iio/light/hid-sensor-als.c
@@ -267,7 +267,21 @@ static int als_capture_sample(struct hid_sensor_hub_device *hsdev,
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct als_state *als_state = iio_priv(indio_dev);
 	int ret = -EINVAL;
-	u32 sample_data = *(u32 *)raw_data;
+	u32 sample_data;
+
+	switch (raw_len) {
+	case 1:
+		sample_data = *(u8 *)raw_data;
+		break;
+	case 2:
+		sample_data = *(u16 *)raw_data;
+		break;
+	default:
+		if (raw_len < sizeof(u32))
+			return -EINVAL;
+		sample_data = *(u32 *)raw_data;
+		break;
+	}
 
 	switch (usage_id) {
 	case HID_USAGE_SENSOR_LIGHT_ILLUM:

---
base-commit: 09f742b49cb2728086d78be2b0b35e4d1d71fc85
change-id: 20261027-iio-als-overread-c9e538fa61fa

Best regards,
-- 
Daniel Schaefer <dhs@frame.work>

