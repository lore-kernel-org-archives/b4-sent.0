From: Maud Spierings <maudspierings@gocontroll.com>
Date: Mon, 24 Feb 2025 14:50:51 +0100
Subject: [PATCH 01/14] dt-bindings: display: simple: add BOE AV101HDT-A10
 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250224-initial_display-v1-1-5ccbbf613543@gocontroll.com>
References: <20250224-initial_display-v1-0-5ccbbf613543@gocontroll.com>
In-Reply-To: <20250224-initial_display-v1-0-5ccbbf613543@gocontroll.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Liu Ying <victor.liu@nxp.com>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740405062; l=1040;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=40zl28floi4M3jn7zLafA4I2SyrY1dnpQAFmoqwqXJY=;
 b=LLEVcADTtIeah3vQnwyqh6H6KYxyToPG8cRuzaIyjCyCSUvmauoZpOiqQDaZczem8xps+vaW1
 HGncx4sAL6dC7u+v73HIGHWpBAoE0EtsHLPn0l6slp4ol77GtQC/CPU
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add a compatible string for the BOE AV101HDT-A10 10.1" LVDS panel

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 Documentation/devicetree/bindings/display/panel/panel-simple.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/panel-simple.yaml b/Documentation/devicetree/bindings/display/panel/panel-simple.yaml
index e3ee3a332bb7e1736a8d44773b0aef4873153be1..b0de4fd6f3d4129d10e07b46533bb551784d8d53 100644
--- a/Documentation/devicetree/bindings/display/panel/panel-simple.yaml
+++ b/Documentation/devicetree/bindings/display/panel/panel-simple.yaml
@@ -63,6 +63,8 @@ properties:
       - auo,t215hvn01
         # Shanghai AVIC Optoelectronics 7" 1024x600 color TFT-LCD panel
       - avic,tm070ddh03
+        # BOE AV101HDT-a10 10.1" 1280x720 LVDS panel
+      - boe,av101hdt-a10
         # BOE BP082WX1-100 8.2" WXGA (1280x800) LVDS panel
       - boe,bp082wx1-100
         # BOE BP101WX1-100 10.1" WXGA (1280x800) LVDS panel

-- 
2.48.1

