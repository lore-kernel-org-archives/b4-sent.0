From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 13:27:45 +0000
Subject: [PATCH 5.10.y] Bluetooth: hci_sysfs: Fix NULL pointer dereference
 in device_del()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-so1b-bt-510-v1-1-bff6435e792d@certik.com>
X-B4-Tracking: v=1; b=H4sIANEzCGsC/02NzQrCMBCEX6Xs2a3ZQAr1VcRDfrY2IolkW1FK3
 91ELx7nY+abDYRLZIFTt0HhZ5SYUw106MDPNl0ZY6gZtNIDkR5QMjl0CxpSOBmlwjiwpZGhLh6
 Fp/j62s5gelL9Gy4/Lqu7sV+aqjWdFUZXbPJzQ8IpLDnfsfHj3wXs+wdAO7bZowAAAA==
X-Change-ID: 20261126-so1b-bt-510-f500d96ea19e
To: stable@vger.kernel.org
Cc: Krystian Kaniewski <krystianmkaniewski@gmail.com>, 
 Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 Marcel Holtmann <marcel@holtmann.org>, linux-bluetooth@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795699665; l=4954;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=2oX3LmQzgfr3BLUZlIpwA7c1t5yFys2nt+Hejx0BAwk=;
 b=Q/WMqm6+5wK4cct2DfIgsskUFNO6dHHehcU5WtF07Vc4fpJ73yhbvSNB2PbNtUYtfz0ynUHut
 ph9reLzilTfDMGr/E357CMprNkw0FblVHYFt3HRjbXRV18gAsn336hF
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Krystian Kaniewski <krystianmkaniewski@gmail.com>

commit 9b851b09b392da68bd715601f10a5adb2d8d19b8 upstream.

A NULL pointer dereference in klist_put() occurs when a child device (such
as a BNEP network device in bnep_session) is concurrently being
unregistered while hci_conn_del_sysfs() reparents child devices.

This is caused by a race condition between hci_conn_del_sysfs() and
concurrent child device unregistration (e.g. bnep_session calling
unregister_netdev()). During device unregistration, device_del() snapshots
a non-NULL parent pointer. Concurrently, hci_conn_del_sysfs() finds the
child device using device_find_any_child() and calls device_move() to
reparent it to NULL, which removes the node from its parent's klist and
clears knode_parent. Subsequently, device_del() calls
klist_del(&dev->p->knode_parent) using the stale parent snapshot, causing
klist_put() to dereference knode_klist(n)->put on an already removed node,
resulting in a NULL pointer dereference.

This race was introduced by commit 27aabf27fd01 ("Bluetooth: fix
use-after-free in device_for_each_child()"), which replaced
device_find_child(..., __match_tty) with device_find_any_child() in
hci_conn_del_sysfs(). That change was intended to avoid a use-after-free
where conn->dev outlived its parent hdev->dev when child devices held
references to conn->dev, because conn->dev only held a reference to
hdev->dev while registered in sysfs.

Fix the issue properly by taking an explicit reference to the parent device
with get_device(&hdev->dev) in hci_conn_init_sysfs() and dropping it with
put_device(parent) in bt_link_release() when the conn device is freed. This
ensures that hdev->dev remains valid for the entire lifecycle of conn->dev,
resolving the underlying use-after-free. With the parent reference held
properly, restore the __match_tty filter in hci_conn_del_sysfs() so that
device_move() is only invoked on persistent RFCOMM TTY devices as
originally intended, eliminating the race condition with unregistering
network devices.

Fixes: 27aabf27fd01 ("Bluetooth: fix use-after-free in device_for_each_child()")
Assisted-by: Gemini:gemini-3.7-flash syzbot
Reported-by: syzbot+6df45dd3d03e1a9aca96@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=6df45dd3d03e1a9aca96
Link: https://syzkaller.appspot.com/ai_job?id=f1c0e740-db21-40af-a9ff-84db0fd8b8bd
Signed-off-by: Krystian Kaniewski <krystianmkaniewski@gmail.com>
Signed-off-by: Luiz Augusto von Dentz <luiz.von.dentz@intel.com>
[ adapted to 5.10.y: device_find_child() match callback takes void * ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.6.y and newer already have this fix. The only change from upstream
is the __match_tty() signature: device_find_child() takes a void *
match argument on this branch.

Tested on v5.10.275:
- x86_64 allmodconfig W=1 build of net/bluetooth/hci_sysfs.o, base
  vs patched, no new warnings
- booted the patched kernel with CONFIG_BT=y under QEMU/KVM. I didn't
  reproduce the race.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 net/bluetooth/hci_sysfs.c | 17 +++++++++++++++--
 1 file changed, 15 insertions(+), 2 deletions(-)

diff --git a/net/bluetooth/hci_sysfs.c b/net/bluetooth/hci_sysfs.c
index 1b4d81ffb4b5..3d5e76992552 100644
--- a/net/bluetooth/hci_sysfs.c
+++ b/net/bluetooth/hci_sysfs.c
@@ -11,7 +11,10 @@ static struct class *bt_class;
 static void bt_link_release(struct device *dev)
 {
 	struct hci_conn *conn = to_hci_conn(dev);
+	struct device *parent = dev->parent;
+
 	kfree(conn);
+	put_device(parent);
 }
 
 static const struct device_type bt_link = {
@@ -19,6 +22,16 @@ static const struct device_type bt_link = {
 	.release = bt_link_release,
 };
 
+/*
+ * The rfcomm tty device will possibly retain even when conn
+ * is down, and sysfs doesn't support move zombie device,
+ * so we should move the device before conn device is destroyed.
+ */
+static int __match_tty(struct device *dev, void *data)
+{
+	return !strncmp(dev_name(dev), "rfcomm", 6);
+}
+
 void hci_conn_init_sysfs(struct hci_conn *conn)
 {
 	struct hci_dev *hdev = conn->hdev;
@@ -27,7 +40,7 @@ void hci_conn_init_sysfs(struct hci_conn *conn)
 
 	conn->dev.type = &bt_link;
 	conn->dev.class = bt_class;
-	conn->dev.parent = &hdev->dev;
+	conn->dev.parent = get_device(&hdev->dev);
 
 	device_initialize(&conn->dev);
 }
@@ -67,7 +80,7 @@ void hci_conn_del_sysfs(struct hci_conn *conn)
 	while (1) {
 		struct device *dev;
 
-		dev = device_find_any_child(&conn->dev);
+		dev = device_find_child(&conn->dev, NULL, __match_tty);
 		if (!dev)
 			break;
 		device_move(dev, NULL, DPM_ORDER_DEV_LAST);

---
base-commit: 99112ea818e35b606397c84fbc05e6fadb6ea162
change-id: 20261126-so1b-bt-510-f500d96ea19e

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

