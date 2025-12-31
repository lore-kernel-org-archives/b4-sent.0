From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Jan 2026 03:52:50 +0800
Subject: [PATCH v2 4/5] clk: allow assigning parent lazily
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-clk-reparent-v2-4-3eb42b78c7f1@outlook.com>
References: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
In-Reply-To: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767210769; l=4869;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=7wdCMBv677d3gdkHf9pFYWh3TG4TqHVTK1I2zZhAd9k=;
 b=x4nT/ygM9P7HULN5RnPer9Asp3hpcz84Ke+mwj5yKc4wFJKF9Vx018mF5PdJs2Xs4vkUveW0W
 MHYuMwWEUcAATzYeiWOpHMJWrgwGaK70F0nnmtn8gi2EveK3YE3z92r
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Don't mandate the parent device exists when registering a clock.

Instead, cache the parent name in the core clk struct and resolve the
parent in clk_get_parent(), which is called lazily upon real use.

Disable this feature for xPLs by default to save size.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/Kconfig      | 12 ++++++++++++
 drivers/clk/clk-uclass.c | 44 ++++++++++++++++++++++++++++++++++++++++++--
 drivers/clk/clk.c        | 14 ++++++++++++--
 include/clk.h            |  2 ++
 4 files changed, 68 insertions(+), 4 deletions(-)

diff --git a/drivers/clk/Kconfig b/drivers/clk/Kconfig
index 19aa2ffa5396..bb2a97a4a07a 100644
--- a/drivers/clk/Kconfig
+++ b/drivers/clk/Kconfig
@@ -40,6 +40,18 @@ config VPL_CLK
 	  setting up clocks within TPL, and allows the same drivers to be
 	  used as U-Boot proper.
 
+config CLK_LAZY_REPARENT
+	bool "Enable clock lazy reparenting feature"
+	depends on CLK_CCF
+	default n if SPL_CLK || TPL_CLK || VPL_CLK
+	default y
+	help
+	  This option allows registering clocks in a less strict order that
+	  Parent clocks can be registered before their children. The clock subsystem
+	  will cache the parent's name and resolve it to the real parent device "lazily".
+	  This is the default behavior in Linux clock subsystem. Enabling this feature
+	  should simplifies the porting of Linux clock drivers to U-Boot.
+
 config CLK_BCM6345
 	bool "Clock controller driver for BCM6345"
 	depends on CLK && ARCH_BMIPS
diff --git a/drivers/clk/clk-uclass.c b/drivers/clk/clk-uclass.c
index bfad71e7af70..cea79e05ea09 100644
--- a/drivers/clk/clk-uclass.c
+++ b/drivers/clk/clk-uclass.c
@@ -490,6 +490,32 @@ ulong clk_get_rate(struct clk *clk)
 	return ops->get_rate(clk);
 }
 
+static struct udevice *clk_reparent(struct clk *clk, const char *parent_name)
+{
+	struct udevice *pdev;
+	int ret;
+
+	if (!clk_valid(clk))
+		return NULL;
+
+	if (!parent_name)
+		return NULL;
+
+	debug("%s(clk=%p) reparenting to %s\n", __func__, clk, parent_name);
+
+	ret = uclass_get_device_by_name(UCLASS_CLK, parent_name, &pdev);
+	if (ret) {
+		log_err("%s(clk=%p) failed to find parent \"%s\"\n", __func__, clk, parent_name);
+		return NULL;
+	}
+
+	ret = device_reparent(clk->dev, pdev);
+	if (ret)
+		return NULL;
+
+	return pdev;
+}
+
 struct clk *clk_get_parent(struct clk *clk)
 {
 	struct udevice *pdev;
@@ -500,8 +526,18 @@ struct clk *clk_get_parent(struct clk *clk)
 		return NULL;
 
 	pdev = dev_get_parent(clk->dev);
-	if (!pdev)
-		return ERR_PTR(-ENODEV);
+	if (!pdev) {
+		if (CONFIG_IS_ENABLED(CLK_LAZY_REPARENT)) {
+			pdev = clk_reparent(clk, clk->parent_name);
+			free(clk->parent_name);
+			clk->parent_name = NULL;
+
+			if (!pdev)
+				return ERR_PTR(-ENODEV);
+		} else {
+			return ERR_PTR(-ENODEV);
+		}
+	}
 
 	if (device_get_uclass_id(pdev) != UCLASS_CLK)
 		return ERR_PTR(-ENODEV);
@@ -625,6 +661,10 @@ int clk_set_parent(struct clk *clk, struct clk *parent)
 	debug("%s(clk=%p, parent=%p)\n", __func__, clk, parent);
 	if (!clk_valid(clk))
 		return 0;
+
+	free(clk->parent_name);
+	clk->parent_name = NULL;
+
 	ops = clk_dev_ops(clk->dev);
 
 	if (!ops->set_parent)
diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index b8c2e8d531b9..32b3c03ab09a 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -24,8 +24,18 @@ int clk_register(struct clk *clk, const char *drv_name,
 	if (parent_name) {
 		ret = uclass_get_device_by_name(UCLASS_CLK, parent_name, &parent);
 		if (ret) {
-			log_err("%s: failed to get %s device (parent of %s)\n",
-				__func__, parent_name, name);
+			log_debug("%s: failed to get %s device (parent of %s)\n",
+				  __func__, parent_name, name);
+
+			if (CONFIG_IS_ENABLED(CLK_LAZY_REPARENT)) {
+				/*
+				 * The parent is not yet registered.
+				 * Cache the parent name and resolve it later.
+				 */
+				clk->parent_name = strdup(parent_name);
+				if (!clk->parent_name)
+					return -ENOMEM;
+			}
 		} else {
 			log_debug("%s: name: %s parent: %s [0x%p]\n", __func__, name,
 				  parent->name, parent);
diff --git a/include/clk.h b/include/clk.h
index a6ef4e026922..5f684dcbf9d2 100644
--- a/include/clk.h
+++ b/include/clk.h
@@ -37,6 +37,7 @@ struct udevice;
 /**
  * struct clk - A handle to (allowing control of) a single clock.
  * @dev: The device which implements the clock signal.
+ * @parent_name: The name of the parent.
  * @rate: The clock rate (in HZ).
  * @flags: Flags used across common clock structure (e.g. %CLK_)
  *         Clock IP blocks specific flags (i.e. mux, div, gate, etc) are defined
@@ -62,6 +63,7 @@ struct udevice;
  */
 struct clk {
 	struct udevice *dev;
+	char *parent_name;
 	long long rate;	/* in HZ */
 	u32 flags;
 	int enable_count;

-- 
2.43.0

