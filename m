From: Oleh Kurudz <admin@or1k.net>
Date: Fri, 20 Nov 2026 00:22:25 +0200
Subject: [PATCH 1/2] USB: core: Add USB_QUIRK_DISCONNECT_PARENT_SUSPEND
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-quadcast-s-suspend-v1-1-add8ccf12c8f@or1k.net>
References: <20261120-quadcast-s-suspend-v1-0-add8ccf12c8f@or1k.net>
In-Reply-To: <20261120-quadcast-s-suspend-v1-0-add8ccf12c8f@or1k.net>
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 Oleh Kurudz <admin@or1k.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795126946; l=5002;
 i=admin@or1k.net; s=20261120; h=from:subject:message-id;
 bh=KS7CYnsQniBo8AQ1uwycWYmb0KvcOWr+4Ntt5Gu/5Bo=;
 b=vUoxPDfWd6mCpilBiN9DmkA3IQgp2ZchSHiDTk99tOOJBcs769O54gcorFxnilLsMnq1BIFcM
 lRJrWaPS/crBN8Gsybs+FW06qczEQn/y7vbtjJmHHXC+LDFvi+IDDjn
X-Developer-Key: i=admin@or1k.net; a=ed25519;
 pk=99OKf9VLJkjldneE6gRk0c6oTl7G+EdqRiFo4h8sH6Q=
X-Endpoint-Received: by B4 Relay for admin@or1k.net/20261120 with auth_id=1577
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some USB products are several functions behind a small hub inside the
same enclosure. On the HyperX QuadCast S microphone one of these
functions drops off the bus while the system is suspending, and the
built-in hub then reports the connect change upstream and wakes the
system, even though remote wakeup is disabled for the hub and for
everything behind it. On s2idle systems the suspend bounces back within
about a second.

USB_QUIRK_DISCONNECT_SUSPEND does not help here. Set on the function
that drops off, it disables that function's port on the built-in hub,
but the hub itself still signals the wakeup. Set on the hub, it would
affect every product that uses the same generic hub chip (a Huasheng
214b:7250 in this case), including ones with a keyboard behind it that
is expected to wake the system.

Add USB_QUIRK_DISCONNECT_PARENT_SUSPEND. When a hub has a child with
this quirk, usb_suspend() disables the hub's upstream port after
suspending it, just as USB_QUIRK_DISCONNECT_SUSPEND would for the hub
itself. The children are checked at suspend time instead of copying the
flag to the hub at enumeration, because a reset-resume of the hub re-runs
usb_detect_quirks() and would drop a copied flag.

Like USB_QUIRK_DISCONNECT_SUSPEND, this only affects system sleep;
runtime suspend does not go through usb_suspend(). The quirk can also be
set with the usbcore.quirks parameter, using the letter 's'.

This patch and its changelog were written with the help of an AI
coding assistant (Claude, claude-opus-5-5). I reviewed the result and
tested it on my hardware, see the next patch.

Signed-off-by: Oleh Kurudz <admin@or1k.net>
---
 Documentation/admin-guide/kernel-parameters.txt |  5 +++++
 drivers/usb/core/driver.c                       | 20 +++++++++++++++++++-
 drivers/usb/core/quirks.c                       |  3 +++
 include/linux/usb/quirks.h                      |  7 +++++++
 4 files changed, 34 insertions(+), 1 deletion(-)

diff --git a/Documentation/admin-guide/kernel-parameters.txt b/Documentation/admin-guide/kernel-parameters.txt
index 176648941..7751c373a 100644
--- a/Documentation/admin-guide/kernel-parameters.txt
+++ b/Documentation/admin-guide/kernel-parameters.txt
@@ -8235,6 +8235,11 @@ Kernel parameters
 					9-bytes configuration descriptor request.
 					Ask for 255-bytes request instead to mirror
 					Windows' behavior);
+				s = USB_QUIRK_DISCONNECT_PARENT_SUSPEND
+					(Device sits behind a hub that signals
+					a spurious wakeup when the device drops
+					off the bus during suspend; disconnect
+					the hub before suspend);
 			Example: quirks=0781:5580:bk,0a5c:5834:gij
 
 	usbhid.mousepoll=
diff --git a/drivers/usb/core/driver.c b/drivers/usb/core/driver.c
index d3a61ebc6..a40d9595b 100644
--- a/drivers/usb/core/driver.c
+++ b/drivers/usb/core/driver.c
@@ -1620,6 +1620,23 @@ static void choose_wakeup(struct usb_device *udev, pm_message_t msg)
 	udev->do_remote_wakeup = w;
 }
 
+/*
+ * Check whether a child of @hdev wants @hdev disconnected during system
+ * suspend. The caller must hold @hdev's device lock, which keeps the set of
+ * children stable.
+ */
+static bool usb_child_wants_parent_disconnect(struct usb_device *hdev)
+{
+	struct usb_device *child;
+	int port1;
+
+	usb_hub_for_each_child(hdev, port1, child) {
+		if (child->quirks & USB_QUIRK_DISCONNECT_PARENT_SUSPEND)
+			return true;
+	}
+	return false;
+}
+
 /* The device lock is held by the PM core */
 int usb_suspend(struct device *dev, pm_message_t msg)
 {
@@ -1637,7 +1654,8 @@ int usb_suspend(struct device *dev, pm_message_t msg)
 	if (r)
 		return r;
 
-	if (udev->quirks & USB_QUIRK_DISCONNECT_SUSPEND)
+	if ((udev->quirks & USB_QUIRK_DISCONNECT_SUSPEND) ||
+	    (udev->parent && usb_child_wants_parent_disconnect(udev)))
 		usb_port_disable(udev);
 
 	return 0;
diff --git a/drivers/usb/core/quirks.c b/drivers/usb/core/quirks.c
index a4bcbe9c9..3933cf9c0 100644
--- a/drivers/usb/core/quirks.c
+++ b/drivers/usb/core/quirks.c
@@ -146,6 +146,9 @@ static int quirks_param_set(const char *value, const struct kernel_param *kp)
 			case 'r':
 				flags |= USB_QUIRK_WINDOWS_CONFIG_REQ_SIZE;
 				break;
+			case 's':
+				flags |= USB_QUIRK_DISCONNECT_PARENT_SUSPEND;
+				break;
 			/* Ignore unrecognized flag characters */
 			}
 		}
diff --git a/include/linux/usb/quirks.h b/include/linux/usb/quirks.h
index a4043b33c..101dd1ca4 100644
--- a/include/linux/usb/quirks.h
+++ b/include/linux/usb/quirks.h
@@ -84,4 +84,11 @@
 /* Use a 255 bytes config descriptor request mirroring windows behavior */
 #define USB_QUIRK_WINDOWS_CONFIG_REQ_SIZE	BIT(19)
 
+/*
+ * Device sits behind a hub that signals a spurious wakeup when the device
+ * drops off the bus during system suspend; the hub needs to be disconnected
+ * before suspend.
+ */
+#define USB_QUIRK_DISCONNECT_PARENT_SUSPEND	BIT(20)
+
 #endif /* __LINUX_USB_QUIRKS_H */

-- 
2.56.1

