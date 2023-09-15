From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 15 Sep 2023 11:10:44 +0300
Subject: [PATCH v4 02/42] ARM: ep93xx: add swlocked prototypes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230915-ep93xx-v4-2-a1d779dcec10@maquefel.me>
References: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
In-Reply-To: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
To: Nikita Shubin <nikita.shubin@maquefel.me>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Sergey Shtylyov <s.shtylyov@omp.ru>
Cc: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Damien Le Moal <dlemoal@kernel.org>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 linux-kernel@vger.kernel.org, Arnd Bergmann <arnd@arndb.de>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694765525; l=998;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=4e/Qr2asmQtXJMkiz50DzFz2rs1k952ZZU/wOSJH0lk=;
 b=jsOX10rW3UP4eHzu10ShbnxtbhsIPxnfNQJ55bMbdLiieNrbNHxswj7ceLFSJRWoH3SH7AcUHyRF
 QUguy3+KA+Ig1fD/1KOb8BGByRCg43rd9wijIc7qQK1FwtyJ2wMM
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ep93xx_regmap_write and ep93xx_regmap_update_bits to make drivers
compilable before actual implementation is added.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 include/linux/soc/cirrus/ep93xx.h | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/include/linux/soc/cirrus/ep93xx.h b/include/linux/soc/cirrus/ep93xx.h
index 56fbe2dc59b1..8b4b8221ed4c 100644
--- a/include/linux/soc/cirrus/ep93xx.h
+++ b/include/linux/soc/cirrus/ep93xx.h
@@ -3,6 +3,7 @@
 #define _SOC_EP93XX_H
 
 struct platform_device;
+struct regmap;
 
 #define EP93XX_CHIP_REV_D0	3
 #define EP93XX_CHIP_REV_D1	4
@@ -34,4 +35,9 @@ static inline unsigned int ep93xx_chip_revision(void) { return 0; }
 
 #endif
 
+static inline void ep93xx_regmap_write(struct regmap *map, unsigned int reg, unsigned int val) {}
+static inline void ep93xx_regmap_update_bits(struct regmap *map, unsigned int reg,
+					     unsigned int mask, unsigned int val)
+{ }
+
 #endif

-- 
2.39.2

