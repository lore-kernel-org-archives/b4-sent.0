From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH v8 0/3] media: rockchip: add driver for the rockchip mipi
 csi-2 receiver
Date: Tue, 20 Jan 2026 13:22:26 +0100
Message-Id: <20251114-rockchip-mipi-receiver-v8-0-bd1cf5cb9588@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIJzb2kC/43QTU7EMAwF4KuMsiYozm87K+6BWCSpQyM6TZVCB
 Rr17rizRJXI8lny9yzf2Yo148qulzuruOU1l5lC93RhcfTzO/I8UGZSSAMAmtcSP+KYF37LS+Y
 VI+YNKxfBJ6l17GOHjJaDX5GH6uc40vr8NU00XCqm/P1oe32jPOb1s9SfR/kGx/Tfng244AMo0
 VnsQAzDSyzT5EOp/jmWGzvYTbZRkigMfdBKOZeiPqNUG6WIArpIee+S6s0ZpdsoTZSnN9qEcRB
 GnlGmjTJEaeM9gEvQC39G2TbKEhVcRIu2CyqdUq6NcsdVMiUNfeqDgb/Uvu+/e7fAo5cCAAA=
To: Michael Riesch <michael.riesch@collabora.com>, 
 Chaoyi Chen <chaoyi.chen@rock-chips.com>, 
 Kever Yang <kever.yang@rock-chips.com>, Frank Li <Frank.li@nxp.com>, 
 Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768911749; l=3584;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=xI3XK/W7MN3TODvGHDwVqQLxNB3kgignpElz2ouoedE=;
 b=c8dBzMuiY14hwKL7xYp8MdP0tAvvQ6oVPsikr49ecWsDas4kEgVMvrYZ3zRVEMs1kEurGoVuh
 ekEKZgxIFDtAn4YUTiTsuO+UbXwu/Te/YGeh+i39IYb8K0WNsqm2Xv/
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Habidere,

This series adds support for the Rockchip MIPI CSI-2 Receiver that is
integrated into recent Rockchip SoCs, such as the RK3568 and the RK3588.

According to Rockchip, this core is NOT the Synopsys MIPI CSI-2 Host, but
it features a compatible register layout (thanks Chaoyi for the
clarification).

As pointed out by Frank, we should thus rename the driver and place it
under drivers/media/platform/synopsys to facilitate re-use of this code
for similar IP cores.

As has been discussed in [0], it would be beneficial to add support 
for the split mode (a feature of the Rockchip CSI-2 DPHY) before
integrating the MIPI CSI-2 Receiver into the respective SoC device tree
includes. However, we can readily add the DT binding and the driver
as I am positive they will not need to be changed significantly when this
feature is introduced.

This constitutes a small step towards mainline video capture and camera
support on the Rockchip RK3588.

Looking forward to your comments!

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>

[0] https://lore.kernel.org/r/20240220-rk3568-vicap-v14-0-b38b6da0fc80@collabora.com

---
Changes in v8:
- moved driver directly to drivers/media/platform/synopsys (Sakari)
- fixed further cosmetic issues (Frank)
- Link to v7: https://lore.kernel.org/r/20251114-rockchip-mipi-receiver-v7-0-42ff419f9b51@collabora.com

Changes in v7:
- fixed several cosmetic issues (Frank)
- Link to v6: https://lore.kernel.org/r/20251114-rockchip-mipi-receiver-v6-0-b7ce6e68b3fa@collabora.com

Changes in v6:
- renamed driver to dw-mipi-csi2rx (Sakari)
- fixed return value of v4l2_get_link_freq (this time, really) (Sakari)
- Link to v5: https://lore.kernel.org/r/20251114-rockchip-mipi-receiver-v5-0-45aa117f190a@collabora.com

Changes in v5:
- fixed indentation in struct platform_driver ... (Sakari)
- fixed return value in case v4l2_get_link_freq returns 0 (Sakari)
- switched from pm_runtime_put_sync() to pm_runtime_put() (Sakari)
- Link to v4: https://lore.kernel.org/r/20251114-rockchip-mipi-receiver-v4-0-a9c86fecd052@collabora.com

Changes in v4:
- moved driver to drivers/media/platform/synopsys and renamed it (Frank)
- addresse review comments by Sakari
- Link to v3: https://lore.kernel.org/r/20251114-rockchip-mipi-receiver-v3-0-16e83aa7f395@collabora.com

Changes in v3:
- rebased onto v6.19/recent media-committers/next
- Link to v2: https://lore.kernel.org/r/20251114-rockchip-mipi-receiver-v2-0-eb9b43377fc4@collabora.com

Changes in v2:
- dropped one R-b by Bryan, as there were two of them on the same patch
  (Krzysztof)
- Link to v1: https://lore.kernel.org/r/20251114-rockchip-mipi-receiver-v1-0-d13086e810dd@collabora.com

---
Michael Riesch (3):
      media: dt-bindings: add rockchip mipi csi-2 receiver
      media: synopsys: add driver for the designware mipi csi-2 receiver
      arm64: defconfig: enable designware mipi csi-2 receiver

 .../bindings/media/rockchip,rk3568-mipi-csi2.yaml  | 141 ++++
 MAINTAINERS                                        |   7 +
 arch/arm64/configs/defconfig                       |   1 +
 drivers/media/platform/synopsys/Kconfig            |  18 +
 drivers/media/platform/synopsys/Makefile           |   2 +
 drivers/media/platform/synopsys/dw-mipi-csi2rx.c   | 726 +++++++++++++++++++++
 6 files changed, 895 insertions(+)
---
base-commit: eb4ee870747c3a77a9c3c84d84efb64bd481013a
change-id: 20251114-rockchip-mipi-receiver-0baf244c9c8e

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

