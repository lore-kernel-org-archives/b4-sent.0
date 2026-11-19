From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 20:12:14 +0000
Subject: [PATCH 2/2] w1: Keep the master alive until the slave is released
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-w1-slave-release-v1-2-c2948c825d08@gmail.com>
References: <20261119-w1-slave-release-v1-0-c2948c825d08@gmail.com>
In-Reply-To: <20261119-w1-slave-release-v1-0-c2948c825d08@gmail.com>
To: krzk@kernel.org
Cc: josef@toxicpanda.com, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795119133; l=2640;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=s7xxV1z0BqGEA94eM7oLKVSYG0/TyrMlUWouAQlJF6Y=;
 b=IYkHBgy09w1VAi/qYFgCX+/Av1jwGZk/juotQBNCxqYE2MnArmRg1E6odQJs7djcFrWIsV1z0
 pXAVa9JTl/HA5yC+1RXUcKHHOEYA7BWcIPjt96cg5Rt/BJ29BIJ8Fc5
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

w1_slave_release() updates the master's slave count:

	sl->master->slave_count--;

but the slave holds no reference to the master. The reference the
slave device took on its parent in device_add() is dropped again in
device_del(), and w1_unref_slave() drops the master's refcnt right
after unregistering the slave, so the master can be removed and freed
before a delayed release of the slave runs.

With CONFIG_DEBUG_KOBJECT_RELEASE and the previous patch applied,
removing a slave through w1_master_remove and then removing the master
right away gives a KASAN report in w1_slave_release(), reading the
4096-byte w1_master allocation freed by the master's release.

Take a reference to the master device when the slave is attached and
drop it at the end of w1_slave_release(). Before commit 9fcbbac5ded4
("w1: process w1 netlink commands in w1_process thread") this could
not happen, because removing a slave waited for its release.

Found with a static analysis tool and checked by hand.

Fixes: 9fcbbac5ded4 ("w1: process w1 netlink commands in w1_process thread")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested in the same setup: six rounds of adding a slave, removing it and
removing the master right after. With only 1/2 applied KASAN reported
the use-after-free in w1_slave_release() in four rounds; with both
patches there were no reports.
---
 drivers/w1/w1.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/w1/w1.c b/drivers/w1/w1.c
index bead2fa08c8b..348edc5bf455 100644
--- a/drivers/w1/w1.c
+++ b/drivers/w1/w1.c
@@ -75,15 +75,17 @@ static void w1_master_release(struct device *dev)
 static void w1_slave_release(struct device *dev)
 {
 	struct w1_slave *sl = dev_to_w1_slave(dev);
+	struct w1_master *master = sl->master;
 
 	dev_dbg(dev, "%s: Releasing %s [%p]\n", __func__, sl->name, sl);
 
 	w1_family_put(sl->family);
-	sl->master->slave_count--;
+	master->slave_count--;
 #ifdef DEBUG
 	memset(sl, 0, sizeof(*sl));
 #endif
 	kfree(sl);
+	put_device(&master->dev);
 }
 
 static ssize_t name_show(struct device *dev, struct device_attribute *attr, char *buf)
@@ -735,6 +737,8 @@ int w1_attach_slave_device(struct w1_master *dev, struct w1_reg_num *rn)
 
 	sl->owner = THIS_MODULE;
 	sl->master = dev;
+	/* w1_slave_release() uses the master, keep it until then */
+	get_device(&dev->dev);
 	set_bit(W1_SLAVE_ACTIVE, &sl->flags);
 
 	memset(&msg, 0, sizeof(msg));

-- 
2.34.1

