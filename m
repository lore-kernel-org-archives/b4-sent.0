From: Corey Leavitt <corey@leavitt.info>
Date: Thu, 23 Apr 2026 01:42:17 -0600
Subject: [PATCH RFC net-next 4/4] net: phy: own phydev->psec via PSE
 notifier and remove fwnode_mdio hook
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260423-pse-notifier-decouple-v1-4-86ed750a9d62@leavitt.info>
References: <20260423-pse-notifier-decouple-v1-0-86ed750a9d62@leavitt.info>
In-Reply-To: <20260423-pse-notifier-decouple-v1-0-86ed750a9d62@leavitt.info>
To: Oleksij Rempel <o.rempel@pengutronix.de>, 
 Kory Maincent <kory.maincent@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: Andrew Lunn <andrew@lunn.ch>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Corey Leavitt <corey@leavitt.info>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776930134; l=15445;
 i=corey@leavitt.info; s=default; h=from:subject:message-id;
 bh=doMA7uwXNEZkymG7Ed0bflskqQqfJ/G13i1ggh380Aw=;
 b=QY4BAIghTuSOAsdlA3Y8aWcsUOy+PuRg8hq7J4GiJKFGv2hZeeb7k0cAYzILD1/qDkysypc0A
 disOxvRubHUB1BNCYsOrgq9NtNRYUHuzS9oM7C6DTBO+0lhNLbCVOZG
X-Developer-Key: i=corey@leavitt.info; a=ed25519;
 pk=Q3mmZT+4CRYT8qp8RWvab30X2v2JnLdhHuK7YIHKzpI=
X-Endpoint-Received: by B4 Relay for corey@leavitt.info/default with auth_id=748
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Transfer ownership of phydev->psec from fwnode_mdio to the phy
subsystem itself. The phy subsystem now subscribes to the pse-pd
notifier chain and manages psec attach/detach in response to PSE
controller lifecycle events, while fwnode_mdio loses its PSE
awareness entirely.

Split phy_device_register() into a public entry point that takes
rtnl_lock() and a phy_device_register_locked() variant that assumes
rtnl is already held. Callers that already hold rtnl (the SFP
module state machine via __sfp_sm_event) use the _locked form to
avoid deadlock; all other callers use the unchanged public API.
This pair mirrors the register_netdevice() / register_netdev()
split convention already established in the core networking stack.
rtnl must span the full registration sequence through device_add(),
not just phy_try_attach_pse(): a PSE_REGISTERED event firing between
a narrow attach lock and device_add() would walk mdio_bus_type, find
the phy not yet on the bus, and leave it permanently unattached.

With rtnl held across the full registration sequence:

  - At phy_device_register_locked(), phy_try_attach_pse() attempts
    an of_pse_control_get() for phys whose DT pses phandle resolves
    now. If the controller is already registered, psec is attached
    before device_add() makes the phy visible on mdio_bus_type.
    If the controller is not yet registered, the swallow-error path
    leaves psec NULL and relies on the subsequent notifier event.

  - On PSE_REGISTERED: an rtnl-guarded bus walk retries the attach
    for every registered phy whose psec is still NULL. This is the
    "phy was enumerated before the PSE controller loaded" case,
    which is the root cause of the boot-time probe-retry storm on
    systems with a modular PSE controller driver. Because the
    pse_controller_notifier is fired synchronously, a concurrent
    pse_controller_register() either (a) completes list_add and
    releases pse_list_mutex before this function takes rtnl, in
    which case phy_try_attach_pse() finds the controller in the
    list and attaches; or (b) fires its notifier during this
    function, in which case the callback blocks on rtnl until this
    function returns, then walks the bus and finds the phy fully
    registered (attaching if psec is still NULL).

  - On PSE_UNREGISTERED: an rtnl-guarded bus walk releases every
    phydev->psec that targets the departing controller before
    pse_release_pis() frees pcdev->pi. Without this, a phy still
    holding a pse_control reference would cause a use-after-free
    in __pse_control_release's pcdev->pi[psec->id] access, and the
    PSE driver module could not finish unloading while any phy
    still held a reference via module_put().

