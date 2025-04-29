From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH v3 0/9] Add strobe/flash duration v4l2 ctrl & use it for
 ov9282
Date: Tue, 29 Apr 2025 14:59:05 +0200
Message-Id: <20250429-ov9282-flash-strobe-v3-0-2105ce179952@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABnNEGgC/33OwWrDMBAE0F8xOneLtJacxKf+R+lh5V3FgmCnk
 iNSgv+9ikNpDqXHGZjH3FSWFCWrvrmpJCXmOE81tC+NGkaajgKRa1ao0elWtzCXA+4RwonyCHl
 JsxegofOs9XBg6VRdnpOEeN3U949HTvJ5qfjyKH/tvtlkRAfe/uBHihNIMAOTJ+cD98WoOzTGv
 Mzpa3tbq7v077FiQIMO7HZkXGc9vZ3idLm+spTNK/hkGPu3gdUwlneEe9Na5GdjXddvNBXpoUM
 BAAA=
X-Change-ID: 20250303-ov9282-flash-strobe-ac6bd00c9de6
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Hans Verkuil <hverkuil@xs4all.nl>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745931554; l=2903;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=2z1C8aiGut4OFg6hwle9DwiM2L+/ljeLGm2qQZiDTEo=;
 b=tOpPmX2FLIW1sYHJ4M1PLeJXlOEXr65fEreCHoAuuLeNdhFf0LdHzwa3d8KlnVGM1HosYgAS+
 mCf8s6WAKNBBwzBfpgMvfACg+NUTlUxSw41nRvA68NwCg5i38pFfvqq
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a new v4l2 controls named "strobe duration" with id
V4L2_CID_FLASH_DURATION. This control enables setting a desired
flash/strobe length/duration in µs.

As a first user of this new control add basic flash/strobe support for
ov9282 sensors using their "hardware strobe output". The duration
calculation is only interpolated from various measurements, as no
documentation was found.

Further flash/strobe-related controls as well as a migration to v4l2-cci
helpers for ov9282 will likely be implemented in future series.

All register addresses/values are based on the OV9281 datasheet v1.53
(january 2019). This series was tested using an ov9281 VisionComponents
camera module.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Changes in v3:
- create separate patch for leds driver changes (thanks Lee)
- Link to v2: https://lore.kernel.org/r/20250314-ov9282-flash-strobe-v2-0-14d7a281342d@linux.dev

Changes in v2:
- remove not needed controls in struct ov9282 (thanks Dave)
- Fix commit message of 3/3 regarding framerate get/set (thanks Dave)
- Add V4L2_CID_FLASH_STROBE_SOURCE impementation to ov9282
- Add new V4L2_CID_FLASH_DURATION control (as suggested by Laurent)
- Use FLASH_DURATION instead of FLASH_TIMEOUT for ov9282
- Link to v1: https://lore.kernel.org/r/20250303-ov9282-flash-strobe-v1-0-0fd57a1564ba@linux.dev

---
Richard Leitner (9):
      media: v4l: ctrls: add a control for flash/strobe duration
      leds: flash: add support for flash/stobe duration
      media: v4l2-flash: add support for flash/strobe duration
      media: v4l2-flash: fix flash_timeout comment
      Documentation: uAPI: media: add V4L2_CID_FLASH_DURATION
      media: i2c: ov9282: add output enable register definitions
      media: i2c: ov9282: add led_mode v4l2 control
      media: i2c: ov9282: add strobe_duration v4l2 control
      media: i2c: ov9282: add strobe_source v4l2 control

 .../userspace-api/media/v4l/ext-ctrls-flash.rst    |  5 ++
 drivers/leds/led-class-flash.c                     | 15 ++++
 drivers/media/i2c/ov9282.c                         | 92 +++++++++++++++++++++-
 drivers/media/v4l2-core/v4l2-ctrls-defs.c          |  1 +
 drivers/media/v4l2-core/v4l2-flash-led-class.c     | 13 +++
 include/linux/led-class-flash.h                    | 18 ++++-
 include/uapi/linux/v4l2-controls.h                 |  1 +
 7 files changed, 141 insertions(+), 4 deletions(-)
---
base-commit: ca91b9500108d4cf083a635c2e11c884d5dd20ea
change-id: 20250303-ov9282-flash-strobe-ac6bd00c9de6
prerequisite-change-id: 20250225-b4-ov9282-gain-ef1cdaba5bfd:v1
prerequisite-patch-id: 86f2582378ff7095ab65ce4bb25a143eb639e840
prerequisite-patch-id: b06eb6ec697aaf0b3155b4b2370f171d0d304ae2
prerequisite-patch-id: b123047d71bfb9b93f743bbdd6893d5a98495801

Best regards,
-- 
Richard Leitner <richard.leitner@linux.dev>

