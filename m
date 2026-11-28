From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH v2 0/3] media: i2c: ov7251: software reset settle,
 autosuspend, and non-continuous clock
Date: Sat, 28 Nov 2026 21:41:06 +0100
Message-Id: <20261128-ov7251-strobe-ncont-v2-0-9428bbb6347e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32Nyw6CMBBFf4XM2prOKI+48j8MCzoOUKOtaWujI
 fy7gHuXJzn33AmiBCsRTsUEQbKN1rsFaFcAj50bRNnrwkCaKkSqlc81lahiCt6IcuxdUtg0dER
 TlgcjsCyfQXr73qqX9sfxZW7CaU2txmhj8uGz3WZcvf8PGZVWLH3XcMWatDkPj87e9+wf0M7z/
 AWoQr4RyAAAAA==
X-Change-ID: 20261127-ov7251-strobe-ncont-188241b553be
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>, Todor Tomov <todor.too@gmail.com>
Cc: Antoine Pichot <antoine.pichot@gmail.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795898468; l=2407;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=hQCpCWRsC5+pSrupw0ovS5WQH47W/IeMlHibVM2ygHk=;
 b=HKOGqZr+KpXilRNRprxL1+dbLdN2psa4oqz3wwoW4Ybkp0p5bt5yST9rVIxGKvPnXUipjnGZh
 hhC7ih6+bHNAO4a9sj1Okpa3Ot+bp8UPGb8y144xSxZlW1cabKRkN1r
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds three small fixes and Qualcomm SC8180X enablement
changes for the OmniVision OV7251 sensor driver, rebased on top of
Antoine Pichot's v3 OV7251 series [1]:

1. Issue software reset (0x0103 = 0x01) explicitly in
   ov7251_set_power_on() and wait 5-10 ms before writing
   ov7251_global_init_setting[] so the sensor settles before the common
   register block is programmed.
2. Use pm_runtime_put_autosuspend() in ov7251_s_ctrl() and
   ov7251_s_stream() so the 1000 ms autosuspend window configured in
   probe is actually honored across stream restarts (preserving the
   common register state introduced in [1]).
3. Support V4L2_MBUS_CSI2_NONCONTINUOUS_CLOCK by setting
   CLOCK_LANE_GATE (BIT(5)) in OV7251_MIPI_CTRL00 (0x4800) during
   power-on when requested by the CSI-2 endpoint.

Patch 4 from v1 (V4L2_CID_FLASH_STROBE_OE) is dropped in favor of patch
8/9 in Antoine Pichot's series [1].

[1] https://lore.kernel.org/linux-media/20261113024059.1087031-1-antoine.pichot@gmail.com/

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Based-on: 20261113024059.1087031-1-antoine.pichot@gmail.com

Changes in v2:
- Rebase onto Antoine Pichot's v3 OV7251 series and drop patch 4/4
  (V4L2_CID_FLASH_STROBE_OE) in favor of Antoine's strobe control patch
  (Antoine Pichot).
- Move the software reset (0x0103 = 0x01) out of
  ov7251_global_init_setting[] and wait 5-10 ms before writing the
  global init table rather than after it (Antoine Pichot).
- Drop redundant pm_runtime_mark_last_busy() calls before
  pm_runtime_put_autosuspend() and point Fixes tag at commit
  207f4162f1c9 (Antoine Pichot).
- Program OV7251_MIPI_CTRL00 non-continuous clock gating once per
  power-on alongside the global init registers.
- Link to v1: https://patch.msgid.link/20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com

---
Robert Ijtsma (3):
      media: i2c: ov7251: wait for software reset before global init
      media: i2c: ov7251: use pm_runtime_put_autosuspend()
      media: i2c: ov7251: support non-continuous MIPI clock mode

 drivers/media/i2c/ov7251.c | 45 +++++++++++++++++++++++++++++++++++++--------
 1 file changed, 37 insertions(+), 8 deletions(-)
---
base-commit: 299860c8390892ac175e8d3e13aa5b086c735dd1
change-id: 20261127-ov7251-strobe-ncont-188241b553be

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

