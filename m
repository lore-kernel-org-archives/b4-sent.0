From: Vincent Knecht <vincent.knecht@mailoo.org>
Date: Fri, 09 May 2025 09:33:57 +0200
Subject: [PATCH] media: i2c: ov8858: Add sensor's pixel matrix size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-ov8858-crop-v1-1-403a0993c1de@mailoo.org>
X-B4-Tracking: v=1; b=H4sIAOSvHWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDUwNL3fwyCwtTC93kovwCXctkYwPzpGTLFNMkMyWgjoKi1LTMCrBp0bG
 1tQCmF1LpXQAAAA==
X-Change-ID: 20250509-ov8858-crop-9c307bc9d5b6
To: Jacopo Mondi <jacopo.mondi@ideasonboard.com>, 
 Nicholas Roth <nicholas@rothemail.net>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Vincent Knecht <vincent.knecht@mailoo.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746776042; l=2530;
 i=vincent.knecht@mailoo.org; s=20250414; h=from:subject:message-id;
 bh=Tbtt8BBwWz2mwKkgqDb8gx79AJW3BuKIcJaTjg3kE+c=;
 b=eNvFV248nRzjXE5U9vVLQkc4ETvKQAQ+lcxDcHgc7pl+KP1aeE3eZt6Rl8TDdrK4i6VgyemT+
 mEJWP5lZKqlAIwvaMVlbH+WEUNKeXQMkxzSPqMDaq3Ue89eBfK9iLqg
X-Developer-Key: i=vincent.knecht@mailoo.org; a=ed25519;
 pk=MFCVQkhL3+d3NHDzNPWpyZ4isxJvT+QTqValj5gSkm4=
X-Endpoint-Received: by B4 Relay for vincent.knecht@mailoo.org/20250414 with auth_id=377
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The OV8858 pixel array is composed as:
- vertically: 16 dummy columns, 3264 valid ones and 16 dummy columns for
  a total of 3296 columns
- horizontally: 24 optical black lines, 16 dummy ones, 2448 valid, 16
  dummies and 24 optical black lines for a total of 2528 lines

Set native and active sensor pixel sizes.

Signed-off-by: Vincent Knecht <vincent.knecht@mailoo.org>
---
 drivers/media/i2c/ov8858.c | 37 +++++++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/drivers/media/i2c/ov8858.c b/drivers/media/i2c/ov8858.c
index 95f9ae7948463e95ce0b2cb58195de02ee72c02a..9a86aa46e20b48ef4bae7d70ce485985c1ba886a 100644
--- a/drivers/media/i2c/ov8858.c
+++ b/drivers/media/i2c/ov8858.c
@@ -77,6 +77,14 @@
 
 #define REG_NULL			0xffff
 
+/* OV8858 native and active pixel array size */
+#define OV8858_NATIVE_WIDTH		3296U
+#define OV8858_NATIVE_HEIGHT		2528U
+#define OV8858_PIXEL_ARRAY_LEFT		16U
+#define OV8858_PIXEL_ARRAY_TOP		40U
+#define OV8858_PIXEL_ARRAY_WIDTH	3264U
+#define OV8858_PIXEL_ARRAY_HEIGHT	2448U
+
 static const char * const ov8858_supply_names[] = {
 	"avdd",		/* Analog power */
 	"dovdd",	/* Digital I/O power */
@@ -1492,11 +1500,40 @@ static int ov8858_init_state(struct v4l2_subdev *sd,
 	return 0;
 }
 
+static int ov8858_get_selection(struct v4l2_subdev *sd,
+				struct v4l2_subdev_state *sd_state,
+				struct v4l2_subdev_selection *sel)
+{
+	switch (sel->target) {
+	case V4L2_SEL_TGT_CROP:
+		sel->r = *v4l2_subdev_state_get_crop(sd_state, 0);
+		return 0;
+
+	case V4L2_SEL_TGT_NATIVE_SIZE:
+		sel->r.top = 0;
+		sel->r.left = 0;
+		sel->r.width = OV8858_NATIVE_WIDTH;
+		sel->r.height = OV8858_NATIVE_HEIGHT;
+		return 0;
+
+	case V4L2_SEL_TGT_CROP_DEFAULT:
+	case V4L2_SEL_TGT_CROP_BOUNDS:
+		sel->r.top = OV8858_PIXEL_ARRAY_TOP;
+		sel->r.left = OV8858_PIXEL_ARRAY_LEFT;
+		sel->r.width = OV8858_PIXEL_ARRAY_WIDTH;
+		sel->r.height = OV8858_PIXEL_ARRAY_HEIGHT;
+		return 0;
+	}
+
+	return -EINVAL;
+}
+
 static const struct v4l2_subdev_pad_ops ov8858_pad_ops = {
 	.enum_mbus_code = ov8858_enum_mbus_code,
 	.enum_frame_size = ov8858_enum_frame_sizes,
 	.get_fmt = v4l2_subdev_get_fmt,
 	.set_fmt = ov8858_set_fmt,
+	.get_selection = ov8858_get_selection,
 };
 
 static const struct v4l2_subdev_ops ov8858_subdev_ops = {

---
base-commit: 37ff6e9a2ce321b7932d3987701757fb4d87b0e6
change-id: 20250509-ov8858-crop-9c307bc9d5b6

Best regards,
-- 
Vincent Knecht <vincent.knecht@mailoo.org>

