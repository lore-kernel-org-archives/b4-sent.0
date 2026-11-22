From: Leicheng Xie <leicheng.dev@gmail.com>
Date: Sun, 22 Nov 2026 17:33:29 +0800
Subject: [PATCH] Bluetooth: RFCOMM: Fix slab-use-after-free in
 rfcomm_dev_add()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-fix-rfcomm-dev-add-uaf-v1-1-cac5354752ed@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOi2AmsC/x2MywqAIBAAf0X23EJr734lOoiutYcylCKI/j3pO
 DAzDySOwglG9UDkS5KEPQMVCuxq9oVRXGbQpW6JtEYvN0Zvw7ah4wuNc3gaj9Zz3VcddTQ0kOM
 jcjb/8TS/7wdFmz/PaAAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Gianluca Anzolin <gianluca@sottospazio.it>
Cc: linux-bluetooth@vger.kernel.org, 
 syzbot+11542ff1d167fdffa1fc@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Leicheng Xie <leicheng.dev@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795340012; l=3276;
 i=leicheng.dev@gmail.com; s=20261122; h=from:subject:message-id;
 bh=wPiurJf5NAB3Lu8Avk81ILeINiSohz9dvVjdRquJVBo=;
 b=6Q+PSt3gaZkOQ7tAFw438TjcTSry2NO0bq7tgnocaG0Af45XxeX3tdpcInxYtCuzgXpbMPTwT
 b45gFQpGmg0DdahRCUttX80fmnMY/QBYxfLGSnB+OANXrPmPYYwCe7I
X-Developer-Key: i=leicheng.dev@gmail.com; a=ed25519;
 pk=3Wc835kaGsdFoMvE39Cn0NKn+/y+alxEDJs7LjGUmis=
X-Endpoint-Received: by B4 Relay for leicheng.dev@gmail.com/20261122 with auth_id=1600
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__rfcomm_dev_add() inserts the newly allocated struct rfcomm_dev into
rfcomm_dev_list and releases rfcomm_dev_lock while holding only the
initial tty_port reference. Back in rfcomm_dev_add(), the device is
registered with tty_port_register_device() and further initialized
(dev->tty_dev assignment, reparenting, drvdata, sysfs attributes, and
reading dev->id).

When RFCOMM_RELEASE_ONHUP is set, a concurrent task can open and close
the RFCOMM TTY device as soon as it becomes visible on rfcomm_dev_list.
rfcomm_tty_install() takes over the initial reference by setting
RFCOMM_TTY_OWNED, and rfcomm_tty_cleanup() drops it to zero, freeing
dev via rfcomm_dev_destruct() while rfcomm_dev_add() is still running:

  BUG: KASAN: slab-use-after-free in rfcomm_dev_add
  Write of size 8 at addr ffff88800e85b3e0 by task rfcomm_uaf_poc/179

Hold an extra tty_port reference in __rfcomm_dev_add() before dropping
rfcomm_dev_lock, and release it at the end of rfcomm_dev_add() after
caching dev->id. On the tty_port_register_device() failure path, use
test_and_set_bit(RFCOMM_TTY_OWNED, &dev->status) before dropping the
initial reference to match __rfcomm_release_dev() and prevent a leak or
double-put if a concurrent open took ownership.

Fixes: 5b899241874d ("Bluetooth: Release RFCOMM port when the last user closes the TTY")
Reported-by: syzbot+11542ff1d167fdffa1fc@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=11542ff1d167fdffa1fc
Cc: stable@vger.kernel.org
Signed-off-by: Leicheng Xie <leicheng.dev@gmail.com>
---
 net/bluetooth/rfcomm/tty.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/net/bluetooth/rfcomm/tty.c b/net/bluetooth/rfcomm/tty.c
index 198c7dd1a95b..3a61c45b5b51 100644
--- a/net/bluetooth/rfcomm/tty.c
+++ b/net/bluetooth/rfcomm/tty.c
@@ -303,6 +303,9 @@ static struct rfcomm_dev *__rfcomm_dev_add(struct rfcomm_dev_req *req,
 	   holds reference to this module. */
 	__module_get(THIS_MODULE);
 
+	/* Hold an extra reference for rfcomm_dev_add() until setup completes */
+	tty_port_get(&dev->port);
+
 	mutex_unlock(&rfcomm_dev_lock);
 	return dev;
 
@@ -316,6 +319,7 @@ static int rfcomm_dev_add(struct rfcomm_dev_req *req, struct rfcomm_dlc *dlc)
 {
 	struct rfcomm_dev *dev;
 	struct device *tty;
+	int id;
 
 	BT_DBG("id %d channel %d", req->dev_id, req->channel);
 
@@ -328,6 +332,8 @@ static int rfcomm_dev_add(struct rfcomm_dev_req *req, struct rfcomm_dlc *dlc)
 	tty = tty_port_register_device(&dev->port, rfcomm_tty_driver,
 			dev->id, NULL);
 	if (IS_ERR(tty)) {
+		if (!test_and_set_bit(RFCOMM_TTY_OWNED, &dev->status))
+			tty_port_put(&dev->port);
 		tty_port_put(&dev->port);
 		return PTR_ERR(tty);
 	}
@@ -342,7 +348,10 @@ static int rfcomm_dev_add(struct rfcomm_dev_req *req, struct rfcomm_dlc *dlc)
 	if (device_create_file(dev->tty_dev, &dev_attr_channel) < 0)
 		BT_ERR("Failed to create channel attribute");
 
-	return dev->id;
+	id = dev->id;
+	tty_port_put(&dev->port);
+
+	return id;
 }
 
 /* ---- Send buffer ---- */

---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261122-fix-rfcomm-dev-add-uaf-cfe483717195

Best regards,
-- 
Leicheng Xie <leicheng.dev@gmail.com>

