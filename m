From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sun, 04 Oct 2026 23:38:43 +1100
Subject: [PATCH v2 2/2] regmap: Drop map lock during cache init and exit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-regcache-lifecycle-submit-v2-2-976d405e89a7@gmail.com>
References: <20261004-regcache-lifecycle-submit-v2-0-976d405e89a7@gmail.com>
In-Reply-To: <20261004-regcache-lifecycle-submit-v2-0-976d405e89a7@gmail.com>
To: Mark Brown <broonie@kernel.org>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, linux-kernel@vger.kernel.org, 
 driver-core@lists.linux.dev, maple-tree@lists.infradead.org, 
 asahi@lists.linux.dev, Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791117521; l=3467;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=zvpCev1OcFqijOyG7vtnR5Nx239kVlRoXAF9NZ7PjIY=;
 b=kfCOCpZ3IVQaT/GRKTiufdV47V8aaFOG8VELtL2P9tUyQH6IFf1sE/0th6nFG3zBvqs7RTJeP
 TxEbHRVExQXC5ibFY7HtwNJ+jpLqD206UI7K8I489budoBFNPxE56MH
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On systems with CONFIG_PROVE_RAW_LOCK_NESTING enabled, Apple GPIO probe
triggers an "Invalid wait context" lockdep warning.

The driver uses a regmap with a raw spinlock and REGCACHE_FLAT. During
regcache_init(), regcache_flat_init() allocates memory while holding the
raw spinlock. The memory allocator can acquire a non-raw spinlock, which
causes an invalid raw-to-non-raw lock nesting error. The abbreviated call
chain is:

  apple_gpio_pinctrl_probe
    regcache_init
      regcache_flat_init
        __kmalloc_noprof
          __pcs_replace_empty_main
            refill_objects
              _raw_spin_lock_irqsave

Cache allocation occurs before the regmap is published, cache destruction
occurs after users have stopped accessing it, and regmap_reinit_cache()
requires callers to prevent concurrent access. Remove the outer map lock
from cache initialization and destruction. Keep it for cache population
and normal register access.

The Maple cache still uses its internal spinlock during teardown. That
lock can also be acquired from hard IRQ context during register access, so
use spin_lock_irqsave() during teardown to preserve its IRQ-safe lockdep
state.

Fixes: fd4ebc07b4df ("regmap: Hold the regmap lock when allocating and freeing the cache")
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 drivers/base/regmap/regcache-maple.c | 5 +++--
 drivers/base/regmap/regcache.c       | 6 ------
 2 files changed, 3 insertions(+), 8 deletions(-)

diff --git a/drivers/base/regmap/regcache-maple.c b/drivers/base/regmap/regcache-maple.c
index e46fe5c32b..9419dc1be9 100644
--- a/drivers/base/regmap/regcache-maple.c
+++ b/drivers/base/regmap/regcache-maple.c
@@ -312,16 +312,17 @@ static void regcache_maple_exit(struct regmap *map)
 	struct maple_tree *mt = map->cache;
 	MA_STATE(mas, mt, 0, UINT_MAX);
 	unsigned int *entry;
+	unsigned long flags;
 
 	/* if we've already been called then just return */
 	if (!mt)
 		return;
 
-	mas_lock(&mas);
+	spin_lock_irqsave(&mt->ma_lock, flags);
 	mas_for_each(&mas, entry, UINT_MAX)
 		kfree(entry);
 	__mt_destroy(mt);
-	mas_unlock(&mas);
+	spin_unlock_irqrestore(&mt->ma_lock, flags);
 
 	kfree(mt);
 	map->cache = NULL;
diff --git a/drivers/base/regmap/regcache.c b/drivers/base/regmap/regcache.c
index 0d58d900a2..b137ded7fd 100644
--- a/drivers/base/regmap/regcache.c
+++ b/drivers/base/regmap/regcache.c
@@ -225,9 +225,7 @@ int regcache_init(struct regmap *map, const struct regmap_config *config)
 	if (map->cache_ops->init) {
 		dev_dbg(map->dev, "Initializing %s cache\n",
 			map->cache_ops->name);
-		map->lock(map->lock_arg);
 		ret = map->cache_ops->init(map);
-		map->unlock(map->lock_arg);
 		if (ret)
 			goto err_free_reg_defaults;
 	}
@@ -259,9 +257,7 @@ int regcache_init(struct regmap *map, const struct regmap_config *config)
 err_exit:
 	if (map->cache_ops->exit) {
 		dev_dbg(map->dev, "Destroying %s cache\n", map->cache_ops->name);
-		map->lock(map->lock_arg);
 		map->cache_ops->exit(map);
-		map->unlock(map->lock_arg);
 	}
 err_free_reg_defaults:
 	kfree(map->reg_defaults);
@@ -281,9 +277,7 @@ void regcache_exit(struct regmap *map)
 	if (map->cache_ops->exit) {
 		dev_dbg(map->dev, "Destroying %s cache\n",
 			map->cache_ops->name);
-		map->lock(map->lock_arg);
 		map->cache_ops->exit(map);
-		map->unlock(map->lock_arg);
 	}
 
 	kfree(map->reg_defaults);

-- 
2.55.0

