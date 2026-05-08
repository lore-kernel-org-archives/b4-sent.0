From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 08 May 2026 18:39:12 +0200
Subject: [PATCH 09/10] fuse mount: Do not set sync_init when sync_init was
 not used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-new-mount-fixes-and-tests-v1-9-c67a0893ddbc@bsbernd.com>
References: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
In-Reply-To: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3303; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=IfLpX0dAI88nGkd6gSPX+QfxV9W/urV5ERySs1L3O4A=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGDL/Ca47aO3vnnUwMczT3XB614QZDMGFJzN2SfyQStj+Y
 rfMj1TujlIWBjEOBlkxRZYuiT22U/7xyap9XX8dZg4rE8gQBi5OAZhI7AxGhr2T5h+MYedXf13Q
 fys8ZMfkszP8Nu6Y6NhhPGmaYK5v6UuGf3pt66fIvp68RFpS778xr/6S+PIg6a1yjZvTBR9mdXw
 35AIA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

synchronous init is just a hint and we cannot fail on it, but for
daemonization we need to do know when it was actually used.
Bug was that se->sync_init() was set unconditionally on mount success.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 lib/fuse_lowlevel.c | 22 +++++++++++++++-------
 1 file changed, 15 insertions(+), 7 deletions(-)

diff --git a/lib/fuse_lowlevel.c b/lib/fuse_lowlevel.c
index 6e078e82..60b936c3 100644
--- a/lib/fuse_lowlevel.c
+++ b/lib/fuse_lowlevel.c
@@ -4471,10 +4471,13 @@ static void *session_sync_init_worker(void *data)
 }
 
 /* Enable synchronous FUSE_INIT and start worker thread */
-static int session_start_sync_init(struct fuse_session *se, int fd)
+static int session_start_sync_init(struct fuse_session *se, int fd,
+				   bool *is_sync_init)
 {
 	int err, res;
 
+	*is_sync_init = false;
+
 	/*
 	 * Older fuse servers do not set want_sync_init or start the new
 	 * daemonize code, so they get async init.
@@ -4536,6 +4539,8 @@ static int session_start_sync_init(struct fuse_session *se, int fd)
 		return -EIO;
 	}
 
+	*is_sync_init = true;
+
 	return 0;
 }
 
@@ -4594,7 +4599,8 @@ static int session_wait_sync_init_completion(struct fuse_session *se)
 static int new_api_fusermount(struct fuse_session *se,
 			      const char *mountpoint,
 			      const char *mnt_opts,
-			      int *sock_fd, pid_t *fusermount_pid)
+			      int *sock_fd, pid_t *fusermount_pid,
+			      bool *is_sync_init)
 {
 	int fd, err;
 
@@ -4617,7 +4623,7 @@ static int new_api_fusermount(struct fuse_session *se,
 
 	/* Start worker thread with correct fd from fusermount3 */
 	se->fd = fd;
-	err = session_start_sync_init(se, fd);
+	err = session_start_sync_init(se, fd, is_sync_init);
 	if (err) {
 		fuse_log(FUSE_LOG_ERR,
 			 "fuse: failed to start sync init worker\n");
@@ -4649,6 +4655,7 @@ static int fuse_session_mount_new_api(struct fuse_session *se,
 	char *mnt_opts = NULL;
 	char *mnt_opts_with_fd = NULL;
 	char fd_opt[32];
+	bool is_sync_init = false;
 
 	res = fuse_kern_mount_get_base_mnt_opts(se->mo, &mnt_opts);
 	err = -EIO;
@@ -4665,7 +4672,7 @@ static int fuse_session_mount_new_api(struct fuse_session *se,
 	}
 
 	se->fd = fd;
-	err = session_start_sync_init(se, fd);
+	err = session_start_sync_init(se, fd, &is_sync_init);
 	if (err)
 		goto err;
 
@@ -4684,7 +4691,8 @@ static int fuse_session_mount_new_api(struct fuse_session *se,
 		close(fd);
 		se->fd = -1;
 		fd = new_api_fusermount(se, mountpoint, mnt_opts,
-					&sock_fd, &fusermount_pid);
+					&sock_fd, &fusermount_pid,
+					&is_sync_init);
 		if (fd < 0) {
 			err = fd;
 			goto err_with_sock;
@@ -4711,11 +4719,12 @@ err:
 		se->fd = -1;
 		se->error = err;
 	}
+	se->is_sync_init = is_sync_init;
+
 	/* Wait for synchronous FUSE_INIT to complete */
 	if (session_wait_sync_init_completion(se) < 0)
 		fuse_log(FUSE_LOG_ERR, "fuse: sync init completion failed\n");
 
-	se->is_sync_init = true;
 	free(mnt_opts);
 	free(mnt_opts_with_fd);
 	return fd;
@@ -4791,7 +4800,6 @@ int fuse_session_mount(struct fuse_session *se, const char *_mountpoint)
 out:
 	se->fd = fd;
 	se->mountpoint = mountpoint;
-
 	fuse_daemonize_early_set_mounted();
 
 	return 0;

-- 
2.53.0

