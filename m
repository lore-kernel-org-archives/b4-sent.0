From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH v2 0/3] media: rockchip: add driver for the rockchip mipi
 csi-2 receiver
Date: Tue, 18 Nov 2025 12:12:24 +0100
Message-Id: <20251114-rockchip-mipi-receiver-v2-0-eb9b43377fc4@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJhUHGkC/4WNQQ7CIBAAv9JwFgNYTfXkP0wPsGxlIy3NokTT9
 O9iP+BxJpnMIjIyYRaXZhGMhTKlqYLZNQKCne4oyVcWRpmj1rqVnOABgWY50kySEZAKslTODqZ
 t4Qwdiho7m1E6thOEmk+vGKucGQd6b7dbXzlQfib+bPOif/bvp2ippNcH1Z2w08r7K6QYrUts9
 5BG0a/r+gUsbyWj1QAAAA==
To: Michael Riesch <michael.riesch@collabora.com>, 
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
 linux-kernel@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763464345; l=2257;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=vg/rAUSulARoX9rCdjKSaqwDFdJwWNhU9fab7PXcE40=;
 b=cjAoIEyEJzBcuSQ30blsRigVfjME6y6fVyfytrVJVdxAX8NqbGz0v4GkzzrQ87JrpJon27Zgg
 9c1PHQrMVyHB4ASS3NMMdvmHX/xCd+KXb9Ew/L5ZT9nr77Bisaoi8Jj
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Habidere,

This series adds support for the Rockchip MIPI CSI-2 Receiver that is
integrated into recent Rockchip SoCs, such as the RK3568 and the RK3588.

These changes have been discussed and reviewed thoroughly in roughly 10
iterations of the rkcif patch series (see [0] and predecessors). Thus,
they should be ready for inclusion in mainline.

However, as has been discussed in [0], it would be beneficial to add
support for the split mode (a feature of the Rockchip CSI-2 DPHY)
before integrating the MIPI CSI-2 Receiver into the respective SoC
device tree includes. We can readily add the DT binding and the driver
as I am positive they will not need to be changed when this feature is
introduced, but there are no patches in the series that introduce the
DT nodes.

This constitutes a small step towards mainline video capture and camera
support on the Rockchip RK3588.

Looking forward to your comments!

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>

[0] https://lore.kernel.org/r/20240220-rk3568-vicap-v14-0-b38b6da0fc80@collabora.com

---
Changes in v2:
- dropped one R-b by Bryan, as there were two of them on the same patch
  (Krzysztof)
- Link to v1: https://lore.kernel.org/r/20251114-rockchip-mipi-receiver-v1-0-d13086e810dd@collabora.com

---
Michael Riesch (3):
      media: dt-bindings: add rockchip mipi csi-2 receiver
      media: rockchip: add driver for the rockchip mipi csi-2 receiver
      arm64: defconfig: enable rockchip mipi csi-2 receiver

 .../bindings/media/rockchip,rk3568-mipi-csi.yaml   | 146 ++++
 MAINTAINERS                                        |   7 +
 arch/arm64/configs/defconfig                       |   1 +
 drivers/media/platform/rockchip/Kconfig            |   1 +
 drivers/media/platform/rockchip/Makefile           |   1 +
 drivers/media/platform/rockchip/rkcsi/Kconfig      |  16 +
 drivers/media/platform/rockchip/rkcsi/Makefile     |   3 +
 drivers/media/platform/rockchip/rkcsi/rkcsi.c      | 742 +++++++++++++++++++++
 8 files changed, 917 insertions(+)
---
base-commit: 1f2353f5a1af995efbf7bea44341aa0d03460b28
change-id: 20251114-rockchip-mipi-receiver-0baf244c9c8e

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

