From: Maud Spierings <maudspierings@gocontroll.com>
Date: Thu, 09 Oct 2025 12:54:17 +0200
Subject: [PATCH 1/5] dt-bindings: arm: fsl: Add GOcontroll Moduline IV/Mini
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251009-mini_iv-v1-1-f3889c492457@gocontroll.com>
References: <20251009-mini_iv-v1-0-f3889c492457@gocontroll.com>
In-Reply-To: <20251009-mini_iv-v1-0-f3889c492457@gocontroll.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760007259; l=1035;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=YdrnHfiDG3B0bwOljviUk0FaT/LUxjf/C85CSrfJE3s=;
 b=p6e/cI8s74gDArLUc9ZfZeMa2Z13mKMWv5y8MtX41NjmGh7J/JuTcLDgUI/X9PFKvIlKB8Y2n
 kvvhw9jZ+qDBkEt8tsFZ+NIOICP9simjsWcYWrIqM4lQEh2Ltvbc0Lx
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the compatible strings for the Moduline IV and Mini.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 Documentation/devicetree/bindings/arm/fsl.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/fsl.yaml b/Documentation/devicetree/bindings/arm/fsl.yaml
index 00cdf490b0620..41eb19e3530da 100644
--- a/Documentation/devicetree/bindings/arm/fsl.yaml
+++ b/Documentation/devicetree/bindings/arm/fsl.yaml
@@ -963,6 +963,8 @@ properties:
               - fsl,imx8mm-evkb           # i.MX8MM EVKB Board
               - gateworks,imx8mm-gw75xx-0x # i.MX8MM Gateworks Board
               - gateworks,imx8mm-gw7904
+              - gocontroll,moduline-iv
+              - gocontroll,moduline-mini
               - gw,imx8mm-gw71xx-0x       # i.MX8MM Gateworks Development Kit
               - gw,imx8mm-gw72xx-0x       # i.MX8MM Gateworks Development Kit
               - gw,imx8mm-gw73xx-0x       # i.MX8MM Gateworks Development Kit

-- 
2.51.0

