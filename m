From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 09 Dec 2025 23:44:37 +0100
Subject: [PATCH v10 2/8] media: v4l: ctrls: add a control for enabling
 strobe output
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251209-ov9282-flash-strobe-v10-2-0117cab82e2d@linux.dev>
References: <20251209-ov9282-flash-strobe-v10-0-0117cab82e2d@linux.dev>
In-Reply-To: <20251209-ov9282-flash-strobe-v10-0-0117cab82e2d@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-leds@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil@kernel.org>
X-Mailer: b4 0.15-dev-a3fc8
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765320290; l=1947;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=NcaeZW4e+lsXcDe5hqIbtTdEyfKMzNjpGnhp1vovOxM=;
 b=5rJ+2YO21XNdLRU2oLJ9WRbWJ6FJ0jiE2cSfJwKQEtRLv56slooLnQ1Mu6dBbcxvTDyHShU47
 i902FFZWDEeCwPggkkR1sFZkQBoSXeOoQ01G29CnP81hoIDgK+WqJ6w
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a control V4L2_CID_FLASH_STROBE_OE to en- or disable the
strobe output of v4l2 devices (most likely sensors).

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/v4l2-core/v4l2-ctrls-defs.c | 2 ++
 include/uapi/linux/v4l2-controls.h        | 1 +
 2 files changed, 3 insertions(+)

diff --git a/drivers/media/v4l2-core/v4l2-ctrls-defs.c b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
index 4848423205ff7..765aeeec84fe5 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-defs.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
@@ -1136,6 +1136,7 @@ const char *v4l2_ctrl_get_name(u32 id)
 	case V4L2_CID_FLASH_CHARGE:		return "Charge";
 	case V4L2_CID_FLASH_READY:		return "Ready to Strobe";
 	case V4L2_CID_FLASH_DURATION:		return "Strobe Duration";
+	case V4L2_CID_FLASH_STROBE_OE:		return "Strobe Output Enable";
 
 	/* JPEG encoder controls */
 	/* Keep the order of the 'case's the same as in v4l2-controls.h! */
@@ -1282,6 +1283,7 @@ void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type,
 	case V4L2_CID_FLASH_STROBE_STATUS:
 	case V4L2_CID_FLASH_CHARGE:
 	case V4L2_CID_FLASH_READY:
+	case V4L2_CID_FLASH_STROBE_OE:
 	case V4L2_CID_MPEG_VIDEO_DECODER_MPEG4_DEBLOCK_FILTER:
 	case V4L2_CID_MPEG_VIDEO_DECODER_SLICE_INTERFACE:
 	case V4L2_CID_MPEG_VIDEO_DEC_DISPLAY_DELAY_ENABLE:
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index 9830833b48a52..32ba3b5fb1dd5 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1187,6 +1187,7 @@ enum v4l2_flash_strobe_source {
 #define V4L2_CID_FLASH_CHARGE			(V4L2_CID_FLASH_CLASS_BASE + 11)
 #define V4L2_CID_FLASH_READY			(V4L2_CID_FLASH_CLASS_BASE + 12)
 #define V4L2_CID_FLASH_DURATION			(V4L2_CID_FLASH_CLASS_BASE + 13)
+#define V4L2_CID_FLASH_STROBE_OE		(V4L2_CID_FLASH_CLASS_BASE + 14)
 
 
 /* JPEG-class control IDs */

-- 
2.47.3

