From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH 0/4] backlight: add new max25014 backlight driver
Date: Fri, 25 Jul 2025 13:09:22 +0200
Message-Id: <20250725-max25014-v1-0-0e8cce92078e@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOJlg2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDMyMz3dzECiDL0ETXxMjA3NTSMNUwMc1UCai8oCg1LbMCbFR0bG0tAB3
 YAxhaAAAA
X-Change-ID: 20250626-max25014-4207591e1af5
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>, 
 "Maud Spierings maudspierings"@gocontroll.com
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753441765; l=1452;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=KbANwn4NmNO7jNz4SGe7SAKLtyBDL4GI6/j143/N1/E=;
 b=PjTusrgPlZupmtwnWn9StKXy2DkRV3eFf5M+adbF+rEkvyz1mG3L2XP9PPZrorFH+PUwg5zR7
 EKaU2GeBddlCmwwgOer6BZEklYbXnOarE4DYHFsHnMYmH89T2htQs71
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Maxim MAX25014 is an automotive grade backlight driver IC. Its
datasheet can be found at [1].

With its integrated boost controller, it can power 4 channels (led
strings) and has a number of different modes using pwm and or i2c.
Currently implemented is only i2c control.

link: https://www.analog.com/media/en/technical-documentation/data-sheets/MAX25014.pdf [1]

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Maud Spierings (4):
      dt-bindings: backlight: Add max25014 bindings
      backlight: add max25014atg backlight
      arm64: dts: freescale: moduline-display-av101hdt-a10: add backlight
      arm64: dts: freescale: moduline-display-av123z7m-n17: add backlight

 .../bindings/leds/backlight/maxim,max25014.yaml    |  78 ++++
 MAINTAINERS                                        |   7 +
 ...x8p-ml81-moduline-display-106-av101hdt-a10.dtso |  21 +
 ...x8p-ml81-moduline-display-106-av123z7m-n17.dtso |  19 +-
 drivers/video/backlight/Kconfig                    |   7 +
 drivers/video/backlight/Makefile                   |   1 +
 drivers/video/backlight/max25014.c                 | 449 +++++++++++++++++++++
 include/linux/platform_data/max25014.h             |  24 ++
 8 files changed, 605 insertions(+), 1 deletion(-)
---
base-commit: d7af19298454ed155f5cf67201a70f5cf836c842
change-id: 20250626-max25014-4207591e1af5

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

