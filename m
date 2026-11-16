From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH v4 0/8] media: i2c: ov9282: fix strobe timing and control
 handling
Date: Mon, 16 Nov 2026 14:50:21 +0100
Message-Id: <20261116-ov9282-fixes-v4-0-f78e5d415c6f@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2XPyw6CMBAF0F8hXVvTTgFbV/6HcdGn1BgwFBoM4
 d8taHzg8mbm3MmMKNjW24D22YhaG33wTZ1CvsmQrmR9ttiblBEQKIkgAjdRAAfs/GADNlLw0ki
 lgXGUyK21yyCJ4+mZQ68uVndzx7xR+dA17X25F+m896qm+W91pJhgVwCRrhDGUXW4+roftsZGN
 FdHeGNK/jAkzJRiu9JwRaVYY/bBlJIVZglrVRrHiU6vwTeepukBrucaAjQBAAA=
X-Change-ID: 20260909-ov9282-fixes-da986dabc238
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Daniele Alessandrelli <daniele.alessandrelli@gmail.com>, 
 "Paul J. Murphy" <paul.j.murphy@intel.com>, 
 Martina Krasteva <martinax.krasteva@intel.com>, 
 Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 Gyula Kelemen <gyula.kelemen@advasolutions.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794837042; l=3997;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=Avrpj9TSbmW8HxXDV/hEDnUl7Dl+3qFFb1QyyA6F1Xo=;
 b=AFBCuY8SUyde0cytqozu7FgSQKVyixaZAfC3CnKxKcTU0Q+/BZK11+ER+2lk2uxW/XXSHfW2F
 YCrUa7FrH0eD+s4MpJXCNV8xCs6KCOrJfCzjjMf61cbzqnFaTHJWSGJ
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes a set of related issues in the OV9282 strobe timing
and control handling code.

The driver updated exposure- and flash duration-related control ranges
in several places, but some of those updates used an incorrect timebase
or were triggered too late, which could leave the controls clamped
against stale values.

The series:
- checks the return value of the exposure range update
- drops the redundant vblank field
- converts probe error messages to dev_err_probe()
- fixes the 8-bit pixel rate (192 MHz instead of 200 MHz) and the
  corresponding line time calculation
- treats the strobe frame span as a line count and converts the flash
  duration accordingly
- fixes the flash duration range (min/max/default) and refreshes it on
  HBLANK changes, independent of the sensor power state
- refreshes the exposure and flash duration ranges on mode changes
- reprograms the strobe span when HBLANK changes

This series was tested with an ov9282 sensor on a vision components camera
module attached to an i.MX8MP mainboard in a defined (dark) environment
with a custom made LED flash pcb.

Any feedback is warmly welcome.

Thanks!

---
Changes in v4:
- Replace DIV_ROUND_UP with DIV_ROUND_UP_ULL to fix 0-day finding
- Link to v3: https://patch.msgid.link/20261110-ov9282-fixes-v3-0-cb6df80cbc22@linux.dev

Changes in v3:
- Adapt commit texts for 4/8 and 5/8
- Thanks to Dave the review!
- Link to v2: https://patch.msgid.link/20261014-ov9282-fixes-v2-0-3bb376d8b1a9@linux.dev

Changes in v2:
- New patch: fix the 8-bit pixel rate.
- New patch: re-write strobe span and HTS in s_ctrl when HBLANK changes
- Calculate line time in ns using 64-bit math instead of 32-bit µs
- Treat the strobe frame span as a line count and reuse the helpers of the
  exposure -> drop OV9282_STROBE_SPAN_FACTOR
- Flash duration range: min is 1 line, max is S32_MAX instead of the
  current exposure time, default is converted from the register default
- Refresh the flash duration range on HBLANK changes instead of on
  exposure/gain writes, so it is also correct while the sensor is idle
- Add missing "\n" to dev_err_probe() messages
- Add Fixes: and Cc: stable tags where applicable
- Reorder patches to keep non-fixes at the end
- Reword commit messages and subjects
- Thanks to Dave, Bryan and Sakari for the review!
- Link to v1: https://patch.msgid.link/20260914-ov9282-fixes-v1-0-f520af59df1b@linux.dev

To: Sakari Ailus <sakari.ailus@linux.intel.com>
To: Dave Stevenson <dave.stevenson@raspberrypi.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>
To: Daniele Alessandrelli <daniele.alessandrelli@gmail.com>
To: Paul J. Murphy <paul.j.murphy@intel.com>
To: Martina Krasteva <martinax.krasteva@intel.com>
To: Richard Leitner <richard.leitner@linux.dev>
To: Hans Verkuil <hverkuil+cisco@kernel.org>
To: Bryan O'Donoghue <bod@kernel.org>
To: Jacopo Mondi <jacopo@jmondi.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>
Cc: Gyula Kelemen <gyula.kelemen@advasolutions.com>
Cc: linux-media@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Richard Leitner (8):
      media: i2c: ov9282: handle error from exposure range update
      media: i2c: ov9282: fix pixel rate and line time calculation
      media: i2c: ov9282: fix flash duration to/from microseconds conversion
      media: i2c: ov9282: fix flash duration range calculation
      media: i2c: ov9282: add refresh of additional ranges on a mode change
      media: i2c: ov9282: recalculate strobe span on HBLANK change
      media: i2c: ov9282: drop redundant vblank field
      media: i2c: ov9282: harmonize dev_err_probe usage

 drivers/media/i2c/ov9282.c | 236 +++++++++++++++++++++++++++------------------
 1 file changed, 144 insertions(+), 92 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20260909-ov9282-fixes-da986dabc238

Best regards,
--  
Richard Leitner <richard.leitner@linux.dev>