Introduce phy_try_attach_pse() as the rtnl-guarded helper used by
both the register path and the notifier walk. Holding rtnl across
of_pse_control_get() is safe because pse_list_mutex is never held
in the opposite order.

Expose pse_control_matches_pcdev() as a predicate so subscribers
can identify which of their held pse_control references target a
given controller, without leaking the struct pse_controller_dev *
out of pse_control opacity.

Move the final pse_control_put() of phydev->psec from
phy_device_remove() to phy_device_release(). The kobject release
callback runs only after every reference on the device has been
dropped, including the bus iterator references taken by
bus_for_each_dev() in the notifier walk, which means by the time
release fires no concurrent reader or writer of phydev->psec can
exist. The mdio_bus_type klist is set up in bus_register() with
klist_devices_get() / klist_devices_put() (drivers/base/bus.c),
which bracket each iteration step with get_device() / put_device()
on the underlying struct device; that reference defers the release
callback from firing until the walk has advanced past this phy.
Keeping phy_device_remove() unchanged avoids introducing a new
locking contract on its many callers (sfp, fixed_phy, xgbe, hns,
netsec, bcm_sf2, mdiobus_unregister).

Finally, delete fwnode_find_pse_control() and its call site in
fwnode_mdiobus_register_phy(), and drop the PSE header from
fwnode_mdio.c. This removes the probe-time -EPROBE_DEFER coupling
between mdio and pse-pd that caused the boot-hang regression on
systems with a modular PSE controller driver and a DT phy with a
pses phandle: the MDIO/DSA probe no longer sees any PSE-originated
-EPROBE_DEFER, so the probe-retry storm is gone. fwnode_mdio is
now PSE-agnostic.

Fixes: fa2f0454174c ("net: pse-pd: Introduce attached_phydev to pse control")
Signed-off-by: Corey Leavitt <corey@leavitt.info>
---
 drivers/net/mdio/fwnode_mdio.c |  34 ----------
 drivers/net/phy/phy_device.c   | 144 ++++++++++++++++++++++++++++++++++++++---
 drivers/net/phy/sfp.c          |   2 +-
 drivers/net/pse-pd/pse_core.c  |  14 ++++
 include/linux/phy.h            |   2 +
 include/linux/pse-pd/pse.h     |   9 +++
 6 files changed, 161 insertions(+), 44 deletions(-)

diff --git a/drivers/net/mdio/fwnode_mdio.c b/drivers/net/mdio/fwnode_mdio.c
index ba7091518265..7bd979b59f49 100644
--- a/drivers/net/mdio/fwnode_mdio.c
+++ b/drivers/net/mdio/fwnode_mdio.c
@@ -11,33 +11,11 @@
 #include <linux/fwnode_mdio.h>
 #include <linux/of.h>
 #include <linux/phy.h>
-#include <linux/pse-pd/pse.h>
 
 MODULE_AUTHOR("Calvin Johnson <calvin.johnson@oss.nxp.com>");
 MODULE_LICENSE("GPL");
 MODULE_DESCRIPTION("FWNODE MDIO bus (Ethernet PHY) accessors");
 
