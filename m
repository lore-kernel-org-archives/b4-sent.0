From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 01 Sep 2025 17:05:08 +0200
Subject: [PATCH v7 03/10] media: v4l: ctrls: add a control for enabling hw
 strobe signal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250901-ov9282-flash-strobe-v7-3-d58d5a694afc@linux.dev>
References: <20250901-ov9282-flash-strobe-v7-0-d58d5a694afc@linux.dev>
In-Reply-To: <20250901-ov9282-flash-strobe-v7-0-d58d5a694afc@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-leds@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756739145; l=2084;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=5h7OmJD5PtNvkXILVzg5eDKV/6YNZ11G+Tij3lhOaeE=;
 b=rw1kcybSIDOWGaINS1Hbvsrq6PdolMoPzFOK/dCXzHwfo9SXC7aM+fd8E5if/ZRyJScI3Y1Nv
 SVFYVgPuLElCMDtqp+4YwgRdyG06w5TWSer1cZ+wITgzFYoLoi8W4Al
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
index a5b7c382d77118eb7966385c5b22d5a89bc2b272..2a09815939a6d9abbe2babb3429e2227970275e1 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1187,6 +1187,7 @@ enum v4l2_flash_strobe_source {
 #define V4L2_CID_FLASH_CHARGE			(V4L2_CID_FLASH_CLASS_BASE + 11)
 #define V4L2_CID_FLASH_READY			(V4L2_CID_FLASH_CLASS_BASE + 12)
 #define V4L2_CID_FLASH_DURATION			(V4L2_CID_FLASH_CLASS_BASE + 13)
+#define V4L2_CID_FLASH_HW_STROBE_SIGNAL		(V4L2_CID_FLASH_CLASS_BASE + 14)
 
 
 /* JPEG-class control IDs */

-- 
2.47.2

