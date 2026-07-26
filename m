From: Jason Yang <jason98166@gmail.com>
Subject: [PATCH v2 0/4] phy: rockchip-samsung-dcphy: support the D-PHY
 receiver direction
Date: Sun, 26 Jul 2026 22:55:43 +0800
Message-Id: <20260726-dcphy-rx-v1-v2-0-cf9cc34a412a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO8fZmoC/22MywrCMBBFf6XM2pEkVWtc+R/SRZgkzYB9kEhoK
 fl3Y9fC3ZwL5+yQXGSX4NHsEF3mxPNUQZ0aoGCmwSHbyqCEuolOSbS0hA3jilmiNv7a+dZZbzV
 UY4nO83rUXn3lwOkzx+2IZ/l7/3fqBF483VsSRIb0cxgNv880j9CXUr4G4YaepgAAAA==
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Guochun Huang <hero.huang@rock-chips.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785077744; l=4521;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=Xk0Wg5LA2QTiKljwaqu5yGBrxyPyNVlXfI3hqcUzr3o=;
 b=hQamqfOn8VR7SpVEPxCVz9zy1LomDAsw66CcgqjgYUm1i3t0JjaE+Wz1qSEVYZjVSuEP0GAO8
 7NMXdF/bQ4YBInrXLvqVXdmJQYYv7u76VR0T2D855RZS+74yqMy/qvH
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung DC-PHY on RK3588 contains both a MIPI transmitter (DSI)
and a MIPI receiver (CSI) with separate register banks and resets.
Mainline currently models only the transmitter. This series adds the
receiver so a CSI camera can use the PHY, including running both
directions concurrently (a DSI panel and a CSI camera on the same PHY
instance).

Design notes, to answer the obvious questions up front:

- Direction as a phy-cell rather than a phy_set_mode() submode:
  The PHY core reference-counts power_on() per struct phy. Bringing TX
  and RX up and down independently requires one struct phy per
  direction; a submode on a single phy cannot express two concurrent
  owners. The extra cell selects which of the two phys a consumer
  gets, following how phy-exynos-mipi-video exposes multiple phys
  from one register block. The existing single-cell binding still
  resolves to the transmitter, ensuring shipped device trees remain
  unaffected.

- BIAS block coordination:
  The BIAS block is part of the PHY's common block and exists once for
  both directions (RK3588 TRM section 22.2), so it must be programmed
  only once. Whichever direction powers on first enables it, and it
  stays enabled until runtime PM suspends the PHY, matching the
  existing transmitter-only driver.

- RX tuning:
  RX tuning uses fixed RK3588 defaults. Boards that need finer
  receiver tuning should extend phy_configure_opts_mipi_dphy rather
  than add private device-tree properties.

Patch summary:
  patch 1: dt-bindings: optional second #phy-cells cell for direction
  patch 2: prep: symmetric TX power on/off helpers, no functional change
  patch 3: register one struct phy per direction
  patch 4: implement the receiver

Testing:
The series was tested on an IEI WAFER-RK3588 board across the following
configurations:
- Concurrent TX/RX: IMX219 CSI camera capture (RAW10, multiple
  resolutions up to 3280x2464) and OV5640 capture (1920x1080) through
  the DC-PHY RX, running concurrently with a MIPI DSI panel (ILI9881C,
  720x1280) driven through the TX half of the same PHY instance.
- DSI-only and CSI-only configurations, and a shipped single-cell DSI
  device tree resolving unchanged to the transmitter.
- The board wires two data lanes in each direction. 1-lane receive was
  additionally exercised end-to-end concurrently with the 2-lane
  transmitter (with a locally patched ov5640 sensor driver, as the
  mainline driver hard-codes the sensor's 2-lane mode), which also
  exercises the per-direction lane bookkeeping introduced in v2. The
  3- and 4-lane paths share the same table-driven programming but are
  untested here.
The DSI half of the concurrent tests additionally required a local
dw-mipi-dsi2 HS-video fix that is not part of this submission; the
receiver support added here is exercised independently by the CSI-only
capture.

---
Changes in v2:
- Rename the dt-bindings header to rockchip,rk3588-mipi-dcphy.h
  (Krzysztof)
- Move the lane count and the receiver link rate into per-direction
  state. A receiver configure() could previously overwrite the
  transmitter's lane count; observed on hardware as the transmitter
  leaving its second data lane enabled on power-off after the receiver
  had been configured for one lane.
- Reject the unsupported direction in configure() before touching any
  state, and drop the provider lock from configure() (per-direction
  state no longer needs it).
- Track each direction's powered state under the provider mutex instead
  of reading the peer phy's power_count.
- Switch already-enabled lanes back off when the receiver bring-up
  fails.
- Link to v1: https://lore.kernel.org/r/20260721-dcphy-rx-v1-v1-0-4fc83c0ccac9@gmail.com

---
Jason Yang (4):
      dt-bindings: phy: rockchip,rk3588-mipi-dcphy: support per-direction phys
      phy: rockchip-samsung-dcphy: factor MIPI D-PHY power on/off into helpers
      phy: rockchip-samsung-dcphy: model TX and RX as separate PHYs
      phy: rockchip-samsung-dcphy: add MIPI D-PHY receiver support

 .../bindings/phy/rockchip,rk3588-mipi-dcphy.yaml   |  22 +-
 drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c  | 478 +++++++++++++++++++--
 .../dt-bindings/phy/rockchip,rk3588-mipi-dcphy.h   |  13 +
 3 files changed, 460 insertions(+), 53 deletions(-)
---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260721-dcphy-rx-v1-9af57f3edfd9

Best regards,
-- 
Jason Yang <jason98166@gmail.com>

