From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:44:35 +0200
Subject: [PATCH 3/4] mount_util: share the mtab flag-option builder
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-use-mount-fsmount-v1-3-d585598896ee@bsbernd.com>
References: <20260930-mount-service-use-mount-fsmount-v1-0-d585598896ee@bsbernd.com>
In-Reply-To: <20260930-mount-service-use-mount-fsmount-v1-0-d585598896ee@bsbernd.com>
To: "Darrick J. Wong" <djwong@kernel.org>
Cc: neal@gompa.dev, fuse-devel@lists.linux.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=7867; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=8TzYlSGEYUJKA/CCBOdfydnc+sGJK5un+feFswTHomk=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2CvlytXw9yHl9oem3J1n+h34KcUQ+n2uncqegxn9Pm
 708l3t9RykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAEzEYCUjw9Lgx+zbnx93cElc
 58jtdcZNXkHobJid8x+LJer8W3Qd9RkZzk+y9bmTL5wy+8rxT7z8d+zWdGVVO27+WvZFRlB1YqI
 kMwA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The loop over mount_flags[] that builds the rw/nosuid/nodev mirrors of
an mtab record existed twice, in lib/mount.c and util/fusermount.c;
both feed the same record, so a change to one silently diverges.
fusermount3 does not link libfuse and cannot call fuse_opt_add_opt(),
so fuse_mnt_add_opt() moves to lib/mount_util.c next to mount_flags[].

fuse_mnt_add_opt() now has one realloc and one snprintf, because
realloc(NULL) is the malloc. The empty-list path reserves expand as
well, which strdup could not do. No caller pairs an empty list with a
non-zero expand, so nothing changes today.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 lib/mount.c         | 21 +--------------------
 lib/mount_fsmount.c | 12 ++----------
 lib/mount_util.c    | 33 +++++++++++++++++++++++++++++++++
 lib/mount_util.h    | 20 ++++++++++++++++++++
 util/fusermount.c   | 33 +++------------------------------
 5 files changed, 59 insertions(+), 60 deletions(-)

diff --git a/lib/mount.c b/lib/mount.c
index a6dd5013ea80..4d03ef4b848f 100644
--- a/lib/mount.c
+++ b/lib/mount.c
@@ -995,25 +995,6 @@ static int fuse_mount_sys(const char *mnt, struct mount_opts *mo,
 	return fd;
 }
 
