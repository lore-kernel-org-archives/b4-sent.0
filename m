From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH v9 0/8] Add strobe duration and strobe output enable v4l2
 ctrl
Date: Thu, 20 Nov 2025 18:04:20 +0100
Message-Id: <20251120-ov9282-flash-strobe-v9-0-6c9e3a4301d7@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABRKH2kC/33R207DMAwG4FeZck2m2Dk1u+I9EBdpDizSWCHpo
 qFp707WSRSqjsvfsj9b8oWUkFMoZLe5kBxqKmk4tmCeNsTt7fEt0ORbJshQMs44HarBDmk82LK
 nZcxDH6h1qveMOeODIm3yI4eYzpP68nrPOXyeGj7ei6S3JVA3vL+ncbepagsdzU6QW/M+lXHIX
 9NFFabuf5dXoIyy6KW2IJXo7fMhHU/nrQ918ir+MkCsG9gMEF5b7IAL9EuDz4ZAs27wZiAw6QJ
 oYyQuDTEbkul1QzRDY4/GOOi1M0tDzoaCB4ZshtEKvdXCMyWXhpoNDWrdUDeDiwhoQ4ycLw09G
 4bBuqGb4WXnpVVG2OiWRvdjALAHf+ma0RvwMURwSv757fV6/QbsgeqavwIAAA==
X-Change-ID: 20250303-ov9282-flash-strobe-ac6bd00c9de6
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-leds@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil@kernel.org>
X-Mailer: b4 0.15-dev-a3fc8
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763658268; l=4829;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=gf/2PytGf+/O37DduiJXYf79VDU4tRhpcB0pc74cBcE=;
 b=H8Df9pIn3RD7Y8tRSJmJKAAHG4fPsVKYvuw7weipecm8QIYh63oRo8r2yYjDuKGipEnlWjTr2
 XEEqF1HdONHBN3a0PJnSK5I8N54z9kqNGwANCOGPMGcV55Ta0Ld+S6k
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds two new v4l2 controls:
- V4L2_CID_FLASH_DURATION: "Strobe duration": This control enables
  setting a desired flash/strobe length/duration in µs.
- V4L2_CID_FLASH_STROBE_OE: "Strobe output enable": This
  control enables the hardware strobe output signal of a v4l2 device.

As a first user of these new controls add basic flash/strobe support
for ov9282 sensors using their "hardware strobe output". The duration
calculation is only interpolated from various measurements, as no
documentation was found.

Further flash/strobe-related controls as well as a migration to v4l2-cci
helpers for ov9282 will likely be implemented in future series.

All register addresses/values are based on the OV9281 datasheet v1.53
(january 2019). This series was tested using an ov9281 VisionComponents
camera module.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Changes in v9:
- Avoid needless multiplication/division in ov9282.c (Thanks Sakari)
- Avoid possible u32 overflow in ov9282.c (Thanks Sakari)
- Link to v8: https://patch.msgid.link/20251104-ov9282-flash-strobe-v8-0-b91dfef1c65a@linux.dev

Changes in v8:
- Minor styling changes across the set
- Add missing error handling for ov9282 strobe_frame_span writing
- Rename V4L2_CID_FLASH_HW_STROBE_SIGNAL to V4L2_CID_FLASH_STROBE_OE
- Drop 02/10: FLASH_DURATION handling in v4l2-flash
- Drop 08/10: strobe_source in ov9282
- Link to v7: https://lore.kernel.org/r/20250901-ov9282-flash-strobe-v7-0-d58d5a694afc@linux.dev

Changes in v7:
- Improved v4l2 uAPI documentation (thanks Sakari)
- Link to v6: https://lore.kernel.org/r/20250716-ov9282-flash-strobe-v6-0-934f12aeff33@linux.dev

Changes in v6:
- Fix "Alignment should match open parenthesis" by Media-CI bot in v4l2-flash-led-class.c
- Fix "format string contains non-ascii character (µ)" by Media-CI bot in ov9282.c
- Introduce new V4L2_CID_FLASH_HW_STROBE_SIGNAL control (as suggested by Sakari)
- Implement V4L2_CID_FLASH_HW_STROBE_SIGNAL instead of
  V4L2_CID_FLASH_LED_MODE in ov9282.c (as suggested by Sakari)
- Drop "media: v4l2-flash: fix flash_timeout comment" as this was
  applied (thanks Lee)
- Link to v5: https://lore.kernel.org/r/20250617-ov9282-flash-strobe-v5-0-9762da74d065@linux.dev

Changes in v5:
- Improve try_ctrl for flash_duration by using DIV_ROUND_UP() and abs() (thanks Sakari)
- Drop "leds: flash: Add support for flash/strobe duration" as this was applied upstream
- Add "media: i2c: ov9282: dynamic flash_duration maximum" (thanks Sakari)
- Link to v4: https://lore.kernel.org/r/20250507-ov9282-flash-strobe-v4-0-72b299c1b7c9@linux.dev

Changes in v4:
- Fix FLASH_DURATION implementation in v4l2-flash-led-class.c by adding a
  missing brace and enum entry (thanks Sakari)
- Fix format of multiline comment in ov9282.c (thanks Sakari)
- Add missing NULL check in ov9282.c (thanks Sakari)
- Adapt nr_of_controls_hint for v4l2 handler in ov9282.c (thanks Sakari)
- Add patch for implementing try_ctrl for strobe_duration (thanks Sakari)
- Link to v3: https://lore.kernel.org/r/20250429-ov9282-flash-strobe-v3-0-2105ce179952@linux.dev

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
Richard Leitner (8):
      media: v4l: ctrls: add a control for flash/strobe duration
      media: v4l: ctrls: add a control for enabling strobe output
      Documentation: uAPI: media: add V4L2_CID_FLASH_{DURATION,STROBE_OE}
      media: i2c: ov9282: add output enable register definitions
      media: i2c: ov9282: add strobe output enable v4l2 control
      media: i2c: ov9282: add strobe_duration v4l2 control
      media: i2c: ov9282: implement try_ctrl for strobe_duration
      media: i2c: ov9282: dynamic flash_duration maximum

 .../userspace-api/media/v4l/ext-ctrls-flash.rst    |  42 ++++++
 drivers/media/i2c/ov9282.c                         | 165 ++++++++++++++++++++-
 drivers/media/v4l2-core/v4l2-ctrls-defs.c          |   3 +
 include/uapi/linux/v4l2-controls.h                 |   2 +
 4 files changed, 206 insertions(+), 6 deletions(-)
---
base-commit: 2f112b1c25da9f5346c2261ed35c5b1e0b906471
change-id: 20250303-ov9282-flash-strobe-ac6bd00c9de6

Best regards,
--  
Richard Leitner <richard.leitner@linux.dev>