-static struct pse_control *
-fwnode_find_pse_control(struct fwnode_handle *fwnode,
-			struct phy_device *phydev)
-{
-	struct pse_control *psec;
-	struct device_node *np;
-
-	if (!IS_ENABLED(CONFIG_PSE_CONTROLLER))
-		return NULL;
-
-	np = to_of_node(fwnode);
-	if (!np)
-		return NULL;
-
-	psec = of_pse_control_get(np, phydev);
-	if (PTR_ERR(psec) == -ENOENT)
-		return NULL;
-
-	return psec;
-}
-
 static struct mii_timestamper *
 fwnode_find_mii_timestamper(struct fwnode_handle *fwnode)
 {
@@ -118,7 +96,6 @@ int fwnode_mdiobus_register_phy(struct mii_bus *bus,
 				struct fwnode_handle *child, u32 addr)
 {
 	struct mii_timestamper *mii_ts = NULL;
-	struct pse_control *psec = NULL;
 	struct phy_device *phy;
 	bool is_c45;
 	u32 phy_id;
@@ -159,14 +136,6 @@ int fwnode_mdiobus_register_phy(struct mii_bus *bus,
 			goto clean_phy;
 	}
 
-	psec = fwnode_find_pse_control(child, phy);
-	if (IS_ERR(psec)) {
-		rc = PTR_ERR(psec);
-		goto unregister_phy;
-	}
-
-	phy->psec = psec;
-
 	/* phy->mii_ts may already be defined by the PHY driver. A
 	 * mii_timestamper probed via the device tree will still have
 	 * precedence.
@@ -176,9 +145,6 @@ int fwnode_mdiobus_register_phy(struct mii_bus *bus,
 
 	return 0;
 
-unregister_phy:
-	if (is_acpi_node(child) || is_of_node(child))
-		phy_device_remove(phy);
 clean_phy:
 	phy_device_free(phy);
 clean_mii_ts:
diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index c2cdf1ae3542..7948800e6e49 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -223,8 +223,19 @@ static void phy_mdio_device_free(struct mdio_device *mdiodev)
 
 static void phy_device_release(struct device *dev)
 {
+	struct phy_device *phydev = to_phy_device(dev);
+
+	/* bus_for_each_dev() holds get_device() across each iteration
+	 * step, deferring this release callback until any in-flight PSE
+	 * notifier walk has advanced past this phy. pse_control_put()
+	 * takes pse_list_mutex, so this path must run in sleepable
+	 * context.
+	 */
+	might_sleep();
+	pse_control_put(phydev->psec);
+
 	fwnode_handle_put(dev->fwnode);
-	kfree(to_phy_device(dev));
+	kfree(phydev);
 }
 
 static void phy_mdio_device_remove(struct mdio_device *mdiodev)
@@ -1102,14 +1113,102 @@ struct phy_device *get_phy_device(struct mii_bus *bus, int addr, bool is_c45)
 }
 EXPORT_SYMBOL(get_phy_device);
 
-/**
- * phy_device_register - Register the phy device on the MDIO bus
- * @phydev: phy_device structure to be added to the MDIO bus
+/* Best-effort attach of phydev->psec from a DT `pses = <&...>` phandle.
+ * Caller must hold rtnl. Errors are swallowed; the notifier retries
+ * at PSE_REGISTERED time.
  */
