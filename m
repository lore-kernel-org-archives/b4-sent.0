From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 19:06:24 +0000
Subject: [PATCH v3 1/2] regmap: Add an optional lockdep class to struct
 regmap_config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-syscon-lockdep-v3-1-2c786aa075bf@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795892783; l=1932;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=spEnYeciCqrdi37P22zTgrk/i7Jyr3pb9K5mnnJSejo=;
 b=9oKYqfu9iLWUnc5mN/Z9W8YHBYw+ifC4GItAkT/lzwz6DbgKQj3QdbcXVI+HfbzyN/XwuBayA
 oM/jEMpN7I1Au9MAYe3Poa0OOSAe2Ax6/xWCFnms61p4Mr+Hl/dJ/3X
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lockdep class of regmap's own lock is per regmap_init_*() call site.
Maps made at one call site, such as all syscons, share it, so lockdep
mixes up their unrelated lock chains.

Let the caller give each map its own class with config->lock_key.

Suggested-by: Lee Jones <lee@kernel.org>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/base/regmap/regmap.c | 3 +++
 include/linux/regmap.h       | 3 +++
 2 files changed, 6 insertions(+)

diff --git a/drivers/base/regmap/regmap.c b/drivers/base/regmap/regmap.c
index 0ba82fcc55bf..3534d27909a0 100644
--- a/drivers/base/regmap/regmap.c
+++ b/drivers/base/regmap/regmap.c
@@ -720,6 +720,9 @@ static int regmap_set_lock(struct regmap *map, const struct regmap_config *confi
 		return 0;
 	}
 
+	if (config->lock_key)
+		lock_key = config->lock_key;
+
 	if (fast_io) {
 		if (config->use_raw_spinlock) {
 			raw_spin_lock_init(&map->raw_spinlock);
diff --git a/include/linux/regmap.h b/include/linux/regmap.h
index 6194948ff9ed..872de9b3dcd5 100644
--- a/include/linux/regmap.h
+++ b/include/linux/regmap.h
@@ -347,6 +347,8 @@ typedef void (*regmap_unlock)(void *);
  * @lock_arg:	  This field is passed as the only argument of lock/unlock
  *		  functions (ignored in case regular lock/unlock functions
  *		  are not overridden).
+ * @lock_key:	  Optional lockdep class for regmap's own lock, instead of
+ *		  one per call site. Must stay registered while the map exists.
  * @max_register: Optional, specifies the maximum valid register address.
  * @max_register_is_0: Optional, specifies that zero value in @max_register
  *                     should be taken into account. This is a workaround to
@@ -445,6 +447,7 @@ struct regmap_config {
 	regmap_lock lock;
 	regmap_unlock unlock;
 	void *lock_arg;
+	struct lock_class_key *lock_key;
 
 	unsigned int max_register;
 	bool max_register_is_0;

-- 
2.55.0

