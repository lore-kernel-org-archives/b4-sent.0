From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v8 0/4] backlight: add new max25014 backlight driver
Date: Tue, 07 Apr 2026 16:41:41 +0200
Message-Id: <20260407-max25014-v8-0-14eac7ed673a@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23OS2rDMBCA4asEresyo7e66j1KF2N5lAiSKNjBp
 ATfvUpKa0G90wh9/+guJh4zT+Jtdxcjz3nK5VwH/7IT8UDnPXd5qLOQIA1YabsT3eoJdaclOBO
 QkZIR9fll5JRvz9THZ50PebqW8etZnvFx+xNx0qyRGTvogH2MHGrP8/u+xHK+juV4fI3lJB6lW
 a7aY2i0rNqkwRH3qJFpU6tVB8RGq6oHUElzT8qZ7d36TyNAu1tXbWnoJQGRMmlTm1UjuEabqgN
 ZIuMU2H5b21VLaH9uq/aeFUWPKNO2dr/aAkrVaFc1Gjag+0Axun96WZZvBG2W5xkCAAA=
X-Change-ID: 20250626-max25014-4207591e1af5
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Frank Li <Frank.Li@nxp.com>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775572904; l=5325;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=J1I/2EOKwZVbytZkVaMR4iXsx/7J4F1JU+XT5ySnbp0=;
 b=p2hDxSqIgqxC9d1BFxg57HCSFAyqjj18dU4K/5XRBHtJvUONwpApN2xyYpYFsaKvIKUwT+EXN
 8/kLvdncznPCJLpxpgDs7Ydqk82Vjgom6VvmfQ1XsZ01J+ZatazMhpM
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
Changes in v8:
- Clean up some leftovers from the led subnodes, address/size-cells (Rob)
- Add Robs rb tag
- Add Daniels rb tag
- Bring the Kconfig option in line text wise with other drivers
- Rebase on the latest next
- Link to v7: https://lore.kernel.org/r/20260123-max25014-v7-0-15e504b9acc7@gocontroll.com

Changes in v7:
- remove the led subnodes
- always enable the regulator by using devm_regulator_get_enable()
- remove the no longer required gotos and simplify early returns
- fix the name of the SHORTED_LED error field
- fix the name of the SHORTGND error field
- use the proper backlight helper functions for setting/getting
  brightness
- Link to v6: https://lore.kernel.org/r/20251201-max25014-v6-0-88e3ac8112ff@gocontroll.com

Changes in v6:
- fixup changes in v4 where default brightness handling was changed but
  not noted
- remove leftover comment about initializing brightness
- use BIT definitions for fields in the DIAG register
- apply reverse christmas tree initialization of local variables
- remove !=0 from checks, just check if (ret)
- remove > 0 from checks, just check if (val)
- use dev_err_probe() more
- set enable gpio high in the get() instead of seperately calling set()
- change usleep_range() to fsleep()
- remove null checks when setting gpio value
- get regular regulator, not optional to avoid further NULL checks in
  case none is provided
- introduce max25014_initial_power_state() to check if the bootloader
  has already initialized the backlight and to correctly set props.power
- squash max25014_register_control() into max25014_update_status()
- in max25014_configure() perform extra checking on the DISABLE register
  now that the state from the bootloader is taken into account
- Link to v5: https://lore.kernel.org/r/20251107-max25014-v5-0-9a6aa57306bf@gocontroll.com

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
- remove setting default brightness, let backlight core take care of it
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

 .../bindings/leds/backlight/maxim,max25014.yaml    |  83 +++++
 MAINTAINERS                                        |   6 +
 ...x8p-ml81-moduline-display-106-av101hdt-a10.dtso |  24 ++
 ...x8p-ml81-moduline-display-106-av123z7m-n17.dtso |  19 +-
 drivers/video/backlight/Kconfig                    |   7 +
 drivers/video/backlight/Makefile                   |   1 +
 drivers/video/backlight/max25014.c                 | 377 +++++++++++++++++++++
 7 files changed, 516 insertions(+), 1 deletion(-)
---
base-commit: f3e6330d7fe42b204af05a2dbc68b379e0ad179e
change-id: 20250626-max25014-4207591e1af5

Best regards,
--  
Maud Spierings <maudspierings@gocontroll.com>

