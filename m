From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 19:06:25 +0000
Subject: [PATCH v3 2/2] mfd: syscon: Give each syscon its own lockdep class
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-syscon-lockdep-v3-2-2c786aa075bf@gmail.com>
References: <20261128-syscon-lockdep-v3-0-2c786aa075bf@gmail.com>
In-Reply-To: <20261128-syscon-lockdep-v3-0-2c786aa075bf@gmail.com>
To: Mark Brown <broonie@kernel.org>, Lee Jones <lee@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, driver-core@lists.linux.dev, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Heiko Stuebner <heiko@sntech.de>, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795892783; l=1703;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=4Y01s69EO98KcWO0AfLuI9kE6XE0+tI0DEtJ/8wbdT0=;
 b=gbSHqCRf4fotORvFM2+1n9sWFsOIvq6qJCGRH9Z9rAnUCxVyVZiPP3fdl5+pW6pfJEUM+ax64
 MxQ/Xiz5DPmDwEUlHb8fLV245WvlV0svOdhILBV89N0DmiS4exfw5nJ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All syscon regmaps share the lockdep class of the regmap_init_mmio() call
site. On RK3588 the VO1 GRF calls clk_enable() under its regmap lock, while
the CRU's GRF gates take the SYS GRF regmap lock under enable_lock. Lockdep
reports a circular dependency and turns itself off.

Give each syscon its own class.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/mfd/syscon.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/mfd/syscon.c b/drivers/mfd/syscon.c
index 21a7fcdd2737..e0d5558b3382 100644
--- a/drivers/mfd/syscon.c
+++ b/drivers/mfd/syscon.c
@@ -13,6 +13,7 @@
 #include <linux/err.h>
 #include <linux/hwspinlock.h>
 #include <linux/list.h>
+#include <linux/lockdep.h>
 #include <linux/mutex.h>
 #include <linux/of.h>
 #include <linux/of_address.h>
@@ -29,6 +30,7 @@ struct syscon {
 	struct regmap *regmap;
 	struct reset_control *reset;
 	struct list_head list;
+	struct lock_class_key lock_key;
 };
 
 static const struct regmap_config syscon_regmap_config = {
@@ -62,6 +64,9 @@ static struct syscon *of_syscon_register(struct device_node *np, bool check_res)
 	if (!base)
 		return ERR_PTR(-ENOMEM);
 
+	lockdep_register_key(&syscon->lock_key);
+	syscon_config.lock_key = &syscon->lock_key;
+
 	/* Parse the device's DT node for an endianness specification */
 	if (of_property_read_bool(np, "big-endian"))
 		syscon_config.val_format_endian = REGMAP_ENDIAN_BIG;
@@ -162,6 +167,7 @@ static struct syscon *of_syscon_register(struct device_node *np, bool check_res)
 	regmap_exit(regmap);
 err_regmap:
 	iounmap(base);
+	lockdep_unregister_key(&syscon->lock_key);
 	return ERR_PTR(ret);
 }
 

-- 
2.55.0

