From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 20 Nov 2026 21:50:12 +0000
Subject: [PATCH] mfd: syscon: Give each syscon its own lockdep class
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-syscon-lockdep-v1-1-aed779a004b8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/zWO3W7CMAxGX6XK9YzmpA0tmqa9x8RF7Dosoz+sb
 tEQ4t0Jf5dH+nyOz0ZlSqJmU5zNJMekaRwy4Fth+CcMO4HUZjb23XpErEBPyuMA3cj7Vg7QonO
 RqpoticlHh0li+r8Lv7cP1oV+heeb5bmY5G/JpfkxM72ohntpU3w8Q80rxN0elhDhiIDQchlKR
 hJXua9dH1K34rH/vGkpqECGPs35faa19TV572ouESM7G93aSeMroZpCIw1ZKs32crkCfN8YTwM
 BAAA=
X-Change-ID: 20261115-syscon-lockdep-d133fb58c2be
To: Lee Jones <lee@kernel.org>, Arnd Bergmann <arnd@arndb.de>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Mark Brown <broonie@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795211412; l=3821;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=WqiBN6Xp2Rqa6ZfdIfM4Z9bo5BDV1QpOV4b8/NaDhLA=;
 b=bV7qC6N8PcVutSRsBfSL/nmmHW3NwY1Keqwl447bgS/qvzvVny8vuxfTo+l50SKkegBdNZ7VK
 mp5l1YLaOh8Cm9JkXuRnrzzNyNU8T4HtjAak3io8yApvq2tBKt2sVnL
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All syscon regmaps share one lockdep class, as regmap_init_mmio() uses a
static key per call site. Lockdep then mixes up unrelated syscons: on
RK3588 the clock-gated VO1 GRF calls clk_enable() under its regmap lock,
while the CRU's GRF gates take the SYS GRF regmap lock under enable_lock.
This is reported as a circular dependency and disables lockdep.

Lock each syscon regmap with its own spinlock and lockdep class.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S) with a 7.3 based kernel that has
out-of-tree DisplayPort patches, lockdep and KASAN on. Without the patch
lockdep reports the cycle during boot. With it /proc/lockdep shows one
syscon lock -> enable_lock and enable_lock -> another syscon lock, there
is no report and lockdep stays on. Build-tested on for-mfd-next.

Applies on top of "mfd: syscon: Put the clock after regmap_exit()":
https://lore.kernel.org/r/20261119-syscon-clk-uaf-v1-1-dc4a4c1be353@gmail.com

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed every change.
---
 drivers/mfd/syscon.c | 36 +++++++++++++++++++++++++++++++++++-
 1 file changed, 35 insertions(+), 1 deletion(-)

diff --git a/drivers/mfd/syscon.c b/drivers/mfd/syscon.c
index 3ff4e024542b..34f278dfd2a8 100644
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
@@ -20,6 +21,7 @@
 #include <linux/reset.h>
 #include <linux/mfd/syscon.h>
 #include <linux/slab.h>
+#include <linux/spinlock.h>
 
 static DEFINE_MUTEX(syscon_list_lock);
 static LIST_HEAD(syscon_list);
@@ -29,8 +31,29 @@ struct syscon {
 	struct regmap *regmap;
 	struct reset_control *reset;
 	struct list_head list;
+	spinlock_t lock;
+	unsigned long lock_flags;
+	struct lock_class_key lock_key;
 };
 
+static void syscon_lock(void *arg)
+__acquires(&syscon->lock)
+{
+	struct syscon *syscon = arg;
+	unsigned long flags;
+
+	spin_lock_irqsave(&syscon->lock, flags);
+	syscon->lock_flags = flags;
+}
+
+static void syscon_unlock(void *arg)
+__releases(&syscon->lock)
+{
+	struct syscon *syscon = arg;
+
+	spin_unlock_irqrestore(&syscon->lock, syscon->lock_flags);
+}
+
 static const struct regmap_config syscon_regmap_config = {
 	.reg_bits = 32,
 	.val_bits = 32,
@@ -114,12 +137,21 @@ static struct syscon *of_syscon_register(struct device_node *np, bool check_res)
 	if (!syscon_config.max_register)
 		syscon_config.max_register_is_0 = true;
 
+	lockdep_register_key(&syscon->lock_key);
+	spin_lock_init(&syscon->lock);
+	lockdep_set_class(&syscon->lock, &syscon->lock_key);
+	if (!syscon_config.use_hwlock) {
+		syscon_config.lock = syscon_lock;
+		syscon_config.unlock = syscon_unlock;
+		syscon_config.lock_arg = syscon;
+	}
+
 	regmap = regmap_init_mmio(NULL, base, &syscon_config);
 	kfree(syscon_config.name);
 	if (IS_ERR(regmap)) {
 		pr_err("regmap init failed\n");
 		ret = PTR_ERR(regmap);
-		goto err_regmap;
+		goto err_key;
 	}
 
 	if (check_res) {
@@ -159,6 +191,8 @@ static struct syscon *of_syscon_register(struct device_node *np, bool check_res)
 	regmap_exit(regmap);
 	if (!IS_ERR(clk))
 		clk_put(clk);
+err_key:
+	lockdep_unregister_key(&syscon->lock_key);
 err_regmap:
 	iounmap(base);
 	return ERR_PTR(ret);

---
base-commit: 1cb7268b6638c411fc32f373e965eb8ba9e9b2b4
change-id: 20261115-syscon-lockdep-d133fb58c2be
prerequisite-message-id: <20261119-syscon-clk-uaf-v1-1-dc4a4c1be353@gmail.com>
prerequisite-patch-id: 7cf33abeabb3eeaf1ba8ac6c461726fca87702cd

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

