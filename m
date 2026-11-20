From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Subject: [PATCH v6 0/2] media: i2c: Samsung S5K3T2 image sensor
Date: Fri, 20 Nov 2026 19:04:17 +0100
Message-Id: <20261120-upstream-s5k3t2-v6-0-dd345fa4201c@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XOQU7DMBAF0KtUXmPkmbET0hX3QCwce0wNahLZb
 gSqcnecIkHUiOWX/vszV5E5Rc7ieLiKxHPMcRxqaB4Owp3s8MYy+poFKmxUh0peplwS27PM5oM
 KSqSeyNteERhR1ZQ4xM/b4svrT86X/p1dWWfWxinmMqav28kZ1t7/6zNIJX2jVatV0AroeUpjG
 YfHM4t1fcatp73H6pUOwVsioxzce9p6vfdUvTXOPPng2GF37/WvBwWw93r9n6gHDD1hs/vf/Hm
 Adu9N9RDaYILnjtFu/bIs33g+sivAAQAA
X-Change-ID: 20260920-upstream-s5k3t2-23b33dab0315
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Elgin Perumbilly <elgin.perumbilly@siliconsignals.io>, 
 phone-devel@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795197857; l=5640;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=mbLrU2TtWG//UqAkd1hg4LGPAE7nIw6zMUc/JOxOByc=;
 b=FhbRJ9ZHCsSkpvTN+YhvnSGI/4gtmlLpvjsKUkKR0TyqJv2ZWGDqPGMTTGgWCoZsYUXRdRhSJ
 AT2FdZNt6c+CxfcvU87q/awxt2W1SqNKqG8/Xs83SjR43Xm64iggwmq
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a binding and a driver for the Samsung S5K3T2, a
20 Mpixel CMOS image sensor with four MIPI D-PHY lanes.

The sensor is the front camera of the Xiaomi POCO F3. That phone has no
device tree in mainline, so this series adds no user for the binding.
The driver was written and tested on the phone with the Qualcomm CAMSS
driver.

The driver supports three modes. All of them are RAW10 on four D-PHY
lanes.

  5184x3880 at 15 fps, link frequency 448 MHz
  2592x1940 at 60 fps, link frequency 448 MHz
  1280x720 at 120 fps, link frequency 300 MHz

The link frequency control selects which modes are available. The pixel
clock does not change between modes, so the pixel rate is constant.

The controls are exposure, analogue gain, horizontal blanking, vertical
blanking, horizontal flip, vertical flip and test pattern. Rotation and
orientation come from the device tree. Power is handled by runtime PM
with autosuspend.

The register tables come from the vendor camera firmware.

Tested:

  v4l2-compliance on the sensor sub-device, 46 tests, 46 passed
  capture in all three modes, twelve runs, no kernel error
  the sensor returns to runtime suspend after every run
  exposure and gain sweeps checked on the captured frames
  Bayer order checked for both flips
  link frequency switching, and the control is busy while streaming

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
Changes in v6:
- The link frequency control is writable now and selects which modes
  are available. When it changes, the format moves to the nearest mode
  at the new frequency.
- Moved the mode list and the other details from the driver commit
  message to the cover letter.
- Dropped the Reviewed-by from Elgin because of the link frequency
  change.
- Added phone-devel to Cc.
- Link to v5: https://patch.msgid.link/20261117-upstream-s5k3t2-v5-0-1f7f5fde9e2a@proton.me

Changes in v5:
- Dropped four page select writes (0x6028) from the register tables.
  Each one selected the page that was already selected. They came from
  the vendor sequence.
- Collected the Reviewed-by from Elgin.
- The link frequency still follows the mode. The question about it on
  v3 is still open.
- Link to v4: https://patch.msgid.link/20261011-upstream-s5k3t2-v4-0-d33b12fb3263@proton.me

Changes in v4:
- Use ARRAY_SIZE() instead of the S5K3T2_NUM_SUPPLIES macro.
- The link frequency and pixel rate controls have no ops now, the
  driver never writes them.
- HBLANK and VBLANK are written from s_ctrl. The line length and frame
  length registers are gone from the mode lists. HBLANK is not read only
  anymore, but its range is still one value per mode.
- The flips are written from s_ctrl and are clustered.
- 0x0100 and 0x0101 are written as 8-bit registers.
- The mode is not kept outside the subdev state anymore. The crop
  rectangle is kept in the state too.
- Every control call in set_fmt has its return value checked.
- The fwnode properties are parsed before the control handler is set
  up, and the control flags are set after the error check.
- Dropped the link_validate op, the redundant fwnode and endpoint
  checks, and the gotos in power_on and set_fmt.
- The error labels in probe start with err_, and remove calls
  pm_runtime_dont_use_autosuspend().
- Small cleanups: container_of_const(), local variable order,
  s5k3t2_format_from_mode(), and init_state returns the set_fmt result.
- The link frequency still follows the mode. The question about it on
  v3 is still open.
- Dropped the line about hidden modes from the commit message.
- Link to v3: https://patch.msgid.link/20260924-upstream-s5k3t2-v3-0-a5c58dfcec29@proton.me

Changes in v3:
- The check on pm_runtime_get_if_active() is back to the form used by
  every other sensor driver. The v2 form skipped the register write when
  the helper returned an error, so a kernel built without CONFIG_PM never
  applied exposure, gain, blanking or the test pattern.
- The binding now requires clocks and the three supplies. The driver does
  not probe without the clock, and the sensor needs all three rails.
- Link to v2: https://patch.msgid.link/20260923-upstream-s5k3t2-v2-0-04ffda3350c1@proton.me

Changes in v2:
- set_pad_format() now stores the new mode before it updates the
  controls. The VBLANK handler reads the mode, so it used to program the
  frame length from the mode that was active before the call.
- A negative return from pm_runtime_get_if_active() is no longer read as
  active. Runtime PM can be disabled for the device, and in that case the
  usage count is not taken, so the old code could drop a count it never
  took.
- The PM ops use RUNTIME_PM_OPS() with pm_ptr(), so the ops and the power
  callbacks are dropped when CONFIG_PM is not set.
- Link to v1: https://patch.msgid.link/20260920-upstream-s5k3t2-v1-0-d640740f4013@proton.me

---
Armandas Kvietkus (2):
      dt-bindings: media: i2c: Add Samsung S5K3T2 image sensor
      media: i2c: Add Samsung S5K3T2 image sensor driver

 .../bindings/media/i2c/samsung,s5k3t2.yaml         |  105 ++
 MAINTAINERS                                        |    8 +
 drivers/media/i2c/Kconfig                          |   10 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/s5k3t2.c                         | 1365 ++++++++++++++++++++
 5 files changed, 1489 insertions(+)
---
base-commit: 518e5b794c06c0f0eb40df3e202274a66202c137
change-id: 20260920-upstream-s5k3t2-23b33dab0315

Best regards,
--  
Armandas Kvietkus <armandas.kvietkus@proton.me>

