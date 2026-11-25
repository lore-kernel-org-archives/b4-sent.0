From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: heikki.krogerus@linux.intel.com, gregkh@linuxfoundation.org
Cc: hdegoede@redhat.com, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH] usb: roles: serialize registered checks and unregister
 under sw->lock
Date: Wed, 25 Nov 2026 23:48:25 +0000
Message-Id: <20261125234825.94733-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795650505; l=2685;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=GuND8n2xqj5QQdwL+68NjBweSNAn1cbbNFIZ1io33u8=;
 b=VX6Qt7SJnnMShPHXs0AFA3PZgzsq8zQ9J0kvT4+DaIasbDiJWcAhIvaOm7WqJxoTjdV2aHnlu
 Pov7pAV68lICjkt3ZjvroL0Xh5HTPEM+j4lia4hOjBqdxq0PHrIzQuH
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

usb_role_switch_set_role() and usb_role_switch_get_role() check
sw->registered outside sw->lock, while usb_role_switch_unregister()
clears sw->registered without acquiring sw->lock.

A consumer can observe sw->registered == true, be preempted before
acquiring sw->lock, and still invoke sw->set() or sw->get() after
usb_role_switch_unregister() has returned and the provider driver has
torn down its state. Likewise, an in-flight callback already holding
sw->lock is not drained before usb_role_switch_unregister() returns.

Move the sw->registered check inside sw->lock in both
usb_role_switch_set_role() and usb_role_switch_get_role(), and clear
sw->registered under sw->lock in usb_role_switch_unregister() so new
callbacks are rejected and in-flight callbacks finish before the
provider continues teardown.

Found and drafted with an AI coding assistant.

Fixes: b787a3e78175 ("usb: roles: don't get/set_role() when usb_role_switch is unregistered")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/usb/roles/class.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/drivers/usb/roles/class.c b/drivers/usb/roles/class.c
index edec139..3370294 100644
--- a/drivers/usb/roles/class.c
+++ b/drivers/usb/roles/class.c
@@ -79,10 +79,11 @@ int usb_role_switch_set_role(struct usb_role_switch *sw, enum usb_role role)
 	if (IS_ERR_OR_NULL(sw))
 		return 0;
 
-	if (!sw->registered)
-		return -EOPNOTSUPP;
-
 	mutex_lock(&sw->lock);
+	if (!sw->registered) {
+		ret = -EOPNOTSUPP;
+		goto out;
+	}
 
 	ret = sw->set(sw, role);
 	if (!ret) {
@@ -90,6 +91,7 @@ int usb_role_switch_set_role(struct usb_role_switch *sw, enum usb_role role)
 		kobject_uevent(&sw->dev.kobj, KOBJ_CHANGE);
 	}
 
+out:
 	mutex_unlock(&sw->lock);
 
 	return ret;
@@ -105,18 +107,21 @@ EXPORT_SYMBOL_GPL(usb_role_switch_set_role);
  */
 enum usb_role usb_role_switch_get_role(struct usb_role_switch *sw)
 {
-	enum usb_role role;
+	enum usb_role role = USB_ROLE_NONE;
 
-	if (IS_ERR_OR_NULL(sw) || !sw->registered)
+	if (IS_ERR_OR_NULL(sw))
 		return USB_ROLE_NONE;
 
 	mutex_lock(&sw->lock);
+	if (!sw->registered)
+		goto out;
 
 	if (sw->get)
 		role = sw->get(sw);
 	else
 		role = sw->role;
 
+out:
 	mutex_unlock(&sw->lock);
 
 	return role;
@@ -423,7 +428,9 @@ void usb_role_switch_unregister(struct usb_role_switch *sw)
 {
 	if (IS_ERR_OR_NULL(sw))
 		return;
+	mutex_lock(&sw->lock);
 	sw->registered = false;
+	mutex_unlock(&sw->lock);
 	if (dev_fwnode(&sw->dev))
 		component_del(&sw->dev, &connector_ops);
 	device_unregister(&sw->dev);
-- 
2.54.0 (Apple Git-157)


