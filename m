From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Thu, 18 Jan 2024 11:20:44 +0300
Subject: [PATCH v7 01/39] ARM: ep93xx: Add terminator to gpiod_lookup_table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240118-ep93xx-v7-1-d953846ae771@maquefel.me>
References: <20240118-ep93xx-v7-0-d953846ae771@maquefel.me>
In-Reply-To: <20240118-ep93xx-v7-0-d953846ae771@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, "Wu, Aaron" <Aaron.Wu@analog.com>, 
 Olof Johansson <olof@lixom.net>, Lee Jones <lee@kernel.org>, 
 Ralf Baechle <ralf@linux-mips.org>, 
 Linus Walleij <linus.walleij@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705566176; l=863;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=V19ji6HRT/LvwSZh25S7DqwrqE2geyei6CamYGzg/Hc=;
 b=YR1wB031b++RwryG4mHPVamzIXC2oyPM3Zu9KFhD3ooTRX5FUQNHjBLVAwtpkLRZM/E0zEh7uKZE
 +8poBxUwCRq+UbGwKikH2jXXdCCQCO/FeFkZ/Bt3+BH9FmY0cNWn
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without the terminator, if a con_id is passed to gpio_find() that
does not exist in the lookup table the function will not stop looping
correctly, and eventually cause an oops.

Fixes: b2e63555592f ("i2c: gpio: Convert to use descriptors")
Reported-by: Andy Shevchenko <andriy.shevchenko@intel.com>
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

