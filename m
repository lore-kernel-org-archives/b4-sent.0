From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Subject: [PATCH v4 0/2] media: i2c: Samsung S5K3T2 image sensor
Date: Sun, 11 Oct 2026 11:13:26 +0200
Message-Id: <20261011-upstream-s5k3t2-v4-0-d33b12fb3263@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNTQ7CIBCG4asY1mIGBurPynsYFxQGRWPbADYa0
 7tL66bRuPySed55sUQxUGK7xYtF6kMKbVOGWi6YPZvmRDy4spkEWcFWAr93KUcyN570FbPkEmt
 EZ2pAoVlRXSQfHlPxcPzsdK8vZPOYGS/OIeU2PqeXvRjv/td7wYG7SsFagVcgcN/FNrfN6kZsr
 Pdy7vHXy+JBee8MogYrvj3Ovfr1WLzRVm+ct2Tldu6HYXgDcADQxkABAAA=
X-Change-ID: 20260920-upstream-s5k3t2-23b33dab0315
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Elgin Perumbilly <elgin.perumbilly@siliconsignals.io>, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791710007; l=4010;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=3YRk5UGBS0VOOHj9mW933zZqL8ZW8nf7hwX5dyuXdYs=;
 b=W5H5IXa0Ch1yt7cxdYyWgep0m0D6UNc09Zz9lqF7aCYUokobV+OCC8vdGg3/hg6YcBG6OhJIH
 fVU3av8iX+wDPguq+/dQocy6nsgdtowJakMpTgHxmN/tIy0J3GhYN1n
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

Tested:

  v4l2-compliance on the sensor sub-device, 46 tests, 46 passed
  capture in all three modes, twelve runs, no kernel error
  the sensor returns to runtime suspend after every run
  exposure and gain sweeps checked on the captured frames
  Bayer order checked for both flips

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
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
 drivers/media/i2c/s5k3t2.c                         | 1331 ++++++++++++++++++++
 5 files changed, 1455 insertions(+)
---
base-commit: 518e5b794c06c0f0eb40df3e202274a66202c137
change-id: 20260920-upstream-s5k3t2-23b33dab0315

Best regards,
--  
Armandas Kvietkus <armandas.kvietkus@proton.me>

