From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Subject: [PATCH v2 00/14] Fix the errors of MediaTek display driver found
 by IGT
Date: Wed, 19 Jun 2024 22:30:41 +0800
Message-Id: <20240619-mediatek-drm-next-v2-0-abf68f46f8d2@mediatek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJHrcmYC/22NwQqDMBBEf0X23C1J1Kg99T+KB5ts6lI0kohYx
 H9vKnjr8Q0zbzaIFJgi3LINAi0c2Y8J1CUD03fji5BtYlBCFULLEgey3M30RhsGHGmdsbNayGd
 eNE7lkHZTIMfr4Xy0iXuOsw+f42KRv/S06T+2RaLAimrXGFfVpa3vZ+dq/ADtvu9f2iX4AbUAA
 AA=
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, David Airlie <airlied@gmail.com>, 
 Daniel Vetter <daniel@ffwll.ch>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 CK Hu <ck.hu@mediatek.com>, Bibby Hsieh <bibby.hsieh@mediatek.com>, 
 Daniel Kurtz <djkurtz@chromium.org>, YT Shen <yt.shen@mediatek.com>, 
 Mao Huang <littlecvr@chromium.org>, "Nancy.Lin" <nancy.lin@mediatek.com>
Cc: dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Hsiao Chien Sung <shawn.sung@mediatek.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718807531; l=1878;
 i=shawn.sung@mediatek.com; s=20240616; h=from:subject:message-id;
 bh=Ex+r9nIcVGsNaV245AkMYgu2Uumjenu/XGyFtzZeBh8=;
 b=IEF5hiIG3ifgryrF+Y8MlCMNwmu37nVrxSNel1hAFKQ2wAABZithABFddvDCkn8Y1YnQgDEZp
 LDA1of5lYZGBDNJ+BZ1PmMzu1sfs+34qS65GE0u8ENXf099f8DQ9dUY
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=lq1w8BuWDINX+4JHjGHhhbAU5ICP+cL9VCj7wn+cEDA=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240616 with auth_id=172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the errors of MediaTek display driver found by IGT.

Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
---
Changes in v2:
- Seperate the changes that belong to another repo (driver/soc/mediatek)
- Move the fix patches to the front of the series
- Link to v1: https://lore.kernel.org/r/20240616-mediatek-drm-next-v1-0-7e8f9cf785d8@mediatek.com

---
Hsiao Chien Sung (14):
      drm/mediatek: Add missing plane settings when async update
      drm/mediatek: Disable 9-bit alpha in ETHDR
      drm/mediatek: Fix XRGB setting error in OVL
      drm/mediatek: Fix XRGB setting error in Mixer
      drm/mediatek: Turn off the layers with zero width or height
      drm/mediatek: Add OVL compatible name for MT8195
      drm/mediatek: Add DRM_MODE_ROTATE_0 to rotation property
      drm/mediatek: Add new color format MACROs in OVL
      drm/mediatek: Set DRM mode configs accordingly
      drm/mediatek: Support more 10bit formats in OVL
      drm/mediatek: Support RGBA8888 and RGBX8888 in OVL on MT8195
      drm/mediatek: Support DRM plane alpha in OVL
      drm/mediatek: Support DRM plane alpha in Mixer
      drm/mediatek: Fix XRGB setting error in OVL

 drivers/gpu/drm/mediatek/mtk_ddp_comp.h         |  6 +-
 drivers/gpu/drm/mediatek/mtk_disp_ovl.c         | 93 ++++++++++++++++++-------
 drivers/gpu/drm/mediatek/mtk_disp_ovl_adaptor.c |  2 +-
 drivers/gpu/drm/mediatek/mtk_drm_drv.c          | 24 +++++++
 drivers/gpu/drm/mediatek/mtk_drm_drv.h          |  4 ++
 drivers/gpu/drm/mediatek/mtk_ethdr.c            | 27 +++++--
 drivers/gpu/drm/mediatek/mtk_plane.c            |  4 +-
 7 files changed, 126 insertions(+), 34 deletions(-)
---
base-commit: 62fe4b067581d480e863191305f108bebffbc0e9
change-id: 20240615-mediatek-drm-next-ad601b349f23

Best regards,
-- 
Hsiao Chien Sung <shawn.sung@mediatek.com>

