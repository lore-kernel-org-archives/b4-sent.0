From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH 0/2] dt-bindings: phy: ti,tcan104x-can: Document TI
 TCAN1051
Date: Fri, 22 Aug 2025 11:20:04 +0200
Message-Id: <20250822-can_phy3-v1-0-73b3ba1690ee@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEQ2qGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCyMj3eTEvPiCjEpjXVMTozRTQxOTZMtUUyWg8oKi1LTMCrBR0bG1tQB
 jqt2YWgAAAA==
X-Change-ID: 20250822-can_phy3-542f5144c9e5
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755854408; l=796;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=pJwGTa7qHTBfaL9aAmiyFWO5jIhPuYuiPmJDsbad+Pk=;
 b=aHvGYtqv3q+QlxMdbuZHJYuNTM+a/CTkqkpJlO5kTKnARtfvn9Yn5wTvrT/45eBcUvBYDcmUg
 NFQXckPE6eAApx+Djex8Konhp03Twirzntgp3C5YrKWzmdCzfpbqyyN
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Moduline Display mainboard contains 2 TI TCAN1051 CAN transceivers,
properly document these and add them to the devicetree.

Thank Peng Fan for inspiring this patch series.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Maud Spierings (2):
      dt-bindings: phy: ti,tcan104x-can: Document TI TCAN1051
      arm64: dts: freescale: imx8mp-moduline-display-106: Use phys to replace xceiver-supply

 .../devicetree/bindings/phy/ti,tcan104x-can.yaml   |  1 +
 .../imx8mp-tx8p-ml81-moduline-display-106.dts      | 46 +++++++++++-----------
 2 files changed, 23 insertions(+), 24 deletions(-)
---
base-commit: 0f4c93f7eb861acab537dbe94441817a270537bf
change-id: 20250822-can_phy3-542f5144c9e5

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

