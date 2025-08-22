From: Maud Spierings <maudspierings@gocontroll.com>
Date: Fri, 22 Aug 2025 11:20:05 +0200
Subject: [PATCH 1/2] dt-bindings: phy: ti,tcan104x-can: Document TI
 TCAN1051
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250822-can_phy3-v1-1-73b3ba1690ee@gocontroll.com>
References: <20250822-can_phy3-v1-0-73b3ba1690ee@gocontroll.com>
In-Reply-To: <20250822-can_phy3-v1-0-73b3ba1690ee@gocontroll.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Aswath Govindraju <a-govindraju@ti.com>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: linux-can@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755854408; l=925;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=h5ZKsrw8gOWNFZ+LrIS6NAt/AwRMIdyfhSIwneUGyVY=;
 b=yNhf/uwZ57jylj44lykbtsjIChzfx1egEmURElSzgQTHDMOtYe+40rbVS0HDW6jz5lQuk9Wrv
 aW/WV+pyMbFDLZRhO0NC1y+NAc6wlOQ1EioJZsPHTHhDBYxzbBDgxh/
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TCAN1051-Q1 Automotive Fault Protected CAN Transceiver with CAN FD

It is pretty much identical to the TCAN1042, add the compatible with
fallback on the TCAN1042.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 Documentation/devicetree/bindings/phy/ti,tcan104x-can.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/phy/ti,tcan104x-can.yaml b/Documentation/devicetree/bindings/phy/ti,tcan104x-can.yaml
index 4a8c3829d85d3c4a4963750d03567c1c345beb91..138923ffedfeeb6a0b391cae863723ec70bf2c88 100644
--- a/Documentation/devicetree/bindings/phy/ti,tcan104x-can.yaml
+++ b/Documentation/devicetree/bindings/phy/ti,tcan104x-can.yaml
@@ -18,6 +18,7 @@ properties:
       - items:
           - enum:
               - microchip,ata6561
+              - ti,tcan1051
           - const: ti,tcan1042
       - enum:
           - ti,tcan1042

-- 
2.50.1

