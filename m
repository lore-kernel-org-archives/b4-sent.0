From: Herman van Hazendonk <github.com@herrie.org>
Subject: [PATCH v2 0/2] media: i2c: add Aptina MT9M113 SoC sensor driver
Date: Fri, 05 Jun 2026 05:38:54 +0200
Message-Id: <20260605-submit-media-mt9m113-v2-0-de1cc807f4cf@herrie.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM5EImoC/x3MTQqAIBBA4avIrBvwhxK7SrSwmmoWWmhFEN09a
 fkt3nsgU2LK0IoHEl2ceYsFuhIwrj4uhDwVg5a6kY2sMZ9D4AMDTewxHC4oZbD2o1HGOqtmDyX
 dE818/9uuf98PtvqZl2YAAAA=
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780630734; l=3080;
 i=github.com@herrie.org; s=20240417; h=from:subject:message-id;
 bh=+/Pfejnvv47jdCDVLiewF3uDmKJ65qBjBwcc879f1Vw=;
 b=S/XL230mm6P9SpLxZkMz98q6BJAL8m0RyU0+mOGX4MPIWDS3gosgqvtlhi4GAUERpGhL3kkw+
 XksDy2IrsIMAWR8KCXTC8/q06r15JfUOee03oEZlLUsds+eZ+5lm8nm
X-Developer-Key: i=github.com@herrie.org; a=ed25519;
 pk=YYxdq8fb5O9vhkW3n2dCH044FPZZO5718v/du7fRhFw=
X-Endpoint-Received: by B4 Relay for github.com@herrie.org/20240417 with auth_id=809
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v2: pure re-send.  No code changes from v1.

v1 was sent on 2026-06-04 but PATCH 2/2 (the driver itself) was
silently dropped by my outbound SMTP relay during the original send;
the cover letter and PATCH 1/2 reached the lists, the driver
patch did not.  Re-sending the full series via b4 / kernel.org so
the driver actually lands.

If you already started reviewing v1's cover or binding, no need to
re-read those - they're byte-identical.

To: Mauro Carvalho Chehab <mchehab@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: van Hazendonk <github.com@herrie.org>
To: Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

This series adds a V4L2 subdev driver and DT binding for the Aptina
MT9M113, a 1.3 Mpx SoC sensor with an on-chip ISP and a small MCU
running a "SOC1040" firmware that performs auto-exposure, auto white
balance and lens-shading correction.  The sensor talks to the host
over MIPI CSI-2 (1 or 2 data lanes); register access is over I2C
using the Qualcomm CCI helper.

Hardware layout exposed to userspace:

    +-------------------+    +-----------------+
    | Pixel Array (PA)  |--->| IFP / ISP       |--->[CSI-2]
    | sink-less subdev  |    | MCU + pipe      |
    +-------------------+    +-----------------+

PA carries V4L2_CID_PIXEL_RATE and V4L2_CID_LINK_FREQ so that
downstream receivers walking the graph from the CSIPHY (camss does
this) find them on the entity flagged MEDIA_ENT_F_CAM_SENSOR.

V4L2 controls implemented:
  - exposure / gain / hflip / vflip
  - test pattern
  - V4L2_CID_COLORFX (sepia / mono / negative / aqua / vivid)
  - V4L2_CID_POWER_LINE_FREQUENCY (50/60 Hz flicker avoidance)

Tested on a HP TouchPad (APQ8060, MSM8x60 family) with the on-board
front 1.3 Mpx MT9M113.  Probes cleanly, both PA and IFP subdevs
register, csiphy_stream_on() picks up link_freq from PA, and the
preview pipeline up through CAMSS produces frames.  A bounded
3-attempt retry around s_stream(1) handles a residual silicon-level
wedge that occasionally leaves the MCU's SEQ_CMD in an inconsistent
state on cold start.

The DTS patches that enable the sensor on the HP TouchPad will be
sent separately to the ARM/DTS tree.

Signed-off-by: Herman van Hazendonk <github.com@herrie.org>
---
Herman van Hazendonk (2):
      dt-bindings: media: i2c: add aptina,mt9m113
      media: i2c: add Aptina MT9M113 1.3 Mpx SoC sensor driver

 .../bindings/media/i2c/aptina,mt9m113.yaml         |  127 +
 drivers/media/i2c/Kconfig                          |   12 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/mt9m113.c                        | 2971 ++++++++++++++++++++
 4 files changed, 3111 insertions(+)
---
base-commit: 944125b4c454b58d2fe6e35f1087a932b2050dff
change-id: 20260605-submit-media-mt9m113-5ac3137971fa

Best regards,
-- 
Herman van Hazendonk <github.com@herrie.org>

