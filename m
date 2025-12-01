From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v2 0/3] arm64: dts: freescale: moduline-display: several
 fixes
Date: Mon, 01 Dec 2025 12:56:49 +0100
Message-Id: <20251201-disp_fix-v2-0-9b03026311b6@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIGCLWkC/22MQQqDMBAAvyJ7bkqy1VJ78h9FStxEXbCJJBJaJ
 H9v6rnHGYbZIdrANsK92iHYxJG9K4CnCmjWbrKCTWFAiY1SqhaG4/oc+S2QWmkujR6kMVDyNdi
 ij9WjLzxz3Hz4HOekfvbPJCkhRd3SYG941SNhN3nybgt+Wc7kX9DnnL+wsV6dpQAAAA==
X-Change-ID: 20251114-disp_fix-2c90d35ab0dd
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764590218; l=1188;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=zMdqW7g2CzgociwT59QgF/DC0rtiRYU2cHrE8GIJF7E=;
 b=CdE/3itTq3j2lcjVA+F8qWr9BwrHdPT4FBmvCbbfte91Ze+IVMe/UCWb1b7nVKhrM8k4Z+sfR
 tuEqVZusKWkBN90xi2u+5ZuiiHi5EtKmm5HQCWx4920Mh3QtQ6fLAJY
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A couple of issues where discovered:
- compatibles should integrate the SoM
- the eqos mac address is stored in eth_mac1

The first one is breaking, but it is early enough that it can be
corrected without causing any issues.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Changes in v2:
- re-add the old compatible to fsl.yaml
- expand the reasoning for these changes in the commit messages
- Link to v1: https://lore.kernel.org/r/20251114-disp_fix-v1-0-49cbe826afc2@gocontroll.com

---
Maud Spierings (3):
      dt-bindings: arm: fsl: moduline-display: fix compatible
      arm64: dts: freescale: moduline-display: fix compatible
      arm64: dts: freescale: tx8p-ml81: fix eqos nvmem-cells

 Documentation/devicetree/bindings/arm/fsl.yaml                   | 9 ++++++++-
 .../boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts | 2 +-
 arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi              | 5 +++++
 3 files changed, 14 insertions(+), 2 deletions(-)
---
base-commit: 0f2995693867bfb26197b117cd55624ddc57582f
change-id: 20251114-disp_fix-2c90d35ab0dd

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

