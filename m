From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH 0/4] media: synopsys: csi2rx: add support for rk3588
 variant
Date: Fri, 06 Mar 2026 15:09:47 +0100
Message-Id: <20260305-rk3588-csi2rx-v1-0-0cd8d2bf28c0@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACvgqmkC/x2NQQqDQAwAvyI5N7C7uir9SukhbmMNlW1JaBHEv
 zd4nIFhdjBWYYNrs4PyT0ze1SFeGigL1SejPJwhhdSHNmTUV5vHEYtJ0g0pxnkoMVMXCLyZyBg
 npVoWr+p3XV1+lGfZzsntfhx/AsxoBXQAAAA=
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Frank Li <Frank.li@nxp.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Collabora Kernel Team <kernel@collabora.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772806189; l=2252;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=QAEkleb6IVGK5L78+HXxLeZCePSBUtX84+LuF5RCLcQ=;
 b=+z1lAM+K34CYNMrpDG4Vre36ujGjSJtdNTMfHFjGBxHcLTuD65Qq7K+Px6e8p2q3OwnGFIp62
 NqLrn7qvsTHBOWIwzloMo39o8x8PtoJjfJAz4fBU1hvQX/HBnS8oizi
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Habidere,

The Rockchip RK3588 features six MIPI CSI-2 receiver units:
 - MIPI0: connected to MIPI DCPHY0
 - MIPI1: connected to MIPI DCPHY1
 - MIPI2: connected to MIPI DPHY0
 - MIPI3: connected to MIPI DPHY0-1 (only with split DPHY0)
 - MIPI4: connected to MIPI DPHY1
 - MIPI5: connected to MIPI DPHY1-1 (only with split DPHY1)

The MIPI DCPHYs (at least the CSI-2 features of them) as well
as the split DPHY mode of the DPHYs are not yet supported by
mainline. However, we can already provide support for the
MIPI2 and MIPI4 units.

When support for the split DPHY mode is introduced, the DPHY
nodes should have the property
    #phy-cells = <1>;
and the MIPI CSI-2 receiver nodes should have the property
    phys = <&csi_dphy{0,1} {0,1}>;
in case the split mode is desired. Since this is a board
specific hardware design, the properties need to be changed
in the board device tree (or any overlays).

As reasonable default, however, we can define, e.g., 
    #phy-cells = <0>;
and
    phys = <&csi_dphy{0,1}>;
in the SoC device tree include.
This series introduces initial support for this default
configuration.

In a related note, the split DPHY allows for different
integrations of the MIPI CSI-2 receiver into the different
SoCs. Therefore, we introduce a separate compatible (and not
only a fallback compatible) in the DT bindings.

Looking forward to your comments!

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
Michael Riesch (4):
      media: dt-bindings: rockchip,rk3568-mipi-csi2: add rk3588 compatible
      media: synopsys: csi2rx: add support for rk3588 variant
      arm64: dts: rockchip: add mipi csi-2 receiver nodes to rk3588
      arm64: defconfig: enable designware mipi csi-2 receiver

 .../bindings/media/rockchip,rk3568-mipi-csi2.yaml  |  1 +
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      | 52 ++++++++++++++++++++++
 arch/arm64/configs/defconfig                       |  1 +
 drivers/media/platform/synopsys/dw-mipi-csi2rx.c   |  3 ++
 4 files changed, 57 insertions(+)
---
base-commit: 11439c4635edd669ae435eec308f4ab8a0804808
change-id: 20260305-rk3588-csi2rx-a11f7c15a40a

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

