From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:44 +0100
Subject: [PATCH RFC v4 02/15] dt-bindings: net: nxp,s32-dwmac: Document
 pcs-handle
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-2-3bfe0589be8d@oss.nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=2480;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=XvSbxkQlAkTxdnIVmZ2WLc0f8gwakCGU+LGgQcKuPyU=;
 b=WRCaqxowpj4b59FfSwGMljIDNOKr0FtOfHQsD8XUEWyRyPDGaq00tpV/gVejjd7NuOoZWsm0T
 iZvcnn4B57hDVUU7GaEoD50g4JIwpPIsrH2dooqiKY7mepjIXU9ypx2
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With SGMII, the PCS is one of the SerDes XPCS instances. The MAC
references its SerDes lane through phys, with the lane, the PHY type,
the XPCS instance and the highest speed in the argument cells, and the
SerDes node that provides the PCS through pcs-handle.

The pcs-handle type comes from ethernet-controller.yaml. Only
maxItems: 1 is added, as the MAC has a single PCS.

phy-mode "sgmii" requires both properties, and each of them requires
the other.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 .../devicetree/bindings/net/nxp,s32-dwmac.yaml     | 30 +++++++++++++++++++++-
 1 file changed, 29 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/net/nxp,s32-dwmac.yaml b/Documentation/devicetree/bindings/net/nxp,s32-dwmac.yaml
index fcad2274302d..219a033b889d 100644
--- a/Documentation/devicetree/bindings/net/nxp,s32-dwmac.yaml
+++ b/Documentation/devicetree/bindings/net/nxp,s32-dwmac.yaml
@@ -15,7 +15,8 @@ description:
   The SoC series S32G2xx and S32G3xx feature one DWMAC instance,
   the SoC S32R45 has two instances. The devices can use RGMII/RMII/MII
   interface over Pinctrl device or the output can be routed
-  to the embedded SerDes for SGMII connectivity.
+  to the embedded SerDes for SGMII connectivity, in which case the
+  SerDes lane is referenced via phys and the PCS via pcs-handle.
   The DWMAC instances have connected all RX/TX queues interrupts,
   enabling load balancing of data traffic across all CPU cores.
 
@@ -81,6 +82,19 @@ properties:
       - const: rx
       - const: ptp_ref
 
+  pcs-handle:
+    maxItems: 1
+    description:
+      phandle pointing to the SerDes node that provides the SGMII PCS for
+      this MAC. See
+      Documentation/devicetree/bindings/phy/nxp,s32g-serdes.yaml.
+
+  phys:
+    maxItems: 1
+    description:
+      The SerDes lane that carries the SGMII link, with the lane, the PHY
+      type, the XPCS instance and the highest speed in the argument cells.
+
   power-domains:
     maxItems: 1
 
@@ -88,8 +102,22 @@ required:
   - clocks
   - clock-names
 
+dependentRequired:
+  pcs-handle: [ phys ]
+  phys: [ pcs-handle ]
+
 allOf:
   - $ref: snps,dwmac.yaml#
+  - if:
+      properties:
+        phy-mode:
+          const: sgmii
+      required:
+        - phy-mode
+    then:
+      required:
+        - pcs-handle
+        - phys
 
 unevaluatedProperties: false
 

-- 
2.55.0

