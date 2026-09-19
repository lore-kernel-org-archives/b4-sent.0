From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sat, 19 Sep 2026 08:54:30 +0200
Subject: [PATCH RFC v3 02/12] dt-bindings: net: nxp,s32-dwmac: Document
 pcs-handle
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-s32g_serdes-v3-2-9d68868c1e89@oss.nxp.com>
References: <20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com>
In-Reply-To: <20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com>
To: Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Magnus Damm <magnus.damm@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Bogdan Hamciuc <bogdan.hamciuc@nxp.com>, 
 Ionut Vicovan <ionut.vicovan@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Clark Wang <xiaoning.wang@nxp.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-renesas-soc@vger.kernel.org, 
 imx@lists.linux.dev, linux-pci@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789800879; l=1921;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=Slo0j2nguHWzRpXyMDnZyPP6ZRovyd2ENG76AQ6nmBk=;
 b=cHFaVf8g3n63N2VUjwi4/XAIkgWpQTh/zlBac/Vo5OQRZtlxgrBauA10q5LsBCCd4hxWrLn/J
 SHJzaPdCFbyA/3QxIQSwaBfGk8ITzF34VbhDFNK7DJIpv5MJypFw4l9
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the MAC output is routed to the embedded SerDes for SGMII, the PCS
is one of the SerDes XPCS instances. Document that it is referenced
through the standard pcs-handle property defined by
ethernet-controller.yaml, pointing at the SerDes XPCS lane child node.

The type already comes from the ethernet-controller.yaml reference in
the schema chain; this only records the intent, the same way
renesas,rzn1-gmac.yaml does.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 Documentation/devicetree/bindings/net/nxp,s32-dwmac.yaml | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/net/nxp,s32-dwmac.yaml b/Documentation/devicetree/bindings/net/nxp,s32-dwmac.yaml
index 753a04941659..b168decb540c 100644
--- a/Documentation/devicetree/bindings/net/nxp,s32-dwmac.yaml
+++ b/Documentation/devicetree/bindings/net/nxp,s32-dwmac.yaml
@@ -15,7 +15,8 @@ description:
   The SoC series S32G2xx and S32G3xx feature one DWMAC instance,
   the SoC S32R45 has two instances. The devices can use RGMII/RMII/MII
   interface over Pinctrl device or the output can be routed
-  to the embedded SerDes for SGMII connectivity.
+  to the embedded SerDes for SGMII connectivity, in which case the
+  SerDes XPCS lane acting as the PCS is referenced via pcs-handle.
   The DWMAC instances have connected all RX/TX queues interrupts,
   enabling load balancing of data traffic across all CPU cores.
 
@@ -81,6 +82,14 @@ properties:
       - const: rx
       - const: ptp_ref
 
+  pcs-handle:
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+    maxItems: 1
+    description:
+      phandle pointing to the SerDes XPCS lane child node that provides
+      the SGMII PCS for this MAC. See
+      Documentation/devicetree/bindings/phy/nxp,s32g-serdes.yaml.
+
 required:
   - clocks
   - clock-names

-- 
2.55.0

