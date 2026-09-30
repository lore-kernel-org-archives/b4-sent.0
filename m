From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:10:58 +0200
Subject: [PATCH v3 04/15] mount_service: use openat to OPEN paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-bound-open-v3-4-e26c5e4eca4c@bsbernd.com>
References: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
In-Reply-To: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2643; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=t2IzH5vYnlchJ/E2OwTN4Ut5dkTmRzg3t2i6gFROXFs=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2cmXf7lz1bofhq/1JGa4zNEoZDC8YTYgU0/kyzX7H8
 0meB/3DOkpZGMQ4GGTFFFm6JPbYTvnHJ6v2df11mDmsTCBDGLg4BWAiZ1YzMmw6fM77d/W+M/u1
 Ha4WygkIXwvSvlfj+ayPf16X0joPyS0M/11qGHlXKfFMz/71UGTyPFWbjAQFy9Wbw/7oh2evban
 1YwUA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fuse server sends fuservicemount3 a series of requests: OPEN for
its backing file, MNTPT to name the mount point, then MOUNT. The server
chooses the order. For a directory mount point, attach_to_mountpoint()
changes the working directory of the helper to the mount point. The
helper then mounts on ".", so a rename of the path cannot redirect the
mount.

A relative path in an OPEN request after MNTPT resolved inside the
mount point. For "fuservicemount3 disk.img /mnt -t fuse.service_ll",
an OPEN of "disk.img" matched the command line argument, but the helper
opened /mnt/disk.img, not disk.img in the user's working directory. The
helper now opens OPEN paths with openat() on the working directory it
started in.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
Reviewed-by: "Darrick J. Wong" <djwong@kernel.org>
---
 util/mount_service.c | 20 +++++++++++++++++++-
 1 file changed, 19 insertions(+), 1 deletion(-)

diff --git a/util/mount_service.c b/util/mount_service.c
index b4081d53273e..84e9d831ce03 100644
--- a/util/mount_service.c
+++ b/util/mount_service.c
@@ -84,6 +84,9 @@ struct mount_service {
 	/* fd for fsopen */
 	int fsopenfd;
 
+	/* fd for the initial working directory */
+	int cwdfd;
+
 	/* did we actually mount successfully? */
 	bool mounted;
 
@@ -247,6 +250,18 @@ static int mount_service_init(struct mount_service *mo, int argc, char *argv[])
 		return -1;
 	}
 
+	drop_privs();
+	mo->cwdfd = open(".", O_PATH | O_CLOEXEC);
+	if (mo->cwdfd < 0) {
+		int error = errno;
+
+		restore_privs();
+		fprintf(stderr, "%s: cannot open working directory: %s\n",
+			mo->msgtag, strerror(error));
+		return -1;
+	}
+	restore_privs();
+
 	return 0;
 }
 
@@ -859,8 +874,9 @@ static int mount_service_open_path(const struct mount_service *mo,
 	}
 
 	open_flags = ntohl(oc->open_flags) | O_CLOEXEC;
+	/* After fchdir to the mountpoint, a relative path would resolve there */
 	drop_privs();
-	fd = open(oc->path, open_flags, ntohl(oc->create_mode));
+	fd = openat(mo->cwdfd, oc->path, open_flags, ntohl(oc->create_mode));
 	if (fd < 0) {
 		int error = errno;
 
@@ -1807,6 +1823,7 @@ static void mount_service_destroy(struct mount_service *mo)
 	close(mo->fusedevfd);
 	close(mo->argvfd);
 	close(mo->fsopenfd);
+	close(mo->cwdfd);
 	shutdown(mo->sockfd, SHUT_RDWR);
 	close(mo->sockfd);
 
@@ -1824,6 +1841,7 @@ static void mount_service_destroy(struct mount_service *mo)
 	mo->fusedevfd = -1;
 	mo->mountfd = -1;
 	mo->fsopenfd = -1;
+	mo->cwdfd = -1;
 }
 
 int mount_service_main(int argc, char *argv[])

-- 
2.53.0

