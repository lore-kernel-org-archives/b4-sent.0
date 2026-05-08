From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 08 May 2026 18:39:07 +0200
Subject: [PATCH 04/10] New mount API: read-only option is for fsmount() and
 fsconfig()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-new-mount-fixes-and-tests-v1-4-c67a0893ddbc@bsbernd.com>
References: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
In-Reply-To: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6797; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=WHQ1HYYTEz5w61YjeNKLQ8ivEaU+L3tPNjujI2EOm3U=;
 b=kA0DAAgWMvNp7peNQvwByyZiAGn+EayiKz+XtFIJASQNJVcnWlYt0pOkJEjarG3JnGd1hJC8G
 Ih0BAAWCAAdFiEEihi8PZT+Dh0m9a/XMvNp7peNQvwFAmn+EawACgkQMvNp7peNQvyySgEAtMz+
 IyIOeP37za307kggO70fA3t5mLdjHK3dF93FAM4A+NLraxNkWGDEFS/Z6/eAM1i/HIiItdA1N7m
 rz6YxLwE=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Darrick J. Wong" <djwong@kernel.org>

The "ro" mount option needs to be handled by

fsmount(..., MOUNT_ATTR_RDONLY), for the superblock
and fsconfig(SET_FLAG, "ro") for the vfsmount.

Update by Bernd: Instead of moving it to MOUNT_ATTR_RDONLY,
handle it by both.

Fixes: 0d7e72541564 ("Unify mount flag structures and remove redundant is_mount_attr field")
Signed-off-by: Darrick J. Wong <djwong@kernel.org>
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 lib/mount_fsmount.c | 21 ++++++++++++++++-----
 lib/mount_util.c    | 44 +++++++++++++++++++++++++-------------------
 lib/mount_util.h    |  3 ++-
 3 files changed, 43 insertions(+), 25 deletions(-)

diff --git a/lib/mount_fsmount.c b/lib/mount_fsmount.c
index 5e13b34c..edb9e043 100644
--- a/lib/mount_fsmount.c
+++ b/lib/mount_fsmount.c
@@ -39,6 +39,7 @@
  * Convert MS_* mount flags to MOUNT_ATTR_* mount attributes.
  * These flags are passed to fsmount(), not fsconfig().
  * Mount attributes control mount-point level behavior.
+ * To called after set_ms_flags() which consumes the fsconfig flags.
  *
  * @attrs MOUNT_ATTR flags, built from MS_ flags
  * @return remaining flags
@@ -108,8 +109,12 @@ static void log_fsconfig_kmsg(int fd)
 
 /*
  * Apply VFS superblock (fsconfig) flags to the filesystem context.
- * Only handles flags that are filesystem parameters (ro, sync, dirsync).
- * Mount attributes (nosuid, nodev, etc.) are handled separately via fsmount().
+ * Handles the fsconfig leg of every entry whose is_fsconfig is set
+ * (ro, rw, sync, async, dirsync). Mount attributes (nosuid, nodev, etc.)
+ * are handled separately via fsmount().
+ *
+ * Entries that have *both* legs (ro/rw) leave the MS_ bit in *ms_flags
+ * so that ms_flags_to_mount_attrs() can also pick them up.
  *
  * @ms_flags flags to set, outvalue are the remaining flags
  * @return 0 on success, negative error code on failure
@@ -120,8 +125,7 @@ static int set_ms_flags(int fsfd, unsigned long *ms_flags)
 	int i;
 
 	for (i = 0; mount_flags[i].opt != NULL && flags != 0; i++) {
-		/* Only process fsconfig flags (mount_attr == 0) with on==1 */
-		if (mount_flags[i].mount_attr || !mount_flags[i].on)
+		if (!mount_flags[i].is_fsconfig || !mount_flags[i].on)
 			continue;
 
 		if (!(flags & mount_flags[i].flag))
@@ -137,7 +141,14 @@ static int set_ms_flags(int fsfd, unsigned long *ms_flags)
 
 			return -save_errno;
 		}
-		flags &= ~mount_flags[i].flag;
+
+		/*
+		 * Only consume the bit if no fsmount mount-attr leg is
+		 * also pending for this option. Otherwise leave it for
+		 * ms_flags_to_mount_attrs() to apply via fsmount().
+		 */
+		if (!mount_flags[i].mount_attr)
+			flags &= ~mount_flags[i].flag;
 	}
 
 	*ms_flags = flags;
diff --git a/lib/mount_util.c b/lib/mount_util.c
index 1a0aec9b..f1e58d98 100644
--- a/lib/mount_util.c
+++ b/lib/mount_util.c
@@ -108,26 +108,32 @@
 #define MOUNT_ATTR_NOSYMFOLLOW	0
 #endif
 
