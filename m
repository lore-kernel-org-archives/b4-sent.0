From: Janne Grunau <j@jannau.net>
Date: Sun, 17 Mar 2024 12:07:06 +0100
Subject: [PATCH v2 4/6] usb: Add environment based device blocklist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240317-asahi-keyboards-v2-4-d3f4b8384f68@jannau.net>
References: <20240317-asahi-keyboards-v2-0-d3f4b8384f68@jannau.net>
In-Reply-To: <20240317-asahi-keyboards-v2-0-d3f4b8384f68@jannau.net>
To: Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marex@denx.de>, 
 Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Joe Hershberger <joe.hershberger@ni.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4777; i=j@jannau.net;
 h=from:subject:message-id; bh=1B9UO0P8CfWsKNUiNEUhYx6LFm2qj3jdyvJC22Nz0Yw=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtRv5+7xRMQdv2S1Qunb9p7S/WaxFexcmhXr6l6GMdpuX
 n1zv5hERykLgxgXg6yYIkuS9ssOhtU1ijG1D8Jg5rAygQxh4OIUgIn0GzEyfFzqemHbzVP7nrGn
 yBtXr5+tPjfw5QqbnJpV+gFNTSxiFxj+RyiyzeMR4N1/qvLh4+49GvF2fN1t59qfRT2o+mt3/bM
 rOwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the environment variable "usb_blocklist" to prevent USB devices
listed in it from being used. This allows to ignore devices which
trigger bugs in u-boot's USB stack or are undesirable for other reasons.
Devices emulating keyboards are one example. U-boot currently supports
only one USB keyboard device. Most commonly, people run into this with
Yubikeys, so let's ignore those in the default environment.

Based on previous USB keyboard specific patches for the same purpose.

Link: https://lore.kernel.org/u-boot/7ab604fb-0fec-4f5e-8708-7a3a7e2cb568@denx.de/
Signed-off-by: Janne Grunau <j@jannau.net>
---
 common/usb.c              | 56 +++++++++++++++++++++++++++++++++++++++++++++++
 doc/usage/environment.rst | 12 ++++++++++
 include/env_default.h     | 11 ++++++++++
 3 files changed, 79 insertions(+)

diff --git a/common/usb.c b/common/usb.c
index 836506dcd9..73af5be066 100644
--- a/common/usb.c
+++ b/common/usb.c
@@ -1084,6 +1084,57 @@ static int usb_prepare_device(struct usb_device *dev, int addr, bool do_read,
 	return 0;
 }
 
+static int usb_blocklist_parse_error(const char *blocklist, size_t pos)
+{
+	printf("usb_blocklist parse error at char %zu in \"%s\"\n", pos,
+	       blocklist);
+	return 0;
+}
+
+static int usb_device_is_blocked(u16 id_vendor, u16 id_product)
+{
+	ulong vid, pid;
+	char *end;
+	const char *block_str = env_get("usb_blocklist");
+	const char *cur = block_str;
+
+	/* parse "usb_blocklist" strictly */
+	while (cur && cur[0] != '\0') {
+		vid = simple_strtoul(cur, &end, 0);
+		if (cur == end || end[0] != ':')
+			return usb_blocklist_parse_error(block_str,
+							 cur - block_str);
+
+		cur = end + 1;
+		pid = simple_strtoul(cur, &end, 0);
+		if (cur == end && end[0] != '*')
+			return usb_blocklist_parse_error(block_str,
+							 cur - block_str);
+
+		if (end[0] == '*') {
+			/* use out of range idProduct as wildcard indication */
+			pid = U16_MAX + 1;
+			end++;
+		}
+		if (end[0] != ',' && end[0] != '\0')
+			return usb_blocklist_parse_error(block_str,
+							 cur - block_str);
+
+		if (id_vendor == vid && (pid > U16_MAX || id_product == pid)) {
+			printf("Ignoring USB device 0x%x:0x%x\n",id_vendor,
+			      id_product);
+			debug("Ignoring USB device 0x%x:0x%x\n",id_vendor,
+			      id_product);
+			return 1;
+		}
+		if (end[0] == '\0')
+			break;
+		cur = end + 1;
+	}
+
+	return 0;
+}
+
 int usb_select_config(struct usb_device *dev)
 {
 	unsigned char *tmpbuf = NULL;
@@ -1099,6 +1150,11 @@ int usb_select_config(struct usb_device *dev)
 	le16_to_cpus(&dev->descriptor.idProduct);
 	le16_to_cpus(&dev->descriptor.bcdDevice);
 
+	/* ignore devices from usb_blocklist */
+	if (usb_device_is_blocked(dev->descriptor.idVendor,
+				  dev->descriptor.idProduct))
+		return -ENODEV;
+
 	/*
 	 * Kingston DT Ultimate 32GB USB 3.0 seems to be extremely sensitive
 	 * about this first Get Descriptor request. If there are any other
diff --git a/doc/usage/environment.rst b/doc/usage/environment.rst
index ebf75fa948..e42702adb2 100644
--- a/doc/usage/environment.rst
+++ b/doc/usage/environment.rst
@@ -366,6 +366,18 @@ tftpwindowsize
     This means the count of blocks we can receive before
     sending ack to server.
 
+usb_blocklist
+    Block USB devices from being bound to an USB device driver. This can be used
+    to ignore devices which causes crashes in u-boot's USB stack or are
+    undesirable for other reasons.
+    The default environment blocks Yubico devices since they emulate USB
+    keyboards. U-boot currently supports only a single USB keyboard device and
+    it is undesirable that a Yubikey is used as keyboard.
+    Devices are matched by idVendor and idProduct. The variable contains a comma
+    separated list of idVendor:idProduct pairs as hexadecimal numbers joined
+    by a colon. '*' functions as a wildcard for idProduct to block all devices
+    with the specified idVendor.
+
 vlan
     When set to a value < 4095 the traffic over
     Ethernet is encapsulated/received over 802.1q
diff --git a/include/env_default.h b/include/env_default.h
index 2ca4a087d3..ba4c7516b4 100644
--- a/include/env_default.h
+++ b/include/env_default.h
@@ -99,6 +99,17 @@ const char default_environment[] = {
 #ifdef CONFIG_SYS_SOC
 	"soc="		CONFIG_SYS_SOC			"\0"
 #endif
+#ifdef CONFIG_USB_HOST
+	"usb_blocklist="
+#ifdef CONFIG_USB_KEYBOARD
+	/* Ignore Yubico devices. Currently only a single USB keyboard device is
+	 * supported and the emulated HID keyboard Yubikeys present is useless
+	 * as keyboard.
+	 */
+	"0x1050:*,"
+#endif
+	"\0"
+#endif
 #ifdef CONFIG_ENV_IMPORT_FDT
 	"env_fdt_path="	CONFIG_ENV_FDT_PATH		"\0"
 #endif

-- 
2.44.0