-/*
- * Append the flag-mirror prefix (rw/nosuid/nodev/...) of the mtab record
- * to @mtab_optsp, derived from the MS_* bitmask in @flags.
- */
-static int get_mtab_flag_opts(char **mtab_optsp, int flags)
-{
-	int i;
-
-	if (!(flags & MS_RDONLY) && fuse_opt_add_opt(mtab_optsp, "rw") == -1)
-		return -1;
-
-	for (i = 0; mount_flags[i].opt != NULL; i++) {
-		if (mount_flags[i].on && (flags & mount_flags[i].flag) &&
-		    fuse_opt_add_opt(mtab_optsp, mount_flags[i].opt) == -1)
-			return -1;
-	}
-	return 0;
-}
-
 struct mount_opts *parse_mount_opts(struct fuse_args *args)
 {
 	struct mount_opts *mo;
@@ -1057,7 +1038,7 @@ void destroy_mount_opts(struct mount_opts *mo)
 int fuse_kern_mount_get_base_mtab_opts(const struct mount_opts *mo,
 				       char **mtab_optsp)
 {
-	if (get_mtab_flag_opts(mtab_optsp, mo->flags) == -1)
+	if (fuse_mnt_get_mtab_flag_opts(mtab_optsp, mo->flags) == -1)
 		return -1;
 	if (mo->kernel_opts && fuse_opt_add_opt(mtab_optsp, mo->kernel_opts) == -1)
 		return -1;
diff --git a/lib/mount_fsmount.c b/lib/mount_fsmount.c
index 0b1fd4300d2d..730071206fc7 100644
--- a/lib/mount_fsmount.c
+++ b/lib/mount_fsmount.c
@@ -446,16 +446,8 @@ int apply_fsconfig_mount_opts(int fsfd, const char *opts)
 			continue;
 		/*
 		 * Skip mount attributes, they're handled by fsmount()
-		 * not fsconfig().
-		 *
-		 * These string options (nosuid, nodev, etc.) are reconstructed
-		 * from MS_* flags by get_mtab_flag_opts() in lib/mount.c and
-		 * get_mtab_opts() in util/fusermount.c. Both the library path
-		 * (via fuse_kern_mount_get_base_mtab_opts) and fusermount3 path
-		 * rebuild these strings from the flags bitmask and pass them in
-		 * mtab_opts. They must be filtered here because they are mount
-		 * attributes (passed to fsmount via MOUNT_ATTR_*), not
-		 * filesystem parameters (which would be passed to fsconfig).
+		 * not fsconfig(). Callers rebuild them as strings from the
+		 * MS_* bitmask for the mtab record, so they do show up here.
 		 *
 		 * Also skip mtab-only options - they're for /run/mount/utab, not kernel
 		 */
diff --git a/lib/mount_util.c b/lib/mount_util.c
index 2f763fe1218e..72ed17c93f47 100644
--- a/lib/mount_util.c
+++ b/lib/mount_util.c
@@ -140,6 +140,39 @@ const struct mount_flags mount_flags[] = {
 {NULL,           0,                0,  0,    0,        0}
 };
 
+int fuse_mnt_add_opt(char **optsp, const char *opt, unsigned int expand)
+{
+	/* an empty list gets no separator, and realloc(NULL) is the malloc */
+	const char *sep = *optsp ? "," : "";
+	size_t oldsize = *optsp ? strlen(*optsp) : 0;
+	size_t newsize = oldsize + strlen(sep) + strlen(opt) + expand + 1;
+	char *newopts = (char *) realloc(*optsp, newsize);
+
+	if (newopts == NULL) {
+		fuse_log(FUSE_LOG_ERR, "fuse: failed to allocate memory\n");
+		return -1;
+	}
+
+	snprintf(newopts + oldsize, newsize - oldsize, "%s%s", sep, opt);
+	*optsp = newopts;
+	return 0;
+}
+
+int fuse_mnt_get_mtab_flag_opts(char **mtab_optsp, int flags)
+{
+	int i;
+
+	if (!(flags & MS_RDONLY) && fuse_mnt_add_opt(mtab_optsp, "rw", 0) == -1)
+		return -1;
+
+	for (i = 0; mount_flags[i].opt != NULL; i++) {
+		if (mount_flags[i].on && (flags & mount_flags[i].flag) &&
+		    fuse_mnt_add_opt(mtab_optsp, mount_flags[i].opt, 0) == -1)
+			return -1;
+	}
+	return 0;
+}
+
 #ifdef IGNORE_MTAB
 #define mtab_needs_update(mnt) 0
 #else
diff --git a/lib/mount_util.h b/lib/mount_util.h
index b20a428d99c7..4485d8a29f93 100644
--- a/lib/mount_util.h
+++ b/lib/mount_util.h
@@ -24,6 +24,26 @@ struct mount_flags {
 };
 extern const struct mount_flags mount_flags[];
 
+/**
+ * @brief Append @opt to the comma-separated option list @optsp.
+ *
+ * @param[in,out] optsp   list to extend, NULL for an empty list.
+ * @param[in]     opt     option to append.
+ * @param[in]     expand  extra bytes to reserve for a value the caller
+ *                        appends itself.
+ * @return 0 on success, -1 on failure.
+ */
+int fuse_mnt_add_opt(char **optsp, const char *opt, unsigned int expand);
+
+/**
+ * @brief Append the flag-mirror part of an mtab record (rw/nosuid/nodev/...).
+ *
+ * @param[in,out] mtab_optsp  option list to extend.
+ * @param[in]     flags       MS_* bitmask the mirrors are derived from.
+ * @return 0 on success, -1 on failure.
+ */
+int fuse_mnt_get_mtab_flag_opts(char **mtab_optsp, int flags);
+
 int fuse_mnt_add_mount(const char *progname, const char *fsname,
 		       const char *mnt, const char *type, const char *opts);
 int fuse_mnt_remove_mount(const char *progname, const char *mnt);
diff --git a/util/fusermount.c b/util/fusermount.c
index 3031b282a7a6..c7de86f4b12e 100644
--- a/util/fusermount.c
+++ b/util/fusermount.c
@@ -556,26 +556,6 @@ static int find_mount_flag(const char *s, unsigned len, int *on, int *flag)
 	return 0;
 }
 
-static int add_option(char **optsp, const char *opt, unsigned expand)
-{
-	char *newopts;
-	if (*optsp == NULL)
-		newopts = strdup(opt);
-	else {
-		unsigned oldsize = strlen(*optsp);
-		unsigned newsize = oldsize + 1 + strlen(opt) + expand + 1;
-		newopts = (char *) realloc(*optsp, newsize);
-		if (newopts)
-			sprintf(newopts + oldsize, ",%s", opt);
-	}
-	if (newopts == NULL) {
-		fprintf(stderr, "%s: failed to allocate memory\n", progname);
-		return -1;
-	}
-	*optsp = newopts;
-	return 0;
-}
-
 /*
  * Build the mtab/utab record string for this mount: flag-mirrors of MS_*
  * (rw/nosuid/nodev/...) + the kernel-bound -o options + "user=<n>" when
@@ -585,19 +565,12 @@ static int add_option(char **optsp, const char *opt, unsigned expand)
  */
 static int get_mtab_opts(int flags, const char *opts, char **mtab_optsp)
 {
-	int i;
 	int l;
 
-	if (!(flags & MS_RDONLY) && add_option(mtab_optsp, "rw", 0) == -1)
+	if (fuse_mnt_get_mtab_flag_opts(mtab_optsp, flags) == -1)
 		return -1;
 
-	for (i = 0; mount_flags[i].opt != NULL; i++) {
-		if (mount_flags[i].on && (flags & mount_flags[i].flag) &&
-		    add_option(mtab_optsp, mount_flags[i].opt, 0) == -1)
-			return -1;
-	}
-
-	if (add_option(mtab_optsp, opts, 0) == -1)
+	if (fuse_mnt_add_opt(mtab_optsp, opts, 0) == -1)
 		return -1;
 	/* remove comma from end of opts*/
 	l = strlen(*mtab_optsp);
@@ -608,7 +581,7 @@ static int get_mtab_opts(int flags, const char *opts, char **mtab_optsp)
 		if (user == NULL)
 			return -1;
 
-		if (add_option(mtab_optsp, "user=", strlen(user)) == -1)
+		if (fuse_mnt_add_opt(mtab_optsp, "user=", strlen(user)) == -1)
 			return -1;
 		strcat(*mtab_optsp, user);
 	}

-- 
2.53.0

