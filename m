From: Jianjun Lang <jianjun.lang@ntu.edu.sg>
Date: Tue, 03 Nov 2026 15:32:10 +0800
Subject: [PATCH] HID: steelseries: Add MSI Raider A18 HX A7VHG to RGB DMI
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-b4-a7vhg-dmi-v1-1-f57c90da16a9@ntu.edu.sg>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrE3SKhWuIhZVg5H4SYtIxN0Vy
 2/x3gWeHJOHMrrA0cGelzlAxhHYwcw9IbfBkIhESykUNima/Bh6bCdGk1mpVSE6nROEZHXU8fn
 tqvq335uR7PY+4L4f6XM/hXAAAAA=
X-Change-ID: 20261103-b4-a7vhg-dmi-a5c16390f67e
To: Benjamin Tissoires <bentiss@kernel.org>, Jiri Kosina <jikos@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Glushkov <david.glushkov@sntiq.com>, 
 Jianjun Lang <jianjun.lang@ntu.edu.sg>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793691129; l=1684;
 i=jianjun.lang@ntu.edu.sg; s=20261103; h=from:subject:message-id;
 bh=QBV4z5tHTq3HQzaDogtIEEXklWl0ixbFdqcyrPVQXWM=;
 b=LZVn64dFEkLDuKc4LFx+u2RtZi+3Oo+HJFwMuP0N094paiynJNgxJWrTxoqzIQdXfqUULz/xw
 1N+2xAJ1qksBldpfFkiWC7ksc+MRoPt9e35dJtUxS8Gl5MzDGvj3CHI
X-Developer-Key: i=jianjun.lang@ntu.edu.sg; a=ed25519;
 pk=e0Fl3OPgaBi/Tn+OeuP32QQtTZps9FERj4BBuR2nCZU=
X-Endpoint-Received: by B4 Relay for jianjun.lang@ntu.edu.sg/20261103 with auth_id=1389
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MSI Raider A18 HX A7VHG (board MS-182K) uses the same internal
SteelSeries KLC (1038:1122) and ALC (1038:1161) RGB controllers as the
A9WJG, with the same 524-byte feature report layout and the same ALC
LED IDs (0x00-0x02 lightbar segments, 0x03 lid logo).

Add it to the DMI allow-list so the keyboard backlight and lightbar
LED class devices are registered on this model as well.

Tested on MSI Raider A18 HX A7VHG (BIOS E182KAMS.10D). Both devices
bind on interface 0 and create steelseries::kbd_backlight and
steelseries::lightbar. Writing multi_intensity and brightness changes
the keyboard, lightbar and logo colors and brightness as expected.

Signed-off-by: Jianjun Lang <jianjun.lang@ntu.edu.sg>
---
This extends the MSI KLC/ALC RGB support added for the Raider A18 HX
A9WJG to the A7VHG variant, which uses the same controllers and
protocol.
---
 drivers/hid/hid-steelseries.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/hid/hid-steelseries.c b/drivers/hid/hid-steelseries.c
index 7292da031..116d5a01e 100644
--- a/drivers/hid/hid-steelseries.c
+++ b/drivers/hid/hid-steelseries.c
@@ -356,6 +356,13 @@ static const struct dmi_system_id steelseries_msi_rgb_dmi_table[] = {
 			DMI_MATCH(DMI_BOARD_NAME, "MS-182L"),
 		},
 	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "Micro-Star International Co., Ltd."),
+			DMI_MATCH(DMI_PRODUCT_NAME, "Raider A18 HX A7VHG"),
+			DMI_MATCH(DMI_BOARD_NAME, "MS-182K"),
+		},
+	},
 	{ }
 };
 

---
base-commit: 720806515cb6921ab05caaa6f470f7054b56385e
change-id: 20261103-b4-a7vhg-dmi-a5c16390f67e

Best regards,
--  
Jianjun Lang <jianjun.lang@ntu.edu.sg>

