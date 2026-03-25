From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH v3 0/2] media: synopsys: csi2rx: add support for rk3588
 variant
Date: Wed, 25 Mar 2026 11:25:33 +0100
Message-Id: <20260305-rk3588-csi2rx-v3-0-754473981f39@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB24w2kC/32NQQ7CIBQFr9KwFvOhpUVX3sO4+FBqiQgGlNQ0v
 bu0SxNdziRv3kySidYkcqxmEk22yQZfoN5VRI/or4bavjDhwFuoQdB4q4WUVCfL40SRsaHTTGA
 DSMpGYTJURfR6LCv/cq7IRzSDnbaT86XwaNMzxPf2mdlqf+Uzo0BB97LnauBSw0kH51CFiHsd7
 mStZf63wEuhO/TAVMtEI9vvwrIsH/WMf14FAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774434334; l=2260;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=pdk69hgSxYlxrpI3vu+iS6YkL5ihSIa3ahhwcNkHEv8=;
 b=I0HG7NrC2CzWSq5p3raWhME1EI5+Q/FWJexuv2OuVi82Sra0oPmeUy9yih67qO3RPrEsuk+3i
 /vW8Be4pNuFDCRmSp2jDuZU9TcqjKgY7ztIqI12zCvEHLx5s1FETiLh
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

Looking forward to your comments!

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
Changes in v3:
- rebased onto Sakari's cleanup branch (as Frank's patches were
  merged) (Sakari)
- added Rob's Acked-by
- Link to v2: https://lore.kernel.org/r/20260305-rk3588-csi2rx-v2-0-79d01b615486@collabora.com

Changes in v2:
- use fallback compatible instead of separate compatible (Krzysztof)
- dropped patch 2 and 4 (as a consequence thereof)
- Link to v1: https://lore.kernel.org/r/20260305-rk3588-csi2rx-v1-0-0cd8d2bf28c0@collabora.com

---
Michael Riesch (2):
      media: dt-bindings: rockchip,rk3568-mipi-csi2: add rk3588 compatible
      arm64: dts: rockchip: add mipi csi-2 receiver nodes to rk3588

 .../bindings/media/rockchip,rk3568-mipi-csi2.yaml  | 10 +++--
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      | 52 ++++++++++++++++++++++
 2 files changed, 59 insertions(+), 3 deletions(-)
---
base-commit: 66bd47face7d5d55e6c3b5dc16fb3c2d6e205360
change-id: 20260305-rk3588-csi2rx-a11f7c15a40a

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

