From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH 0/5] phy: rockchip: phy-rockchip-inno-csidphy: add support
 for rk3588 variant
Date: Tue, 17 Jun 2025 10:54:41 +0200
Message-Id: <20250616-rk3588-csi-dphy-v1-0-84eb3b2a736c@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFEtUWgC/x3MQQqAIBBA0avErBswS7GuEi3CmXIILBSiiO6et
 HyL/x/InIQzDNUDiU/JsseCpq7AhzmujELFoJU2yjYW09Ya59BnQTrCjb5n0jN1nvoFSnUkXuT
 6j+P0vh9u/TV2YQAAAA==
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Vinod Koul <vkoul@kernel.org>, Kishon Vijay Abraham I <kishon@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Jagan Teki <jagan@amarulasolutions.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, 
 Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750150493; l=1495;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=Si2W4F7cUbz3L54al/Qkxuum2j7kVFvTLzKFSkA8wyQ=;
 b=+p79y9jGgbIVFS386LZQ8TkpJw4rRZgJWWo3ICGeMWt4e0bJeMPjAC6VRl6QTmGaCgn2g/1VP
 cV9D94y/SBoCd72D6wrP7Yf32Xp2wJV04pR88bAa2zcbbYTaNO7Iofm
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Habidere,

The Rockchip RK3588 features two MIPI CSI-2 DPHYs (not to be confused with
the two combo MIPI DSI/CSI CPHY/DPHY blocks). The CSI-2 DPHYs can be
supported using the existing phy-rockchip-inno-csidphy driver, the notable
differences being
 - the control bits in the GRF
 - the additional reset line
This patch series adds support for this variant.

As you may have guessed, this is part of the efforts to bring the support
for the RK3588 Video Capture (VICAP) unit mainline.

Looking forward to your comments!

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
Michael Riesch (5):
      dt-bindings: soc: rockchip: add rk3588 csidphy grf syscon
      dt-bindings: phy: rockchip-inno-csi-dphy: add rk3588 variant
      phy: rockchip: phy-rockchip-inno-csidphy: allow writes to grf register 0
      phy: rockchip: phy-rockchip-inno-csidphy: add support for rk3588 variant
      arm64: dts: rockchip: add mipi csi-2 dphy nodes to rk3588

 .../bindings/phy/rockchip-inno-csi-dphy.yaml       | 60 ++++++++++++++++++++--
 .../devicetree/bindings/soc/rockchip/grf.yaml      |  1 +
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      | 31 +++++++++++
 drivers/phy/rockchip/phy-rockchip-inno-csidphy.c   | 28 ++++++++--
 4 files changed, 112 insertions(+), 8 deletions(-)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250616-rk3588-csi-dphy-c9ed2ad4cd9f

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

