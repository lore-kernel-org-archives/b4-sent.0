From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Thu, 05 Nov 2026 02:20:14 +0000
Subject: [PATCH] media: dvb-core: fix use-after-free in dvb_remove_device()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-dvb-remove-device-uaf-v1-1-a9e091d7c9ae@gmail.com>
X-B4-Tracking: v=1; b=H4sIAN3n62oC/x2MOwqAMBAFryJbu+CqsfAqYhGTp27hhwSDIN7dY
 DkwMw9FBEWkvngoIGnUY88gZUFutfsCVp+Z6qruRCrDPk0csB0J7LPvwJed2cI2rTSdM2Iot2f
 ArPf/Hcb3/QDZT06qZwAAAA==
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+37578f730d38898f4b74@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Joas Antonio dos Santos <joasantonio108@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793845213; l=2266;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=prLpSJVWNrnZT55RbJ2w1/TI1YO7NXSCENMkRGHUepw=;
 b=zCVEFfk4tLNKrt4gCOPsh3ztTBXtUF35/c3pdzSfvAzgmMIih85IFQxlWBVrgTs/tGl0aN+ib
 ICsbECE8OH3CIWpJSE7Z0yTVnIqb9SBOurvdMKsOf9AFWkgpphJRgci
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dvb_remove_device() calls dvb_device_put() while still holding and
using the dvb_device pointer.  If the put drops the last reference,
dvb_free_device() kfrees the struct, and the subsequent calls to
dvb_media_device_free(), device_destroy(), and list_del() all operate
on freed memory.

The syzbot KASAN report shows the freed kmalloc-256 object being read
at dvb_media_device_free()+0x3a, which dereferences dvbdev->entity
(dvbdev.c:210) after dvb_device_put() in dvb_remove_device() already
freed it via dvb_free_device().

Fix by saving the minor number before releasing the reference and
moving dvb_device_put() to after all accesses to the dvb_device
struct.  This ensures the device remains valid for the entire cleanup
sequence regardless of the reference count.

Found by LLM-assisted code review of syzbot-reported crash patterns.

Reported-by: syzbot+37578f730d38898f4b74@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=37578f730d38898f4b74
Fixes: 0fc044b2b5e2 ("media: dvbdev: adopts refcnt to avoid UAF")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/media/dvb-core/dvbdev.c | 13 ++++++++-----
 1 file changed, 8 insertions(+), 5 deletions(-)

diff --git a/drivers/media/dvb-core/dvbdev.c b/drivers/media/dvb-core/dvbdev.c
index d753d3295..b2beacbab 100644
--- a/drivers/media/dvb-core/dvbdev.c
+++ b/drivers/media/dvb-core/dvbdev.c
@@ -593,19 +593,22 @@ EXPORT_SYMBOL(dvb_register_device);
 
 void dvb_remove_device(struct dvb_device *dvbdev)
 {
+	int minor;
+
 	if (!dvbdev)
 		return;
 
+	minor = dvbdev->minor;
+
 	down_write(&minor_rwsem);
-	dvb_minors[dvbdev->minor] = NULL;
-	dvb_device_put(dvbdev);
+	dvb_minors[minor] = NULL;
 	up_write(&minor_rwsem);
 
 	dvb_media_device_free(dvbdev);
-
-	device_destroy(dvb_class, MKDEV(DVB_MAJOR, dvbdev->minor));
-
+	device_destroy(dvb_class, MKDEV(DVB_MAJOR, minor));
 	list_del(&dvbdev->list_head);
+
+	dvb_device_put(dvbdev);
 }
 EXPORT_SYMBOL(dvb_remove_device);
 

---
base-commit: ebcf66fba448879076bfdd1018ac5cda37b912bf
change-id: 20261105-dvb-remove-device-uaf-aea34136c515

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

