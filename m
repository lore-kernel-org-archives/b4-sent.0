From: Jason Yang <jason98166@gmail.com>
Date: Tue, 11 Aug 2026 15:18:12 +0800
Subject: [PATCH v2] media: ov5640: select the MIPI lane mode from the
 endpoint lane count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-ov5640-1lane-v1-v2-1-65205ae86feb@gmail.com>
X-B4-Tracking: v=1; b=H4sIALPMemoC/3WNzQqDMBCEX0X23JSsP4npqe9RPERddUGTkpTQI
 r57U++FuXwD880OkQJThFuxQ6DEkb3LUF4KGBbrZhI8ZoZSlkq2iMKnRtVS4GodiYSilxNVmmx
 fjy3k1TPQxO/T+OgyLxxfPnzOg4S/9r8rB4U2ypi60QNhdZ83y+t18Bt0x3F8AWjCDCOuAAAA
To: Steve Longerbeam <slongerbeam@gmail.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Hans Verkuil <hverkuil@kernel.org>, 
 Jacopo Mondi <jacopo.mondi@ideasonboard.com>, 
 Kieran Bingham <kieran.bingham@ideasonboard.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786432691; l=3765;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=pSPMWEyRSJt0POuL6M01PgsQ18cplbbeS6z+IFWiviA=;
 b=XqSudxIf42JvhucWbRVvcpjfnBOHaGx+EKPPtp2skWVGq5T1P8j7mmG4k2YEtBnYSRtOidM6L
 RJBzBm+MFs0CyFWIE0C1bNokzYxGzQPHdaETTdQ+octeB7qForU7vC5
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

Take the lane mode from the endpoint instead. The field encodes
the lane count directly - 001 for one lane, 010 for two - per the
current sensor manual (version 2.33). The 2.03 manual documented
000/001 for one/two lanes; OmniVision corrected the table in
version 2.1, which is why the long-standing comment here found 001
unusable for two lanes and validated 010 instead.

The power-up path also programs a two data lane mode, but that
value is overwritten when streaming starts, so it is left alone.

Tested with a single data lane module on an i.MX8MP board
(imx-mipi-csis receiver), where the unpatched value produces no
frames at all, and on an RK3588 board.

Fixes: 19a81c1426c1 ("[media] add Omnivision OV5640 sensor driver")
Cc: stable@vger.kernel.org
Signed-off-by: Jason Yang <jason98166@gmail.com>
Assisted-by: Claude:claude-opus-5
---
Changes in v2:
- Compute the register value from the lane count in the single
  write instead of branching on it (Sakari Ailus), with the count
  in a local variable to stay within 80 columns; the programmed
  values are unchanged, 0x25 for one lane and 0x45 for two.
- Request a normal stable backport rather than opting out of
  AUTOSEL (Sakari Ailus).
- Drop the quotes around the function name in the reference from
  ov5640_set_power_mipi() (Sakari Ailus).
- Link to v1: https://lore.kernel.org/r/20260811-ov5640-1lane-v1-v1-1-79699457ce13@gmail.com
---
 drivers/media/i2c/ov5640.c | 18 ++++++------------
 1 file changed, 6 insertions(+), 12 deletions(-)

diff --git a/drivers/media/i2c/ov5640.c b/drivers/media/i2c/ov5640.c
index 8deb5f5501fa..e261461cc2f2 100644
--- a/drivers/media/i2c/ov5640.c
+++ b/drivers/media/i2c/ov5640.c
@@ -1826,27 +1826,21 @@ static int ov5640_set_stream_dvp(struct ov5640_dev *sensor, bool on)
 
 static int ov5640_set_stream_mipi(struct ov5640_dev *sensor, bool on)
 {
+	u32 num_lanes = sensor->ep.bus.mipi_csi2.num_data_lanes;
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
-	 * [7:5] = 010	: 2 data lanes mode
+	 * [7:5]	: data lane count, 001 for one lane and 010 for two,
+	 *		  per version 2.33 of the sensor manual
 	 * [4] = 0	: Power up MIPI HS Tx
 	 * [3] = 0	: Power up MIPI LS Rx
 	 * [2] = 1/0	: MIPI interface enable/disable
 	 * [1:0] = 01/00: FIXME: 'debug'
 	 */
 	ret = ov5640_write_reg(sensor, OV5640_REG_IO_MIPI_CTRL00,
-			       on ? 0x45 : 0x40);
+			       on ? 0x05 | num_lanes << 5 : 0x40);
 	if (ret)
 		return ret;
 
@@ -2535,8 +2529,8 @@ static int ov5640_set_power_mipi(struct ov5640_dev *sensor, bool on)
 	 * Power up MIPI HS Tx and LS Rx; 2 data lanes mode
 	 *
 	 * 0x300e = 0x40
-	 * [7:5] = 010	: 2 data lanes mode (see FIXME note in
-	 *		  "ov5640_set_stream_mipi()")
+	 * [7:5] = 010	: 2 data lanes mode (see the note in
+	 *		  ov5640_set_stream_mipi())
 	 * [4] = 0	: Power up MIPI HS Tx
 	 * [3] = 0	: Power up MIPI LS Rx
 	 * [2] = 1	: MIPI interface enabled

---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260811-ov5640-1lane-v1-b0fe37eab4d8

Best regards,
-- 
Jason Yang <jason98166@gmail.com>

