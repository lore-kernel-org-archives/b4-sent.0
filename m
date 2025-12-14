From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Subject: [PATCH RFC 0/4] Support multi-channel IRQs in stmmac platform
 drivers
Date: Sun, 14 Dec 2025 23:15:36 +0100
Message-Id: <20251214-dwmac_multi_irq-v1-0-36562ab0e9f7@oss.nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAg3P2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDIwNL3ZTy3MTk+NzSnJLM+MyiQl3LFIs0MwMTM6PkZEMloK6CotS0zAq
 widFKQW7OSrG1tQC+VpqgZgAAAA==
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
 Conor Dooley <conor+dt@kernel.org>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, devicetree@vger.kernel.org, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765750551; l=4064;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=eoWq0R056rv6qFunXhkW+ex9LyETDs54864ThvZUEN0=;
 b=2gQIU5wXxSZN34/wa2M1NFfbZH0jsb3PuTqiNgL/E7P0BbaWTcjdieFbbA7UU7kR4LeCpMq6i
 XH6Jmr1v0jWAEEMu9tEhHckAVlKp6UMi8B3z0/Ksqx3lOIILWxGtVh4
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The stmmac core supports two interrupt modes, controlled by the
flag STMMAC_FLAG_MULTI_MSI_EN.
- When the flag is set, the driver uses multi-channel IRQ mode (multi-IRQ).
- Otherwise, a single IRQ line is requested:

static int stmmac_request_irq(struct net_device *dev)
{
        /* Request the IRQ lines */
        if (priv->plat->flags & STMMAC_FLAG_MULTI_MSI_EN)
                ret = stmmac_request_irq_multi_msi(dev);
        else
                ret = stmmac_request_irq_single(dev);
}

At present, only PCI drivers (Intel and Loongson) make use of the multi-IRQ
mode. This concept can be extended to DT-based embedded glue drivers
(dwmac-xxx.c).

This series adds support for reading per-channel IRQs from the DT node and
reuses the existing STMMAC_FLAG_MULTI_MSI_EN flag to enable multi-IRQ
operation in platform drivers.

NXP S32G2/S32G3/S32R SoCs integrate the DWMAC IP with multi-channel
interrupt support. The dwmac-s32.c driver change is provided as an example of
enabling multi-IRQ mode for non-PCI drivers.

An open question remains: should platform drivers support both single-IRQ
and multi-IRQ modes, or should multi-IRQ be required with the DT node
specifying all channel interrupts? The current RFC implementation follows
the latter approach — dwmac-s32 requires IRQs to be defined for all
channels.

So, when the glue driver has set the flag, but the corresponding DT node
has not expanded 'interrupts' property accordingly, the driver init
fails with the following error:

[4.925420] s32-dwmac 4033c000.ethernet eth0: stmmac_request_irq_multi_msi: alloc rx-0  MSI -6 (error: -22)

When correctly set, the assigned IRQs can be visible
in /proc/interrupts:

root@s32g399aevb3:~# grep eth /proc/interrupts
 29:          0          0          0          0          0          0          0          0    GICv3  89 Level     eth0:mac
 30:          0          0          0          0          0          0          0          0    GICv3  91 Level     eth0:rx-0
 31:          0          0          0          0          0          0          0          0    GICv3  93 Level     eth0:rx-1
 32:          0          0          0          0          0          0          0          0    GICv3  95 Level     eth0:rx-2
 33:          0          0          0          0          0          0          0          0    GICv3  97 Level     eth0:rx-3
 34:          0          0          0          0          0          0          0          0    GICv3  99 Level     eth0:rx-4
 35:          0          0          0          0          0          0          0          0    GICv3  90 Level     eth0:tx-0
 36:          0          0          0          0          0          0          0          0    GICv3  92 Level     eth0:tx-1
 37:          0          0          0          0          0          0          0          0    GICv3  94 Level     eth0:tx-2
 38:          0          0          0          0          0          0          0          0    GICv3  96 Level     eth0:tx-3
 39:          0          0          0          0          0          0          0          0    GICv3  98 Level     eth0:tx-4

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
Jan Petrous (OSS) (4):
      net: stmmac: platform: read channels irq
      dt-bindings: net: nxp,s32-dwmac: Declare per-queue interrupts
      arm64: dts: s32: set Ethernet channel irqs
      stmmac: s32: enable multi irqs mode

 .../devicetree/bindings/net/nxp,s32-dwmac.yaml     | 40 +++++++++++++++++++---
 arch/arm64/boot/dts/freescale/s32g2.dtsi           | 24 +++++++++++--
 arch/arm64/boot/dts/freescale/s32g3.dtsi           | 24 +++++++++++--
 drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c    |  3 +-
 .../net/ethernet/stmicro/stmmac/stmmac_platform.c  | 38 +++++++++++++++++++-
 5 files changed, 119 insertions(+), 10 deletions(-)
---
base-commit: cb015814f8b6eebcbb8e46e111d108892c5e6821
change-id: 20251209-dwmac_multi_irq-9d8f60462cc1

Best regards,
-- 
Jan Petrous (OSS) <jan.petrous@oss.nxp.com>

