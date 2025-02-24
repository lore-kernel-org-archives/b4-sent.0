From: Maud Spierings <maudspierings@gocontroll.com>
Date: Mon, 24 Feb 2025 14:50:55 +0100
Subject: [PATCH 05/14] dt-bindings: trivial-devices: add GOcontroll
 Moduline IO modules
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250224-initial_display-v1-5-5ccbbf613543@gocontroll.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740405062; l=1292;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=MzfkGV7s1Bx+ubm3O33iLbvUjEe7KE6YD28WzxYypQI=;
 b=XPAaKQUyngLl8QTmZ2xkR4XmJbDTaVMt0nfkm38EyJAR9Hbkjfs8fA5TFPpN3fjtjLE6mPMh0
 IcCzcWXiVmbCoxk1qiFME3yluxZfxnzsoxkLi+xdTK8Air4RmwpRu2T
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The main point of the Moduline series of embedded controllers is its
ecosystem of IO modules, these currently are operated through the spidev
interface. Ideally there will be a full dedicated driver in the future.

Add the gocontroll moduline-module-slot device to enable the required
spidev interface.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 Documentation/devicetree/bindings/trivial-devices.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index 8255bb590c0cc619d15b27dcbfd3aa85389c0a54..24ba810f91b73efdc615c7fb46f771a300926f05 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -107,6 +107,8 @@ properties:
           - fsl,mpl3115
             # MPR121: Proximity Capacitive Touch Sensor Controller
           - fsl,mpr121
+            # GOcontroll Moduline module slot for spi based IO modules
+          - gocontroll,moduline-module-slot
             # Honeywell Humidicon HIH-6130 humidity/temperature sensor
           - honeywell,hi6130
             # IBM Common Form Factor Power Supply Versions (all versions)

-- 
2.48.1

