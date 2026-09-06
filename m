From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:25 +0200
Subject: [PATCH v2 02/22] usb: typec: Represent USB4 on the Type-C bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-2-1f80085f93fb@kernel.org>
References: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
In-Reply-To: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=19872; i=sven@kernel.org;
 h=from:subject:message-id; bh=B/qrsmu6dNMa0mdZN1vjAuTnmbaVMn70eJ9KkkRXhqY=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTbvqZtzc8CWfma/2wAUH49yL0Uc2Xl68UCuft8Nim
 tEb11TNjlIWBjEuBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEFroy/BUXePGzeeevB5nL
 1AQ0OkP2Hn1w4A/fkzfiuVuimFbl33vLyLA5kp1hLj/DWrWt82r2StaZBvy5vlrw5GGGEuYoack
 mDm4A
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

USB4 technically isn't alternate mode and entered using the EUDO and has
no SVID or Discover Modes Response. We can still represent it like an
altmode on the Type-C bus though by adding a mode kind. Exclude the USB4
modes from any SVID-specific operations and driver binding, but allow
consumers to observe their state through notifications.

Like for other altmodes, expose the USB4 mode to sysfs: Add a mode_kind
to be able to differentiate and then expose the EUDO, make the USB4
active state read-only since we only represent firmware-negotiated USB4
modes and omit anything that only applies to SVID-specific altmodes.

Signed-off-by: Sven Peter <sven@kernel.org>
---
Hope it's fine to add you as the contact for the sysfs documentation,
happy to add myself otherwise though.
---
 Documentation/ABI/testing/sysfs-bus-typec | 36 ++++++++++++++
 drivers/usb/typec/bus.c                   | 67 ++++++++++++++++++++-----
 drivers/usb/typec/class.c                 | 83 +++++++++++++++++++++++++++----
 drivers/usb/typec/mode_selection.c        |  6 ++-
 include/linux/usb/typec.h                 | 20 +++++++-
 include/linux/usb/typec_altmode.h         | 10 +++-
 6 files changed, 193 insertions(+), 29 deletions(-)

diff --git a/Documentation/ABI/testing/sysfs-bus-typec b/Documentation/ABI/testing/sysfs-bus-typec
index 205d9c91e2e1..524bbcbadf64 100644
--- a/Documentation/ABI/testing/sysfs-bus-typec
+++ b/Documentation/ABI/testing/sysfs-bus-typec
@@ -12,6 +12,35 @@ Description:
 
 		Valid values are boolean.
 
+		For USB4 mode devices this attribute is read-only. On a port it
+		indicates whether USB4 support is enabled; on a partner it reports
+		whether USB4 is active. USB4 entry and exit are controlled by the
+		port controller. Partner state changes notify this attribute and
+		generate KOBJ_CHANGE uevents.
+
+What:		/sys/bus/typec/devices/.../mode_kind
+Date:		September 2026
+Contact:	Heikki Krogerus <heikki.krogerus@linux.intel.com>
+Description:
+		Read-only protocol kind represented by this mode device:
+		"altmode" for an SVID-specific alternate mode, or "usb4" for
+		USB4 negotiated using Enter_USB.
+
+		USB4 devices do not expose svid, mode, vdo, or priority
+		attributes, or the legacy modeN attribute group. USB4 partner
+		uevents contain MODE_KIND=usb4 instead of SVID, MODE, and
+		MODALIAS variables.
+
+What:		/sys/bus/typec/devices/.../eudo
+Date:		September 2026
+Contact:	Heikki Krogerus <heikki.krogerus@linux.intel.com>
+Description:
+		Read-only Enter_USB Data Object (EUDO), formatted as
+		0x followed by eight hexadecimal digits. Present only on USB4
+		partner mode devices, not on ports or SVID-specific alternate
+		modes. USB4 cable information is encoded in the EUDO; there are
+		no USB4 cable plug mode devices.
+
 What:		/sys/bus/typec/devices/.../description
 Date:		July 2018
 Contact:	Heikki Krogerus <heikki.krogerus@linux.intel.com>
@@ -36,6 +65,8 @@ Description:
 		the mode index is not assigned, identifying the alternate mode
 		must be done with either mode VDO or the description.
 
