From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH 0/3] soc: cortina: Add CS7542 shared gates and reset
 domains
Date: Tue, 24 Nov 2026 00:50:57 +0300
Message-Id: <20261124-b4-cs7542-global-controls-v1-0-12548785df2c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/zWOSW7DMBAEvyLwHAbiIonWyf8wfJgZDWUGWhKOb
 CQw/PfQ27GB7uq6KuGcWFRfXVXmS5K0LiWYj0rRCZaRdRpKVra2rTHWa/SapGu81eO0Ikya1mX
 L6ySavXeEgJGDVWX/nTmm3wf7cHxmOeMX03YHvhqZf87ldHvWFIJwIc5z2voKW9hFcJ7Ym9ARt
 rvBURMCeMQYyRniZsAQ76iZReBh21cvV/cWlT8pkvridK2joboD09Uuhv04Q5o+y5063m7/3tA
 fLgsBAAA=
X-Change-ID: 20261124-b4-cs7542-global-controls-e443cbabfe82
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795470657; l=3632;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=oWwEGHbvb0LFq8Gwa0S1Oy8KMPiFJPQoiptcl7pgoU4=;
 b=yIq+dxLdfFEletCfSzHbkgBFAvZw9FdhHtkrme/yaAI1obYfBq3IaTyySKRj2cYNP3GCwjZS9
 Kx70zwC4m6kDotVXQUXBQ51uUBsdhShNfmYG6yeLT2rhZdTwiGTX/hC
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CS7542 global block contains PCIe clock gates and controller resets,
and a composite network engine reset. Publish these controls together
through the existing early global provider, so PCIe and Ethernet can use
the same provider without either consumer depending on the other driver.
This also avoids a resource-less network reset child node.

This series extracts the global controls from PCIe v2 and moves the NE
reset implementation from Ethernet v1 to that same provider. PCIe reset
indices 0..2 and clock indices 3..5 remain unchanged; the network engine
uses reset index 3. The NE domain includes the entire DMA-LSO/SSP block
and excludes SDRAM. Its consumer must own the domain exclusively.

The existing NE assert/deassert readback polling and partial-domain error
handling are retained. The new NE reset index does not support pulse
reset; its consumer uses assert/deassert/status. PCIe pulse timing and
registration error cleanup are retained. Clock-only DTs remain valid.

This is based on the posted clock/pinctrl v3 series:
https://lore.kernel.org/all/20261123-cs7542-syscon-v3-0-f1c07a1703f8@gmail.com/

The next PCIe and Ethernet revisions will remove their duplicate provider
patches and use this prerequisite. They do not need a dependency on one
another. Board DTS changes are prepared separately.

Validation completed so far: full independent ARM multi_v7 vmlinux and
modules with W=1, COMPILE_TEST=n and no pending platform series; binding
examples and complete integrated board DT validation; actual-source
fault tests covering gates, resets, partial NE masks, polling timeouts,
regmap errors and registration cleanup (736 cases/106098 assertions).
On Almond+ with the moved provider in a Linux RAM kernel, checked all
six clocks, NE assert/deassert/status and unrelated global-register
preservation, real factory MAC probing and two Ethernet load/unload
cycles. A second exclusive reset acquisition correctly returned EBUSY
while the datapath was bound. After unload the entire NE domain was
held in reset. All six PCIe devices and root-port MSI remained present
throughout, and MDIO read/write/induced-timeout recovery checks passed.
The test partitions were read-only; no flash writes were performed.
The board returned automatically to the installed OpenWrt.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
Fil Dunsky (3):
      dt-bindings: soc: Describe CS7542 global gates and reset domains
      clk: cs7542: Add global PCIe controls and network engine reset
      MAINTAINERS: Track CS7542 global reset specifiers

 .../soc/cortina/cortina,cs7542-syscon.yaml         |  14 +-
 MAINTAINERS                                        |   1 +
 drivers/clk/Kconfig                                |   7 +-
 drivers/clk/clk-cs7542.c                           | 211 +++++++++++++++++++--
 include/dt-bindings/clock/cortina,cs7542-clock.h   |   4 +
 include/dt-bindings/reset/cortina,cs7542-reset.h   |  12 ++
 6 files changed, 224 insertions(+), 25 deletions(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261124-b4-cs7542-global-controls-e443cbabfe82
prerequisite-message-id: 20261123-cs7542-syscon-v3-0-f1c07a1703f8@gmail.com
prerequisite-patch-id: 083c8eb9fa3b09678418ed19c0dd275afd66ae1f
prerequisite-patch-id: 746951fd830617cad03b52208443a8b6f7e8f440
prerequisite-patch-id: f8a2ba71717f71ca2bedda986f8b861995cdc586
prerequisite-patch-id: 7fbe9405265ef3d1ec62811415a46c0061afd7c8
prerequisite-patch-id: 25220835f5d2506a01ba652d86f9b9ac3ad5121a

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

