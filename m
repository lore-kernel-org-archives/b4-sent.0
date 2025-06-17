From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 17 Jun 2025 09:31:38 +0200
Subject: [PATCH v5 04/10] Documentation: uAPI: media: add
 V4L2_CID_FLASH_DURATION
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250617-ov9282-flash-strobe-v5-4-9762da74d065@linux.dev>
References: <20250617-ov9282-flash-strobe-v5-0-9762da74d065@linux.dev>
In-Reply-To: <20250617-ov9282-flash-strobe-v5-0-9762da74d065@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Hans Verkuil <hverkuil@xs4all.nl>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750145501; l=1038;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=16N0ehkJWytFD5jx5wDbSTZhtNf5Qf6vx2SOhlkAC1Y=;
 b=DVSTCYqNJufAJ3eLL86OJ8J58+xjr+B8yJkFVS4dnrxT53dv3Po4+gGFv81Z2jtJs1PWzSllW
 aOcTeZmAgFCAt8ZqtbtsOFUemwNxb+Wi1pxyh4nONJ4MIdO/ea56VsE
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the new strobe_duration control to v4l uAPI documentation.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst b/Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst
index d22c5efb806a183a3ad67ec3e6550b002a51659a..03a58ef94be7c870f55d5a9bb09503995dbfb402 100644
--- a/Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst
+++ b/Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst
@@ -186,3 +186,8 @@ Flash Control IDs
     charged before strobing. LED flashes often require a cooldown period
     after strobe during which another strobe will not be possible. This
     is a read-only control.
+
+``V4L2_CID_FLASH_DURATION (integer)``
+    Duration the flash should be on when the flash LED is in flash mode
+    (V4L2_FLASH_LED_MODE_FLASH). The unit should be microseconds (µs)
+    if possible.

-- 
2.47.2

