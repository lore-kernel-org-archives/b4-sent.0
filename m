From: =?utf-8?q?Noralf_Tr=C3=B8nnes?= <noralf@tronnes.org>
Subject: [PATCH 0/5] drm/tiny: panel-mipi-dbi: Support 18 bits per color
 RGB666
Date: Tue, 07 May 2024 11:57:25 +0200
Message-Id: <20240507-panel-mipi-dbi-rgb666-v1-0-6799234afa3e@tronnes.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAX7OWYC/x3MTQqAIBBA4avErBuwNPu5SrQonWqgTBQikO6et
 PwW7yWIFJgiDEWCQDdHvlxGVRZg9tlthGyzoRa1Eko06GdHB57sGe3CGLZFa42KhJRt11ptesi
 tD7Ty83/H6X0/IxsMwmcAAAA=
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, Sam Ravnborg <sam@ravnborg.org>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Kamlesh Gurudasani <kamlesh.gurudasani@gmail.com>, 
 Tommaso Merciai <tommaso.merciai@amarulasolutions.com>, 
 =?utf-8?q?Noralf_Tr=C3=B8nnes?= <noralf@tronnes.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715075866; l=3259;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=cOslNnFXMgXOobE/xiF5+42V/TZM+XXhX8L45V5ggnc=;
 b=41Zf668TAp8cqriNW2DsPKYmEM4c0aWJfyLBTOF67tWFBNUJC+z5QyZpMG+t0ClldrRxfxLhC
 dIZZ21CwkQbC+e8kcN2QKeslmVL7sLNYD83//eoBfwdWqMRYmasnMFp
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Relay for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

To my suprise I have discovered that the MIPI DBI specification does only
list RGB111 as a pixel format for the Serial Interface (Type C).

For the parallel interface type (Type A and B) it lists: RGB332, RGB444,
RGB565, RGB666 and RGB888.

I have never read the specification closely enough to discover this always
assuming that the datasheets for the various MIPI DBI compatible
controllers I've looked at over the years did follow the specification
when they supported RGB565 and RGB666 on the serial interface.

So it is quite clear that the industry has chosen to extend the standard
and provide support for more pixel formats over the serial interface.

drm_mipi_dbi and its predecessor fbtft support only RGB565 over SPI since
RGB666 uses 3 bytes per pixel instead of 2 bytes, severly impacting the
framerate.

The reason I started to look at this is that there seem to be an increase
in cheap SPI displays that is based on the ILI9488 controller. The
datasheet for this controller states that it supports RGB565, but
experience[1] shows that this is not true and that the controller only
supports RGB666 over SPI.

I have known for some time that the ILI9486 controller does not support
RGB565 over SPI, it only supports RGB111 and RGB666. Some display
breakoutboard manufacturers have solved this by putting a shift register
in front of the parallel bus on this controller in order to support
RGB565. This requires some custom code when writing to the SPI bus as
shown in the tiny/ili9486.c driver. The downside is that these displays
are really slow due to the slow shift registers used.

This patchset documents the defacto industry standard wrt pixel formats
over SPI and adds support for RGB666 in the panel-mipi-dbi driver.

There have been two previous attempts to add a DRM driver for
ili9488[2][3]. The panel-mipi-dbi driver is a generic MIPI DBI driver
supporting controller initialization via a firmware file and with the help
of this patchset it will support ILI9488 based SPI displays.

[1] https://github.com/notro/panel-mipi-dbi/issues/2#issuecomment-2016857690
[2] https://lore.kernel.org/dri-devel/cover.1592055494.git.kamlesh.gurudasani@gmail.com/
[3] https://lore.kernel.org/dri-devel/20221018164532.1705215-1-tommaso.merciai@amarulasolutions.com/

Signed-off-by: Noralf Trønnes <noralf@tronnes.org>
---
Noralf Trønnes (5):
      dt-bindings: display: panel: mipi-dbi-spi: Add a pixel format property
      drm/mipi-dbi: Remove mipi_dbi_machine_little_endian()
      drm/mipi-dbi: Make bits per word configurable for pixel transfers
      drm/mipi-dbi: Add support for DRM_FORMAT_RGB888
      drm/tiny: panel-mipi-dbi: Support the pixel format property

 .../bindings/display/panel/panel-mipi-dbi-spi.yaml | 31 +++++++++
 drivers/gpu/drm/drm_mipi_dbi.c                     | 76 +++++++++++++++-------
 drivers/gpu/drm/tiny/panel-mipi-dbi.c              | 55 +++++++++++++++-
 include/drm/drm_mipi_dbi.h                         | 10 +++
 4 files changed, 148 insertions(+), 24 deletions(-)
---
base-commit: 0209df3b4731516fe77638bfc52ba2e9629c67cd
change-id: 20240405-panel-mipi-dbi-rgb666-4e033787d6c9

Best regards,
-- 
Noralf Trønnes <noralf@tronnes.org>

