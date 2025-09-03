From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH v4 0/7] phy: rockchip: phy-rockchip-inno-csidphy: add
 support for rk3588 variant
Date: Wed, 03 Sep 2025 19:04:48 +0200
Message-Id: <20250616-rk3588-csi-dphy-v4-0-a4f340a7f0cf@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADB1uGgC/4XNTQ7CIBCG4as0rMXw10JdeQ/jAgawRC0NmMam6
 d2lXRpNl++XzDMzyi4Fl9GpmlFyY8gh9iXEoULQ6f7mcLClESOsJg1tcLrzWikMOWA7dBOG1lm
 mrQDbelSuhuR8eG/i5Vq6C/kV07Q9GOm6/rdGiglWwhlumJa8gTPEx0ObmPQR4hOt3sh2DFYMq
 VvhiWyNpOyXwXcMXgxdA9jaUy+4+jaWZfkApc8QXjoBAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Vinod Koul <vkoul@kernel.org>, Kishon Vijay Abraham I <kishon@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Jagan Teki <jagan@amarulasolutions.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Diederik de Haas <didi.debian@cknow.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Collabora Kernel Team <kernel@collabora.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, 
 Michael Riesch <michael.riesch@collabora.com>, stable@kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756919100; l=2751;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=Sp1oVh07PV5J1vHgtpAOsZp9J99yIuyi/v/VuN5rhXY=;
 b=6NCRuBLPC+EN/UwAOUVq62wlOgaZhr5BntQTg7A08B7KaV3CqcIuHyxpxS4zRDkiBeOAmpxWv
 CdsHYjMsTyWAa8YaBkBU/u+ViTzmhn/1Z4nhnjnBDbcw7n9svQkPeKq
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
Changes in v4:
- fixed commit message "false negatives" -> "false positives"
- fixed mipi csi dphy node addition -> mipidcphy1 remains as-is now
- moved allOf: block after required: block (Krzysztof)
- added remark w.r.t. the description of the original reset (Krzysztof)
- name of the new reset remains "phy" as I didn't find any better
  name. Suggestions welcome! (Krzysztof)
- Link to v3: https://lore.kernel.org/r/20250616-rk3588-csi-dphy-v3-0-a5ccd5f1f438@collabora.com

Changes in v3:
- added if:then: for required 'power-domains' (Krzysztof)
- fixed restriction of resets/reset-names (Rob)
- Link to v2: https://lore.kernel.org/r/20250616-rk3588-csi-dphy-v2-0-7a94f079b712@collabora.com

Changes in v2:
- rebased onto v6.17-rc1
- added patch that makes 'power-domains' non-required (Diederik)
- added patch that allows for different sets of resets (Neil)
- introduced name for additional reset line (Neil)
- fixed example in bindings (Rob, Diederik)
- Link to v1: https://lore.kernel.org/r/20250616-rk3588-csi-dphy-v1-0-84eb3b2a736c@collabora.com

---
Michael Riesch (7):
      dt-bindings: soc: rockchip: add rk3588 csidphy grf syscon
      dt-bindings: phy: rockchip-inno-csi-dphy: make power-domains non-required
      dt-bindings: phy: rockchip-inno-csi-dphy: add rk3588 variant
      phy: rockchip: phy-rockchip-inno-csidphy: allow writes to grf register 0
      phy: rockchip: phy-rockchip-inno-csidphy: allow for different reset lines
      phy: rockchip: phy-rockchip-inno-csidphy: add support for rk3588 variant
      arm64: dts: rockchip: add mipi csi-2 dphy nodes to rk3588

 .../bindings/phy/rockchip-inno-csi-dphy.yaml       | 65 ++++++++++++++++++++-
 .../devicetree/bindings/soc/rockchip/grf.yaml      |  1 +
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      | 34 +++++++++++
 drivers/phy/rockchip/phy-rockchip-inno-csidphy.c   | 67 ++++++++++++++++++++--
 4 files changed, 159 insertions(+), 8 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250616-rk3588-csi-dphy-c9ed2ad4cd9f

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

