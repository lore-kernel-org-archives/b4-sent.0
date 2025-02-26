From: Maud Spierings <maudspierings@gocontroll.com>
Date: Wed, 26 Feb 2025 15:19:17 +0100
Subject: [PATCH v2 06/12] MAINTAINERS: add maintainer for the GOcontroll
 Moduline module slot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250226-initial_display-v2-6-23fafa130817@gocontroll.com>
References: <20250226-initial_display-v2-0-23fafa130817@gocontroll.com>
In-Reply-To: <20250226-initial_display-v2-0-23fafa130817@gocontroll.com>
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
 Fabio Estevam <festevam@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-spi@vger.kernel.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740579556; l=783;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=mdt5JwC9bMt5XKdossnzN3k8EjfciPnd06zO7qteiiY=;
 b=swcJF9ByfdpVHmCmammooQCjX5IvAKt8c17sTXTdoEyj5DX6o80SUU3RCp7CWPn4G54Ymlrk+
 Fj9IkqRG4yRD6J9m7fM0Rih25iWwXewk3AaED6WkG5cZZ0yYEJGg8Lw
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a maintainer for the GOcontroll Moduline module slot bindings and
future driver.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 MAINTAINERS | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index b4c76d7ad890be0f618109918ad89328bc72e8cd..3d75c66942ca2059e7a054072502b726d1dec04c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -9843,6 +9843,11 @@ L:	linux-media@vger.kernel.org
 S:	Maintained
 F:	drivers/media/usb/go7007/
 
+GOCONTROLL MODULINE MODULE SLOT
+M:	Maud Spierings <maudspierings@gocontroll.com>
+S:	Maintained
+F:	Documentation/connector/gocontroll,moduline-module-slot.yaml
+
 GOODIX TOUCHSCREEN
 M:	Bastien Nocera <hadess@hadess.net>
 M:	Hans de Goede <hdegoede@redhat.com>

-- 
2.48.1

