From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH 0/4] media: i2c: ov7251: runtime PM, non-continuous MIPI
 clock, and strobe OE
Date: Fri, 27 Nov 2026 21:30:12 +0100
Message-Id: <20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFToCWsC/x3MQQ5AMBBA0avIrE1ihiKuIhbKYDattNJIxN01l
 m/x/wNRgkqEoXggSNKo3mVQWcByzG4X1DUbuOKWiDv0qWNDGK/graBbvLuQ+p4bssbUViCXZ5B
 N7/86Tu/7AZK/S3xlAAAA
X-Change-ID: 20261127-ov7251-strobe-ncont-188241b553be
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>, Todor Tomov <todor.too@gmail.com>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811412; l=1347;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=sh5vcsf0vWaLWJozQbA8jgzmmNs5/qohRCr+09epJjM=;
 b=T8+25KV3fxI+T79n7ZnoVUHu4xSx/l0cyDLOPM+xPdGqpJCTJklmVNhiT5qeV0oy7D6Ggupop
 /PNZ99hWtwkCtnMDdVuYwGZbUTkg8l9qz35TymmITnvpDZpOjLRJbqJ
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds four cleanups and hardware enablement features to the
OmniVision OV7251 sensor driver needed for reliable operation on
Qualcomm SC8180X / Microsoft Surface Pro X:

1. Wait 5-10 ms after global initialization (software reset 0x0103)
   in ov7251_set_power_on().
2. Use pm_runtime_mark_last_busy() and pm_runtime_put_autosuspend()
   in ov7251_s_ctrl() and ov7251_s_stream() to match the autosuspend
   configuration in probe.
3. Support V4L2_MBUS_CSI2_NONCONTINUOUS_CLOCK by setting
   CLOCK_LANE_GATE (BIT(5)) in OV7251_MIPI_CTRL00 (0x4800).
4. Expose V4L2_CID_FLASH_STROBE_OE to control the sensor's hardware
   STROBE output pin for synchronized IR illumination.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Robert Ijtsma (4):
      media: i2c: ov7251: wait for software reset settle in power-on
      media: i2c: ov7251: use pm_runtime_put_autosuspend()
      media: i2c: ov7251: support non-continuous MIPI clock mode
      media: i2c: ov7251: add V4L2_CID_FLASH_STROBE_OE control

 drivers/media/i2c/ov7251.c | 79 +++++++++++++++++++++++++++++++++++++++++++---
 1 file changed, 74 insertions(+), 5 deletions(-)
---
base-commit: 10c156a0a06c0a255cbd13cabad649fd8d604b47
change-id: 20261127-ov7251-strobe-ncont-188241b553be

Best regards,
-- 
Robert Ijtsma <robertijtsma@gmail.com>

