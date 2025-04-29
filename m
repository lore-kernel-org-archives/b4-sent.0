From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 29 Apr 2025 14:59:06 +0200
Subject: [PATCH v3 1/9] media: v4l: ctrls: add a control for flash/strobe
 duration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250429-ov9282-flash-strobe-v3-1-2105ce179952@linux.dev>
References: <20250429-ov9282-flash-strobe-v3-0-2105ce179952@linux.dev>
In-Reply-To: <20250429-ov9282-flash-strobe-v3-0-2105ce179952@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Hans Verkuil <hverkuil@xs4all.nl>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745931554; l=1793;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=0nzpfTzsTCcWDqac7ZTk2BZgJrXNm8rZpSw6OMimBsU=;
 b=q0HdotQ1a3Lpu50SYXXrSIedy34zGRbVP85oeqT3uX74IjThduRjeyIdqv7WKOAQl3DpQ5spv
 a9RTte8pwtUAH8OaPV3ZJBAk66Dz2jwehtJHkJGzaBMI8/zwriVjhUX
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a control V4L2_CID_FLASH_DURATION to set the duration of a
flash/strobe pulse. This is different to the V4L2_CID_FLASH_TIMEOUT
control, as the timeout defines a limit after which the flash is
"forcefully" turned off again.

On the other hand the new V4L2_CID_FLASH_DURATION is the desired length
of the flash/strobe pulse.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/v4l2-core/v4l2-ctrls-defs.c | 1 +
 include/uapi/linux/v4l2-controls.h        | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/media/v4l2-core/v4l2-ctrls-defs.c b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
index 1ea52011247accc51d0261f56eab1cf13c0624a0..f9ed7273a9f3eafe01c31b638e1c8d9fcf5424af 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-defs.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
@@ -1135,6 +1135,7 @@ const char *v4l2_ctrl_get_name(u32 id)
 	case V4L2_CID_FLASH_FAULT:		return "Faults";
 	case V4L2_CID_FLASH_CHARGE:		return "Charge";
 	case V4L2_CID_FLASH_READY:		return "Ready to Strobe";
+	case V4L2_CID_FLASH_DURATION:		return "Strobe Duration";
 
 	/* JPEG encoder controls */
 	/* Keep the order of the 'case's the same as in v4l2-controls.h! */
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index 72e32814ea83dee5f1202c1249eac7cf3b85a22a..72c6bd26e2dfa23a0224e745e5cd07c9fca0c8b5 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1180,6 +1180,7 @@ enum v4l2_flash_strobe_source {
 
 #define V4L2_CID_FLASH_CHARGE			(V4L2_CID_FLASH_CLASS_BASE + 11)
 #define V4L2_CID_FLASH_READY			(V4L2_CID_FLASH_CLASS_BASE + 12)
+#define V4L2_CID_FLASH_DURATION			(V4L2_CID_FLASH_CLASS_BASE + 13)
 
 
 /* JPEG-class control IDs */

-- 
2.47.2

