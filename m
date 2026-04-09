From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 09 Apr 2026 18:16:08 -0500
Subject: [PATCH] Input: edt-ft5x06 - Support label device property for
 input name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-ft5x06-label-v1-1-21e8a9ae9a60@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEwNL3bQS0woDM92cxKTUHF0Lc4uUVINU0zQLk2QloJaCotS0zAqwcdG
 xtbUAztxzQ14AAAA=
X-Change-ID: 20260409-ft5x06-label-878de0e5f84c
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775776568; l=1205;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=KTxgBMVlEg3nom+rhZXznr0aORzvFvN9pOpo7KbEjOA=;
 b=1vVpMCrRkRGnRugfIpLGE0lKz4nHo57TCv6oi7mWcYS3Fxf9eVfmsXdDLaQvDdJ8aDtC82oLx
 fpewtU+DfmEAY5ykrgzg8YussbdTycqfRwUgnrSAS4KpWn9VVFhmKuA
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AYN Thor uses a ft5426 and a ft5452 for each screen respectively and
these currently get the same input name, making them indistinguishable
from userspace. Support setting a label in kernel dt to make these
report uniquely.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/input/touchscreen/edt-ft5x06.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/edt-ft5x06.c b/drivers/input/touchscreen/edt-ft5x06.c
index ba8ff65f7ea671..c36497571b1aa1 100644
--- a/drivers/input/touchscreen/edt-ft5x06.c
+++ b/drivers/input/touchscreen/edt-ft5x06.c
@@ -1285,7 +1285,9 @@ static int edt_ft5x06_ts_probe(struct i2c_client *client)
 		"Model \"%s\", Rev. \"%s\", %dx%d sensors\n",
 		tsdata->name, tsdata->fw_version, tsdata->num_x, tsdata->num_y);
 
-	input->name = tsdata->name;
+	if (device_property_read_string(&client->dev, "label", &input->name))
+		input->name = tsdata->name;
+
 	input->id.bustype = BUS_I2C;
 	input->dev.parent = &client->dev;
 

---
base-commit: 3fa7d958829eb9bc3b469ed07f11de3d2804ef71
change-id: 20260409-ft5x06-label-878de0e5f84c

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

