From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Tue, 12 Dec 2023 11:20:18 +0300
Subject: [PATCH v6 01/40] ARM: ep93xx: Add terminator to gpiod_lookup_table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231212-ep93xx-v6-1-c307b8ac9aa8@maquefel.me>
References: <20231212-ep93xx-v6-0-c307b8ac9aa8@maquefel.me>
In-Reply-To: <20231212-ep93xx-v6-0-c307b8ac9aa8@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702369322; l=740;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=BLqbGJKvsA7sLJyVC3iK75j5WqPmntAKufr+KsjrO8M=;
 b=VYM6IAgjJ4AS/synFz4n7psMJW+cvi6GL+317NuXXjxtumJ9AgZbQxp1v1chmXVQemUPzRZop6DM
 ukG6sH4rBKlE34uN7mSliYxHYtu+OecQvOyCJkTXfUuEgThZ/GMk
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without the terminator, if a con_id is passed to gpio_find() that
does not exist in the lookup table the function will not stop looping
correctly, and eventually cause an oops.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 arch/arm/mach-ep93xx/core.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/mach-ep93xx/core.c b/arch/arm/mach-ep93xx/core.c
index 71b113976420..8b1ec60a9a46 100644
--- a/arch/arm/mach-ep93xx/core.c
+++ b/arch/arm/mach-ep93xx/core.c
@@ -339,6 +339,7 @@ static struct gpiod_lookup_table ep93xx_i2c_gpiod_table = {
 				GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN),
 		GPIO_LOOKUP_IDX("G", 0, NULL, 1,
 				GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN),
+		{ }
 	},
 };
 

-- 
2.41.0

