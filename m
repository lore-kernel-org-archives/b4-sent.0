From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Subject: [PATCH v8 0/5] Support multi-channel IRQs in stmmac platform
 drivers
Date: Mon, 09 Mar 2026 18:55:19 +0100
Message-Id: <20260309-dwmac_multi_irq-v8-0-f0cc5bc811a7@oss.nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIcJr2kC/23OTU7DMBAF4KtUXpPKHv/EZsU9EKrsiYdaIkmJS
 yiqcnecCkSEu3wjzffeleU4pZjZ4+7KpjinnMahBPuwY3j0w2tsUlcyAw5aAHdN99l7PPQfb+d
 0SNN74zpLhisDiIKVr9MUKV1u4vNLyceUz+P0dSuYxXr9sYSqrFk0vJFGG/CBR0ft05jzfric9
 jj2bNVm+BUML0QtwCoECw4k73grakFuBVkLsgiIWhKEaJ25I6itYGtBFcECeakICQhqQf8JcG+
 DXgVC45zX5FHVgtkKuhZMEUDpQKJrheBYC+1WMLXQFoEsRRlcccK/DcuyfAPZFtL2PAIAAA==
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, devicetree@vger.kernel.org, rmk+kernel@armlinux.org.uk, 
 vladimir.oltean@nxp.com, boon.khai.ng@altera.com, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773078934; l=4408;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=sO07tyz0BnpKMjr6r5zLC5D/8i7eRB8tzHj5WeTMKes=;
 b=NURN8/QYSkqZZLXj1aloeoq7dAWoFo23M83WY9RoJyTaWJ1j7RSIIEnqdCkP3VT93JzWQx/Gc
 Gv1qF9SmuskDN1y66NyEVStxKrIORy85uaDpHu98clRdx7RAg2WBBhF
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The stmmac core supports two interrupt modes, controlled by the
flag STMMAC_FLAG_MULTI_MSI_EN:

- When the flag is set, the driver uses multi-channel IRQ mode (Multi-IRQ).
- Otherwise, a single IRQ line is requested (aka MAC-IRQ):

static int stmmac_request_irq(struct net_device *dev)
{
        /* Request the IRQ lines */
        if (priv->plat->flags & STMMAC_FLAG_MULTI_MSI_EN)
                ret = stmmac_request_irq_multi_msi(dev);
        else
                ret = stmmac_request_irq_single(dev);
}

At present, only PCI drivers (Intel and Loongson) make use of the Multi-IRQ
mode. This concept can be extended to DT-based embedded glue drivers
(dwmac-xxx.c).

This series adds support for reading per-channel IRQs from the DT node and
reuses the existing STMMAC_FLAG_MULTI_MSI_EN flag to enable multi-IRQ
operation in platform drivers.

The final decision if Multi-IRQ gets enabled remains on glue driver
to allow implementing any reguirements/limitions the focused platform
needs.

NXP S32G2/S32G3/S32R SoCs integrate the DWMAC IP with multi-channel
interrupt support. The dwmac-s32.c driver change is provided as an example of
enabling multi-IRQ mode for non-PCI drivers.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
Changes in v8:
- Rewritten queue irq getter, based on Russell's (ready-to-use) hint
- Renamed s32_gmac_validate_multi_irq() to s32_gmac_setup_multi_irq() to
  better describe the functionality
- Fixed typo in commit message for patch 5
- Renamed label in patch 5 to make it more descriptive
- Link to v7: https://lore.kernel.org/r/20260226-dwmac_multi_irq-v7-0-f8fe3b945bb4@oss.nxp.com

Changes in v7:
- Optimized 2 similar loops on queue rx/tx irq reading
- Swap the yaml and dts patches with hope it fix dt_binding_check failing
- Link to v6: https://lore.kernel.org/r/20260225-dwmac_multi_irq-v6-0-245bf1d7110c@oss.nxp.com

Changes in v6:
- Added 2 mintainers which were not covered by 'b4 prep --auto-to-cc'
  but complained on patchwork check
- Added helper macro for loop over queue-based arrays (inspired by AI
  review)
- Added full validation on all channel IRQs
- Link to v5: https://lore.kernel.org/r/20260223-dwmac_multi_irq-v5-0-8fc699a5fac4@oss.nxp.com

Changes in v5:
- fixed typo in "symetrical"
- cleaned negative return value on platform_get_irq_byname_optional()
  in stmmac_get_platform_resources()
- rebased on v7.0-rc1
- Link to v4: https://lore.kernel.org/r/20260128-dwmac_multi_irq-v4-0-82fa34fcf2f2@oss.nxp.com

Changes in v4:
- Fixed IRQ reading check
- Made cleaner the IRQ validity (to get AI reviewer happy)
- Fixed minItems of interrupts property in yaml
- Link to v3: https://lore.kernel.org/r/20260123-dwmac_multi_irq-v3-0-cc53f2be8961@oss.nxp.com

Changes in v3:
- removed RFC prefix
- rebased on v6.19-rc6
- fixed forgotten extra line setting to Multi-IRQ unconditionally
- fixed yaml
- Link to v2: https://lore.kernel.org/r/20260121-dwmac_multi_irq-v2-0-3b829230d071@oss.nxp.com

Changes in v2:
- Fixed incorrect buffer len for 'rx-queue-%d' property check
- Added backward compatibility to not break old settings
- Fixed DT example in yaml
- Link to v1: https://lore.kernel.org/r/20251214-dwmac_multi_irq-v1-0-36562ab0e9f7@oss.nxp.com

---
Jan Petrous (OSS) (5):
      net: stmmac: Use helper macro for loop over queue-based arrays
      net: stmmac: platform: read channels irq
      arm64: dts: s32: set Ethernet channel irqs
      dt-bindings: net: nxp,s32-dwmac: Declare per-queue interrupts
      stmmac: s32: enable support for Multi-IRQ mode

 .../devicetree/bindings/net/nxp,s32-dwmac.yaml     | 44 +++++++++++++++--
 arch/arm64/boot/dts/freescale/s32g2.dtsi           | 26 ++++++++--
 arch/arm64/boot/dts/freescale/s32g3.dtsi           | 26 ++++++++--
 drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c    | 36 +++++++++++++-
 .../net/ethernet/stmicro/stmmac/dwxgmac2_core.c    |  2 +-
 drivers/net/ethernet/stmicro/stmmac/stmmac.h       |  3 ++
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c  | 16 +++---
 .../net/ethernet/stmicro/stmmac/stmmac_platform.c  | 57 +++++++++++++++++++++-
 8 files changed, 188 insertions(+), 22 deletions(-)
---
base-commit: 6de23f81a5e08be8fbf5e8d7e9febc72a5b5f27f
change-id: 20251209-dwmac_multi_irq-9d8f60462cc1

Best regards,
-- 
Jan Petrous (OSS) <jan.petrous@oss.nxp.com>

