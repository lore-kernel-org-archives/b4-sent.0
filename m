From: Jason Yang <jason98166@gmail.com>
Date: Tue, 11 Aug 2026 22:06:24 +0800
Subject: [PATCH v5] media: ov5640: select the MIPI lane mode from the
 endpoint lane count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-ov5640-1lane-v1-v5-1-14849a3d3a71@gmail.com>
X-B4-Tracking: v=1; b=H4sIAF8se2oC/4XNTQqDMBAF4KtI1k3JzyRqV71H6SKJEw1YU7SEF
 vHuja6KUITZvAffm5lMOAacyKWYyYgpTCEOOahTQVxnhhZpaHImggnNKs5pTEoDo7w3A9LEqWU
 eZYnGQlORrJ4j+vDeFm/3nLswveL42R4kvrb/t/JxWta6rkGVDrm8tg8T+rOLD7JuJXHgRfZaC
 aYMVtqj3Xt54GX2BqHUaLxiAvYeDjxk78Aw1YDjVopfvyzLF/AcNl1uAQAA
To: Steve Longerbeam <slongerbeam@gmail.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Hans Verkuil <hverkuil@kernel.org>, 
 Jacopo Mondi <jacopo.mondi@ideasonboard.com>, 
 Kieran Bingham <kieran.bingham@ideasonboard.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786457192; l=4903;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=uAAC7TSafNkUxaGVKrMNqcaGlxdJ/qh/FP1j05iJCXk=;
 b=t8E2nqcm3luy3WHm6UwJumed0JU8Aou0OZwWXfLpenfguEYaciyCq1VlEiYGc97lxBGQEaR8R
 SOh5VtLSo46AdHeALmqXLTXu7RT4H7kWvAygV4XMjzajak9JE+mn93q
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

Take the lane mode from the endpoint instead, both when streaming
starts and in the power-up path. The field encodes the lane count
directly - 001 for one lane, 010 for two - per the current sensor
manual (version 2.33). The 2.03 manual documented 000/001 for
one/two lanes; OmniVision corrected the table in version 2.1,
which is why the long-standing comment here found 001 unusable for
two lanes and validated 010 instead.

The power-down path still resets the register to 0x58, which is
the chip's reset default.

Tested with a single data lane module on an i.MX8MP board
(imx-mipi-csis receiver), where the unpatched value produces no
frames at all, and on an RK3588 board.

Fixes: 19a81c1426c1 ("[media] add Omnivision OV5640 sensor driver")
Cc: stable@vger.kernel.org
Signed-off-by: Jason Yang <jason98166@gmail.com>
Assisted-by: Claude:claude-opus-5
---
Changes in v5:
- Program the endpoint lane count in the power-up path as well,
  instead of leaving the hardcoded two-lane value there until
  streaming starts (Hans de Goede); the power-down reset value
  0x58 is the chip default and stays.
- Credit the v4 changes to Hans de Goede - v4 wrongly named
  Hans Verkuil.
- Link to v4: https://lore.kernel.org/r/20260811-ov5640-1lane-v1-v4-1-c4a05d4c1b32@gmail.com

Changes in v4:
- Keep the lane count programmed also while the interface is
  disabled, toggling only the enable bits (Hans Verkuil); with one
  data lane the disable value becomes 0x20 instead of 0x40.
- Link to v3: https://lore.kernel.org/r/20260811-ov5640-1lane-v1-v3-1-ae476eaf5024@gmail.com

Changes in v3:
- Inline the lane count in the write instead of going through a
  local variable (Sakari Ailus).
- Link to v2: https://lore.kernel.org/r/20260811-ov5640-1lane-v1-v2-1-65205ae86feb@gmail.com

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
 drivers/media/i2c/ov5640.c | 25 ++++++++++---------------
 1 file changed, 10 insertions(+), 15 deletions(-)

diff --git a/drivers/media/i2c/ov5640.c b/drivers/media/i2c/ov5640.c
index 8deb5f5501fa..526939041ad0 100644
--- a/drivers/media/i2c/ov5640.c
+++ b/drivers/media/i2c/ov5640.c
@@ -1831,22 +1831,16 @@ static int ov5640_set_stream_mipi(struct ov5640_dev *sensor, bool on)
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
+			       sensor->ep.bus.mipi_csi2.num_data_lanes << 5 |
+			       (on ? 0x05 : 0x0));
 	if (ret)
 		return ret;
 
@@ -2532,16 +2526,17 @@ static int ov5640_set_power_mipi(struct ov5640_dev *sensor, bool on)
 	}
 
 	/*
-	 * Power up MIPI HS Tx and LS Rx; 2 data lanes mode
+	 * Power up MIPI HS Tx and LS Rx
 	 *
-	 * 0x300e = 0x40
-	 * [7:5] = 010	: 2 data lanes mode (see FIXME note in
-	 *		  "ov5640_set_stream_mipi()")
+	 * [7:5]	: data lane count (see the note in
+	 *		  ov5640_set_stream_mipi())
 	 * [4] = 0	: Power up MIPI HS Tx
 	 * [3] = 0	: Power up MIPI LS Rx
 	 * [2] = 1	: MIPI interface enabled
 	 */
-	ret = ov5640_write_reg(sensor, OV5640_REG_IO_MIPI_CTRL00, 0x44);
+	ret = ov5640_write_reg(sensor, OV5640_REG_IO_MIPI_CTRL00,
+			       sensor->ep.bus.mipi_csi2.num_data_lanes << 5 |
+			       0x04);
 	if (ret)
 		return ret;
 

---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260811-ov5640-1lane-v1-b0fe37eab4d8

Best regards,
-- 
Jason Yang <jason98166@gmail.com>

