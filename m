From: Mani Tofigh <mt4022@columbia.edu>
Date: Wed, 11 Nov 2026 17:46:31 -0500
Subject: [PATCH] nvme: fix deadlock on nvme_subsystems_lock in
 nvme_init_subsystem()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-nvme-subsys-lock-deadlock-v1-1-1837b8e9076f@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMSw7CMAwFr1J5jaU2Aiq4CmIR4kdrPimKoQJVv
 TumvNWbxcxEhqIw2lcTFYxqOmSHZlVR6mPuwCrOFOqwbXycxzvYXif7GN+GdGVBlOW06wCBiGx
 2kdx/FJz1vbQPxz+7d0F6/oI0z1+LO4dAfQAAAA==
X-Change-ID: 20261111-nvme-subsys-lock-deadlock-742ededdd59a
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794437191; l=2940;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=cOZLSGE+OmO3+XZiW2AyMoXiLb0mQ0fDaQF1JNZtd3I=;
 b=DFCsz9vJwyVkdjRUdcJS1+RgfZoeSSZgklxln7oPkWlolfNySJO2nXIEmKzRhVDzA1zS+lXKZ
 M3QEdsuQ0g2BRHGDCojYiG0FWbXULh3Y8n+Fdf2bPkfZM6ohEJRIE1B
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Connecting a controller to a new subsystem deadlocks when
sysfs_create_link() fails in nvme_init_subsystem(), e.g., on an
allocation failure.  The error path drops the last subsystem reference
with nvme_subsystems_lock held and nvme_destroy_subsystem() takes the
same lock again:

  nvme nvme0: failed to create sysfs link from subsystem.
  ============================================
  WARNING: possible recursive locking detected
  ...
  nvmesubsys/95 is trying to acquire lock:
  (nvme_subsystems_lock){+.+.}-{4:4}, at: nvme_destroy_subsystem+0x1b/0x1e0

  but task is already holding lock:
  (nvme_subsystems_lock){+.+.}-{4:4}, at: nvme_init_identify+0x81e/0x34b0
  ...
  Call Trace:
   __mutex_lock+0x1a2/0x26e0
   nvme_destroy_subsystem+0x1b/0x1e0
   nvme_init_identify.cold+0x3bc/0x56f
   nvme_init_ctrl_finish+0x1bc/0x7a0
   nvme_loop_configure_admin_queue+0x205/0x2b0
   nvme_loop_create_ctrl+0x480/0xd10
   nvmf_dev_write+0x365/0x650
   vfs_write+0x1e3/0x1250
   ksys_write+0xfa/0x200
   do_syscall_64+0xfb/0x590
   entry_SYSCALL_64_after_hwframe+0x77/0x7f
  ...
  INFO: task nvmesubsys:95 blocked for more than 20 seconds.
  INFO: task nvmesubsys:95 is blocked on a mutex likely owned by task nvmesubsys:95.

Every later controller setup or removal then waits for the lock too.
The nvme_validate_cntlid() error path for an existing subsystem does the
same put, and deadlocks the same way if the other references go away in
between.

Drop the lock before the put.  For a new subsystem, take it off the list
first so another controller can't find it in between.  With the fix,
the connect fails and the next connect works.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 30s.

Fixes: 32fd90c40768 ("nvme: change locking for the per-subsystem controller list")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/nvmesubsys.c

It uses nvme-loop and fault injection to fail the sysfs link.
---
 drivers/nvme/host/core.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index cd0df9b03806..f43582e5f6c4 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -3413,7 +3413,11 @@ static int nvme_init_subsystem(struct nvme_ctrl *ctrl, struct nvme_id_ctrl *id)
 	return 0;
 
 out_put_subsystem:
+	if (!found)
+		list_del_init(&subsys->entry);
+	mutex_unlock(&nvme_subsystems_lock);
 	nvme_put_subsystem(subsys);
+	return ret;
 out_unlock:
 	mutex_unlock(&nvme_subsystems_lock);
 	return ret;

---
base-commit: f92fe8dea19c743eb9e4d998ae0384344dd40091
change-id: 20261111-nvme-subsys-lock-deadlock-742ededdd59a

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

