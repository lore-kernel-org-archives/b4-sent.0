From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:24 +0200
Subject: [PATCH v2 01/22] usb: typec: Add alternate mode state notifiers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-1-1f80085f93fb@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5945; i=sven@kernel.org;
 h=from:subject:message-id; bh=DTWuRGoGwBcM1jGnxAkzk6R1cL0Y4ZnoYiAhUMuNaHk=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTTvX7XKrMNssNHvL2jO9X7SW17ybzmu/rSdt7XXjp
 5a2l/MvdJSyMIhxMciKKbJs329v+uThG8Glmy69h5nDygQyhIGLUwAmcqmU4X/Am4pD875f0N64
 ZlZmYdsk2+plr0UqeKYErJ7Gn3ll0dEbjAyTt2Rd8LgRrvGW7fi5N6rOU+6lu/qxXL0ZtfaaU/d
 l4/N8AA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Apple Silicon USB4/Thunderbolt driver needs to be made aware of
cable details and whenever USB4 or Thunderbolt is entered. The cable
details are already available as part of the typec subsystem but there
is no way to get a notification on typec_altmode_update_active() so
far.

Add a blocking notifier chain to each alternate mode and call it
whenever the mode is activated or deactivated right next to the already
existing sysfs and kobject_uevent notifications. Replay activations when a
notifier is registered.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/bus.h   |  6 +++++
 drivers/usb/typec/class.c | 59 +++++++++++++++++++++++++++++++++++++++++++++++
 include/linux/usb/typec.h | 16 +++++++++++++
 3 files changed, 81 insertions(+)

diff --git a/drivers/usb/typec/bus.h b/drivers/usb/typec/bus.h
index 7df5deb1dd3a..4dc60c48c91e 100644
--- a/drivers/usb/typec/bus.h
+++ b/drivers/usb/typec/bus.h
@@ -3,6 +3,8 @@
 #ifndef __USB_TYPEC_ALTMODE_H__
 #define __USB_TYPEC_ALTMODE_H__
 
+#include <linux/mutex.h>
+#include <linux/notifier.h>
 #include <linux/usb/typec_altmode.h>
 
 struct typec_mux;
@@ -23,6 +25,10 @@ struct altmode {
 
 	struct altmode			*partner;
 	struct altmode			*plug[2];
+
+	/* Serializes active state changes and notifier registration. */
+	struct mutex			state_lock;
+	struct blocking_notifier_head	state_notifier;
 };
 
 #define to_altmode(d) container_of(d, struct altmode, adev)
diff --git a/drivers/usb/typec/class.c b/drivers/usb/typec/class.c
index 54c7810b563b..5808a3ef0d6c 100644
--- a/drivers/usb/typec/class.c
+++ b/drivers/usb/typec/class.c
@@ -299,8 +299,11 @@ static void typec_altmode_put_partner(struct altmode *altmode)
  */
 void typec_altmode_update_active(struct typec_altmode *adev, bool active)
 {
+	struct altmode *alt = to_altmode(adev);
 	char dir[6];
 
+	guard(mutex)(&alt->state_lock);
+
 	if (adev->active == active)
 		return;
 
@@ -312,6 +315,10 @@ void typec_altmode_update_active(struct typec_altmode *adev, bool active)
 	}
 
 	adev->active = active;
+	blocking_notifier_call_chain(&alt->state_notifier,
+				     active ? TYPEC_ALTMODE_ENTERED :
+					      TYPEC_ALTMODE_EXITED,
+				     adev);
 	snprintf(dir, sizeof(dir), "mode%d", adev->mode);
 	sysfs_notify(&adev->dev.kobj, dir, "active");
 	sysfs_notify(&adev->dev.kobj, NULL, "active");
@@ -319,6 +326,56 @@ void typec_altmode_update_active(struct typec_altmode *adev, bool active)
 }
 EXPORT_SYMBOL_GPL(typec_altmode_update_active);
 