+/*
+ * is_fsconfig and mount_attr are independent: ro/rw need both legs
+ * (SB_RDONLY on the superblock via fsconfig SET_FLAG, plus
+ * MOUNT_ATTR_RDONLY on the vfsmount via fsmount). Everything else is
+ * exclusively one or the other.
+ */
 const struct mount_flags mount_flags[] = {
-/* opt            flag             on  safe  mount_attr */
-{"rw",           MS_RDONLY,        0,  1,    0},                      /* fsconfig */
-{"ro",           MS_RDONLY,        1,  1,    0},                      /* fsconfig */
-{"suid",         MS_NOSUID,        0,  0,    MOUNT_ATTR_NOSUID},     /* fsmount  */
-{"nosuid",       MS_NOSUID,        1,  1,    MOUNT_ATTR_NOSUID},     /* fsmount  */
-{"dev",          MS_NODEV,         0,  1,    MOUNT_ATTR_NODEV},      /* fsmount  */
-{"nodev",        MS_NODEV,         1,  1,    MOUNT_ATTR_NODEV},      /* fsmount  */
-{"exec",         MS_NOEXEC,        0,  1,    MOUNT_ATTR_NOEXEC},     /* fsmount  */
-{"noexec",       MS_NOEXEC,        1,  1,    MOUNT_ATTR_NOEXEC},     /* fsmount  */
-{"async",        MS_SYNCHRONOUS,   0,  1,    0},                      /* fsconfig */
-{"sync",         MS_SYNCHRONOUS,   1,  1,    0},                      /* fsconfig */
-{"noatime",      MS_NOATIME,       1,  1,    MOUNT_ATTR_NOATIME},    /* fsmount  */
-{"nodiratime",   MS_NODIRATIME,    1,  1,    MOUNT_ATTR_NODIRATIME}, /* fsmount  */
-{"norelatime",   MS_RELATIME,      0,  1,    MOUNT_ATTR_RELATIME},   /* fsmount  */
-{"nostrictatime", MS_STRICTATIME,  0,  1,    MOUNT_ATTR_STRICTATIME},/* fsmount  */
-{"symfollow",    MS_NOSYMFOLLOW,   0,  1,    MOUNT_ATTR_NOSYMFOLLOW},/* fsmount  */
-{"nosymfollow",  MS_NOSYMFOLLOW,   1,  1,    MOUNT_ATTR_NOSYMFOLLOW},/* fsmount  */
-{"dirsync",      MS_DIRSYNC,       1,  1,    0},                      /* fsconfig */
-{NULL,           0,                0,  0,    0}
+/* opt            flag             on  safe  fsconfig  mount_attr */
+{"rw",           MS_RDONLY,        0,  1,    1,        MOUNT_ATTR_RDONLY},
+{"ro",           MS_RDONLY,        1,  1,    1,        MOUNT_ATTR_RDONLY},
+{"suid",         MS_NOSUID,        0,  0,    0,        MOUNT_ATTR_NOSUID},
+{"nosuid",       MS_NOSUID,        1,  1,    0,        MOUNT_ATTR_NOSUID},
+{"dev",          MS_NODEV,         0,  1,    0,        MOUNT_ATTR_NODEV},
+{"nodev",        MS_NODEV,         1,  1,    0,        MOUNT_ATTR_NODEV},
+{"exec",         MS_NOEXEC,        0,  1,    0,        MOUNT_ATTR_NOEXEC},
+{"noexec",       MS_NOEXEC,        1,  1,    0,        MOUNT_ATTR_NOEXEC},
+{"async",        MS_SYNCHRONOUS,   0,  1,    1,        0},
+{"sync",         MS_SYNCHRONOUS,   1,  1,    1,        0},
+{"noatime",      MS_NOATIME,       1,  1,    0,        MOUNT_ATTR_NOATIME},
+{"nodiratime",   MS_NODIRATIME,    1,  1,    0,        MOUNT_ATTR_NODIRATIME},
+{"norelatime",   MS_RELATIME,      0,  1,    0,        MOUNT_ATTR_RELATIME},
+{"nostrictatime", MS_STRICTATIME,  0,  1,    0,        MOUNT_ATTR_STRICTATIME},
+{"symfollow",    MS_NOSYMFOLLOW,   0,  1,    0,        MOUNT_ATTR_NOSYMFOLLOW},
+{"nosymfollow",  MS_NOSYMFOLLOW,   1,  1,    0,        MOUNT_ATTR_NOSYMFOLLOW},
+{"dirsync",      MS_DIRSYNC,       1,  1,    1,        0},
+{NULL,           0,                0,  0,    0,        0}
 };
 
 #ifdef IGNORE_MTAB
diff --git a/lib/mount_util.h b/lib/mount_util.h
index 7ddd6b01..bf088996 100644
--- a/lib/mount_util.h
+++ b/lib/mount_util.h
@@ -18,7 +18,8 @@ struct mount_flags {
 	unsigned long flag;
 	int on;
 	int safe; /* used by fusermount */
-	unsigned long mount_attr; /* MOUNT_ATTR_* value for fsmount (0 = fsconfig flag) */
+	int is_fsconfig; /* apply via fsconfig SET_FLAG (superblock-level) */
+	unsigned long mount_attr; /* MOUNT_ATTR_* for fsmount (0 = none) */
 };
 extern const struct mount_flags mount_flags[];
 

-- 
2.53.0

