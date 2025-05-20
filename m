From: Maud Spierings <maudspierings@gocontroll.com>
Date: Tue, 20 May 2025 08:34:50 +0200
Subject: [PATCH v7 1/8] dt-bindings: arm: fsl: Add GOcontroll Moduline
 Display
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250520-initial_display-v7-1-a8f0195420aa@gocontroll.com>
References: <20250520-initial_display-v7-0-a8f0195420aa@gocontroll.com>
In-Reply-To: <20250520-initial_display-v7-0-a8f0195420aa@gocontroll.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747722892; l=1206;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=7LK5io9tXyJrf5fT7pNPykcX/YAUSsMUIEqjia8Pbmw=;
 b=cIHZnnDGBjVlYMnVnr15Baq4iQ5GbRfwYKNbHYbdVGdz2NiZmnj/8g7K+USmDmACK1Wfw54nU
 9mGdbQk82PJCpaLR0dm6eiTs9UOtXpmvbvshhKjgsbXkThhhe4ws8Hl
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the compatible strings for the Moduline Display controller.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 Documentation/devicetree/bindings/arm/fsl.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/fsl.yaml b/Documentation/devicetree/bindings/arm/fsl.yaml
index 1b90870958a22e49355dd1f932bf3d84cd864b5f..ecde2123ea0fae38ef233929c7ad343812851a58 100644
--- a/Documentation/devicetree/bindings/arm/fsl.yaml
+++ b/Documentation/devicetree/bindings/arm/fsl.yaml
@@ -1095,6 +1095,7 @@ properties:
               - gateworks,imx8mp-gw74xx   # i.MX8MP Gateworks Board
               - gateworks,imx8mp-gw75xx-2x # i.MX8MP Gateworks Board
               - gateworks,imx8mp-gw82xx-2x # i.MX8MP Gateworks Board
+              - gocontroll,moduline-display # GOcontroll Moduline Display controller
               - skov,imx8mp-skov-basic # SKOV i.MX8MP baseboard without frontplate
               - skov,imx8mp-skov-revb-hdmi # SKOV i.MX8MP climate control without panel
               - skov,imx8mp-skov-revb-lt6 # SKOV i.MX8MP climate control with 7” panel

-- 
2.49.0

