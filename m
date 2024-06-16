From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Subject: [PATCH 00/13] Fix the errors of MediaTek display driver found by
 IGT
Date: Sun, 16 Jun 2024 16:29:10 +0800
Message-Id: <20240616-mediatek-drm-next-v1-0-7e8f9cf785d8@mediatek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFaibmYC/x3MTQqAIBBA4avIrBtQ+4G6SrSwnGoILTQiEO+et
 PwW7yWIFJgiDCJBoIcjn75AVQKW3fiNkG0xaKkb2akWHVk2Nx1og0NP743GdlLNddOvuobSXYF
 Wfv/nOOX8ASDqfQljAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718526553; l=1639;
 i=shawn.sung@mediatek.com; s=20240616; h=from:subject:message-id;
 bh=r10waYEMGAymNOh3QIyIV85JK6+0pN1kGYW3MVMVAVg=;
 b=tingLMnjsTKtbIyzbXebc3jnQb0ioiL1lqGVFCw4e0VaknTStBGtN+rZoSzvDVFJUrNJ/nvBW
 txWOmGBNVd5AWc8Num1/KDshCYgGD3L1Kwcf8Ys7mnaoMpLEmfUC+Sz
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=lq1w8BuWDINX+4JHjGHhhbAU5ICP+cL9VCj7wn+cEDA=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240616 with auth_id=172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the errors of MediaTek display driver found by IGT.

Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
---
Hsiao Chien Sung (13):
      soc: mediatek: Disable 9-bit alpha in ETHDR
      drm/mediatek: Add OVL compatible name for MT8195
      drm/mediatek: Add missing plane settings when async update
      drm/mediatek: Add DRM_MODE_ROTATE_0 to rotation property
      drm/mediatek: Set DRM mode configs accordingly
      drm/mediatek: Turn off the layers with zero width or height
      drm/mediatek: Support more 10bit formats in OVL
      drm/mediatek: Support RGBA8888 and RGBX8888 in OVL on MT8195
      drm/mediatek: Fix XRGB setting error in OVL
      drm/mediatek: Fix XRGB setting error in Mixer
      drm/mediatek: Add new color format MACROs in OVL
      drm/mediatek: Support DRM plane alpha in OVL
      drm/mediatek: Support DRM plane alpha in Mixer

 drivers/gpu/drm/mediatek/mtk_ddp_comp.h         |  6 +-
 drivers/gpu/drm/mediatek/mtk_disp_ovl.c         | 85 +++++++++++++++++--------
 drivers/gpu/drm/mediatek/mtk_disp_ovl_adaptor.c |  2 +-
 drivers/gpu/drm/mediatek/mtk_drm_drv.c          | 24 +++++++
 drivers/gpu/drm/mediatek/mtk_drm_drv.h          |  4 ++
 drivers/gpu/drm/mediatek/mtk_ethdr.c            | 26 ++++++--
 drivers/gpu/drm/mediatek/mtk_plane.c            |  4 +-
 drivers/soc/mediatek/mtk-mmsys.c                |  1 +
 8 files changed, 118 insertions(+), 34 deletions(-)
---
base-commit: 62fe4b067581d480e863191305f108bebffbc0e9
change-id: 20240615-mediatek-drm-next-ad601b349f23

Best regards,
-- 
Hsiao Chien Sung <shawn.sung@mediatek.com>

