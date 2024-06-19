From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Subject: [PATCH 0/5] Support alpha blending in MTK display driver
Date: Thu, 20 Jun 2024 01:27:05 +0800
Message-Id: <20240620-blend-v1-0-72670072ca20@mediatek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOoUc2YC/02OywqDMBBFf0Vm3cAk0Rj9leIij0kbWrVNrAjiv
 zfUTZfncjmcHTKlSBn6aodEa8xxngrwSwXubqYbsegLg0BRoxLI7JMmzzoU0khsnA0tlO8rUYj
 bz3MdTk70/hTdco5gTSbm5nGMS18pEai2qNpGc19rJK0k73gRBo7akg3BOqQO/jP66ozgDRvJR
 7PQg/k0som2hRmvkFtZd0HIfpUwHMcX91ar6NwAAAA=
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, David Airlie <airlied@gmail.com>, 
 Daniel Vetter <daniel@ffwll.ch>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Hsiao Chien Sung <shawn.sung@mediatek.com>, CK Hu <ck.hu@mediatek.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718818030; l=1980;
 i=shawn.sung@mediatek.com; s=20240616; h=from:subject:message-id;
 bh=ffa9QQcOJtyAVtiNDqxJ1WmYeHKO0blFbInuddhMTh8=;
 b=Em29vUs75c5lfJAEUFMC1hTlqcCcSmdGQzeYIvo6/AGBCkZ8m4TWer36zaThJfIeZeITw0f32
 v0Vfbb67LuDADyMxoePAZ3AVo1rlmHkOhPrxcUign/xyHGac4mrdNMa
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=lq1w8BuWDINX+4JHjGHhhbAU5ICP+cL9VCj7wn+cEDA=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240616 with auth_id=172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support "Pre-multiplied" and "None" blend mode on MediaTek's chips by
adding correct blend mode property when the planes init.
Before this patch, only the "Coverage" mode (default) is supported.

Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
---
Hsiao Chien Sung (5):
      drm/mediatek: Support "None" blending in OVL
      drm/mediatek: Support "None" blending in Mixer
      drm/mediatek: Support "Pre-multiplied" blending in OVL
      drm/mediatek: Support "Pre-multiplied" blending in Mixer
      drm/mediatek: Support alpha blending in display driver

 drivers/gpu/drm/mediatek/mtk_disp_ovl.c | 36 +++++++++++++++++++++++++--------
 drivers/gpu/drm/mediatek/mtk_ethdr.c    | 14 ++++++++++---
 drivers/gpu/drm/mediatek/mtk_plane.c    | 11 ++++++++++
 3 files changed, 50 insertions(+), 11 deletions(-)
---
base-commit: 62fe4b067581d480e863191305f108bebffbc0e9
change-id: 20240620-blend-9023a305cbf7
prerequisite-change-id: 20240615-mediatek-drm-next-ad601b349f23:v3
prerequisite-patch-id: fdd0efbeca41c69c6fa93a5e49a2f16b3d2e8ef7
prerequisite-patch-id: 24bfda7b207bf9698ab88c7233d9168187aa54bb
prerequisite-patch-id: f2ab4804bbe54091a89b310c2ecd4b65fe031137
prerequisite-patch-id: 26bfe746bda376c070c23c72fcc25949e396d952
prerequisite-patch-id: b0b1589f88a9067b93a1e439e1db9abbde96e9e8
prerequisite-patch-id: 14603755fd2d5b6f0ef8a7843e118d0e8d27f57d
prerequisite-patch-id: 86f89ad0a06705cd2ad2867e9409da5610c9d228
prerequisite-patch-id: bd0b091709980bc6e993055d78573f3979139662
prerequisite-patch-id: 2f4da7b628f9d1f03e045b4c8f04b53eeb133a03
prerequisite-patch-id: 9ee1d1b3c69dc6ca828c21fae9180d2e9b5cd4d5
prerequisite-patch-id: 5c1f57bc1bd2d56061c2b927c9efbc9dad36ab68
prerequisite-patch-id: 05443d9f227599f0784da4006c4c983513654087
prerequisite-patch-id: 694abac72844a2b9753453aa514f9485a47a8f32
prerequisite-patch-id: 99f314c9dc697cb78c57d1311dfe055204b9e7b8

Best regards,
-- 
Hsiao Chien Sung <shawn.sung@mediatek.com>

