From: Jason Yang <jason98166@gmail.com>
Date: Tue, 11 Aug 2026 12:40:13 +0800
Subject: [PATCH] media: ov5640: select the MIPI lane mode from the endpoint
 lane count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-ov5640-1lane-v1-v1-1-79699457ce13@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKynemoC/x3MTQqAIBBA4avIrBtw+rHoKtHCaqyB0FCQILp70
 vJbvPdA4iicYFQPRM6SJPgCqhSsh/U7o2zFUOva6IEIQ+5Mq5FO6xkz4aIdNz3bpd0GKNUV2cn
 9H6f5fT+GuxsRYQAAAA==
To: Steve Longerbeam <slongerbeam@gmail.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Hans Verkuil <hverkuil@kernel.org>, 
 Jacopo Mondi <jacopo.mondi@ideasonboard.com>, 
 Kieran Bingham <kieran.bingham@ideasonboard.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable+noautosel@kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786423213; l=3857;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=JLDHPSBzrmch0mGpVQ30kfImnbkVknIlLZhN6P+MA10=;
 b=8luqWGa83kBbS3u+hSP+wCiAxj72h1IH0Wlkkjig1Hf53dXV5FookHIDpx0DgQ167OwmF33ob
 rtY73D25TDhAbn2Zc308tOYh7ft1OaKcsuffh1yiqEdwiKALUNiIuKV
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ov5640_set_stream_mipi() always programs IO_MIPI_CTRL00 with 0x45,
which selects the two data lane mode: the number of data lanes
described in the devicetree endpoint only feeds the sensor's clock
tree computations, so a module wired with one data lane starts
streaming in two lane mode and the receiver never assembles a
frame.

Select the lane mode from the endpoint instead. The one lane
encoding is [7:5] = 001 per the current sensor manual (version
2.33). The 2.03 manual documented 000/001 for one/two lanes;
OmniVision corrected the table in version 2.1, which is why the
long-standing comment here found 001 unusable for two lanes and
validated 010 instead.

The power-up path also programs a two data lane mode, but that
value is overwritten when streaming starts, so it is left alone.

Tested with a single data lane module on an i.MX8MP board
(imx-mipi-csis receiver), where the unpatched value produces no
frames at all, and on an RK3588 board.

Fixes: 19a81c1426c1 ("[media] add Omnivision OV5640 sensor driver")
Cc: stable+noautosel@kernel.org # no in-tree 1-lane users
Signed-off-by: Jason Yang <jason98166@gmail.com>
Assisted-by: Claude:claude-opus-5
---
The three [7:5] encodings were exercised individually on the
i.MX8MP board (v7.2-rc4, data-lanes = <1>) by patching the value
and capturing with v4l2-ctl:

  001 (this patch): 30/30 frames, zero PHY error events in
      steady state (3 x 300 frames)
  000 (2.03 manual / NXP KB): same result
  010 (unpatched two lane mode): no frames; the receiver logs
      only start-of-transmission errors and never assembles one

The RK3588 run used the same module and devicetree (data-lanes =
<1>) through a Rockchip CSI-2 receiver, streaming to natural EOS
with a clean kernel log.

Happy to run additional tests on either platform if that would
help.
---
 drivers/media/i2c/ov5640.c | 22 +++++++++++-----------
 1 file changed, 11 insertions(+), 11 deletions(-)

diff --git a/drivers/media/i2c/ov5640.c b/drivers/media/i2c/ov5640.c
index 8deb5f5501fa..ef731709bdc8 100644
--- a/drivers/media/i2c/ov5640.c
+++ b/drivers/media/i2c/ov5640.c
@@ -1826,27 +1826,27 @@ static int ov5640_set_stream_dvp(struct ov5640_dev *sensor, bool on)
 
 static int ov5640_set_stream_mipi(struct ov5640_dev *sensor, bool on)
 {
+	u8 val;
 	int ret;
 
 	/*
 	 * Enable/disable the MIPI interface
 	 *
-	 * 0x300e = on ? 0x45 : 0x40
-	 *
-	 * FIXME: the sensor manual (version 2.03) reports
-	 * [7:5] = 000  : 1 data lane mode
-	 * [7:5] = 001  : 2 data lanes mode
-	 * But this settings do not work, while the following ones
-	 * have been validated for 2 data lanes mode.
-	 *
+	 * [7:5] = 001	: 1 data lane mode
 	 * [7:5] = 010	: 2 data lanes mode
+	 *		  Encodings per version 2.33 of the sensor manual.
 	 * [4] = 0	: Power up MIPI HS Tx
 	 * [3] = 0	: Power up MIPI LS Rx
 	 * [2] = 1/0	: MIPI interface enable/disable
 	 * [1:0] = 01/00: FIXME: 'debug'
 	 */
-	ret = ov5640_write_reg(sensor, OV5640_REG_IO_MIPI_CTRL00,
-			       on ? 0x45 : 0x40);
+	if (on)
+		val = sensor->ep.bus.mipi_csi2.num_data_lanes == 1 ?
+		      0x25 : 0x45;
+	else
+		val = 0x40;
+
+	ret = ov5640_write_reg(sensor, OV5640_REG_IO_MIPI_CTRL00, val);
 	if (ret)
 		return ret;
 
@@ -2535,7 +2535,7 @@ static int ov5640_set_power_mipi(struct ov5640_dev *sensor, bool on)
 	 * Power up MIPI HS Tx and LS Rx; 2 data lanes mode
 	 *
 	 * 0x300e = 0x40
-	 * [7:5] = 010	: 2 data lanes mode (see FIXME note in
+	 * [7:5] = 010	: 2 data lanes mode (see the note in
 	 *		  "ov5640_set_stream_mipi()")
 	 * [4] = 0	: Power up MIPI HS Tx
 	 * [3] = 0	: Power up MIPI LS Rx

---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260811-ov5640-1lane-v1-b0fe37eab4d8

Best regards,
-- 
Jason Yang <jason98166@gmail.com>

