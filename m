From: Jason Yang <jason98166@gmail.com>
Subject: [PATCH v3 0/5] phy: rockchip-samsung-dcphy: add the MIPI D-PHY
 receiver
Date: Mon, 10 Aug 2026 20:10:08 +0800
Message-Id: <20260810-dcphy-rx-v1-v3-0-a2d25c29adfc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKC/eWoC/22MywqDMBBFf0Vm3ZQ8rDau+h+lizBJdKA+SEpQx
 H9vdGWhcDfnwjkrRBfIRWiKFYJLFGkcMqhLAdiZoXWMbGaQXFa8loJZnLqFhZklwbTxt9orZ73
 VkI0pOE/zUXu+MncUP2NYjngS+/u/k8dZ6fGukCMa1I+2N/S+4tjD3kny7Fa/rswueo2oSlMKa
 c7utm1fvkplLeIAAAA=
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Guochun Huang <hero.huang@rock-chips.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Michael Riesch <michael.riesch@collabora.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786363808; l=7032;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=nevNfidY6tsvxmk+AdwfOzkmhff8+MRU0pDkI+4ZBuc=;
 b=7A0CDyykn+qWFWEvsExBDgO5yZ4y3sY4YrblPB3GkuOxw0ASQiqla71xDMe2K/z2SfWnYHi/D
 JQJc+wCU2pxA/pq20URUwnbW5B4f4taOxaSqFvNT9cRcj/9gOkHWUGJ
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung MIPI D-/C-PHY block on RK3588 drives a MIPI DSI transmitter
and, on the same PHY, can receive from a MIPI CSI camera. Mainline
currently models the block as a single struct phy, so the two cannot be
brought up independently: the PHY core reference-counts power_on() per
struct phy, and the devicetree has no way to say which of the two a
consumer is attaching to.

This series registers one struct phy each for the transmitter and the
receiver, adds generic PHY_TYPE_DSI/PHY_TYPE_CSI constants so the
devicetree can name them, and implements the receiver side.

  1/5  adds PHY_TYPE_DSI and PHY_TYPE_CSI to the generic header
  2/5  lets this binding's existing single cell take them
  3/5  factors the transmitter power on/off into helpers (no functional
       change; the object code is unchanged)
  4/5  registers the two PHYs and use-counts the shared common block
  5/5  implements the receiver bring-up

Note on the constant values: 1/5 takes 14 and 15, and 14 is also claimed
by "dt-bindings: phy: Add PHY_TYPE_EUSB2 definition" [1], which is still
under discussion. Whichever series lands first, I am happy to respin on
whatever values you prefer - please just say which.

[1] https://lore.kernel.org/all/20260723-eusb2-int-handling-v5-v5-1-f32ea6c1a318@oss.qualcomm.com/

The in-tree devicetrees and the rockchip,rk3588-mipi-dsi2.yaml example
keep using PHY_TYPE_DPHY on purpose: for the transmitter the two
spellings are equivalent, and converting them would make new DTBs
require a new kernel for no functional gain.

D-PHY versus C-PHY selection is unchanged by this series: the
PHY_TYPE_CPHY cell still selects a C-PHY transmitter, and the driver
still returns -EOPNOTSUPP for it. The receiver support added here is
D-PHY only.

Testing
=======

Tested on an RK3588 board: DCPHY0 drives a DSI panel from its
transmitter while an IMX219 camera feeds its receiver, using the new
PHY_TYPE_DSI and PHY_TYPE_CSI cells; DCPHY1 drives a second DSI panel
through an unchanged PHY_TYPE_DPHY cell.

  - transmitter-first: panels light from boot, the camera joins and
    streams (30-frame byte-exact captures)
  - receiver-first: with the DCPHY0 transmitter disabled, the camera
    brings the block up as the first user through the use-counted
    reset path; the transmitter then joins mid-stream and its panel
    lights without disturbing the capture
  - transmitter leaving mid-stream: 150 consecutive frames captured
    byte-exact across a panel disable
  - repeated camera start/stop and panel enable/disable cycles on
    both PHYs, with no PHY warnings or use-count underflows logged
  - the D-PHY settle registers, including the SETTLE_CLK_SEL bit the
    TRM marks read-only, read back as programmed while streaming
  - receiver-first bring-up and the mid-stream transmitter join were
    also verified with an OV5640

