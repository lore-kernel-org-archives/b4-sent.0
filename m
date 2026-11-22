From: Kevin Nguyen <kevinnguyen4221@gmail.com>
Date: Sun, 22 Nov 2026 00:25:34 -0600
Subject: [PATCH] libvhost-user: fail SET_LOG_BASE if mmap() of the log
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-libvhost-user-log-mmap-v1-1-4ccf0773426d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAN2KAmsC/yXMMQ6DMAxA0asgz7VUR4WhV6k6JMEBV0BQDBES4
 u4NML7h/x2Uk7DCu9ohcRaVOBXQowLf26ljlLYYzNM0RIZwEJf7qAuupcQhdjiOdsYmmFeogyd
 rHZR4Thxku8af721d3Y/9ct7gOP7w1XKUegAAAA==
X-Change-ID: 20261121-libvhost-user-log-mmap-6f24f5fc1aab
To: qemu-devel@nongnu.org
Cc: "Michael S. Tsirkin" <mst@redhat.com>, 
 Stefano Garzarella <sgarzare@redhat.com>, vhost-user@lists.linux.dev, 
 Kevin Nguyen <kevinnguyen4221@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795328743; l=2047;
 i=kevinnguyen4221@gmail.com; s=20261122; h=from:subject:message-id;
 bh=SxRVO/izDzYDID+FOGrsw/Qa/MKm2CvHM3VK68d+uuk=;
 b=1MSdQhGdWhkVii1UESGNaxMkTQKDGXTU6JioYZdIwlEli5ipOq4nTrKGrn/0cEXTYVe1fK8YQ
 CpUyAkqQ2eJDfuqFWHVzIYEGFOF1k50CTCUuvSUydt7PKmmBYk4kFcs
X-Developer-Key: i=kevinnguyen4221@gmail.com; a=ed25519;
 pk=cBY2wqCM3aigaylJj7NwKyb/YiW+LT6+Ane7Mxc7p0s=
X-Endpoint-Received: by B4 Relay for kevinnguyen4221@gmail.com/20261122 with auth_id=1599
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If mmap() of the dirty log fd fails, vu_set_log_base_exec() only
prints an error, then unmaps the previous log, stores MAP_FAILED in
dev->log_table and replies as if the request succeeded. The next
request completed with VHOST_F_LOG_ALL set writes through
(uint8_t *)-1 and the backend crashes with SIGSEGV.

Leave the existing log untouched and call vu_panic() instead, without
sending a reply. Setting log_table to NULL would avoid the crash but
silently stop dirty logging, so a migration could complete with
missing pages. The SET_LOG_BASE reply has no status field, so dropping
the connection is the only way to tell the frontend that logging
failed.

Also save errno before close(fd), which may clobber it.

Resolves: https://gitlab.com/qemu-project/qemu/-/issues/4793
Signed-off-by: Kevin Nguyen <kevinnguyen4221@gmail.com>
---
 subprojects/libvhost-user/libvhost-user.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/subprojects/libvhost-user/libvhost-user.c b/subprojects/libvhost-user/libvhost-user.c
index df21581033..f47612f9e7 100644
--- a/subprojects/libvhost-user/libvhost-user.c
+++ b/subprojects/libvhost-user/libvhost-user.c
@@ -1159,6 +1159,7 @@ vu_set_log_base_exec(VuDev *dev, VhostUserMsg *vmsg)
     int fd;
     uint64_t log_mmap_size, log_mmap_offset;
     void *rc;
+    int err;
 
     if (vmsg->fd_num != 1 ||
         vmsg->size != sizeof(vmsg->payload.log)) {
@@ -1174,9 +1175,11 @@ vu_set_log_base_exec(VuDev *dev, VhostUserMsg *vmsg)
 
     rc = mmap(0, log_mmap_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd,
               log_mmap_offset);
+    err = errno;
     close(fd);
     if (rc == MAP_FAILED) {
-        perror("log mmap error");
+        vu_panic(dev, "log mmap error: %s", strerror(err));
+        return false;
     }
 
     if (dev->log_table) {

---
base-commit: 8f66cb79044c370e3813c56ceb7a75a5ca2d0a0e
change-id: 20261121-libvhost-user-log-mmap-6f24f5fc1aab

Best regards,
--  
Kevin Nguyen <kevinnguyen4221@gmail.com>

