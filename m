From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 20:43:22 +1000
Subject: [PATCH] regmap: Drop map lock during cache init and exit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-regcache-lifecycle-submit-v1-1-83b75ca79d96@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQrCMBBG4auUWRuIVSN6FXGRjH+agTbKTBWl9
 O5Gl9/ivYUMKjA6dwspXmJyrw3bTUdcYh3g5NZMve+DP/UHpxg4coEbJYM/PMLZM00yu+M+70J
 I8Dkxtf6hyPL+vy/X5hQNLmmsXH7HKdoMpXX9AqTUvreEAAAA
X-Change-ID: 20260925-regcache-lifecycle-submit-74f366be0fbc
To: Mark Brown <broonie@kernel.org>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 linux-kernel@vger.kernel.org, driver-core@lists.linux.dev, 
 asahi@lists.linux.dev, Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790333007; l=3198;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=bhjdNcpqzJyQqu6KoQ8twHsi4wLo39lzrrDM3q6SV2U=;
 b=dUG6HMWKRqJlIop9DgRJPb3yaHf2oRN1ulewe0RSquIucnpgEeaD4QYiU0nCrYihnyo2OHmbE
 ZqaWLU/lz7nCNl5ztbqyWdqV8WQL4Uud5DiTfVkChm4nrPoRdWuzwbm
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

GFP_ATOMIC does not make this lock nesting valid.

Holding the map lock during cache allocation and exit is not needed:

- Cache allocation occurs before the regmap is published.
- Cache destruction occurs only after all users stop access.
- regmap_reinit_cache() requires callers to prevent concurrent access.

Commit fd4ebc07b4df ("regmap: Hold the regmap lock when allocating and
freeing the cache") added the lock for Maple tree lockdep validation.
The current Maple tree backend uses internal locking, and cache
population is now separate from cache allocation.

Remove map locking from the cache init and exit callbacks. Keep map
locking for cache population and normal register access.

Fixes: fd4ebc07b4df ("regmap: Hold the regmap lock when allocating and freeing the cache")
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
Tested on Apple M3 MacBook Air (T8122):

- All 4 GPIO controllers probe successfully with lockdep enabled.
- The "Invalid wait context" warning no longer occurs.
- All 549 regmap KUnit tests pass (38 test groups).
---
 drivers/base/regmap/regcache.c | 6 ------
 1 file changed, 6 deletions(-)

diff --git a/drivers/base/regmap/regcache.c b/drivers/base/regmap/regcache.c
index 0d58d900a..b137ded7f 100644
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

---
base-commit: 5dd1818b15d98d4a20806cd00b1b40320b06004f
change-id: 20260925-regcache-lifecycle-submit-74f366be0fbc

Best regards,
-- 
Michael Reeves <michael.reeves077@gmail.com>