-int phy_device_register(struct phy_device *phydev)
+static void phy_try_attach_pse(struct phy_device *phydev)
+{
+	struct pse_control *psec;
+	struct device_node *np;
+
+	ASSERT_RTNL();
+
+	np = phydev->mdio.dev.of_node;
+	if (!np)
+		return;
+
+	if (phydev->psec)
+		return;
+
+	psec = of_pse_control_get(np, phydev);
+	if (IS_ERR(psec))
+		return;
+
+	phydev->psec = psec;
+}
+
+static int phy_pse_attach_one(struct device *dev, void *data __maybe_unused)
+{
+	ASSERT_RTNL();
+
+	if (dev->type != &mdio_bus_phy_type)
+		return 0;
+
+	phy_try_attach_pse(to_phy_device(dev));
+	return 0;
+}
+
+static int phy_pse_detach_one(struct device *dev, void *data)
+{
+	struct pse_controller_dev *pcdev = data;
+	struct phy_device *phydev;
+	struct pse_control *psec;
+
+	ASSERT_RTNL();
+
+	if (dev->type != &mdio_bus_phy_type)
+		return 0;
+
+	phydev = to_phy_device(dev);
+	psec = phydev->psec;
+	if (!psec || !pse_control_matches_pcdev(psec, pcdev))
+		return 0;
+
+	phydev->psec = NULL;
+	pse_control_put(psec);
+	return 0;
+}
+
+static int phy_pse_notifier_event(struct notifier_block *nb,
+				  unsigned long event, void *data)
+{
+	switch (event) {
+	case PSE_REGISTERED:
+		rtnl_lock();
+		bus_for_each_dev(&mdio_bus_type, NULL, NULL,
+				 phy_pse_attach_one);
+		rtnl_unlock();
+		return NOTIFY_OK;
+	case PSE_UNREGISTERED:
+		rtnl_lock();
+		bus_for_each_dev(&mdio_bus_type, NULL, data,
+				 phy_pse_detach_one);
+		rtnl_unlock();
+		return NOTIFY_OK;
+	default:
+		return NOTIFY_DONE;
+	}
+}
+
+static struct notifier_block phy_pse_notifier __read_mostly = {
+	.notifier_call = phy_pse_notifier_event,
+};
+
+/**
+ * phy_device_register_locked - Register the phy device on the MDIO bus
+ * @phydev: phy_device structure to be added to the MDIO bus
+ *
+ * Same as phy_device_register() but caller must already hold rtnl_lock().
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int phy_device_register_locked(struct phy_device *phydev)
 {
 	int err;
 
+	ASSERT_RTNL();
+
 	err = mdiobus_register_device(&phydev->mdio);
 	if (err)
 		return err;
@@ -1124,6 +1223,8 @@ int phy_device_register(struct phy_device *phydev)
 		goto out;
 	}
 
+	phy_try_attach_pse(phydev);
+
 	err = device_add(&phydev->mdio.dev);
 	if (err) {
 		phydev_err(phydev, "failed to add\n");
@@ -1133,12 +1234,32 @@ int phy_device_register(struct phy_device *phydev)
 	return 0;
 
  out:
-	/* Assert the reset signal */
+	/* If phy_try_attach_pse() set phydev->psec before device_add()
+	 * failed, the caller's phy_device_free() -> phy_device_release()
+	 * chain will drop it.
+	 */
 	phy_device_reset(phydev, 1);
-
 	mdiobus_unregister_device(&phydev->mdio);
 	return err;
 }
+EXPORT_SYMBOL(phy_device_register_locked);
+
+/**
+ * phy_device_register - Register the phy device on the MDIO bus
+ * @phydev: phy_device structure to be added to the MDIO bus
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int phy_device_register(struct phy_device *phydev)
+{
+	int err;
+
+	rtnl_lock();
+	err = phy_device_register_locked(phydev);
+	rtnl_unlock();
+
+	return err;
+}
 EXPORT_SYMBOL(phy_device_register);
 
 /**
@@ -1152,8 +1273,6 @@ EXPORT_SYMBOL(phy_device_register);
 void phy_device_remove(struct phy_device *phydev)
 {
 	unregister_mii_timestamper(phydev->mii_ts);
-	pse_control_put(phydev->psec);
-
 	device_del(&phydev->mdio.dev);
 
 	/* Assert the reset signal */
@@ -3962,8 +4081,14 @@ static int __init phy_init(void)
 	if (rc)
 		goto err_c45;
 
+	rc = pse_register_notifier(&phy_pse_notifier);
+	if (rc)
+		goto err_genphy;
+
 	return 0;
 
+err_genphy:
+	phy_driver_unregister(&genphy_driver);
 err_c45:
 	phy_driver_unregister(&genphy_c45_driver);
 err_ethtool_phy_ops:
