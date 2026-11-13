From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/9] RK3588: Enable the PHP SMMU
Date: Fri, 13 Nov 2026 16:38:46 +0000
Message-Id: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/z2N0W4CIRBFf2XDc6dhQDBsTON/GB8GGJSmKF12T
 RPjv5fVpm9zkjvn3EXjKXMT43AXE99yy9dLB3wbRDjT5cSQY2ehpLKIqKGUxUoJ9VxBartNvE1
 opRP9oU6c8s9Tdji+uC3+k8O8Gv4WE38vvTK/ZqJwa/SsjMPuP9J6BW4aasgMNa6nBO3Yb5JDZ
 5Tbnwrlr/dwLR+r11Nj6FDyPA5BeyI2CQmN3ZgQI8XglXfkY+RkYlIOk3Hi+Hj8Aj6BXwAAAQA
 A
X-Change-ID: 20261113-mmu600-php-0367fe7f1609
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>, Serge Semin <fancer.lancer@gmail.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org, 
 Pranjal Shrivastava <praan@google.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, iommu@lists.linux.dev, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587927; l=2938;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Jmo5oZh4/PhZlA1l9HdDGiyc/oiQRtE0uFFYTpbR1r8=;
 b=LclplOwvlOIHkFOlOW5OQnvIF078toyrzCc0cl4+5/NgniHUdg1bY9c9ymu8UBH1xAs51lm01
 A+/isLOIibdBFDd0lHBhlsHMVBXeTuzftGlgXghFJ5QxBCWx6E4SoAH
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 PHP SMMU (MMU600_PHP) is disabled because nothing programs
the StreamIDs of its masters (GMAC0/1, SATA0-2, USB3OTG_2) in the PHP
GRF. Program them, attach the masters and enable the SMMU.

Shawn Lin asked whether mmu600_php should be enabled too; Heiko asked
for the same handling as the PCIe SMMU [3].

Patch 7 needs [1]. Please hold the last patch until [2] is merged:
PD_PHP is off in deep suspend and the SMMU resumes in bypass (GBPA read
as 0).

Tested on an Orange Pi 5 (RK3588S), 7.3-based with [2] (my Tested-by
is [4]):
- SATA0 root, GMAC1 and a USB3 disk translated: 1 GiB sha256-checked
  on each; three reboots; no SMMU events or bus errors;
- deep suspend 3/3 with all three translated; s2idle 3/3 with USB3OTG_2
  and GMAC1. TF-A v2.15 kept the StreamIDs; patch 6 restored six zeroed
  for the test (pm_test=core).
Not tested: GMAC0, SATA1/2, the series without [2], the reset (no
driver uses it).

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/r/20261113-smmu-v3-pcie-pd-v3-0-39eb4f919529@gmail.com
[2] https://lore.kernel.org/r/20260929034510.2023173-1-praan@google.com
[3] https://lore.kernel.org/r/9_7qTfdNSViwtNUGq9D13w@sntech.de
[4] https://lore.kernel.org/r/179455903885.2418534.14656921897583011972@gmail.com

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (9):
      dt-bindings: net: rockchip-dwmac: Allow iommus
      dt-bindings: ata: rockchip,dwc-ahci: Allow iommus
      dt-bindings: soc: rockchip: grf: Allow a clock for the RK3588 PHP GRF
      soc: rockchip: grf: Assign the StreamIDs of the RK3588 PHP SMMU masters
      arm64: dts: rockchip: Add the PHP GRF clock on RK3588
      soc: rockchip: grf: Restore the RK3588 PHP StreamIDs after system suspend
      arm64: dts: rockchip: Add the clock and reset of the RK3588 PHP SMMU
      arm64: dts: rockchip: Attach the masters of the RK3588 PHP SMMU
      arm64: dts: rockchip: Enable the RK3588 PHP SMMU

 .../devicetree/bindings/ata/rockchip,dwc-ahci.yaml |   3 +
 .../devicetree/bindings/net/rockchip-dwmac.yaml    |   3 +
 .../devicetree/bindings/soc/rockchip/grf.yaml      |  12 ++-
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      |   8 +-
 arch/arm64/boot/dts/rockchip/rk3588-extra.dtsi     |   2 +
 drivers/soc/rockchip/grf.c                         | 103 +++++++++++++++++++++
 6 files changed, 128 insertions(+), 3 deletions(-)
---
base-commit: c3baae5f1a15645cddadcb2b9abddef5df291f59
change-id: 20261113-mmu600-php-0367fe7f1609
prerequisite-message-id: <20261113-smmu-v3-pcie-pd-v3-0-39eb4f919529@gmail.com>
prerequisite-patch-id: 51134fb38514fa92f20d3831e7905b02c7fbaae6
prerequisite-patch-id: c59ab0be12ec964dc1698dfa3e0d5bfae82d0c54
prerequisite-patch-id: 845e9980a7e0de45c746b7d8b6fd439033e08fdd

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

