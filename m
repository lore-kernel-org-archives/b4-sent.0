From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 21 Aug 2026 14:28:32 +0200
Subject: [PATCH] fuse: Fix the condition to enable over-io-uring
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-fuse-fix-enable-condition-v1-1-488f77b27e96@bsbernd.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QqDMAwAf0XyvICW6cp+ZeyhpqmLSB2NykD8d
 7Pt8eDudlAuwgr3aofCm6jM2aC5VECvkAdGicbgatfV3jWYVmVM8kHOoZ8Yac5RFqswJn8L4Uq
 uJQ/Wvwub93s/nn/WtR+Zlu8QjuMEY8xDGH0AAAA=
X-Change-ID: 20260821-fuse-fix-enable-condition-df87aa4c25c8
To: Miklos Szeredi <miklos@szeredi.hu>, Bernd Schubert <bernd@bsbernd.com>
Cc: Joanne Koong <joannelkoong@gmail.com>, fuse-devel@lists.linux.dev, 
 Baokun Li <libaokun@linux.alibaba.com>, 
 Thomas <thomas.fractalbits@gmail.com>, zhu <zzsheng@gmail.com>, 
 Stefan Hajnoczi <stefanha@gmail.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=3881; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=x0saBZr76A+AJaVweFwY6LEpGdlTSPbLMHA+ayIkzFU=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLI6XIqzbqyVN3LL9K2+JbCmeUYt+6LVbZfLXpvnyLhwL
 dgd+2JHRykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAEyk1JGRYcudz3z7OJ+ITPVQ
 4Pin5+gee8tL7uQPzp1PBeOXZNSx/WD4Z/ayX6yDcVPQscdnNSu2cR15sdDTycfRNCQtIzp9uvE
 UdgA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I had accidentally used "&&" instead of "||" and totally broken
the intention of the condition. This has several implications

1) fuse-servers can bypass the module option "enable_uring"
   by setting FUSE_OVER_IO_URING in the FUSE_INIT reply, although
   fuse-client/kernel wouldn't have announced availability of
   that flag. I.e.

2) fuse-servers do not need to set FUSE_OVER_IO_URING in FUSE_INIT
   reply and could just send FUSE_IO_URING_CMD_REGISTER at
   any time while IO is already going on. That has further
   implications:

    2.1) The barrier in fuse_block_alloc() waiting for fuse_uring_ready()
         is then bypassed - fuse requests are not blocked until queues
         are initialized - results in dynamic switching from /dev/fuse
         to io-uring.

    2.2) The dynamic switching from /dev/fuse to io-uring exposes
         at least one easily exposable lock order issue between
         fch->bg_lock and queue->lock. There might more issues, as
         dynamic run time switching was never tested.

The change itself is simple, but brings behavior change,
FUSE_OVER_IO_URING has to be set in the FUSE_INIT_REPLY by fuse servers
to accept any IORING_OP_URING_CMD. Libfuse does that and the only
non-libfuse implementation I found (fractal-fuse) also does that.
Qemu patches for fuse-io-uring are not merged yet, as far as I know.

Also moved up is the check for fch->initialized as a fuse-server
implementation might try to setup io-uring before FUSE_INIT is
processed and might have gotten -EOPNOTSUPP instead of -EAGAIN.

Also fixed is a stale comment that explain the handling of the
FUSE_OVER_IO_URING flag in early RFC versions.

If there should be a report from any library or application we
probably need to revert this commit, although slightly modified then
to prevent bypassing of the module option.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 16 ++++++++--------
 fs/fuse/inode.c     |  4 ----
 2 files changed, 8 insertions(+), 12 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 77c8cec43d9c..eba322f79df1 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -1237,8 +1237,15 @@ int fuse_uring_cmd(struct io_uring_cmd *cmd, unsigned int issue_flags)
 	}
 	fch = fud->chan;
 
+	/*
+	 * fuse_uring_register() needs the ring to be initialized,
+	 * we need to know the max payload size
+	 */
+	if (!fch->initialized)
+		return -EAGAIN;
+
 	/* Once a connection has io-uring enabled on it, it can't be disabled */
-	if (!enable_uring && !fch->io_uring) {
+	if (!enable_uring || !fch->io_uring) {
 		pr_info_ratelimited("fuse-io-uring is disabled\n");
 		return -EOPNOTSUPP;
 	}
@@ -1248,13 +1255,6 @@ int fuse_uring_cmd(struct io_uring_cmd *cmd, unsigned int issue_flags)
 	if (!fch->connected)
 		return -ENOTCONN;
 
-	/*
-	 * fuse_uring_register() needs the ring to be initialized,
-	 * we need to know the max payload size
-	 */
-	if (!fch->initialized)
-		return -EAGAIN;
-
 	switch (cmd_op) {
 	case FUSE_IO_URING_CMD_REGISTER:
 		err = fuse_uring_register(cmd, issue_flags, fch);
diff --git a/fs/fuse/inode.c b/fs/fuse/inode.c
index d975073c6029..f29bd7432fa3 100644
--- a/fs/fuse/inode.c
+++ b/fs/fuse/inode.c
@@ -1474,10 +1474,6 @@ static struct fuse_init_args *fuse_new_init(struct fuse_mount *fm)
 	if (IS_ENABLED(CONFIG_FUSE_PASSTHROUGH))
 		flags |= FUSE_PASSTHROUGH;
 
-	/*
-	 * This is just an information flag for fuse server. No need to check
-	 * the reply - server is either sending IORING_OP_URING_CMD or not.
-	 */
 	if (fuse_uring_enabled())
 		flags |= FUSE_OVER_IO_URING;
 

---
base-commit: 818bebeb63dd6bf5f4e07e145f6cdbace520a34c
change-id: 20260821-fuse-fix-enable-condition-df87aa4c25c8

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

