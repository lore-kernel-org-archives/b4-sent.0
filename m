From: Fabio Forni <development@redaril.me>
Date: Tue, 15 Sep 2026 21:35:21 +0200
Subject: [PATCH] mux: convert to use fwnode interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-mux_fwnode-v1-1-ed5a6d8202d4@redaril.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDS0NT3dzSivi08rz8lFTdREMzU0vjZGPLtLQUJaCGgqLUtMwKsGHRsbW
 1AFe/s/9cAAAA
X-Change-ID: 20260915-mux_fwnode-a16593c39ffd
To: Peter Rosin <peda@lysator.liu.se>, Linus Walleij <linusw@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 xu.yang_2@nxp.com, Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=12642;
 i=development@redaril.me; h=from:subject:message-id;
 bh=JNk4y1gUu8yNoKSpP9Cw+3Zk597uwGKQpVC+yDgTGnU=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLJWzmPijRNYnXrLUl/so8MNJjfjsy/D5Pwmdqdt+zFpc
 rq20xK5jlIWBjEuBlkxRZb/Tkabus1MjG71S9TCzGFlAhnCwMUpABP5lM/wv2C9iKt6cIWup6hX
 Tl/Kv8UVl7aw3lzg9HFR1aKnnm76FYwMV+TlZq+qFptx9PCxq0mL1Rfd8ZgXP7F149uI/9Xz6tf
 sZAcA
X-Developer-Key: i=development@redaril.me; a=openpgp;
 fpr=FF4232B28B363432DA8F187D81C2729AADA16A67
X-Endpoint-Received: by B4 Relay for development@redaril.me/default with auth_id=1033
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As firmware node is a more common abstract, this will convert the whole
thing to fwnode interface.

Co-developed-by: Xu Yang <xu.yang_2@nxp.com>
Signed-off-by: Xu Yang <xu.yang_2@nxp.com>
Signed-off-by: Fabio Forni <development@redaril.me>
---
This patch migrates the multiplexer subsystem from using the of_*          
family of functions and structs, to the more generic fwnode framework.     
                                                                           
It is a rebase of a single commit[1] contained in a old patch series[2]
submitted by Xu Yang. The original commit plus follow-up comments were
tested on kernel v6.12 on an arm64-based board, but this current rebase
isn't tested yet.                                                  
                                                                           
Link: https://lore.kernel.org/all/20220823195429.1243516-3-xu.yang_2@nxp.com [1]
Link: https://lore.kernel.org/all/20220823195429.1243516-1-xu.yang_2@nxp.com [2]
---
 drivers/mux/core.c                    | 96 ++++++++++++++++++-----------------
 drivers/pinctrl/pinctrl-generic-mux.c |  4 +-
 include/linux/mux/consumer.h          |  6 ++-
 3 files changed, 57 insertions(+), 49 deletions(-)

diff --git a/drivers/mux/core.c b/drivers/mux/core.c
index 5083e3d19606..2de0d1fd43d0 100644
--- a/drivers/mux/core.c
+++ b/drivers/mux/core.c
@@ -18,7 +18,7 @@
 #include <linux/module.h>
 #include <linux/mux/consumer.h>
 #include <linux/mux/driver.h>
-#include <linux/of.h>
+#include <linux/property.h>
 #include <linux/slab.h>
 
 /*
@@ -118,6 +118,7 @@ struct mux_chip *mux_chip_alloc(struct device *dev,
 	mux_chip->dev.type = &mux_type;
 	mux_chip->dev.parent = dev;
 	mux_chip->dev.of_node = dev->of_node;
+	mux_chip->dev.fwnode = dev->fwnode;
 	dev_set_drvdata(&mux_chip->dev, mux_chip);
 
 	mux_chip->id = ida_alloc(&mux_ida, GFP_KERNEL);
@@ -517,11 +518,11 @@ int mux_state_deselect(struct mux_state *mstate)
 EXPORT_SYMBOL_GPL(mux_state_deselect);
 
 /* Note this function returns a reference to the mux_chip dev. */
