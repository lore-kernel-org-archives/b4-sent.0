From: Sam Ravnborg <sam@ravnborg.org>
Date: Fri, 23 Feb 2024 20:36:49 +0100
Subject: [PATCH 3/6] mtd: maps: sun_uflash: Declare uflash_devinit static
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240223-sam-fix-sparc32-all-builds-v1-3-5c60fd5c9250@ravnborg.org>
References: <20240223-sam-fix-sparc32-all-builds-v1-0-5c60fd5c9250@ravnborg.org>
In-Reply-To: <20240223-sam-fix-sparc32-all-builds-v1-0-5c60fd5c9250@ravnborg.org>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 "Maciej W. Rozycki" <macro@orcam.me.uk>
Cc: sparclinux@vger.kernel.org, linux-parport@lists.infradead.org, 
 "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708717023; l=826;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=x2uAqMv58+DpgI3eYVpcudpJwlGuM5xq788IvJ499fo=;
 b=wqNjuoc4O6iR10ugVZng/NWir9h8I22iG/JoQ0Dc1v9cOvXdZROnE4FJPufIwv1hmdqp3WaYn6on
 OHCOKIlgABUBMri0Mmqs42qDdIHPTN0exdx5pM/8IpLNnnO/1ZpO
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes the following warning:
sun_uflash.c:50:5: error: no previous prototype for 'uflash_devinit'

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
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