@@ -3980,6 +4105,7 @@ static int __init phy_init(void)
 
 static void __exit phy_exit(void)
 {
+	pse_unregister_notifier(&phy_pse_notifier);
 	phy_driver_unregister(&genphy_c45_driver);
 	phy_driver_unregister(&genphy_driver);
 	rtnl_lock();
diff --git a/drivers/net/phy/sfp.c b/drivers/net/phy/sfp.c
index bd970f753beb..d19fe0f30c5d 100644
--- a/drivers/net/phy/sfp.c
+++ b/drivers/net/phy/sfp.c
@@ -1932,7 +1932,7 @@ static int sfp_sm_probe_phy(struct sfp *sfp, int addr, bool is_c45)
 	/* Mark this PHY as being on a SFP module */
 	phy->is_on_sfp_module = true;
 
-	err = phy_device_register(phy);
+	err = phy_device_register_locked(phy);
 	if (err) {
 		phy_device_free(phy);
 		dev_err(sfp->dev, "phy_device_register failed: %pe\n",
diff --git a/drivers/net/pse-pd/pse_core.c b/drivers/net/pse-pd/pse_core.c
index 82125502a8e3..a0667324a029 100644
--- a/drivers/net/pse-pd/pse_core.c
+++ b/drivers/net/pse-pd/pse_core.c
@@ -2016,3 +2016,17 @@ bool pse_has_c33(struct pse_control *psec)
 	return psec->pcdev->types & ETHTOOL_PSE_C33;
 }
 EXPORT_SYMBOL_GPL(pse_has_c33);
+
+/**
+ * pse_control_matches_pcdev - Test whether a pse_control targets a controller
+ * @psec: pse_control obtained from of_pse_control_get()
+ * @pcdev: PSE controller to compare against
+ *
+ * Return: %true if @psec was obtained from @pcdev, %false otherwise.
+ */
+bool pse_control_matches_pcdev(struct pse_control *psec,
+			       struct pse_controller_dev *pcdev)
+{
+	return psec->pcdev == pcdev;
+}
+EXPORT_SYMBOL_GPL(pse_control_matches_pcdev);
diff --git a/include/linux/phy.h b/include/linux/phy.h
index 199a7aaa341b..865b9baddb85 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -2158,6 +2158,8 @@ struct phy_device *fwnode_phy_find_device(struct fwnode_handle *phy_fwnode);
 struct fwnode_handle *fwnode_get_phy_node(const struct fwnode_handle *fwnode);
 struct phy_device *get_phy_device(struct mii_bus *bus, int addr, bool is_c45);
 int phy_device_register(struct phy_device *phy);
+/* Caller must hold rtnl_lock(); see phy_device_register() for the public form. */
+int phy_device_register_locked(struct phy_device *phy);
 void phy_device_free(struct phy_device *phydev);
 void phy_device_remove(struct phy_device *phydev);
 int phy_get_c45_ids(struct phy_device *phydev);
diff --git a/include/linux/pse-pd/pse.h b/include/linux/pse-pd/pse.h
index 78fe3a2b1ea8..d4310ca71a3e 100644
--- a/include/linux/pse-pd/pse.h
+++ b/include/linux/pse-pd/pse.h
@@ -385,6 +385,9 @@ int pse_ethtool_set_prio(struct pse_control *psec,
 bool pse_has_podl(struct pse_control *psec);
 bool pse_has_c33(struct pse_control *psec);
 
+bool pse_control_matches_pcdev(struct pse_control *psec,
+			       struct pse_controller_dev *pcdev);
+
 int pse_register_notifier(struct notifier_block *nb);
 int pse_unregister_notifier(struct notifier_block *nb);
 
@@ -438,6 +441,12 @@ static inline bool pse_has_c33(struct pse_control *psec)
 	return false;
 }
 
+static inline bool pse_control_matches_pcdev(struct pse_control *psec,
+					     struct pse_controller_dev *pcdev)
+{
+	return false;
+}
+
 static inline int pse_register_notifier(struct notifier_block *nb)
 {
 	return 0;

-- 
2.53.0

