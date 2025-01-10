From: Ao Xu <ao.xu@amlogic.com>
Subject: [PATCH 00/11] Subject: [PATCH 00/11] Add DRM support for Amlogic
 S4
Date: Fri, 10 Jan 2025 13:39:50 +0800
Message-Id: <20250110-drm-s4-v1-0-cbc2d5edaae8@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKaygGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDQ0MD3ZSiXN1iE91kS7NkC4ukVFOjVBMloOKCotS0zAqwQdGxtbUAfIW
 dnlgAAAA=
X-Change-ID: 20250110-drm-s4-c96c88be52e4
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: dri-devel@lists.freedesktop.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Ao Xu <ao.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736487593; l=2879;
 i=ao.xu@amlogic.com; s=20250103; h=from:subject:message-id;
 bh=VKVoKeBszJaQBYp+1nP1v5nM4InY/X3cRLrD0IhuQow=;
 b=F3Mz88aVHJb35MqlLV7mcSGlYoAXJTxGxcX3PBI2E5jRY346NpbBCGN3qyXahNHofIwyZU18U
 dAo+IgFzxxrA0N4OsXeTdBgstJaxB7XTuHVW16NAqF25UNM4ttlpbOs
X-Developer-Key: i=ao.xu@amlogic.com; a=ed25519;
 pk=c0TSXrwQuL4EhPVf3lJ676U27ax2yfFTqmRoseP/fA8=
X-Endpoint-Received: by B4 Relay for ao.xu@amlogic.com/20250103 with auth_id=308
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds DRM support for the Amlogic S4-series SoCs.
Compared to the Amlogic G12-series, the S4-series introduces the following changes:

1 The S4-series splits the HIU into three separate components: `sys_ctrl`, `pwr_ctrl`, and `clk_ctrl`.
  As a result, VENC and VCLK drivers are updated with S4-specific compatible strings to accommodate these changes.
2 The S4-series secures access to HDMITX DWC and TOP registers,
  requiring modifications to the driver to handle this new access method.
3 The register addresses for the video1 and video2 planes have been updated in the S4 hardware,
  and the DRM driver has been adapted accordingly.
4 The OSD, VIU, and VPP components remain unchanged and are consistent with the G12-series.

Signed-off-by: Ao Xu <ao.xu@amlogic.com>
---
Ao Xu (11):
      dt-bindings: display: meson-dw-hdmi: Add compatible for S4 HDMI controller
      dt-bindings: display: meson-vpu: Add compatible for S4 display controller
      drm: meson: add S4 compatible for DRM driver
      drm: meson: add primary and overlay plane support for S4
      drm: meson: update VIU and VPP support for S4
      drm: meson: add meson_dw_hdmi support for S4
      drm: meson: change api call parameter
      drm: meson: add hdmitx vmode timing support for S4
      drm: meson: add vpu clk setting for S4
      drm: meson: add CVBS support for S4
      arm64: dts: amlogic: s4: add DRM support [1/1]

 .../bindings/display/amlogic,meson-dw-hdmi.yaml    |    1 +
 .../bindings/display/amlogic,meson-vpu.yaml        |   48 +-
 .../boot/dts/amlogic/meson-s4-s805x2-aq222.dts     |   39 +
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          |  121 +++
 drivers/gpu/drm/meson/meson_crtc.c                 |   90 +-
 drivers/gpu/drm/meson/meson_drv.c                  |  127 ++-
 drivers/gpu/drm/meson/meson_drv.h                  |    6 +
 drivers/gpu/drm/meson/meson_dw_hdmi.c              |  244 ++++-
 drivers/gpu/drm/meson/meson_dw_hdmi.h              |  126 +++
 drivers/gpu/drm/meson/meson_encoder_cvbs.c         |   10 +
 drivers/gpu/drm/meson/meson_encoder_hdmi.c         |   19 +-
 drivers/gpu/drm/meson/meson_overlay.c              |    7 +-
 drivers/gpu/drm/meson/meson_plane.c                |   24 +-
 drivers/gpu/drm/meson/meson_registers.h            |   17 +
 drivers/gpu/drm/meson/meson_vclk.c                 | 1018 ++++++++++++++------
 drivers/gpu/drm/meson/meson_venc.c                 |  346 ++++++-
 drivers/gpu/drm/meson/meson_venc.h                 |    4 +-
 drivers/gpu/drm/meson/meson_viu.c                  |    9 +-
 drivers/gpu/drm/meson/meson_vpp.c                  |   12 +-
 19 files changed, 1865 insertions(+), 403 deletions(-)
---
base-commit: 6ecd20965bdc21b265a0671ccf36d9ad8043f5ab
change-id: 20250110-drm-s4-c96c88be52e4

Best regards,
-- 
Ao Xu <ao.xu@amlogic.com>

