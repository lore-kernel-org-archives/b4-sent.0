From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 21 Jun 2025 18:54:19 +0800
Subject: [PATCH RFC 2/3] clk: allow assigning parent lazily
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250621-clk-reparent-v1-2-48a7f2f31c59@outlook.com>
References: <20250621-clk-reparent-v1-0-48a7f2f31c59@outlook.com>
In-Reply-To: <20250621-clk-reparent-v1-0-48a7f2f31c59@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750503259; l=4677;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=M4ETxzx1tCptzduCq/daGnVeROMlU8YfDr9GIZMOx4o=;
 b=8od1PjD+TgZEf9MupDiUgqSp9I/+GlIFGfaOfDXPRbx41XTjIHkWsXGm6vQzRj8qiYAqyFSiJ
 RNk/O+d/kteCW4hl0gihL46oYFE+/sqJFz7W/bPITLEGFX/XG31K/3A
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Don't mandate parent to exist when registering clocks.

Cache the parent name in core clk struct, and refresh the parent in
clk_get_parent(), which is called later.

Also modify clk_enable() and clk_disable() to use clk_get_parent()
rather than getting parent from dm directly, which bypassed the
reparent logic.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk-uclass.c | 47 ++++++++++++++++++++++++++++++++++-------------
 drivers/clk/clk.c        | 14 ++++++++++++--
 include/clk.h            |  2 ++
 3 files changed, 48 insertions(+), 15 deletions(-)

diff --git a/drivers/clk/clk-uclass.c b/drivers/clk/clk-uclass.c
index 2167cd5ad0fe..f619b963e66d 100644
--- a/drivers/clk/clk-uclass.c
+++ b/drivers/clk/clk-uclass.c
@@ -494,14 +494,31 @@ struct clk *clk_get_parent(struct clk *clk)
 {
 	struct udevice *pdev;
 	struct clk *pclk;
+	int ret;
 
 	debug("%s(clk=%p)\n", __func__, clk);
 	if (!clk_valid(clk))
 		return NULL;
 
 	pdev = dev_get_parent(clk->dev);
-	if (!pdev)
-		return ERR_PTR(-ENODEV);
+	if (!pdev) {
+		clk = dev_get_clk_ptr(clk->dev);
+		if (!clk->parent_name)
+			return ERR_PTR(-ENODEV);
+
+		debug("%s: Trying to reparent to %s\n", __func__, clk->parent_name);
+
+		ret = uclass_get_device_by_name(UCLASS_CLK, clk->parent_name, &pdev);
+		free(clk->parent_name);
+		clk->parent_name = NULL;
+		if (ret)
+			return ERR_PTR(ret);
+
+		ret = device_reparent(clk->dev, pdev);
+		if (ret)
+			return ERR_PTR(ret);
+	}
+
 	pclk = dev_get_clk_ptr(pdev);
 	if (!pclk)
 		return ERR_PTR(-ENODEV);
@@ -652,7 +669,7 @@ int clk_set_parent(struct clk *clk, struct clk *parent)
 int clk_enable(struct clk *clk)
 {
 	const struct clk_ops *ops;
-	struct clk *clkp = NULL;
+	struct clk *clkp = NULL, *clk_parent;
 	int ret;
 
 	debug("%s(clk=%p name=%s)\n", __func__, clk, clk->dev->name);
@@ -668,9 +685,10 @@ int clk_enable(struct clk *clk)
 				clkp->enable_count++;
 				return 0;
 			}
-			if (clkp->dev->parent &&
-			    device_get_uclass_id(clkp->dev->parent) == UCLASS_CLK) {
-				ret = clk_enable(dev_get_clk_ptr(clkp->dev->parent));
+
+			clk_parent = clk_get_parent(clkp);
+			if (!IS_ERR_OR_NULL(clk_parent)) {
+				ret = clk_enable(clk_parent);
 				if (ret) {
 					printf("Enable %s failed\n",
 					       clkp->dev->parent->name);
@@ -743,13 +761,16 @@ int clk_disable(struct clk *clk)
 				return ret;
 		}
 
-		if (clkp && clkp->dev->parent &&
-		    device_get_uclass_id(clkp->dev->parent) == UCLASS_CLK) {
-			ret = clk_disable(dev_get_clk_ptr(clkp->dev->parent));
-			if (ret) {
-				printf("Disable %s failed\n",
-				       clkp->dev->parent->name);
-				return ret;
+		if (clkp) {
+			struct clk *clk_parent = clk_get_parent(clkp);
+
+			if (!IS_ERR_OR_NULL(clk_parent)) {
+				ret = clk_disable(clk_parent);
+				if (ret) {
+					printf("Disable %s failed\n",
+					       clkp->dev->parent->name);
+					return ret;
+				}
 			}
 		}
 	} else {
diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index b8c2e8d531b9..a0c7fad700f9 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -24,12 +24,22 @@ int clk_register(struct clk *clk, const char *drv_name,
 	if (parent_name) {
 		ret = uclass_get_device_by_name(UCLASS_CLK, parent_name, &parent);
 		if (ret) {
-			log_err("%s: failed to get %s device (parent of %s)\n",
-				__func__, parent_name, name);
+			/*
+			 * The parent is not registered yet right now.
+			 * Cache the parent name and reparent it when needed.
+			 */
+			log_debug("%s: failed to get %s device (parent of %s)\n",
+				  __func__, parent_name, name);
+
+			clk->parent_name = strdup(parent_name);
+			if (!clk->parent_name)
+				return -ENOMEM;
 		} else {
 			log_debug("%s: name: %s parent: %s [0x%p]\n", __func__, name,
 				  parent->name, parent);
 		}
+	} else {
+		clk->parent_name = NULL;
 	}
 
 	drv = lists_driver_lookup_name(drv_name);
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

