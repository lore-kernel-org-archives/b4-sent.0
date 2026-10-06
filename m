From: Michael Reeves <michael.reeves077@gmail.com>
Date: Tue, 06 Oct 2026 18:03:16 +1100
Subject: [PATCH v3 2/2] regmap: Drop map lock during cache init and exit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-regcache-lifecycle-submit-v3-2-37bdd82fd47c@gmail.com>
References: <20261006-regcache-lifecycle-submit-v3-0-37bdd82fd47c@gmail.com>
In-Reply-To: <20261006-regcache-lifecycle-submit-v3-0-37bdd82fd47c@gmail.com>
To: Mark Brown <broonie@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Andrew Ballance <andrewjballance@gmail.com>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, linux-kernel@vger.kernel.org, 
 driver-core@lists.linux.dev, maple-tree@lists.infradead.org, 
 asahi@lists.linux.dev, linux-mm@kvack.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791270197; l=4482;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=SZnYqaht9eHldUBPSRohyllzfPag5yZhmg8EqkFgLTI=;
 b=uN5nLx6ZAujPvKZMbgpw3DySy1o1+pySMXk2i51JpxFsW1vI7ul6yjeaShfQMDox58eZ0ur+P
 QigVOzCdaz4BIRbCRE2hVKGYtz7KbVfe1XF33e16jGnFVgEnrsdLO0B
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
lock can also be acquired from hard IRQ context during register access.
Add Maple-state irqsave helpers and use them during teardown to preserve
the lock's IRQ-safe lockdep state.

Fixes: fd4ebc07b4df ("regmap: Hold the regmap lock when allocating and freeing the cache")
Suggested-by: Mark Brown <broonie@kernel.org>
Suggested-by: Liam R. Howlett <liam@infradead.org>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 drivers/base/regmap/regcache-maple.c | 9 +++++++--
 drivers/base/regmap/regcache.c       | 6 ------
 include/linux/maple_tree.h           | 4 ++++
 3 files changed, 11 insertions(+), 8 deletions(-)

diff --git a/drivers/base/regmap/regcache-maple.c b/drivers/base/regmap/regcache-maple.c
index e46fe5c32b..16e488da5f 100644
--- a/drivers/base/regmap/regcache-maple.c
+++ b/drivers/base/regmap/regcache-maple.c
@@ -312,16 +312,21 @@ static void regcache_maple_exit(struct regmap *map)
 	struct maple_tree *mt = map->cache;
 	MA_STATE(mas, mt, 0, UINT_MAX);
 	unsigned int *entry;
+	unsigned long flags;
 
 	/* if we've already been called then just return */
 	if (!mt)
 		return;
 
-	mas_lock(&mas);
+	/*
+	 * Register access may take the Maple lock from hard IRQ context, so
+	 * preserve its IRQ-safe lockdep state during teardown.
+	 */
+	mas_lock_irqsave(&mas, flags);
 	mas_for_each(&mas, entry, UINT_MAX)
 		kfree(entry);
 	__mt_destroy(mt);
-	mas_unlock(&mas);
+	mas_unlock_irqrestore(&mas, flags);
 
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
diff --git a/include/linux/maple_tree.h b/include/linux/maple_tree.h
index e595ae5cd0..f6491a92ea 100644
--- a/include/linux/maple_tree.h
+++ b/include/linux/maple_tree.h
@@ -507,9 +507,13 @@ struct ma_wr_state {
 };
 
 #define mas_lock(mas)           spin_lock(&((mas)->tree->ma_lock))
+#define mas_lock_irqsave(mas, flags) \
+		spin_lock_irqsave(&((mas)->tree->ma_lock), flags)
 #define mas_lock_nested(mas, subclass) \
 		spin_lock_nested(&((mas)->tree->ma_lock), subclass)
 #define mas_unlock(mas)         spin_unlock(&((mas)->tree->ma_lock))
+#define mas_unlock_irqrestore(mas, flags) \
+		spin_unlock_irqrestore(&((mas)->tree->ma_lock), flags)
 
 /*
  * Special values for ma_state.node.

-- 
2.55.0

