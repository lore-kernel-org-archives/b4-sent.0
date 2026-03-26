From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH v4 0/2] media: synopsys: csi2rx: add support for rk3588
 variant
Date: Fri, 27 Mar 2026 00:09:59 +0100
Message-Id: <20260305-rk3588-csi2rx-v4-0-81c6bcfefa63@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMe8xWkC/33NSw7CIAAE0KsY1mL4ttSV9zAu+FpiBQNKapreX
 dql0S5nknkzgWyTtxkcdxNItvjsY6iB7XdA9zJcLfSmZkAQaRBFHKYb5UJAnT1JI5QYu1ZjLhm
 SoG6UzBaqJIPu6yq8hqGWj2SdH9eT86Xm3udnTO/1s+Cl/ccXDBFE2ghDlCNCo5OOwyBVTPKg4
 x0sWiGbAqlC2xmEVYM5E80vgW4KdBE4Yy3tBHa0+xbmef4AvALURkcBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774566600; l=2509;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=F+kzzca6Z4BmvXweVJwbOgdkmwl7lP2kz+U6gv7BBLA=;
 b=Q31Ushq3MPm7/rk/deCaFnjvfmVxk9/KY9/ptu4vESyDcHaREKfCWa+676qoOfzvkuVYr5Aae
 cbQSVm2trRLBMNUxDD+5gf6NZwQhNeHbeOBdu4LveLZPK3i8dL1Rq8M
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
Changes in v4:
- rebased onto media-commiters/next again (as Frank's patches
  are now there)
- changed "oneOf entries to enum in dt binding (Rob)
- Link to v3: https://lore.kernel.org/r/20260305-rk3588-csi2rx-v3-0-754473981f39@collabora.com

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

 .../bindings/media/rockchip,rk3568-mipi-csi2.yaml  | 11 +++--
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      | 52 ++++++++++++++++++++++
 2 files changed, 60 insertions(+), 3 deletions(-)
---
base-commit: 4fbeef21f5387234111b5d52924e77757626faa5
change-id: 20260305-rk3588-csi2rx-a11f7c15a40a

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

