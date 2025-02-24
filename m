From: Maud Spierings <maudspierings@gocontroll.com>
Date: Mon, 24 Feb 2025 14:50:52 +0100
Subject: [PATCH 02/14] dt-bindings: display: simple: Add BOE AV123Z7M-N17
 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250224-initial_display-v1-2-5ccbbf613543@gocontroll.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740405062; l=1145;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=CUdxnBhmE0c15sBOxDGAJvFl6x2ngU8cBR/mW9XP/q0=;
 b=8ODcB0rUC2FCMlYWpOJd40nb/Ts7PTLBk3WgfwZYrREBCT9OYN3uqwTLDOGws29fxvE0EzHex
 RXcCodSY0drAfkStA7xPS7yPaM2UY1fNlqnwhS988Y/biTviyJFkBbb
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the BOE AV123Z7M-N17 12.3" LVDS panel.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 .../devicetree/bindings/display/panel/panel-simple-lvds-dual-ports.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/panel-simple-lvds-dual-ports.yaml b/Documentation/devicetree/bindings/display/panel/panel-simple-lvds-dual-ports.yaml
index e80fc7006984e052b4f7c0007679ee0e228d9989..548f5ac14500a7f8c3e0e5df7db9e19f5af40eb8 100644
--- a/Documentation/devicetree/bindings/display/panel/panel-simple-lvds-dual-ports.yaml
+++ b/Documentation/devicetree/bindings/display/panel/panel-simple-lvds-dual-ports.yaml
@@ -40,6 +40,8 @@ properties:
       - auo,g185han01
         # AU Optronics Corporation 19.0" (1280x1024) TFT LCD panel
       - auo,g190ean01
+        # BOE AV123Z7M-N17 12.3" (1920x720) LVDS TFT LCD panel
+      - boe,av123z7m-n17
         # Kaohsiung Opto-Electronics Inc. 10.1" WUXGA (1920 x 1200) LVDS TFT LCD panel
       - koe,tx26d202vm0bwa
         # Lincoln Technology Solutions, LCD185-101CT 10.1" TFT 1920x1200

-- 
2.48.1