+/**
+ * typec_altmode_register_notifier - Register an alternate mode state notifier
+ * @adev: Handle to the alternate mode
+ * @nb: Notifier block
+ *
+ * The notifier is called synchronously when the mode represented by @adev is
+ * entered or exited. If @adev is already active %TYPEC_ALTMODE_ENTERED will be
+ * emitted before this function returns. Callbacks must not update the state of
+ * @adev or register or unregister another notifier for @adev. They must also
+ * handle failures locally and return %NOTIFY_OK or %NOTIFY_DONE so that other
+ * subscribers also receive the event. Callback return values do not affect the
+ * active state or the result of notifier registration.
+ *
+ * Return: 0 on success or a negative error code on failure.
+ */
+int typec_altmode_register_notifier(struct typec_altmode *adev,
+				    struct notifier_block *nb)
+{
+	struct altmode *alt = to_altmode(adev);
+	int ret;
+
+	guard(mutex)(&alt->state_lock);
+	ret = blocking_notifier_chain_register(&alt->state_notifier, nb);
+	if (!ret && adev->active)
+		nb->notifier_call(nb, TYPEC_ALTMODE_ENTERED, adev);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(typec_altmode_register_notifier);
+
+/**
+ * typec_altmode_unregister_notifier - Unregister an alternate mode notifier
+ * @adev: Handle to the alternate mode
+ * @nb: Notifier block
+ *
+ * Return: 0 on success or a negative error code on failure.
+ */
+int typec_altmode_unregister_notifier(struct typec_altmode *adev,
+				      struct notifier_block *nb)
+{
+	struct altmode *alt = to_altmode(adev);
+	int ret;
+
+	guard(mutex)(&alt->state_lock);
+	ret = blocking_notifier_chain_unregister(&alt->state_notifier, nb);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(typec_altmode_unregister_notifier);
+
 /**
  * typec_altmode2port - Alternate Mode to USB Type-C port
  * @alt: The Alternate Mode
@@ -658,6 +715,8 @@ typec_register_altmode(struct device *parent,
 	alt->adev.mode_selection = desc->mode_selection;
 	alt->roles = desc->roles;
 	alt->id = id;
+	mutex_init(&alt->state_lock);
+	BLOCKING_INIT_NOTIFIER_HEAD(&alt->state_notifier);
 
 	alt->attrs[0] = &dev_attr_vdo.attr;
 	alt->attrs[1] = &dev_attr_description.attr;
diff --git a/include/linux/usb/typec.h b/include/linux/usb/typec.h
index 10a783b738ef..914a6f0844c5 100644
--- a/include/linux/usb/typec.h
+++ b/include/linux/usb/typec.h
@@ -19,6 +19,7 @@ struct typec_plug;
 struct typec_port;
 struct typec_altmode_ops;
 struct typec_cable_ops;
+struct notifier_block;
 
 struct bus_type;
 struct fwnode_handle;
@@ -184,6 +185,21 @@ struct typec_port *typec_altmode2port(struct typec_altmode *alt);
 
 void typec_altmode_update_active(struct typec_altmode *alt, bool active);
 
+/**
+ * enum typec_altmode_event - USB Type-C alternate mode state event
+ * @TYPEC_ALTMODE_ENTERED: The alternate mode has been entered
+ * @TYPEC_ALTMODE_EXITED: The alternate mode has been exited
+ */
+enum typec_altmode_event {
+	TYPEC_ALTMODE_ENTERED,
+	TYPEC_ALTMODE_EXITED,
+};
+
+int typec_altmode_register_notifier(struct typec_altmode *alt,
+				    struct notifier_block *nb);
+int typec_altmode_unregister_notifier(struct typec_altmode *alt,
+				      struct notifier_block *nb);
+
 void typec_altmode_set_ops(struct typec_altmode *alt,
 			   const struct typec_altmode_ops *ops);
 

-- 
2.55.0

