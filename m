From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:53 +0100
Subject: [PATCH RFC v4 11/15] MAINTAINERS: Add NXP S32G SerDes entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-11-3bfe0589be8d@oss.nxp.com>
References: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
In-Reply-To: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
To: Vincent Guittot <vincent.guittot@linaro.org>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bogdan Hamciuc <bogdan.hamciuc@nxp.com>, 
 Ionut Vicovan <ionut.vicovan@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=1513;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=86svSsXyW7XbXvUHtBhNIUJ9Mfx/TitxfATul2iPoAs=;
 b=Gn3XzjwMZOtGZ1tpGqksVlxXFvvg/WVPIMYMlFPNjKYIjT+/z53UTUVfoAcEhSfLFZO4pJrFP
 rnLdd3g1YLCBeMxaKmPQkCpeiJ+E+6Aemr9FWq/nclrrZL9SVwY4VL1
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vincent Guittot <vincent.guittot@linaro.org>

Add an entry for the S32G SerDes PHY driver, the S32G XPCS glue, the
S32G part of pcs-xpcs, their headers and the SerDes binding. netdev is
listed because the PCS code lives in drivers/net/pcs/.

Signed-off-by: Vincent Guittot <vincent.guittot@linaro.org>
[jan.petrous: dropped the shared core entry along with the core]
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 MAINTAINERS | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 742c4e6b291f..cb465ba42d73 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -3449,6 +3449,22 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/pci/nxp,s32g-pcie.yaml
 F:	drivers/pci/controller/dwc/pcie-nxp-s32g*
 
+ARM/NXP S32G SERDES DRIVER
+M:	Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>
+M:	Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>
+M:	Jan Petrous <jan.petrous@oss.nxp.com>
+R:	NXP S32 Linux Team <s32@nxp.com>
+L:	linux-arm-kernel@lists.infradead.org (moderated for non-subscribers)
+L:	linux-phy@lists.infradead.org
+L:	netdev@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/phy/nxp,s32g-serdes.yaml
+F:	drivers/net/pcs/pcs-nxp-s32g-xpcs.c
+F:	drivers/net/pcs/pcs-xpcs-s32g.c
+F:	drivers/phy/freescale/phy-nxp-s32g-serdes.c
+F:	include/linux/pcs/pcs-nxp-s32g-xpcs.h
+F:	include/linux/phy/nxp-s32g-serdes.h
+
 ARM/NXP S32G/S32R DWMAC ETHERNET DRIVER
 M:	Jan Petrous <jan.petrous@oss.nxp.com>
 R:	s32@nxp.com

-- 
2.55.0

