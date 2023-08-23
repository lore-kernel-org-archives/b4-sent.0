From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Wed, 23 Aug 2023 12:47:27 +0300
Subject: [PATCH 1/2] ata: pata_ep93xx: fix error return code in probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230823-ep93xx_pata_fixes-v1-1-d7e7229be148@maquefel.me>
References: <20230823-ep93xx_pata_fixes-v1-0-d7e7229be148@maquefel.me>
In-Reply-To: <20230823-ep93xx_pata_fixes-v1-0-d7e7229be148@maquefel.me>
To: Sergey Shtylyov <s.shtylyov@omp.ru>, 
 Damien Le Moal <dlemoal@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Shubin <nikita.shubin@maquefel.me>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692784059; l=900;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=jYEaemYd1aErVDz1ZLCTtX58S5YLSNWId6yDIFw7HVw=;
 b=iV4woMczzqwWfAyaeeBpmYNnvFmAVzLgmavJtQvOa677LWj7OjdgnBPGOjXOyvkq1IvHu2gJVkwf
 NhAV/ZimBI22z6M/kXCSrq4TsrBRgHlpdUKT5w+AmYCLfN+B2KFO
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Return -ENOMEM from ep93xx_pata_probe() if devm_kzalloc() or
ata_host_alloc() fails.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/ata/pata_ep93xx.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/ata/pata_ep93xx.c b/drivers/ata/pata_ep93xx.c
index c6e043e05d43..4ce0f37c7a89 100644
--- a/drivers/ata/pata_ep93xx.c
+++ b/drivers/ata/pata_ep93xx.c
@@ -939,7 +939,7 @@ static int ep93xx_pata_probe(struct platform_device *pdev)
 
 	drv_data = devm_kzalloc(&pdev->dev, sizeof(*drv_data), GFP_KERNEL);
 	if (!drv_data) {
-		err = -ENXIO;
+		err = -ENOMEM;
 		goto err_rel_gpio;
 	}
 
@@ -952,7 +952,7 @@ static int ep93xx_pata_probe(struct platform_device *pdev)
 	/* allocate host */
 	host = ata_host_alloc(&pdev->dev, 1);
 	if (!host) {
-		err = -ENXIO;
+		err = -ENOMEM;
 		goto err_rel_dma;
 	}
 

-- 
2.39.2