+		This attribute is not present on USB4 mode devices.
+
 What:		/sys/bus/typec/devices/.../svid
 Date:		July 2018
 Contact:	Heikki Krogerus <heikki.krogerus@linux.intel.com>
@@ -43,9 +74,14 @@ Description:
 		The Standard or Vendor ID (SVID) assigned by USB-IF for this
 		alternate mode.
 
+		This attribute is not present on USB4 mode devices.
+
 What:		/sys/bus/typec/devices/.../vdo
 Date:		July 2018
 Contact:	Heikki Krogerus <heikki.krogerus@linux.intel.com>
 Description:
 		Shows the VDO in hexadecimal returned by Discover Modes command
 		for this mode.
+
+		This attribute is not present on USB4 mode devices. USB4 partner
+		mode devices expose the EUDO in the eudo attribute.
diff --git a/drivers/usb/typec/bus.c b/drivers/usb/typec/bus.c
index e84b134a3381..8e6d7769fac3 100644
--- a/drivers/usb/typec/bus.c
+++ b/drivers/usb/typec/bus.c
@@ -93,6 +93,8 @@ int typec_altmode_notify(struct typec_altmode *adev,
 
 	if (!adev)
 		return 0;
+	if (adev->mode_kind != TYPEC_MODE_KIND_ALTMODE)
+		return -EOPNOTSUPP;
 
 	altmode = to_altmode(adev);
 
@@ -125,12 +127,19 @@ EXPORT_SYMBOL_GPL(typec_altmode_notify);
  */
 int typec_altmode_enter(struct typec_altmode *adev, u32 *vdo)
 {
-	struct altmode *partner = to_altmode(adev)->partner;
-	struct typec_altmode *pdev = &partner->adev;
+	struct typec_altmode *pdev;
+	struct altmode *partner;
 	int ret;
 
-	if (!adev || adev->active)
+	if (!adev)
 		return 0;
+	if (adev->mode_kind != TYPEC_MODE_KIND_ALTMODE)
+		return -EOPNOTSUPP;
+	if (adev->active)
+		return 0;
+
+	partner = to_altmode(adev)->partner;
+	pdev = &partner->adev;
 
 	if (!pdev->ops || !pdev->ops->enter)
 		return -EOPNOTSUPP;
@@ -156,12 +165,19 @@ EXPORT_SYMBOL_GPL(typec_altmode_enter);
  */
 int typec_altmode_exit(struct typec_altmode *adev)
 {
-	struct altmode *partner = to_altmode(adev)->partner;
-	struct typec_altmode *pdev = &partner->adev;
+	struct typec_altmode *pdev;
+	struct altmode *partner;
 	int ret;
 
-	if (!adev || !adev->active)
+	if (!adev)
 		return 0;
+	if (adev->mode_kind != TYPEC_MODE_KIND_ALTMODE)
+		return -EOPNOTSUPP;
+	if (!adev->active)
+		return 0;
+
+	partner = to_altmode(adev)->partner;
+	pdev = &partner->adev;
 
 	if (!pdev->ops || !pdev->ops->exit)
 		return -EOPNOTSUPP;
@@ -185,8 +201,13 @@ EXPORT_SYMBOL_GPL(typec_altmode_exit);
  */
 int typec_altmode_attention(struct typec_altmode *adev, u32 vdo)
 {
-	struct altmode *partner = to_altmode(adev)->partner;
 	struct typec_altmode *pdev;
+	struct altmode *partner;
+
+	if (adev->mode_kind != TYPEC_MODE_KIND_ALTMODE)
+		return -EOPNOTSUPP;
+
+	partner = to_altmode(adev)->partner;
 
 	if (!partner)
 		return -ENODEV;
@@ -219,6 +240,8 @@ int typec_altmode_vdm(struct typec_altmode *adev,
 
 	if (!adev)
 		return 0;
+	if (adev->mode_kind != TYPEC_MODE_KIND_ALTMODE)
+		return -EOPNOTSUPP;
 
 	altmode = to_altmode(adev);
 
@@ -258,12 +281,17 @@ EXPORT_SYMBOL_GPL(typec_altmode_get_partner);
  */
 int typec_cable_altmode_enter(struct typec_altmode *adev, enum typec_plug_index sop, u32 *vdo)
 {
-	struct altmode *partner = to_altmode(adev)->partner;
 	struct typec_altmode *pdev;
+	struct altmode *partner;
 
-	if (!adev || adev->active)
+	if (!adev)
+		return 0;
+	if (adev->mode_kind != TYPEC_MODE_KIND_ALTMODE)
+		return -EOPNOTSUPP;
+	if (adev->active)
 		return 0;
 
+	partner = to_altmode(adev)->partner;
 	if (!partner)
 		return -ENODEV;
 
@@ -288,12 +316,17 @@ EXPORT_SYMBOL_GPL(typec_cable_altmode_enter);
  */
 int typec_cable_altmode_exit(struct typec_altmode *adev, enum typec_plug_index sop)
 {
-	struct altmode *partner = to_altmode(adev)->partner;
 	struct typec_altmode *pdev;
+	struct altmode *partner;
 
-	if (!adev || !adev->active)
+	if (!adev)
+		return 0;
+	if (adev->mode_kind != TYPEC_MODE_KIND_ALTMODE)
+		return -EOPNOTSUPP;
+	if (!adev->active)
 		return 0;
 
+	partner = to_altmode(adev)->partner;
 	if (!partner)
 		return -ENODEV;
 
@@ -326,6 +359,8 @@ int typec_cable_altmode_vdm(struct typec_altmode *adev, enum typec_plug_index so
 
 	if (!adev)
 		return 0;
+	if (adev->mode_kind != TYPEC_MODE_KIND_ALTMODE)
+		return -EOPNOTSUPP;
 
 	altmode = to_altmode(adev);
 
@@ -422,7 +457,8 @@ struct typec_altmode *typec_match_altmode(struct typec_altmode **altmodes,
 	for (i = 0; i < n; i++) {
 		if (!altmodes[i])
 			break;
-		if (altmodes[i]->svid == svid && altmodes[i]->mode == mode)
+		if (altmodes[i]->mode_kind == TYPEC_MODE_KIND_ALTMODE &&
+		    altmodes[i]->svid == svid && altmodes[i]->mode == mode)
 			return altmodes[i];
 	}
 
@@ -472,6 +508,10 @@ static int typec_match(struct device *dev, const struct device_driver *driver)
 	if (!is_typec_partner_altmode(dev))
 		return 0;
 
+	/* USB4 mode devices report firmware state through notifiers only. */
+	if (altmode->mode_kind != TYPEC_MODE_KIND_ALTMODE)
+		return 0;
+
 	for (id = drv->id_table; id->svid; id++)
 		if (id->svid == altmode->svid)
 			return 1;
@@ -485,6 +525,9 @@ static int typec_uevent(const struct device *dev, struct kobj_uevent_env *env)
 	if (!is_typec_partner_altmode(dev))
 		return 0;
 
+	if (altmode->mode_kind == TYPEC_MODE_KIND_USB4)
+		return add_uevent_var(env, "MODE_KIND=usb4");
+
 	if (add_uevent_var(env, "SVID=%04X", altmode->svid))
 		return -ENOMEM;
 
diff --git a/drivers/usb/typec/class.c b/drivers/usb/typec/class.c
index 5808a3ef0d6c..869d6857c0dc 100644
--- a/drivers/usb/typec/class.c
+++ b/drivers/usb/typec/class.c
@@ -233,23 +233,24 @@ static const char * const usb_modes[] = {
 static int altmode_match(struct device *dev, const void *data)
 {
 	struct typec_altmode *adev = to_typec_altmode(dev);
-	const struct typec_device_id *id = data;
+	const struct typec_altmode *match = data;
 
 	if (!is_typec_port_altmode(dev))
 		return 0;
 
-	return (adev->svid == id->svid);
+	if (adev->mode_kind != match->mode_kind)
+		return 0;
+	return adev->mode_kind == TYPEC_MODE_KIND_USB4 || adev->svid == match->svid;
 }
 
 static void typec_altmode_set_partner(struct altmode *altmode)
 {
 	struct typec_altmode *adev = &altmode->adev;
-	struct typec_device_id id = { adev->svid };
 	struct typec_port *port = typec_altmode2port(adev);
 	struct altmode *partner;
 	struct device *dev;
 
-	dev = device_find_child(&port->dev, &id, altmode_match);
+	dev = device_find_child(&port->dev, adev, altmode_match);
 	if (!dev)
 		return;
 
@@ -296,6 +297,8 @@ static void typec_altmode_put_partner(struct altmode *altmode)
  *
  * If a partner or cable plug executes Enter/Exit Mode command successfully, the
  * drivers use this routine to report the updated state of the mode.
+ * For USB4 partner modes, drivers use this routine to report entry through
+ * Enter_USB and exit from USB4.
  */
 void typec_altmode_update_active(struct typec_altmode *adev, bool active)
 {
@@ -319,8 +322,10 @@ void typec_altmode_update_active(struct typec_altmode *adev, bool active)
 				     active ? TYPEC_ALTMODE_ENTERED :
 					      TYPEC_ALTMODE_EXITED,
 				     adev);
-	snprintf(dir, sizeof(dir), "mode%d", adev->mode);
-	sysfs_notify(&adev->dev.kobj, dir, "active");
+	if (adev->mode_kind == TYPEC_MODE_KIND_ALTMODE) {
+		snprintf(dir, sizeof(dir), "mode%d", adev->mode);
+		sysfs_notify(&adev->dev.kobj, dir, "active");
+	}
 	sysfs_notify(&adev->dev.kobj, NULL, "active");
 	kobject_uevent(&adev->dev.kobj, KOBJ_CHANGE);
 }
@@ -502,13 +507,30 @@ svid_show(struct device *dev, struct device_attribute *attr, char *buf)
 }
 static DEVICE_ATTR_RO(svid);
 
+static ssize_t mode_kind_show(struct device *dev, struct device_attribute *attr,
+			      char *buf)
+{
+	struct typec_altmode *adev = to_typec_altmode(dev);
+
+	return sysfs_emit(buf, "%s\n",
+			 adev->mode_kind == TYPEC_MODE_KIND_USB4 ? "usb4" : "altmode");
+}
+static DEVICE_ATTR_RO(mode_kind);
+
+static ssize_t eudo_show(struct device *dev, struct device_attribute *attr, char *buf)
+{
+	return sysfs_emit(buf, "0x%08x\n", to_typec_altmode(dev)->eudo);
+}
+static DEVICE_ATTR_RO(eudo);
+
 static int increment_duplicated_priority(struct device *dev, void *data)
 {
 	if (is_typec_port_altmode(dev)) {
 		struct typec_altmode **alt_target = (struct typec_altmode **)data;
 		struct typec_altmode *alt = to_typec_altmode(dev);
 
-		if (alt != *alt_target && alt->priority == (*alt_target)->priority) {
+		if (alt->mode_kind == TYPEC_MODE_KIND_ALTMODE &&
+		    alt != *alt_target && alt->priority == (*alt_target)->priority) {
 			alt->priority++;
 			*alt_target = alt;
 			return 1;
@@ -523,7 +545,8 @@ static int find_duplicated_priority(struct device *dev, void *data)
 		struct typec_altmode **alt_target = (struct typec_altmode **)data;
 		struct typec_altmode *alt = to_typec_altmode(dev);
 
-		if (alt != *alt_target && alt->priority == (*alt_target)->priority)
+		if (alt->mode_kind == TYPEC_MODE_KIND_ALTMODE &&
+		    alt != *alt_target && alt->priority == (*alt_target)->priority)
 			return 1;
 	}
 	return 0;
@@ -579,6 +602,8 @@ static ssize_t priority_show(struct device *dev,
 static DEVICE_ATTR_RW(priority);
 
 static struct attribute *typec_altmode_attrs[] = {
+	&dev_attr_mode_kind.attr,
+	&dev_attr_eudo.attr,
 	&dev_attr_active.attr,
 	&dev_attr_mode.attr,
 	&dev_attr_svid.attr,
@@ -593,6 +618,18 @@ static umode_t typec_altmode_attr_is_visible(struct kobject *kobj,
 	struct typec_altmode *adev = to_typec_altmode(kobj_to_dev(kobj));
 	struct typec_port *port = typec_altmode2port(adev);
 
+	if (adev->mode_kind == TYPEC_MODE_KIND_USB4) {
+		if (attr == &dev_attr_svid.attr || attr == &dev_attr_mode.attr ||
+		    attr == &dev_attr_vdo.attr || attr == &dev_attr_priority.attr)
+			return 0;
+		if (attr == &dev_attr_eudo.attr && !is_typec_partner(adev->dev.parent))
+			return 0;
+		if (attr == &dev_attr_active.attr)
+			return 0444;
+	} else if (attr == &dev_attr_eudo.attr) {
+		return 0;
+	}
+
 	if (attr == &dev_attr_active.attr) {
 		if (!is_typec_port(adev->dev.parent)) {
 			if (!port->mode_control || !adev->ops || !adev->ops->activate)
@@ -698,20 +735,33 @@ typec_register_altmode(struct device *parent,
 		       const struct typec_altmode_desc *desc,
 		       const struct device_type *type)
 {
-	unsigned int id = altmode_id_get(parent);
 	bool is_port = is_typec_port(parent);
 	struct altmode *alt;
+	unsigned int id;
 	int ret;
 
+	if (desc->mode_kind != TYPEC_MODE_KIND_ALTMODE &&
+	    desc->mode_kind != TYPEC_MODE_KIND_USB4)
+		return ERR_PTR(-EINVAL);
+	if (desc->mode_kind == TYPEC_MODE_KIND_USB4 &&
+	    (desc->svid || desc->mode || is_typec_plug(parent)))
+		return ERR_PTR(-EINVAL);
+
+	id = altmode_id_get(parent);
+
 	alt = kzalloc_obj(*alt);
 	if (!alt) {
 		altmode_id_remove(parent, id);
 		return ERR_PTR(-ENOMEM);
 	}
 
+	alt->adev.mode_kind = desc->mode_kind;
 	alt->adev.svid = desc->svid;
 	alt->adev.mode = desc->mode;
-	alt->adev.vdo = desc->vdo;
+	if (desc->mode_kind == TYPEC_MODE_KIND_USB4)
+		alt->adev.eudo = desc->eudo;
+	else
+		alt->adev.vdo = desc->vdo;
 	alt->adev.mode_selection = desc->mode_selection;
 	alt->roles = desc->roles;
 	alt->id = id;
@@ -730,7 +780,8 @@ typec_register_altmode(struct device *parent,
 	sprintf(alt->group_name, "mode%d", desc->mode);
 	alt->group.name = alt->group_name;
 	alt->group.attrs = alt->attrs;
-	alt->groups[0] = &alt->group;
+	if (desc->mode_kind == TYPEC_MODE_KIND_ALTMODE)
+		alt->groups[0] = &alt->group;
 
 	alt->adev.dev.parent = parent;
 	alt->adev.dev.groups = alt->groups;
@@ -1110,6 +1161,10 @@ EXPORT_SYMBOL_GPL(typec_partner_set_num_altmodes);
  * SVID listed in response to Discover Modes command need to be listed in an
  * array in @desc.
  *
+ * For USB4, set @desc->mode_kind to %TYPEC_MODE_KIND_USB4 and @desc->eudo to the
+ * EUDO and leave SVID and mode zero. USB4 devices expose firmware state
+ * through notifications and do not bind alternate-mode drivers.
+ *
  * Returns handle to the alternate mode on success or ERR_PTR on failure.
  */
 struct typec_altmode *
@@ -2698,6 +2753,9 @@ EXPORT_SYMBOL_GPL(typec_get_fw_cap);
  * This routine is used to register an alternate mode that @port is capable of
  * supporting.
  *
+ * For USB4, set @desc->mode_kind to %TYPEC_MODE_KIND_USB4 and leave SVID and
+ * mode zero. Register it before the USB4 partner mode, which carries the EUDO.
+ *
  * Returns handle to the alternate mode on success or ERR_PTR on failure.
  */
 struct typec_altmode *
@@ -2727,6 +2785,9 @@ typec_port_register_altmode(struct typec_port *port,
 		to_altmode(adev)->mux = mux;
 		to_altmode(adev)->retimer = retimer;
 
+		if (adev->mode_kind == TYPEC_MODE_KIND_USB4)
+			return adev;
+
 		ret = typec_mode_set_priority(adev, 0);
 		if (ret) {
 			typec_unregister_altmode(adev);
diff --git a/drivers/usb/typec/mode_selection.c b/drivers/usb/typec/mode_selection.c
index cd376f67e445..5e378deed5c2 100644
--- a/drivers/usb/typec/mode_selection.c
+++ b/drivers/usb/typec/mode_selection.c
@@ -66,7 +66,8 @@ static int activate_altmode(struct device *dev, void *data)
 		struct typec_altmode *alt = to_typec_altmode(dev);
 		struct mode_order *order = (struct mode_order *)data;
 
-		if (order->svid == alt->svid) {
+		if (alt->mode_kind == TYPEC_MODE_KIND_ALTMODE &&
+		    order->svid == alt->svid) {
 			if (alt->ops && alt->ops->activate)
 				order->result = alt->ops->activate(alt, order->enter);
 			else
@@ -215,7 +216,8 @@ static int altmode_add_to_list(struct device *dev, void *data)
 		const struct typec_altmode *pdev = typec_altmode_get_partner(altmode);
 		struct mode_state *ms;
 
-		if (pdev && altmode->ops && altmode->ops->activate) {
+		if (altmode->mode_kind == TYPEC_MODE_KIND_ALTMODE &&
+		    pdev && altmode->ops && altmode->ops->activate) {
 			ms = kzalloc_obj(*ms);
 			if (!ms)
 				return -ENOMEM;
diff --git a/include/linux/usb/typec.h b/include/linux/usb/typec.h
index 914a6f0844c5..add2c1368774 100644
--- a/include/linux/usb/typec.h
+++ b/include/linux/usb/typec.h
@@ -138,11 +138,23 @@ struct usb_pd_identity {
 int typec_partner_set_identity(struct typec_partner *partner);
 int typec_cable_set_identity(struct typec_cable *cable);
 
+/**
+ * enum typec_mode_kind - Protocol represented by a Type-C mode device
+ * @TYPEC_MODE_KIND_ALTMODE: SVID-specific alternate mode (the default)
+ * @TYPEC_MODE_KIND_USB4: USB4, negotiated using Enter_USB
+ */
+enum typec_mode_kind {
+	TYPEC_MODE_KIND_ALTMODE,
+	TYPEC_MODE_KIND_USB4,
+};
+
 /*
  * struct typec_altmode_desc - USB Type-C Alternate Mode Descriptor
  * @svid: Standard or Vendor ID
  * @mode: Index of the Mode
- * @vdo: VDO returned by Discover Modes USB PD command
+ * @vdo: Discover Modes VDO for SVID-specific alternate modes
+ * @eudo: Enter_USB Data Object for USB4 partner modes
+ * @mode_kind: Protocol kind; SVID and mode are unused for USB4
  * @roles: Only for ports. DRP if the mode is available in both roles
  * @inactive: Only for ports. Make this port inactive (default is active).
  *
@@ -152,11 +164,15 @@ int typec_cable_set_identity(struct typec_cable *cable);
 struct typec_altmode_desc {
 	u16			svid;
 	u8			mode;
-	u32			vdo;
+	union {
+		u32		vdo;
+		u32		eudo;
+	};
 	/* Only used with ports */
 	enum typec_port_data	roles;
 	bool			inactive;
 	bool			mode_selection;
+	enum typec_mode_kind	mode_kind;
 };
 
 void typec_partner_set_pd_revision(struct typec_partner *partner, u16 pd_revision);
diff --git a/include/linux/usb/typec_altmode.h b/include/linux/usb/typec_altmode.h
index ef21ead551be..8d31e35e9320 100644
--- a/include/linux/usb/typec_altmode.h
+++ b/include/linux/usb/typec_altmode.h
@@ -24,7 +24,9 @@ struct typec_altmode_ops;
  * @dev: Driver model's view of this device
  * @svid: Standard or Vendor ID (SVID) of the alternate mode
  * @mode: Index of the Mode
- * @vdo: VDO returned by Discover Modes USB PD command
+ * @vdo: Discover Modes VDO for SVID-specific alternate modes
+ * @eudo: Enter_USB Data Object for USB4 partner modes
+ * @mode_kind: Protocol kind; SVID and mode are unused for USB4
  * @active: Tells has the mode been entered or not
  * @priority: Priority used by the automatic alternate mode selection process
  * @mode_selection: Whether entry to this alternate mode is managed by the
@@ -37,7 +39,11 @@ struct typec_altmode {
 	struct device			dev;
 	u16				svid;
 	int				mode;
-	u32				vdo;
+	union {
+		u32			vdo;
+		u32			eudo;
+	};
+	enum typec_mode_kind		mode_kind;
 	unsigned int			active:1;
 	u8				priority;
 	bool			mode_selection;

-- 
2.55.0