The 3- and 4-lane receiver paths share the same table-driven
programming but are untested here.

As in v2, driving the DSI panels needs a local dw-mipi-dsi2 timing
workaround. That has since been root-caused: the bootloader can leave
the SPLL at the 351 MHz bootrom default while the devicetree describes
it as a 702 MHz fixed clock, halving the rate of both DSI hosts. A fix
is already on the U-Boot list [3]. None of this affects the receiver
path, which the camera captures exercise independently.

[3] https://lore.kernel.org/u-boot/20260804002643.2308515-3-jonas@kwiboo.se/

Changes since v2 [2]
====================

- Add generic PHY_TYPE_DSI/PHY_TYPE_CSI and select the PHY by the
  protocol the consumer speaks (the constants were suggested by Michael
  Riesch, and Vinod Koul agreed they are reasonable). With the protocol
  named in the first cell there is nothing left for a second cell to
  carry, so the Rockchip-specific header and the enum: [1, 2] are both
  gone.
- Because 1/4 of v2 was rewritten around the new constants, Bryan
  O'Donoghue's Reviewed-by on it has not been carried over.
- Turn the type switch into an early guard and drop the unreachable
  trailing return (Bryan O'Donoghue; the object code is unchanged either
  way).
- Rework the shared-block handling as Michael Riesch suggested: one
  struct samsung_mipi_phy per PHY, a use count in the parent taken and
  dropped inside the power helpers, lockdep_assert_held() in the shared
  helper rather than taking the mutex there, and no "first" flags.
- The APB reset is now issued on the same use-counted path for both
  PHYs, so a receiver-first power-on gets it too.
- On the open question from the v2 thread: the BIAS registers have no
  enable bit - they hold only static analog settings, per TRM section
  22.4.3 - so the release side only drops the use count. Michael has
  since confirmed the block is shared per the TRM and had no objection
  to renaming; get()/put() is used rather than a one-shot
  configure()/bool because the APB reset folded into the same path
  must be allowed to run again once every user is gone, which a flag
  that is never cleared cannot express.
- In the receiver patch itself: reject a zero lane count at power-on,
  correct the clock-lane comment (the register spacing is regular; the
  field layout is what differs), document the vendor settle-table
  quirks (the 1490 Mbps boundary and the read-only-marked SETTLE_CLK_SEL
  bit) and the per-lane tuning provenance, annotate the teardown delay,
  and use unsigned loop counters throughout.
- The driver still does not touch the GRF M/S_CPHY_MODE selects that
  Michael pointed at: both PHYs here run D-PHY, which is the GRF
  reset default. Explicit mode programming belongs to C-PHY support,
  pending the Rockchip clarification he is chasing. The first-user
  BIAS programming also stays correct once C-PHY lands: the only
  mode-dependent BIAS field is BIAS_CON4.I_MUX_SEL, and TRM section
  22.1 states that "The TX and RX only support operate in the same
  PHY mode", so the two PHYs cannot disagree about it. With the
  driver D-PHY only for now, that combination cannot be exercised
  yet.

[2] https://lore.kernel.org/all/20260726-dcphy-rx-v1-v2-0-cf9cc34a412a@gmail.com/

---
Jason Yang (5):
      dt-bindings: phy: Add PHY_TYPE_DSI and PHY_TYPE_CSI definitions
      dt-bindings: phy: rockchip,rk3588-mipi-dcphy: allow DSI and CSI consumers
      phy: rockchip-samsung-dcphy: factor MIPI D-PHY power on/off into helpers
      phy: rockchip-samsung-dcphy: model TX and RX as separate PHYs
      phy: rockchip-samsung-dcphy: add MIPI D-PHY receiver support

 .../bindings/phy/rockchip,rk3588-mipi-dcphy.yaml   |  11 +-
 drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c  | 555 +++++++++++++++++++--
 include/dt-bindings/phy/phy.h                      |   2 +
 3 files changed, 517 insertions(+), 51 deletions(-)
---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260721-dcphy-rx-v1-9af57f3edfd9

Best regards,
-- 
Jason Yang <jason98166@gmail.com>

