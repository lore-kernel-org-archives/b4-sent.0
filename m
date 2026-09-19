From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sat, 19 Sep 2026 08:54:31 +0200
Subject: [PATCH RFC v3 03/12] dt-bindings: PCI: nxp,s32g-pcie: Fix SerDes
 PHY phandle in example
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-s32g_serdes-v3-3-9d68868c1e89@oss.nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789800879; l=1567;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=Na+zOsB+scHEU/5Sa34th6CSnJzMvXvCSt2p2AdpCXQ=;
 b=/FnXnC/g0lwE3bBZfsHmeuSK3HZ8ktdkgjTKjNTxtKu0Q/fQ5SAhUZEF4Nb9zaMQU4VnaVGa6
 SLEjPNq1l4hASGuJYsX8216FYqHW50IOjDFp9fLyn7qYumfxSZVSywN
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The example references the SerDes PHY as

  phys = <&serdes0 PHY_TYPE_PCIE 0 0>;

i.e. the SerDes node itself with three PHY cells. That does not match
the SerDes binding: the per-lane child node is the generic PHY
provider and carries '#phy-cells = <0>', while the SerDes node itself
has no '#phy-cells' at all.

Point the example at the PCIe lane child instead, which is also what
the S32G3 board device trees use. The dt-bindings/phy/phy.h include is
dropped along with the now-unused PHY_TYPE_PCIE constant.

The schema itself is unchanged; 'phys: maxItems: 1' already describes
the corrected form.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 Documentation/devicetree/bindings/pci/nxp,s32g-pcie.yaml | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/pci/nxp,s32g-pcie.yaml b/Documentation/devicetree/bindings/pci/nxp,s32g-pcie.yaml
index 66a050028278..29323e50bd8b 100644
--- a/Documentation/devicetree/bindings/pci/nxp,s32g-pcie.yaml
+++ b/Documentation/devicetree/bindings/pci/nxp,s32g-pcie.yaml
@@ -82,7 +82,6 @@ unevaluatedProperties: false
 examples:
   - |
     #include <dt-bindings/interrupt-controller/arm-gic.h>
-    #include <dt-bindings/phy/phy.h>
 
     bus {
         #address-cells = <2>;
@@ -124,7 +123,7 @@ examples:
                 ranges;
 
                 device_type = "pci";
-                phys = <&serdes0 PHY_TYPE_PCIE 0 0>;
+                phys = <&serdes0_pcie0>;
             };
         };
     };

-- 
2.55.0

