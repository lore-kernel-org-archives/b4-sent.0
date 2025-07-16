From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 16 Jul 2025 11:06:54 +0200
Subject: [PATCH v6 04/11] media: v4l: ctrls: add a control for enabling hw
 strobe signal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250716-ov9282-flash-strobe-v6-4-934f12aeff33@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752656846; l=2084;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=+3yfsgI+RLqnieyZVNdemukQE4ylJowi0on/ywo/VYE=;
 b=9JLb25GYJCpdRkX12l+TSBfT4FDrm9DsPLtQqGsFQjGUtvDvf0cWjAkaFN2zsAit1TcoQYgID
 wSnEbm5q+cBDeKgTGp2H2pYpSyJUKUFx+hwiCZr8ZpPcx65gjhqxo0Y
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a control V4L2_CID_FLASH_HW_STROBE_SIGNAL to en- or disable the
strobe output of v4l2 devices (most likely sensors).

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/v4l2-core/v4l2-ctrls-defs.c | 2 ++
 include/uapi/linux/v4l2-controls.h        | 1 +
 2 files changed, 3 insertions(+)

diff --git a/drivers/media/v4l2-core/v4l2-ctrls-defs.c b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
index f9ed7273a9f3eafe01c31b638e1c8d9fcf5424af..e13214ca362b9bdd2302118963008b04fcad8d4c 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-defs.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
@@ -1136,6 +1136,7 @@ const char *v4l2_ctrl_get_name(u32 id)
 	case V4L2_CID_FLASH_CHARGE:		return "Charge";
 	case V4L2_CID_FLASH_READY:		return "Ready to Strobe";
 	case V4L2_CID_FLASH_DURATION:		return "Strobe Duration";
+	case V4L2_CID_FLASH_HW_STROBE_SIGNAL:	return "Hardware Strobe Signal";
 
 	/* JPEG encoder controls */
 	/* Keep the order of the 'case's the same as in v4l2-controls.h! */
@@ -1282,6 +1283,7 @@ void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type,
 	case V4L2_CID_FLASH_STROBE_STATUS:
 	case V4L2_CID_FLASH_CHARGE:
 	case V4L2_CID_FLASH_READY:
+	case V4L2_CID_FLASH_HW_STROBE_SIGNAL:
 	case V4L2_CID_MPEG_VIDEO_DECODER_MPEG4_DEBLOCK_FILTER:
 	case V4L2_CID_MPEG_VIDEO_DECODER_SLICE_INTERFACE:
 	case V4L2_CID_MPEG_VIDEO_DEC_DISPLAY_DELAY_ENABLE:
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index 72c6bd26e2dfa23a0224e745e5cd07c9fca0c8b5..ad693870bef951df168f43d50c3e9d4255deed91 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1181,6 +1181,7 @@ enum v4l2_flash_strobe_source {
 #define V4L2_CID_FLASH_CHARGE			(V4L2_CID_FLASH_CLASS_BASE + 11)
 #define V4L2_CID_FLASH_READY			(V4L2_CID_FLASH_CLASS_BASE + 12)
 #define V4L2_CID_FLASH_DURATION			(V4L2_CID_FLASH_CLASS_BASE + 13)
+#define V4L2_CID_FLASH_HW_STROBE_SIGNAL		(V4L2_CID_FLASH_CLASS_BASE + 14)
 
 
 /* JPEG-class control IDs */

-- 
2.47.2

