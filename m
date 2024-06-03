From: =?utf-8?q?Noralf_Tr=C3=B8nnes?= <noralf@tronnes.org>
Subject: [PATCH v3 0/5] drm/tiny: panel-mipi-dbi: Support 18 bits per color
 RGB666
Date: Mon, 03 Jun 2024 13:21:31 +0200
Message-Id: <20240603-panel-mipi-dbi-rgb666-v3-0-59ed53ca73da@tronnes.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADunXWYC/3XNQQ6DIBCF4asY1qVBQNCueo+mC5RRJ2nBgCFtj
 Hcv2k27cPm/ZL5ZSISAEMmlWEiAhBG9yyFOBelG4wagaHMTzrhkklV0Mg4e9IkTUtsiDUOrlKI
 SmBC61lZ1Dcm3U4AeX7t7u+ceMc4+vPc3qdzWr1gxfSCmkjKqdNNwIU1vBFzn4J2DePZhIJuZ+
 I9T8iOHZ0c21nKlBK8N+3fWdf0AEg+XvgQBAAA=
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, Sam Ravnborg <sam@ravnborg.org>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <david@lechnology.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Kamlesh Gurudasani <kamlesh.gurudasani@gmail.com>, 
 Tommaso Merciai <tommaso.merciai@amarulasolutions.com>, 
 =?utf-8?q?Noralf_Tr=C3=B8nnes?= <noralf@tronnes.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717413714; l=1627;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=RPUu+iwtMtjEihe7ScmSFAxjz8n4fVKaMgkGP+usYvQ=;
 b=QKvzJIxqOjUSr1RSiUKNA4TmdcnFE6Ufk0GdfYdrOAMONsa6RpQ7zGrD0TtswWko9FU+5NdY9
 efGMK2VTCbFA5Mv0vwGxX6epE1sDPFt6mK03FxlWfV0MqUII+1etPRR
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Relay for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

The binding and driver patches have been reviewed and I appreciate if
someone can take a look at the drm_mipi_dbi patches. The first patch
removes some erroneous big endian code and the 2 other makes it possible
to configure bits per word for the SPI pixel transfer. It's currently
hardcoded for RGB565.

See version 1 of the patchset for the full cover letter.

Signed-off-by: Noralf Trønnes <noralf@tronnes.org>
---
Changes in v3:
- Added r-b's to patch 1 and 5
- Link to v2: https://lore.kernel.org/r/20240512-panel-mipi-dbi-rgb666-v2-0-49dd266328a0@tronnes.org

Changes in v2:
- binding: Use 'default: r5g6b5' (Rob)
- Link to v1: https://lore.kernel.org/r/20240507-panel-mipi-dbi-rgb666-v1-0-6799234afa3e@tronnes.org

---
Noralf Trønnes (5):
      dt-bindings: display: panel: mipi-dbi-spi: Add a pixel format property
      drm/mipi-dbi: Remove mipi_dbi_machine_little_endian()
      drm/mipi-dbi: Make bits per word configurable for pixel transfers
      drm/mipi-dbi: Add support for DRM_FORMAT_RGB888
      drm/tiny: panel-mipi-dbi: Support the pixel format property

 .../bindings/display/panel/panel-mipi-dbi-spi.yaml | 30 +++++++++
 drivers/gpu/drm/drm_mipi_dbi.c                     | 76 +++++++++++++++-------
 drivers/gpu/drm/tiny/panel-mipi-dbi.c              | 55 +++++++++++++++-
 include/drm/drm_mipi_dbi.h                         | 10 +++
 4 files changed, 147 insertions(+), 24 deletions(-)
---
base-commit: 0209df3b4731516fe77638bfc52ba2e9629c67cd
change-id: 20240405-panel-mipi-dbi-rgb666-4e033787d6c9

Best regards,
-- 
Noralf Trønnes <noralf@tronnes.org>

