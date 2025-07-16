From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 16 Jul 2025 11:06:55 +0200
Subject: [PATCH v6 05/11] Documentation: uAPI: media: add
 V4L2_CID_FLASH_HW_STROBE_SIGNAL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250716-ov9282-flash-strobe-v6-5-934f12aeff33@linux.dev>
References: <20250716-ov9282-flash-strobe-v6-0-934f12aeff33@linux.dev>
In-Reply-To: <20250716-ov9282-flash-strobe-v6-0-934f12aeff33@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Hans Verkuil <hverkuil@xs4all.nl>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752656846; l=1182;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=lJUA/HTTIB5OPd67y2vtLKCQ0ts0kps9jsdTJGZwJyk=;
 b=fgleXUKtAWZqXdfokkA0eBdArbpobxJ1udxoGb1AqOJYHsBbOpTldfB36V1u4A7tSEODoDGeR
 OxvfJ0g4Z9wCGcPDWTfYitJ/ReFtGYA6NMO3BnyPiGb3R1j8VzgoVDJ
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new hardware strobe signal control to v4l uAPI documentation.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst b/Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst
index 03a58ef94be7c870f55d5a9bb09503995dbfb402..af43e7329cb77cf952b8996cd8c5384eae08c3fc 100644
--- a/Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst
+++ b/Documentation/userspace-api/media/v4l/ext-ctrls-flash.rst
@@ -191,3 +191,9 @@ Flash Control IDs
     Duration the flash should be on when the flash LED is in flash mode
     (V4L2_FLASH_LED_MODE_FLASH). The unit should be microseconds (µs)
     if possible.
+
+``V4L2_CID_FLASH_HW_STROBE_SIGNAL (boolean)``
+    Enable or disable the output of a hardware strobe signal. This is typically
+    set on a sensor that provides a hardware strobe output which is connected
+    to a flash device/LEDs. The flash device should then be configured to use
+    an external strobe source (V4L2_FLASH_STROBE_SOURCE_EXTERNAL).

-- 
2.47.2

