From: Herman van Hazendonk <github.com@herrie.org>
Subject: [PATCH v4 0/2] media: i2c: add Aptina MT9M113 image sensor driver
Date: Sat, 06 Jun 2026 10:17:57 +0200
Message-Id: <20260606-submit-media-mt9m113-v4-0-046b4cbc7f94@herrie.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALbXI2oC/x2MQQqAIBAAvxJ7bsFMJPtKdCjbag9aaEUg/j2JO
 c1hJkGkwBShrxIEejjy4YuougK7T34j5KU4SCG1KGC8Z8cXOlp4QncZ1zQtSiVtN5M2ZASU9Ay
 08vtvhzHnD9tQ+blmAAAA
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Herman van Hazendonk <github.com@herrie.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780733878; l=3845;
 i=github.com@herrie.org; s=20240417; h=from:subject:message-id;
 bh=F/6oEepyPd63WZNPjLRITrV5xNoQfnuFOmwjm6Tgq+M=;
 b=+gXCPqcUD2GXQ/cSDcEF8ziXy4lvSawR6zHJDGhNKwlA7UPmHI9NEgXE5nE2Mb5PsgvD5JNNb
 mwqAwRIht3DDkGC1ww6pP2srFw2gf50XuhjFErrFKsyc10Vw82ez8+/
X-Developer-Key: i=github.com@herrie.org; a=ed25519;
 pk=YYxdq8fb5O9vhkW3n2dCH044FPZZO5718v/du7fRhFw=
X-Endpoint-Received: by B4 Relay for github.com@herrie.org/20240417 with auth_id=809
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2 subdev driver for the Aptina (now ON Semiconductor) MT9M113
1.3 megapixel SoC image sensor with embedded ISP, as used on the HP
TouchPad (apq8060) front camera. The sensor is programmed over I2C and
streams YUV / RGB / monochrome over a 1-lane MIPI CSI-2 D-PHY link.

Tested on HP TouchPad (Qualcomm APQ8060), front camera. The 10-mode
test-camera.sh sweep passes all of pix640 / pix640-nv16 / pix1280 /
pix1280-nv16 / video640 / video640-nv16 / video1280 / video1280-nv16 /
zsl640 / zsl1280 with exact frame-size matches and no MCU wedge
messages in dmesg.

Changes since v3:

  - Fix Context B (1280x1024 capture) stream-start regression. The
    MT9M113_SEQ_STATE_PREVIEW constant was 0x04 (== datasheet's
    "Leave preview" transient state); the actual stable preview state
    is 0x03. The Context-B preview-first step in stream_context_b()
    polled for 0x04 and timed out on every 1280x1024 stream-start
    with "MCU not ready for CAPTURE command -> stream start failed
    (-110)". Constant corrected to 0x03 with explanatory comment.
    Verified by passing pix1280 / video1280 / zsl1280 in the sweep
    above; Context A (640x480) behaviour unchanged.

  - Document an extensive forensic investigation of the IFP test-
    pattern generator (R0x0066 mode_test_mode, MCU logical addr
    0x2766) in a NOTE comment above the MODE_TEST_MODE define. The
    V4L2_CID_TEST_PATTERN control plumbing is retained, but on the
    HP TouchPad's MT9M113 die the IFP TPG MUX never engages despite
    every documented and undocumented enable path: writes to R0x2766
    stick across REFRESH; SEQ_MODE = 0 verifiably silences the MCU
    firmware drivers (visible darkening from AE-off); the IFP color
    pipeline can be stripped to nothing (R0x3210 = 0); none of it
    yields a visible pattern. R0x321C bit 4 is hardwired to 0 and
    R0x3246..R0x3252 (where the mt9d111-inherited test-mode register
    lives in the page-flattened address space) is a continuous dead
    block - classic Aptina foundry-removal fingerprints. No public
    driver in the MT9M113/V113/D113 family (HP webOS, codeaurora
    msm-3.4, esp_cam_sensor mt9d111, upstream mt9m114, etc.) drives
    this register either, consistent with the silicon-removal
    diagnosis. The plumbing stays in case a different silicon variant
    or vendor SROM patch actually wires up the TPG block; setting
    test_pattern > 0 on the current die is harmless (writes succeed,
    no pattern appears).

  - No driver behaviour changes for AE / AWB / HFLIP / VFLIP /
    COLORFX / SATURATION / POWER_LINE_FREQUENCY / EXPOSURE /
    ANALOGUE_GAIN / AUTO_WHITE_BALANCE controls or for the standard
    stream-start path; all addressed in v3.

Changes since v2 (already in v3):

  - Address Krzysztof + Sakari binding feedback: maxItems on
    reset-gpios / powerdown-gpios; drop |- from descriptions; drop
    redundant link-frequencies / remote-endpoint / data-lanes;
    rename i2c0 -> i2c in example.

  - Add MAINTAINERS entry per patchwork checkpatch.

Signed-off-by: Herman van Hazendonk <github.com@herrie.org>
---
Herman van Hazendonk (2):
      dt-bindings: media: i2c: add aptina,mt9m113
      media: i2c: add Aptina MT9M113 1.3 Mpx SoC sensor driver

 .../bindings/media/i2c/aptina,mt9m113.yaml         |  122 +
 MAINTAINERS                                        |    8 +
 drivers/media/i2c/Kconfig                          |   12 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/mt9m113.c                        | 3114 ++++++++++++++++++++
 5 files changed, 3257 insertions(+)
---
base-commit: 944125b4c454b58d2fe6e35f1087a932b2050dff
change-id: 20260606-submit-media-mt9m113-242c8be69e90

Best regards,
-- 
Herman van Hazendonk <github.com@herrie.org>

