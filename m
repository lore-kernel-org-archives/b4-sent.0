From: Rui Cao <i@udp0.com>
Date: Tue, 17 Nov 2026 17:11:33 +0800
Subject: [PATCH v2 3/5] watchdog: mediatek: Add MT6833
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-mt6833-base-v2-3-058a0685c40c@udp0.com>
References: <20261117-mt6833-base-v2-0-058a0685c40c@udp0.com>
In-Reply-To: <20261117-mt6833-base-v2-0-058a0685c40c@udp0.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-watchdog@vger.kernel.org, linux-serial@vger.kernel.org, 
 phone-devel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>, 
 Rui Cao <i@udp0.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794906695; l=1016;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=b+SMsmXF4lIy9e6odjAYdc3PAu/hTjDn96dpS5CTy+E=;
 b=dIK67eDYZoEmBPQ+hhU+D0gRmd9uuLWDbGnoXMjK4JmWt/tYUhv9JDXMU27TE8XI8gemcGHCy
 InnqM3tQG7oBma8vqXpGLdDhPg59o8gZC1oGUb2ZgHn6kqMJQ4Of6Zo
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Match MT6833's watchdog. It works as MT6589's, but its TOPRGU reset
layout isn't known well enough to describe, so it gets no match data
and the driver registers no reset controller for it.

Signed-off-by: Rui Cao <i@udp0.com>
---
 drivers/watchdog/mtk_wdt.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/watchdog/mtk_wdt.c b/drivers/watchdog/mtk_wdt.c
index 1630ab65d59..575233c7911 100644
--- a/drivers/watchdog/mtk_wdt.c
+++ b/drivers/watchdog/mtk_wdt.c
@@ -595,6 +595,7 @@ static const struct of_device_id mtk_wdt_dt_ids[] = {
 	{ .compatible = "mediatek,mt6589-wdt", .data = &mt6589_data },
 	{ .compatible = "mediatek,mt6735-wdt", .data = &mt6735_data },
 	{ .compatible = "mediatek,mt6795-wdt", .data = &mt6795_data },
+	{ .compatible = "mediatek,mt6833-wdt" },
 	{ .compatible = "mediatek,mt7986-wdt", .data = &mt7986_data },
 	{ .compatible = "mediatek,mt7988-wdt", .data = &mt7988_data },
 	{ .compatible = "mediatek,mt8167-wdt", .data = &mt8167_data },

-- 
Git-157)

