From: Marco Ziliani <rylos78@gmail.com>
Date: Tue, 27 Oct 2026 21:29:46 +0100
Subject: [PATCH 2/3] media: i2c: ov5693: Keep the Bayer order when flipping
 at full resolution
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-ov5693-fixes-v1-2-3c8ab1ae104d@gmail.com>
References: <20261027-ov5693-fixes-v1-0-3c8ab1ae104d@gmail.com>
In-Reply-To: <20261027-ov5693-fixes-v1-0-3c8ab1ae104d@gmail.com>
To: Daniel Scally <dan.scally@ideasonboard.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, Chris Simpson <chris@nilk.net>, 
 Simon Kruse <simon0x+git@proton.me>, "D. Manresa" <dmanresa@gmail.com>, 
 linux-kernel@vger.kernel.org, Marco Ziliani <rylos78@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793132984; l=4327;
 i=rylos78@gmail.com; s=20261027; h=from:subject:message-id;
 bh=bY5qiR9F/Y1aGuZr5TS65OJX6ey1ya1/HNWGJsKosVA=;
 b=9lwlbZoEg/2kfHXqrliosIUbaOzuhB1NR2kWmo6Ce7MfCiDmQ1m70k+0mO1go4vtLCfv+PyS/
 2QMiTEWRBNED7i/9d5+flisg6dpy+SsItVF8qdQ0QvGrzm3Ka9acvjJ
X-Developer-Key: i=rylos78@gmail.com; a=ed25519;
 pk=nXCfiK5yExPZCMp+lfKif3gdXkfjkUK2qk7bDW+ixMo=
X-Endpoint-Received: by B4 Relay for rylos78@gmail.com/20261027 with auth_id=1333
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the full (unbinned) readout each of the horizontal and vertical
flips moves the Bayer phase by one column. With exactly one flip
enabled the CSI-2 receiver gets GBRG instead of the SBGGR10 the driver
reports, which gives a magenta and green image; with both enabled the
two shifts cancel out.

The crop start is only honoured in steps of two pixels, so compensate
by shifting the output window by one column when hflip XOR vflip, and
widen the crop by two columns, within the pixel array, so that the
window still fits. Reprogram the window when either flip changes. The
binned readout is left unchanged.

With this change, raw 2592x1944 frames come out BGGR at all four
hflip/vflip settings on the Surface Pro 5 (IPU3); the same change in
the linux-surface tree gave BGGR at all four settings on a Surface
Pro 7 (IPU4P) and a Surface Pro 9 (IPU6). Without it, the order is only
right with both flips off or both on.

Fixes: 89aef879cb53 ("media: i2c: Add support for ov5693 sensor")
Link: https://github.com/linux-surface/kernel/pull/181
Signed-off-by: Marco Ziliani <rylos78@gmail.com>
---
 drivers/media/i2c/ov5693.c | 56 +++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 48 insertions(+), 8 deletions(-)

diff --git a/drivers/media/i2c/ov5693.c b/drivers/media/i2c/ov5693.c
index 579aa55b7..ca0968498 100644
--- a/drivers/media/i2c/ov5693.c
+++ b/drivers/media/i2c/ov5693.c
@@ -361,6 +361,49 @@ static const u8 ov5693_test_pattern_bits[] = {
 
 /* V4L2 Controls Functions */
 
+/*
+ * In the full (unbinned) readout each flip moves the Bayer phase by one
+ * column, so with exactly one of them enabled the CSI-2 receiver gets GBRG
+ * instead of the SBGGR10 the driver reports; with both enabled the two shifts
+ * cancel out. The crop start is only honoured in steps of two pixels, so
+ * compensate by shifting the output window by one column instead, and widen
+ * the crop so that the window still fits.
+ */
+static bool ov5693_bayer_shift(struct ov5693_device *ov5693)
+{
+	const struct ov5693_mode *mode = &ov5693->mode;
+	bool hflip, vflip;
+
+	if (mode->binning_x || mode->binning_y)
+		return false;
+
+	hflip = ov5693->ctrls.hflip && ov5693->ctrls.hflip->val;
+	vflip = ov5693->ctrls.vflip && ov5693->ctrls.vflip->val;
+
+	return hflip ^ vflip;
+}
+
+static int ov5693_window_x_configure(struct ov5693_device *ov5693)
+{
+	const struct ov5693_mode *mode = &ov5693->mode;
+	bool shift = ov5693_bayer_shift(ov5693);
+	u32 crop_end = mode->crop.left + mode->crop.width;
+	int ret = 0;
+
+	/* Widen the crop for the shifted window, within the pixel array */
+	if (shift)
+		crop_end = min(crop_end + 2,
+			       max_t(u32, crop_end, OV5693_NATIVE_WIDTH - 1));
+
+	/* Offset X */
+	cci_write(ov5693->regmap, OV5693_OFFSET_START_X_REG, shift, &ret);
+
+	/* Crop End X */
+	cci_write(ov5693->regmap, OV5693_CROP_END_X_REG, crop_end, &ret);
+
+	return ret;
+}
+
 static int ov5693_flip_vert_configure(struct ov5693_device *ov5693,
 				      bool enable)
 {
@@ -373,7 +416,7 @@ static int ov5693_flip_vert_configure(struct ov5693_device *ov5693,
 	if (ret)
 		return ret;
 
-	return 0;
+	return ov5693_window_x_configure(ov5693);
 }
 
 static int ov5693_flip_horz_configure(struct ov5693_device *ov5693,
@@ -388,7 +431,7 @@ static int ov5693_flip_horz_configure(struct ov5693_device *ov5693,
 	if (ret)
 		return ret;
 
-	return 0;
+	return ov5693_window_x_configure(ov5693);
 }
 
 static int ov5693_get_exposure(struct ov5693_device *ov5693, s32 *value)
@@ -566,16 +609,13 @@ static int ov5693_mode_configure(struct ov5693_device *ov5693)
 	cci_write(ov5693->regmap, OV5693_CROP_START_X_REG, mode->crop.left,
 		  &ret);
 
-	/* Offset X */
-	cci_write(ov5693->regmap, OV5693_OFFSET_START_X_REG, 0, &ret);
-
 	/* Output Size X */
 	cci_write(ov5693->regmap, OV5693_OUTPUT_SIZE_X_REG, mode->format.width,
 		  &ret);
 
-	/* Crop End X */
-	cci_write(ov5693->regmap, OV5693_CROP_END_X_REG,
-		  mode->crop.left + mode->crop.width, &ret);
+	/* Offset X and Crop End X follow the flips, see ov5693_bayer_shift() */
+	if (!ret)
+		ret = ov5693_window_x_configure(ov5693);
 
 	/* Horizontal Total Size */
 	cci_write(ov5693->regmap, OV5693_TIMING_HTS_REG, OV5693_FIXED_PPL,

-- 
2.56.0

