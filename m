From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 20:12:13 +0000
Subject: [PATCH 1/2] w1: Free the slave from its device release callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-w1-slave-release-v1-1-c2948c825d08@gmail.com>
References: <20261119-w1-slave-release-v1-0-c2948c825d08@gmail.com>
In-Reply-To: <20261119-w1-slave-release-v1-0-c2948c825d08@gmail.com>
To: krzk@kernel.org
Cc: josef@toxicpanda.com, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795119133; l=3501;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=h00RIfaNaF6buZJJbs9syNwkmQRRBcWSBtsJmdwtlnA=;
 b=7OLNMn9Ir4zOshS9QgYQTJmK8jJyJkZYGm2mG/g+CbII57ps5MS3QThx3vcz8JB1MWazUu71V
 1tvP/q+GdKIAYH8YX7nAXD6dNzwh9v+Xj7wxZCnkREd85P4HAAaar3+
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

w1_unref_slave() frees the slave right after unregistering its device:

	device_unregister(&sl->dev);
	...
	kfree(sl);

but sl embeds that struct device, and w1_slave_release() still uses sl
(sl->family, sl->master) when the last reference to the device is
dropped. If anything else holds a reference to sl->dev at that point,
the release callback and the kobject code run on freed memory.

Before commit 9fcbbac5ded4 ("w1: process w1 netlink commands in
w1_process thread"), w1_slave_detach() waited for the release callback
to complete before freeing the slave; that commit dropped the wait.
The attach error path has had the same problem since commit
0ec4eb71b495 ("w1: use put_device() if device_register() fail"): it
frees sl after __w1_attach_slave_device() has dropped the device with
put_device().

This is easy to see with CONFIG_DEBUG_KOBJECT_RELEASE, which delays the
release: adding a slave through the master's w1_master_add file and
removing it through w1_master_remove gives a series of KASAN
use-after-free reports (in __run_timers, __queue_work and
w1_slave_release) on the object freed by:

  kfree+0x176/0x530
  w1_unref_slave+0x38b/0x510
  w1_slave_detach+0xbf/0xf0
  w1_master_attribute_store_remove+0x137/0x240

Move the kfree() into w1_slave_release(). The attach error path now
relies on the release callback as well, and no longer reads sl->name
or sl->master after put_device().

Found with a static analysis tool and checked by hand.

Fixes: 9fcbbac5ded4 ("w1: process w1 netlink commands in w1_process thread")
Fixes: 0ec4eb71b495 ("w1: use put_device() if device_register() fail")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested in QEMU (x86_64, KASAN, CONFIG_DEBUG_KOBJECT_RELEASE) with a test
master that has no devices on the bus: write a slave id to w1_master_add,
then to w1_master_remove. Without the patch KASAN reports the
use-after-free above; with it there are no reports. The attach error
path is not exercised by this test.
---
 drivers/w1/w1.c | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/drivers/w1/w1.c b/drivers/w1/w1.c
index 8b33d933a582..bead2fa08c8b 100644
--- a/drivers/w1/w1.c
+++ b/drivers/w1/w1.c
@@ -80,6 +80,10 @@ static void w1_slave_release(struct device *dev)
 
 	w1_family_put(sl->family);
 	sl->master->slave_count--;
+#ifdef DEBUG
+	memset(sl, 0, sizeof(*sl));
+#endif
+	kfree(sl);
 }
 
 static ssize_t name_show(struct device *dev, struct device_attribute *attr, char *buf)
@@ -761,10 +765,10 @@ int w1_attach_slave_device(struct w1_master *dev, struct w1_reg_num *rn)
 
 	err = __w1_attach_slave_device(sl);
 	if (err < 0) {
-		dev_err(&dev->dev, "%s: Attaching %s failed.\n", __func__,
-			 sl->name);
-		atomic_dec(&sl->master->refcnt);
-		kfree(sl);
+		/* the put_device() in __w1_attach_slave_device() freed sl */
+		dev_err(&dev->dev, "%s: Attaching %02x-%012llx failed.\n",
+			__func__, rn->family, (unsigned long long)rn->id);
+		atomic_dec(&dev->refcnt);
 		return err;
 	}
 
@@ -806,10 +810,6 @@ int w1_unref_slave(struct w1_slave *sl)
 
 		w1_family_notify(BUS_NOTIFY_DEL_DEVICE, sl);
 		device_unregister(&sl->dev);
-		#ifdef DEBUG
-		memset(sl, 0, sizeof(*sl));
-		#endif
-		kfree(sl);
 	}
 	atomic_dec(&dev->refcnt);
 	return refcnt;

-- 
2.34.1

