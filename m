From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH 00/10] media: i2c: ov9282: fix control range handling
Date: Mon, 14 Sep 2026 21:20:57 +0200
Message-Id: <20260914-ov9282-fixes-v1-0-f520af59df1b@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABlJqGoC/yXMQQ5AMBCF4avIrDWpkUjrKmJR7WAskA4iEXdXL
 L+8/O8CocgkUGcXRDpYeJkTijwDP7p5IMUhGVBjpa22ajksGlQ9nyQqOGuq4DqPpYGUrJG+IRV
 N+1v2biK/vR9w3w8JUoEBcAAAAA==
X-Change-ID: 20260909-ov9282-fixes-da986dabc238
To: Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Martina Krasteva <martinax.krasteva@intel.com>, 
 "Paul J. Murphy" <paul.j.murphy@intel.com>, 
 Daniele Alessandrelli <daniele.alessandrelli@gmail.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 Gyula Kelemen <gyula.kelemen@advasolutions.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789413683; l=1987;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=3irs+JPodkYv8XStf29IdedO2ZXzXnhbXVoH2x8iVG0=;
 b=iCiYHgrs5MYBiangGDKWdA40tZkWP8x11UnblTud99605Tu+WUF+c+/DLuGrU+SmyV7EM847l
 hrTDBlLkPMwD0VyNKwX7NQ4ABIRCzlaM45KaM7gvQbcn3YL61vufQ4e
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes a set of related issues in the OV9282 control handling
code.

The driver updated exposure- and flash duration-related control ranges
in several places, but some of those updates used an incorrect timebase
or were triggered too late, which could leave the controls clamped
against stale values.

The series:
- checks the return value of exposure range updates,
- introduces various helpers for calculating/converting times,
- refreshes flash-duration limits while the sensor is powered down,
- refreshes dependent ranges on mode changes,
- recomputes flash-duration limits when HBLANK changes,
- removes the no longer needed hblank field of the driver struct,
- harmonizes error printing during probe

This series was tested with an ov9282 sensor on a vision components camera
module attached to an i.MX8MP mainboard.

Any feedback is warmly welcome.

Thanks!

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Richard Leitner (10):
      media: i2c: ov9282: handle error from exposure range update
      media: i2c: ov9282: fix line time and exposure time calculation
      media: i2c: ov9282: fix flash duration to/from microseconds conversion
      media: i2c: ov9282: update flash_duration range even when powered down
      media: i2c: ov9282: add refresh of missing ranges on a mode change
      media: i2c: ov9282: refresh flash_duration range on an HBLANK write
      media: i2c: ov9282: drop redundant vblank field
      media: i2c: ov9282: harmonize dev_err_probe usage
      media: i2c: ov9282: fix flash duration control range
      media: i2c: ov9282: clamp flash_duration default to its maximum

 drivers/media/i2c/ov9282.c | 253 +++++++++++++++++++++++++++++++--------------
 1 file changed, 174 insertions(+), 79 deletions(-)
---
base-commit: fd73f4a6659897191fa0d40695fe370925dd3780
change-id: 20260909-ov9282-fixes-da986dabc238

Best regards,
--  
Richard Leitner <richard.leitner@linux.dev>

