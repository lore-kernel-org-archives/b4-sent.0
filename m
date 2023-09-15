From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 15 Sep 2023 11:11:10 +0300
Subject: [PATCH v4 28/42] ata: pata_ep93xx: add device tree support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230915-ep93xx-v4-28-a1d779dcec10@maquefel.me>
References: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
In-Reply-To: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
To: Sergey Shtylyov <s.shtylyov@omp.ru>, 
 Damien Le Moal <dlemoal@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694765525; l=1082;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=iQdf0+FvvFvVUiOq9gimGZkfb2i0Js2MC1h+Ul6CtHM=;
 b=8RjktMz/XlhaiBntulYXPzsVXoND9QuTSDeM7wL7ZLOwmsJc7F9ajymIP2xiegpp9B9QWN/cacmp
 BY8PCFVaBvgi0Qsk0KXMIG9EBunBmMy9EiLL0J93JoarqPY/XDrW
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add OF ID match table.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/ata/pata_ep93xx.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/ata/pata_ep93xx.c b/drivers/ata/pata_ep93xx.c
index 3f91b6cff353..47686dc1fed6 100644
--- a/drivers/ata/pata_ep93xx.c
+++ b/drivers/ata/pata_ep93xx.c
@@ -44,6 +44,7 @@
 #include <linux/delay.h>
 #include <linux/dmaengine.h>
 #include <linux/ktime.h>
+#include <linux/mod_devicetable.h>
 
 #include <linux/platform_data/dma-ep93xx.h>
 #include <linux/soc/cirrus/ep93xx.h>
@@ -1022,9 +1023,16 @@ static int ep93xx_pata_remove(struct platform_device *pdev)
 	return 0;
 }
 
+static const struct of_device_id ep93xx_pata_of_ids[] = {
+	{ .compatible = "cirrus,ep9312-pata" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ep93xx_pata_of_ids);
+
 static struct platform_driver ep93xx_pata_platform_driver = {
 	.driver = {
 		.name = DRV_NAME,
+		.of_match_table = ep93xx_pata_of_ids,
 	},
 	.probe = ep93xx_pata_probe,
 	.remove = ep93xx_pata_remove,

-- 
2.39.2

