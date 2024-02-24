From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 24 Feb 2024 18:42:24 +0100
Subject: [PATCH v2 3/7] mtd: maps: sun_uflash: Declare uflash_devinit
 static
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240224-sam-fix-sparc32-all-builds-v2-3-1f186603c5c4@ravnborg.org>
References: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
In-Reply-To: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
To: "Maciej W. Rozycki" <macro@orcam.me.uk>, sparclinux@vger.kernel.org, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>
Cc: Miquel Raynal <miquel.raynal@bootlin.com>, 
 linux-parport@lists.infradead.org, "David S. Miller" <davem@davemloft.net>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708796545; l=1022;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=1CQEn1rR62vDngISirB1bMAgXc9+BD3JSgTxbntNHpM=;
 b=J7vmq08a1WA/yKaJnn8961lo1M50MdiWJaS56NAsS66meT3rhpm7+wO7l1LTep/srhdb9PoD+9SA
 OHZdMimeCmy5hI9xnAPkeScVn7WU6Yy3CoFvNqOgAlKwHkwNbP+z
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes the following warning:
sun_uflash.c:50:5: error: no previous prototype for 'uflash_devinit'

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Fixes: 0fcb70851fbf ("Makefile.extrawarn: turn on missing-prototypes globally")
Reviewed-by: Randy Dunlap <rdunlap@infradead.org>
Tested-by: Randy Dunlap <rdunlap@infradead.org> # build-tested
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 drivers/mtd/maps/sun_uflash.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/mtd/maps/sun_uflash.c b/drivers/mtd/maps/sun_uflash.c
index f58cfb15d6e8..b69dade3f7ad 100644
--- a/drivers/mtd/maps/sun_uflash.c
+++ b/drivers/mtd/maps/sun_uflash.c
@@ -47,7 +47,7 @@ struct map_info uflash_map_templ = {
 	.bankwidth =	UFLASH_BUSWIDTH,
 };
 
-int uflash_devinit(struct platform_device *op, struct device_node *dp)
+static int uflash_devinit(struct platform_device *op, struct device_node *dp)
 {
 	struct uflash_dev *up;
 

-- 
2.34.1

