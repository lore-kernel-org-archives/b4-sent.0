From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v5 0/4] backlight: add new max25014 backlight driver
Date: Fri, 07 Nov 2025 13:49:57 +0100
Message-Id: <20251107-max25014-v5-0-9a6aa57306bf@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPXqDWkC/23NS47CMAyA4augrAmy8+hjVnOPEQs3dSASNKMUV
 SDUu49hJFoJdnHk7/ddjVwSj+prc1eFpzSmPMjgtxsVjjQcWKdeZmXAeKhMpc90lRc67QzUvkV
 Gil7J+m/hmK7P1M9e5mMaL7ncnuUJH7//kdr4JTKhBg3chMCt9Br+PuSQh0vJp9Mu5LN6lCaz6
 AbblTaifexr4g4dMn3UdtEt4kpb0T3Y6LgjW/vPt91LI8D6thNdUd8ZAiLr45ue5/kPQ42L+F8
 BAAA=
X-Change-ID: 20250626-max25014-4207591e1af5
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762519811; l=3392;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=aMU6lI+FXL9SA5HsmuUzM3T7gQp8a2xCL/Hf/lasg3A=;
 b=tHu4Cu2n2geb7CXzMfQZdheXEYSEHLIEAHda4GTiB9rSeI4w1XX8+DhtQ6cGKxl6Pk6zCuWEa
 5iC7I71JaikDQXYf6oiFrknLfgaFfSZNdahLsuimPV+N1iJRv6RdxHQ
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
Changes in v5:
- moved comment about current functions of the driver to the actual
  comment section of the commit
- fixed the led@0 property, regex patternProperty is not needed as of
  now
- added extra clarification about the ISET field/register
- moved #address-cells and #size-cells to the correct location
- remove leftover default-brightness in backlight nodes
- Link to v4: https://lore.kernel.org/r/20251009-max25014-v4-0-6adb2a0aa35f@gocontroll.com

Changes in v4:
- use a led node to describe the backlight
- use led-sources to enable specific channels
- also wait 2ms when there is a supply but no enable
- change dev_warn() to dev_err() in error path in max25014_check_errors()
- set backlight_properties.scale to BACKLIGHT_SCALE_LINEAR
- rebase latest next
- add address-cells and size-cells to i2c4 in av101hdt-a10.dtso
- Link to v3: https://lore.kernel.org/r/20250911-max25014-v3-0-d03f4eba375e@gocontroll.com

Changes in v3:
- fixed commit message type intgrated -> integrated
- added maximum and description to maxim,iset-property
- dropped unused labels and pinctrl in bindings example
- put the compatible first in the bindings example and dts
- removed brackets around defines
- removed the leftover pdata struct field
- removed the initial_brightness struct field
- Link to v2: https://lore.kernel.org/r/20250819-max25014-v2-0-5fd7aeb141ea@gocontroll.com

Changes in v2:
- Remove leftover unused property from the bindings example
- Complete the bindings example with all properties
- Remove some double info from the maxim,iset property
- Remove platform_data header, fold its data into the max25014 struct
- Don't force defines to be unsigned
- Remove stray struct max25014 declaration
- Remove chipname and device from the max25014 struct
- Inline the max25014_backlight_register() and strings_mask() functions
- Remove CONFIG_OF ifdef
- Link to v1: https://lore.kernel.org/r/20250725-max25014-v1-0-0e8cce92078e@gocontroll.com

---
Maud Spierings (4):
      dt-bindings: backlight: Add max25014 support
      backlight: add max25014atg backlight
      arm64: dts: freescale: moduline-display-av101hdt-a10: add backlight
      arm64: dts: freescale: moduline-display-av123z7m-n17: add backlight

 .../bindings/leds/backlight/maxim,max25014.yaml    | 107 ++++++
 MAINTAINERS                                        |   6 +
 ...x8p-ml81-moduline-display-106-av101hdt-a10.dtso |  30 ++
 ...x8p-ml81-moduline-display-106-av123z7m-n17.dtso |  25 +-
 drivers/video/backlight/Kconfig                    |   7 +
 drivers/video/backlight/Makefile                   |   1 +
 drivers/video/backlight/max25014.c                 | 409 +++++++++++++++++++++
 7 files changed, 584 insertions(+), 1 deletion(-)
---
base-commit: 9c0826a5d9aa4d52206dd89976858457a2a8a7ed
change-id: 20250626-max25014-4207591e1af5

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