-static struct mux_chip *of_find_mux_chip_by_node(struct device_node *np)
+static struct mux_chip *mux_chip_find_by_fwnode(struct fwnode_handle *fwnode)
 {
 	struct device *dev;
 
-	dev = class_find_device_by_of_node(&mux_class, np);
+	dev = class_find_device_by_fwnode(&mux_class, fwnode);
 
 	return dev ? to_mux_chip(dev) : NULL;
 }
@@ -533,17 +534,17 @@ static struct mux_chip *of_find_mux_chip_by_node(struct device_node *np)
  * @state: Pointer to where the requested state is returned, or NULL when
  *         the required multiplexer states are handled by other means.
  * @optional: Whether to return NULL and silence errors when mux doesn't exist.
- * @node: the device nodes, use dev->of_node if it is NULL.
+ * @node: the device nodes, use dev's fwnode if it is NULL.
  *
  * Return: Pointer to the mux-control on success, an ERR_PTR with a negative
  * errno on error, or NULL if optional is true and mux doesn't exist.
  */
 static struct mux_control *mux_get(struct device *dev, const char *mux_name,
 				   unsigned int *state, bool optional,
-				   struct device_node *node)
+				   struct fwnode_handle *node)
 {
-	struct device_node *np = node ? node : dev->of_node;
-	struct of_phandle_args args;
+	struct fwnode_handle *fwnode = node ? node : dev_fwnode(dev);
+	struct fwnode_reference_args args;
 	struct mux_chip *mux_chip;
 	unsigned int controller;
 	int index = 0;
@@ -551,11 +552,13 @@ static struct mux_control *mux_get(struct device *dev, const char *mux_name,
 
 	if (mux_name) {
 		if (state)
-			index = of_property_match_string(np, "mux-state-names",
-							 mux_name);
+			index = fwnode_property_match_string(fwnode,
+							     "mux-state-names",
+							     mux_name);
 		else
-			index = of_property_match_string(np, "mux-control-names",
-							 mux_name);
+			index = fwnode_property_match_string(fwnode,
+							     "mux-control-names",
+							     mux_name);
 		if (index < 0 && optional) {
 			return NULL;
 		} else if (index < 0) {
@@ -566,39 +569,40 @@ static struct mux_control *mux_get(struct device *dev, const char *mux_name,
 	}
 
 	if (state)
-		ret = of_parse_phandle_with_args(np,
-						 "mux-states", "#mux-state-cells",
-						 index, &args);
+		ret = fwnode_property_get_reference_args(fwnode, "mux-states",
+							 "#mux-state-cells", 0,
+							 index, &args);
 	else
-		ret = of_parse_phandle_with_args(np,
-						 "mux-controls", "#mux-control-cells",
-						 index, &args);
+		ret = fwnode_property_get_reference_args(fwnode,
+							 "mux-controls", "#mux-control-cells",
+							 0, index, &args);
+
 	if (ret) {
 		if (optional && ret == -ENOENT)
 			return NULL;
 
-		dev_err(dev, "%pOF: failed to get mux-%s %s(%i)\n",
-			np, state ? "state" : "control",
-			mux_name ?: "", index);
+		dev_err(dev, "%pfw: failed to get mux-%s %s(%i)\n",
+			fwnode, state ? "state" : "control", mux_name ?: "",
+			index);
 		return ERR_PTR(ret);
 	}
 
-	mux_chip = of_find_mux_chip_by_node(args.np);
-	of_node_put(args.np);
+	mux_chip = mux_chip_find_by_fwnode(args.fwnode);
+	fwnode_handle_put(args.fwnode);
 	if (!mux_chip)
 		return ERR_PTR(-EPROBE_DEFER);
 
 	controller = 0;
 	if (state) {
-		if (args.args_count > 2 || args.args_count == 0 ||
-		    (args.args_count < 2 && mux_chip->controllers > 1)) {
-			dev_err(dev, "%pOF: wrong #mux-state-cells for %pOF\n",
-				np, args.np);
+		if (args.nargs > 2 || args.nargs == 0 ||
+		    (args.nargs < 2 && mux_chip->controllers > 1)) {
+			dev_err(dev, "%pfw: wrong #mux-state-cells for %pfw\n",
+				fwnode, args.fwnode);
 			put_device(&mux_chip->dev);
 			return ERR_PTR(-EINVAL);
 		}
 
-		if (args.args_count == 2) {
+		if (args.nargs == 2) {
 			controller = args.args[0];
 			*state = args.args[1];
 		} else {
@@ -606,21 +610,21 @@ static struct mux_control *mux_get(struct device *dev, const char *mux_name,
 		}
 
 	} else {
-		if (args.args_count > 1 ||
-		    (!args.args_count && mux_chip->controllers > 1)) {
-			dev_err(dev, "%pOF: wrong #mux-control-cells for %pOF\n",
-				np, args.np);
+		if (args.nargs > 1 ||
+		    (!args.nargs && mux_chip->controllers > 1)) {
+			dev_err(dev, "%pfw: wrong #mux-control-cells for %pfw\n",
+				fwnode, args.fwnode);
 			put_device(&mux_chip->dev);
 			return ERR_PTR(-EINVAL);
 		}
 
-		if (args.args_count)
+		if (args.nargs)
 			controller = args.args[0];
 	}
 
 	if (controller >= mux_chip->controllers) {
-		dev_err(dev, "%pOF: bad mux controller %u specified in %pOF\n",
-			np, controller, args.np);
+		dev_err(dev, "%pfw: bad mux controller %u specified in %pfw\n",
+			fwnode, controller, args.fwnode);
 		put_device(&mux_chip->dev);
 		return ERR_PTR(-EINVAL);
 	}
@@ -714,14 +718,14 @@ EXPORT_SYMBOL_GPL(devm_mux_control_get);
  * @dev: The device that needs a mux-state.
  * @mux_name: The name identifying the mux-state.
  * @optional: Whether to return NULL and silence errors when mux doesn't exist.
- * @np: the device nodes, use dev->of_node if it is NULL.
+ * @node: the device nodes, use dev's fwnode if it is NULL.
  *
  * Return: Pointer to the mux-state on success, an ERR_PTR with a negative
  * errno on error, or NULL if optional is true and mux doesn't exist.
  */
 static struct mux_state *
 mux_state_get(struct device *dev, const char *mux_name, bool optional,
-	      struct device_node *np)
+	      struct fwnode_handle *node)
 {
 	struct mux_state *mstate;
 
@@ -729,7 +733,7 @@ mux_state_get(struct device *dev, const char *mux_name, bool optional,
 	if (!mstate)
 		return ERR_PTR(-ENOMEM);
 
-	mstate->mux = mux_get(dev, mux_name, &mstate->state, optional, np);
+	mstate->mux = mux_get(dev, mux_name, &mstate->state, optional, node);
 	if (IS_ERR(mstate->mux)) {
 		int err = PTR_ERR(mstate->mux);
 
@@ -771,7 +775,7 @@ static void devm_mux_state_release(struct device *dev, void *res)
  * @dev: The device that needs a mux-state.
  * @mux_name: The name identifying the mux-state.
  * @optional: Whether to return NULL and silence errors when mux doesn't exist.
- * @np: The device nodes, use dev->of_node if it is NULL.
+ * @node: The device nodes, use dev's fwnode if it is NULL.
  * @init: Optional function pointer for mux-state object initialisation.
  * @exit: Optional function pointer for mux-state object cleanup on release.
  *
@@ -779,7 +783,7 @@ static void devm_mux_state_release(struct device *dev, void *res)
  * errno on error, or NULL if optional is true and mux doesn't exist.
  */
 static struct mux_state *__devm_mux_state_get(struct device *dev, const char *mux_name,
-					      bool optional, struct device_node *np,
+					      bool optional, struct fwnode_handle *node,
 					      int (*init)(struct mux_state *mstate),
 					      int (*exit)(struct mux_state *mstate))
 {
@@ -787,7 +791,7 @@ static struct mux_state *__devm_mux_state_get(struct device *dev, const char *mu
 	struct mux_state *mstate;
 	int ret;
 
-	mstate = mux_state_get(dev, mux_name, optional, np);
+	mstate = mux_state_get(dev, mux_name, optional, node);
 	if (IS_ERR(mstate))
 		return ERR_CAST(mstate);
 	else if (optional && !mstate)
@@ -821,23 +825,23 @@ static struct mux_state *__devm_mux_state_get(struct device *dev, const char *mu
 }
 
 /**
- * devm_mux_state_get_from_np() - Get the mux-state for a device, with resource
+ * devm_mux_state_get_from_swnode() - Get the mux-state for a device, with resource
  *				  management.
  * @dev: The device that needs a mux-control.
  * @mux_name: The name identifying the mux-control.
- * @np: the device nodes, use dev->of_node if it is NULL.
+ * @node: the device nodes, use dev's fwnode if it is NULL.
  *
  * Return: Pointer to the mux-state, or an ERR_PTR with a negative errno.
  *
  * The mux-state will automatically be freed on release.
  */
 struct mux_state *
-devm_mux_state_get_from_np(struct device *dev, const char *mux_name,
-			   struct device_node *np)
+devm_mux_state_get_from_swnode(struct device *dev, const char *mux_name,
+			       struct fwnode_handle *node)
 {
-	return __devm_mux_state_get(dev, mux_name, false, np, NULL, NULL);
+	return __devm_mux_state_get(dev, mux_name, false, node, NULL, NULL);
 }
-EXPORT_SYMBOL_GPL(devm_mux_state_get_from_np);
+EXPORT_SYMBOL_GPL(devm_mux_state_get_from_swnode);
 
 /**
  * devm_mux_state_get_optional() - Get the optional mux-state for a device,
diff --git a/drivers/pinctrl/pinctrl-generic-mux.c b/drivers/pinctrl/pinctrl-generic-mux.c
index 202b72351efb..bb6681753727 100644
--- a/drivers/pinctrl/pinctrl-generic-mux.c
+++ b/drivers/pinctrl/pinctrl-generic-mux.c
@@ -50,7 +50,9 @@ mux_pinmux_dt_node_to_map(struct pinctrl_dev *pctldev,
 	if (!group_names)
 		return -ENOMEM;
 
-	function->mux_state = devm_mux_state_get_from_np(pctldev->dev, NULL, np_config);
+	function->mux_state = devm_mux_state_get_from_swnode(pctldev->dev,
+							     NULL,
+							     of_fwnode_handle(np_config));
 	if (IS_ERR(function->mux_state))
 		return PTR_ERR(function->mux_state);
 
diff --git a/include/linux/mux/consumer.h b/include/linux/mux/consumer.h
index 449e38e6e2c5..ceb6858cdce8 100644
--- a/include/linux/mux/consumer.h
+++ b/include/linux/mux/consumer.h
@@ -11,6 +11,7 @@
 #define _LINUX_MUX_CONSUMER_H
 
 #include <linux/compiler.h>
+#include <linux/device.h>
 
 struct device;
 struct mux_control;
@@ -62,7 +63,8 @@ void mux_control_put(struct mux_control *mux);
 struct mux_control *devm_mux_control_get(struct device *dev, const char *mux_name);
 
 struct mux_state *
-devm_mux_state_get_from_np(struct device *dev, const char *mux_name, struct device_node *np);
+devm_mux_state_get_from_swnode(struct device *dev, const char *mux_name,
+			       struct fwnode_handle *node);
 
 struct mux_state *devm_mux_state_get_optional(struct device *dev, const char *mux_name);
 struct mux_state *devm_mux_state_get_selected(struct device *dev, const char *mux_name);
@@ -165,6 +167,6 @@ static inline struct mux_state *devm_mux_state_get_optional_selected(struct devi
 #endif /* CONFIG_MULTIPLEXER */
 
 #define devm_mux_state_get(dev, mux_name)		\
-	devm_mux_state_get_from_np(dev, mux_name, NULL)
+	devm_mux_state_get_from_swnode(dev, mux_name, NULL)
 
 #endif /* _LINUX_MUX_CONSUMER_H */

---
base-commit: f6e7b42bf05b2427fb8a7a1d1c387a86638bb413
change-id: 20260915-mux_fwnode-a16593c39ffd

Best regards,
-- 
Fabio Forni <development@redaril.me>

