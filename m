From: "Jason-JH.Lin" <jason-jh.lin@mediatek.com>
Subject: [PATCH v3 0/2] Fix missing configuration flags in
 mtk_crtc_ddp_config
Date: Tue, 27 Aug 2024 22:55:18 +0800
Message-Id: <20240827-drm-fixup-0819-v3-0-4761005211ec@mediatek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANbozWYC/0XMQQ7CIBCF4as0s3YIFA2tq97DuCBlsFMFGqjGp
 OndJd24/PLy/g0KZaYC12aDTB8unGKFPjUwTjY+CNlVQyvbs+xUjy4H9Px9L3jQXxS1Ths/OgP
 1tGSq6xG83at9TgHXKZP9Z4zUSmotO6Gk6jtUONuSIs6TeHEcAjm2Kz3FmALs+w+OtgfXowAAA
 A==
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: Philipp Zabel <p.zabel@pengutronix.de>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 Singo Chang <singo.chang@mediatek.com>, Nancy Lin <nancy.lin@mediatek.com>, 
 "Jason-JH.Lin" <jason-jh.lin@mediatek.com>, 
 Project_Global_Chrome_Upstream_Group@mediatek.com, 
 dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 CK Hu <ck.hu@mediatek.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724770559; l=663;
 i=jason-jh.lin@mediatek.com; s=20240718; h=from:subject:message-id;
 bh=QZQ5u0mI5GTvIERqL7sO8uE4R1i9WTqn8mFJ1e8m6Cg=;
 b=vtG4j8YW0CdzhCv8m6K3/A14B+OP06kMhQBxegBLibqv5A+ThNrS9j9AtzKCmfL5WKoGsUltR
 pkKWr0ek2bACtvFDpM7Yc2/BNhHDyMbTxGxk84DGDUjNJmsCM1zIoJP
X-Developer-Key: i=jason-jh.lin@mediatek.com; a=ed25519;
 pk=7Hn+BnFBlPrluT5ks5tKVWb3f7O/bMBs6qEemVJwqOo=
X-Endpoint-Received: by B4 Relay for jason-jh.lin@mediatek.com/20240718 with auth_id=187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Jason-JH.Lin <jason-jh.lin@mediatek.com>
---
Change in v3:
Change config_lock from spin_lock to spin_lock_irqsave

Change in v2:
Add spin_lock protection for config_updating flag.

---
Jason-JH.Lin (2):
      drm/mediatek: Fix missing configuration flags in mtk_crtc_ddp_config()
      drm/mediatek: change config_lock from spin_lock to spin_lock_irqsave

 drivers/gpu/drm/mediatek/mtk_crtc.c | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)
---
base-commit: 469f1bad3c1c6e268059f78c0eec7e9552b3894c
change-id: 20240819-drm-fixup-0819-f51e2d37fcd7

Best regards,
-- 
Jason-JH.Lin <jason-jh.lin@mediatek.com>

