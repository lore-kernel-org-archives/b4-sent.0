From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 12 Nov 2026 09:57:03 +0000
Subject: [PATCH] thunderbolt: Keep the USB4 port when component_add() fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-thunderbolt-v1-1-fc30057cb7cd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAG6N9WoC/yXMSwqEMBBF0a1IjTtgZeBvK+KgY55aIlGSKIK4d
 2P38AzuvSjACwI12UUehwRZXQJ/MuqnrxuhxCaTznXBzFrFaXcW3qxLVKVlmNoUFbimVGweg5y
 /W9v9HXYzo4/vgu77AQjJtbFvAAAA
X-Change-ID: 20261112-thunderbolt-7d1eb9b68e19
To: andreas.noever@gmail.com, YehezkelShB@gmail.com, westeri@kernel.org
Cc: heikki.krogerus@linux.intel.com, linux-kernel@vger.kernel.org, 
 alok.a.tiwari@oracle.com, linux-usb@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794477425; l=4179;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=ki/sIY/g7xSk0EAREsQF/l4ZOt4JaXBRGwX2+sn3T8U=;
 b=4LDAM163qsvP4HlzHvmtX2k/wcdBdvgGPl2BALV8K6VUgwrm8O60yNfau0R9Wemt/4GblZWBS
 JsS/lKdTq63AOy1zQXc/Fcni4Hj6WJIGaJoSNqnGcNBspWJNcnx+0i0
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When component_add() fails, usb4_port_device_add() unregisters the
device but doesn't return:

    ret = component_add(&usb4->dev, &connector_ops);
    if (ret) {
            dev_err(&usb4->dev, "failed to add component\n");
            device_unregister(&usb4->dev);
    }

The port was registered just before, so device_unregister() normally
drops the last reference and usb4_port_device_release() frees usb4.
The function still goes on to set up runtime PM on usb4->dev and
returns usb4 to usb4_switch_add_ports(), which stores the stale pointer
in port->usb4. When the router is removed later,
usb4_switch_remove_ports() calls component_del() and
device_unregister() on that pointer again.

component_add() can fail on allocation, or when binding the aggregate
driver fails. It isn't common, but when it happens the result is a
use-after-free and a double unregister.

The USB4 port can keep working without the component link. Keep the
port registered when component_add() fails, and track whether the
component was added, so that usb4_port_device_remove() only calls
component_del() for a registered component. Otherwise component_del()
would hit its WARN_ON().

Found with a static analysis tool and checked by hand.

Fixes: 5dddb4169284 ("thunderbolt: Link USB4 ports to their USB Type-C connectors")
Reported-by: Alok Tiwari <alok.a.tiwari@oracle.com>
Closes: https://lore.kernel.org/all/20250622140455.2884518-1-alok.a.tiwari@oracle.com/
Suggested-by: Mika Westerberg <mika.westerberg@linux.intel.com>
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Alok asked about the missing return in 2025, and a one-line return
patch was posted in May. In both threads Mika said he'd rather keep the
port, so this does that instead.

https://lore.kernel.org/all/20260517142923.80585-1-darknessshayder@gmail.com/

Compile tested only, I didn't try to force component_add() to fail.
---
 drivers/thunderbolt/tb.h        |  2 ++
 drivers/thunderbolt/usb4_port.c | 12 +++++++-----
 2 files changed, 9 insertions(+), 5 deletions(-)

diff --git a/drivers/thunderbolt/tb.h b/drivers/thunderbolt/tb.h
index e86845762e22..8ed373e94b65 100644
--- a/drivers/thunderbolt/tb.h
+++ b/drivers/thunderbolt/tb.h
@@ -314,6 +314,7 @@ struct tb_port {
  * @can_offline: Does the port have necessary platform support to move
  *		 it into offline mode and back
  * @offline: The port is currently in offline mode
+ * @component_added: The port was added to the component framework
  * @margining: Pointer to margining structure if enabled
  */
 struct usb4_port {
@@ -321,6 +322,7 @@ struct usb4_port {
 	struct tb_port *port;
 	bool can_offline;
 	bool offline;
+	bool component_added;
 #ifdef CONFIG_USB4_DEBUGFS_MARGINING
 	struct tb_margining *margining;
 #endif
diff --git a/drivers/thunderbolt/usb4_port.c b/drivers/thunderbolt/usb4_port.c
index 890de530debc..7582acadf37c 100644
--- a/drivers/thunderbolt/usb4_port.c
+++ b/drivers/thunderbolt/usb4_port.c
@@ -320,11 +320,12 @@ struct usb4_port *usb4_port_device_add(struct tb_port *port)
 		return ERR_PTR(ret);
 	}
 
+	/* The port works fine without the component, so don't fail here */
 	ret = component_add(&usb4->dev, &connector_ops);
-	if (ret) {
-		dev_err(&usb4->dev, "failed to add component\n");
-		device_unregister(&usb4->dev);
-	}
+	if (ret)
+		dev_err(&usb4->dev, "failed to add component: %d\n", ret);
+	else
+		usb4->component_added = true;
 
 	if (!tb_is_upstream_port(port))
 		device_set_wakeup_capable(&usb4->dev, true);
@@ -348,7 +349,8 @@ struct usb4_port *usb4_port_device_add(struct tb_port *port)
  */
 void usb4_port_device_remove(struct usb4_port *usb4)
 {
-	component_del(&usb4->dev, &connector_ops);
+	if (usb4->component_added)
+		component_del(&usb4->dev, &connector_ops);
 	device_unregister(&usb4->dev);
 }
 

---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261112-thunderbolt-7d1eb9b68e19

Best regards,
--  
Suyuan Wang <shyckless@gmail.com>

