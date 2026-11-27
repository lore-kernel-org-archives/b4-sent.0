From: Hank Liou <hank.liou@mediatek.com>
Date: Fri, 27 Nov 2026 14:12:56 +0800
Subject: [PATCH] phy: phy-mtk-dp: Suppress sysfs bind/unbind
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-phy-mtk-dp-suppress-bind-v1-1-eb64c6e39240@mediatek.com>
X-B4-Tracking: v=1; b=H4sIAGcfCWsC/x2MQQqDMBAAvyJ7dqGJWsWvSA/GbOpSjCFrRQn5e
 0OPwzCTQCgyCYxVgkgnC+++gKorWNbZvwnZFgb90E+ldI9hvXE7PmgDyjeESCJo2FvslqFzfdN
 aRwZKXpTj67+eXjn/APeP2aZqAAAA
X-Change-ID: 20261127-phy-mtk-dp-suppress-bind-5c85f734dfeb
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: Chunfeng Yun <chunfeng.yun@mediatek.com>, 
 Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Markus Schneider-Pargmann <msp@baylibre.com>, CK Hu <ck.hu@mediatek.com>, 
 linux-phy@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, Hank Liou <hank.liou@mediatek.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795759976; l=1859;
 i=hank.liou@mediatek.com; s=20261126; h=from:subject:message-id;
 bh=O3jXFQr6H1w8UsvUZJ9qBE1F3KBO3rzzg1q1UUmq4PE=;
 b=0Qq9O8JaNLT8C+2TcaCnF7eQXA+zB8jRSZrFJjKrHanyORj07ENpyhfdLhjuUmcbhxvvAtinQ
 qlksxz2dR4sDTTdl3HiVOxkzXmeqU+Q3aqgo1eD3lvZ57A98med4pIm
X-Developer-Key: i=hank.liou@mediatek.com; a=ed25519;
 pk=oQN2zU+HMrJQgqX4bhL5CVRrBmac4amZ/53yK20L/6M=
X-Endpoint-Received: by B4 Relay for hank.liou@mediatek.com/20261126 with auth_id=1646
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mtk_dp_register_phy() registers the "mediatek-dp-phy" platform device
as a child of mtk_dp and caches the struct phy returned by
devm_phy_get() in mtk_dp->phy. The PHY driver still exposes the sysfs
unbind attribute, so root can unbind the child while mediatek-drm-dp
stays bound. devres then frees the struct phy, and the next
phy_configure(), phy_reset() or phy_init() call from mtk_dp uses freed
memory.

This was observed on a MT8188 Chromebook running a ChromeOS 6.1 kernel:
after unbinding the PHY device from sysfs, plugging in a DP monitor
panics in phy_reset() from the HPD IRQ thread.

The legacy PHY device is only created and destroyed by its parent, so
set suppress_bind_attrs to drop the bind/unbind attributes and let the
PHY go away only together with mtk_dp.

Fixes: f70ac097a2cf ("drm/mediatek: Add MT8195 Embedded DisplayPort driver")
Signed-off-by: Hank Liou <hank.liou@mediatek.com>
---
Other PHY drivers disable sysfs bind/unbind for the same reason, e.g. commit 6aeec986f1bc ("phy: samsung: disable bind/unbind platform driver feature"): their consumers have no way to be told that the PHY went away.
---
 drivers/phy/mediatek/phy-mtk-dp.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/phy/mediatek/phy-mtk-dp.c b/drivers/phy/mediatek/phy-mtk-dp.c
index 0048e1a8c6..924f08ed4d 100644
--- a/drivers/phy/mediatek/phy-mtk-dp.c
+++ b/drivers/phy/mediatek/phy-mtk-dp.c
@@ -828,6 +828,7 @@ static struct platform_driver mtk_dp_phy_driver = {
 	.driver = {
 		.name = "mediatek-dp-phy",
 		.of_match_table = mtk_dp_phy_of_match,
+		.suppress_bind_attrs = true,
 	},
 };
 module_platform_driver(mtk_dp_phy_driver);

---
base-commit: ebb7a8dc1e74c705daffe11c2faf38ec2628f838
change-id: 20261127-phy-mtk-dp-suppress-bind-5c85f734dfeb

Best regards,
-- 
Hank Liou <hank.liou@mediatek.com>

