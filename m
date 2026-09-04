From: Daan De Meyer <daan@amutable.com>
Date: Fri, 04 Sep 2026 16:48:56 +0200
Subject: [PATCH v3 2/2] selftests/bpf: verify mount idmaps reach inode
 hooks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260904-lsm-mount-idmaps-v3-2-920a1963675d@amutable.com>
References: <20260904-lsm-mount-idmaps-v3-0-920a1963675d@amutable.com>
In-Reply-To: <20260904-lsm-mount-idmaps-v3-0-920a1963675d@amutable.com>
To: Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Paul Moore <paul@paul-moore.com>
Cc: linux-fsdevel@vger.kernel.org, linux-security-module@vger.kernel.org, 
 Daan De Meyer <daan@amutable.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788533337; l=10145;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=u4GiTIZYgqLv3c6YBoMnUhElfysaNCSwRqVywNmRGhg=;
 b=/rXwiJDElK0pAd3c4CbjKmjtmdiKSAtDZvJ2h5v/XS5TDBTamMx877qWeYtJMrS6ASfMSfbhg
 FTMFThflq81DBTyyWxUMxftca9Oq45iGkdSypS9NvMsPZUKQHA5a4JH
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the BPF LSM selftest to exercise create, link, symlink, mkdir,
mknod, and permission through both the VFS identity idmap and a real
idmapped tmpfs mount.

Record the idmap observed by each hook and verify that every updated hook
receives the mapping used by the VFS operation. This provides regression
coverage for passing mount idmaps through inode security hooks.

Signed-off-by: Daan De Meyer <daan@amutable.com>
---
 tools/testing/selftests/bpf/prog_tests/test_lsm.c | 231 ++++++++++++++++++++++
 tools/testing/selftests/bpf/progs/lsm.c           |  79 ++++++++
 2 files changed, 310 insertions(+)

diff --git a/tools/testing/selftests/bpf/prog_tests/test_lsm.c b/tools/testing/selftests/bpf/prog_tests/test_lsm.c
index d7495efd4a56..c0ae813698ae 100644
--- a/tools/testing/selftests/bpf/prog_tests/test_lsm.c
+++ b/tools/testing/selftests/bpf/prog_tests/test_lsm.c
@@ -1,18 +1,30 @@
 // SPDX-License-Identifier: GPL-2.0
+#define _GNU_SOURCE
 
 /*
  * Copyright (C) 2020 Google LLC.
  */
 
 #include <test_progs.h>
+#include <sched.h>
+#include <signal.h>
+#include <string.h>
+#include <sys/stat.h>
+#include <sys/syscall.h>
 #include <sys/wait.h>
 #include <unistd.h>
 
+#include <linux/mount.h>
+
 #include "lsm.skel.h"
 #include "lsm_tailcall.skel.h"
 
 char *CMD_ARGS[] = {"true", NULL};
 
+enum {
+	INODE_IDMAP_ALL = (1U << 6) - 1,
+};
+
 int exec_cmd(int *monitored_pid)
 {
 	int child_pid, child_status;
@@ -30,6 +42,219 @@ int exec_cmd(int *monitored_pid)
 	return -EINVAL;
 }
 
+static ssize_t write_nointr(int fd, const void *buf, size_t count)
+{
+	ssize_t ret;
+
+	do {
+		ret = write(fd, buf, count);
+	} while (ret < 0 && errno == EINTR);
+
+	return ret;
+}
+
+static int write_file(const char *path, const char *value)
+{
+	size_t len = strlen(value);
+	int fd, saved_errno = 0;
+	ssize_t ret;
+
+	fd = open(path, O_WRONLY | O_CLOEXEC | O_NOCTTY | O_NOFOLLOW);
+	if (fd < 0)
+		return -1;
+
+	ret = write_nointr(fd, value, len);
+	if (ret < 0)
+		saved_errno = errno;
+	else if ((size_t)ret != len)
+		saved_errno = EIO;
+	close(fd);
+	if (saved_errno) {
+		errno = saved_errno;
+		return -1;
+	}
+	return 0;
+}
+
+static int write_userns_file(pid_t pid, const char *name, const char *value)
+{
+	char path[64];
+	int len;
+
+	len = snprintf(path, sizeof(path), "/proc/%d/%s", pid, name);
+	if (len < 0 || (size_t)len >= sizeof(path)) {
+		errno = EOVERFLOW;
+		return -1;
+	}
+
+	return write_file(path, value);
+}
+
+static int create_userns_fd(void)
+{
+	char path[64];
+	pid_t pid, waited;
+	int fd = -1, len, saved_errno, status;
+
+	pid = fork();
+	if (pid < 0)
+		return -1;
+	if (pid == 0) {
+		if (unshare(CLONE_NEWUSER))
+			_exit(1);
+		raise(SIGSTOP);
+		_exit(0);
+	}
+
+	do {
+		waited = waitpid(pid, &status, WUNTRACED);
+	} while (waited < 0 && errno == EINTR);
+	if (waited != pid)
+		goto out;
+	if (!WIFSTOPPED(status)) {
+		pid = -1;
+		goto out;
+	}
+
+	/* A one-entry map is identity for root but remains distinct from nop_mnt_idmap. */
+	if (write_userns_file(pid, "setgroups", "deny") && errno != ENOENT)
+		goto out;
+	if (write_userns_file(pid, "uid_map", "0 0 1") ||
+	    write_userns_file(pid, "gid_map", "0 0 1"))
+		goto out;
+
+	len = snprintf(path, sizeof(path), "/proc/%d/ns/user", pid);
+	if (len < 0 || (size_t)len >= sizeof(path)) {
+		errno = EOVERFLOW;
+		goto out;
+	}
+	fd = open(path, O_RDONLY | O_CLOEXEC);
+
+out:
+	saved_errno = errno;
+	if (pid > 0) {
+		kill(pid, SIGKILL);
+		do {
+			waited = waitpid(pid, NULL, 0);
+		} while (waited < 0 && errno == EINTR);
+	}
+	errno = saved_errno;
+	return fd;
+}
+
+static int create_idmapped_tmpfs(void)
+{
+	struct mount_attr attr = {
+		.attr_set = MOUNT_ATTR_IDMAP,
+	};
+	int fsfd = -1, mntfd = -1, saved_errno, userns_fd = -1;
+
+	userns_fd = create_userns_fd();
+	if (userns_fd < 0)
+		goto out;
+
+	/* A detached tmpfs avoids relying on the host test directory supporting idmaps. */
+	fsfd = syscall(__NR_fsopen, "tmpfs", FSOPEN_CLOEXEC);
+	if (fsfd < 0)
+		goto out;
+	if (syscall(__NR_fsconfig, fsfd, FSCONFIG_CMD_CREATE, NULL, NULL, 0))
+		goto out;
+
+	mntfd = syscall(__NR_fsmount, fsfd, FSMOUNT_CLOEXEC, 0);
+	if (mntfd < 0)
+		goto out;
+
+	attr.userns_fd = userns_fd;
+	if (syscall(__NR_mount_setattr, mntfd, "", AT_EMPTY_PATH, &attr,
+		    sizeof(attr))) {
+		close(mntfd);
+		mntfd = -1;
+	}
+
+out:
+	saved_errno = errno;
+	if (fsfd >= 0)
+		close(fsfd);
+	if (userns_fd >= 0)
+		close(userns_fd);
+	errno = saved_errno;
+	return mntfd;
+}
+
+static int exercise_inode_idmap_hooks(int dirfd)
+{
+	int fd = -1, ret = -1;
+
+	fd = openat(dirfd, "file", O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC,
+		    0600);
+	if (!ASSERT_GE(fd, 0, "create"))
+		goto out;
+	close(fd);
+	fd = -1;
+
+	if (!ASSERT_OK(mkdirat(dirfd, "dir", 0700), "mkdir"))
+		goto out;
+	if (!ASSERT_OK(symlinkat("target", dirfd, "symlink"), "symlink"))
+		goto out;
+	if (!ASSERT_OK(linkat(dirfd, "file", dirfd, "link", 0), "link"))
+		goto out;
+	if (!ASSERT_OK(mkfifoat(dirfd, "fifo", 0600), "mknod"))
+		goto out;
+
+	ret = 0;
+out:
+	if (fd >= 0)
+		close(fd);
+	unlinkat(dirfd, "link", 0);
+	unlinkat(dirfd, "fifo", 0);
+	unlinkat(dirfd, "symlink", 0);
+	unlinkat(dirfd, "file", 0);
+	unlinkat(dirfd, "dir", AT_REMOVEDIR);
+	return ret;
+}
+
+static int test_lsm_inode_idmap(struct lsm *skel)
+{
+	char tmpdir[] = "/var/tmp/test_lsm_idmap.XXXXXX";
+	__u32 expected = INODE_IDMAP_ALL;
+	int dirfd = -1, idmapped_dirfd = -1;
+	int ret = -1;
+
+	if (!ASSERT_OK_PTR(mkdtemp(tmpdir), "mkdtemp"))
+		return -1;
+
+	dirfd = open(tmpdir, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
+	if (!ASSERT_GE(dirfd, 0, "open_tmpdir"))
+		goto out;
+
+	idmapped_dirfd = create_idmapped_tmpfs();
+	if (!ASSERT_GE(idmapped_dirfd, 0, "create_idmapped_tmpfs"))
+		goto out;
+
+	skel->bss->inode_identity_idmap_seen = 0;
+	skel->bss->inode_idmapped_mount_seen = 0;
+
+	if (!ASSERT_OK(exercise_inode_idmap_hooks(dirfd), "identity_idmap"))
+		goto out;
+	if (!ASSERT_OK(exercise_inode_idmap_hooks(idmapped_dirfd),
+		       "idmapped_mount"))
+		goto out;
+
+	if (!ASSERT_EQ(skel->bss->inode_identity_idmap_seen, expected,
+		       "inode_identity_idmap_seen"))
+		goto out;
+	ret = ASSERT_EQ(skel->bss->inode_idmapped_mount_seen, expected,
+			"inode_idmapped_mount_seen") ? 0 : -1;
+
+out:
+	if (idmapped_dirfd >= 0)
+		close(idmapped_dirfd);
+	if (dirfd >= 0)
+		close(dirfd);
+	rmdir(tmpdir);
+	return ret;
+}
+
 static int test_lsm(struct lsm *skel)
 {
 	struct bpf_link *link;
@@ -53,6 +278,10 @@ static int test_lsm(struct lsm *skel)
 
 	skel->bss->monitored_pid = getpid();
 
+	err = test_lsm_inode_idmap(skel);
+	if (!ASSERT_OK(err, "test_lsm_inode_idmap"))
+		return err;
+
 	err = stack_mprotect();
 	if (!ASSERT_EQ(err, -1, "stack_mprotect") ||
 	    !ASSERT_EQ(errno, EPERM, "stack_mprotect"))
@@ -71,6 +300,8 @@ static int test_lsm(struct lsm *skel)
 	skel->bss->copy_test = 0;
 	skel->bss->bprm_count = 0;
 	skel->bss->mprotect_count = 0;
+	skel->bss->inode_identity_idmap_seen = 0;
+	skel->bss->inode_idmapped_mount_seen = 0;
 	return 0;
 }
 
diff --git a/tools/testing/selftests/bpf/progs/lsm.c b/tools/testing/selftests/bpf/progs/lsm.c
index 7de173daf27b..7e32fbddbfad 100644
--- a/tools/testing/selftests/bpf/progs/lsm.c
+++ b/tools/testing/selftests/bpf/progs/lsm.c
@@ -84,6 +84,85 @@ char _license[] SEC("license") = "GPL";
 int monitored_pid = 0;
 int mprotect_count = 0;
 int bprm_count = 0;
+__u32 inode_identity_idmap_seen = 0;
+__u32 inode_idmapped_mount_seen = 0;
+
+enum {
+	INODE_IDMAP_CREATE	= 1U << 0,
+	INODE_IDMAP_LINK	= 1U << 1,
+	INODE_IDMAP_SYMLINK	= 1U << 2,
+	INODE_IDMAP_MKDIR	= 1U << 3,
+	INODE_IDMAP_MKNOD	= 1U << 4,
+	INODE_IDMAP_PERMISSION	= 1U << 5,
+};
+
+static __always_inline bool is_monitored_idmap(struct mnt_idmap *idmap)
+{
+	__u32 pid = bpf_get_current_pid_tgid() >> 32;
+
+	return monitored_pid == pid && idmap;
+}
+
+static __always_inline bool is_identity_idmap(struct mnt_idmap *idmap)
+{
+	return idmap->uid_map.nr_extents == 0 &&
+	       idmap->gid_map.nr_extents == 0;
+}
+
+static __always_inline int record_inode_idmap(struct mnt_idmap *idmap,
+					      __u32 hook, int ret)
+{
+	if (ret || !is_monitored_idmap(idmap))
+		return ret;
+	if (is_identity_idmap(idmap))
+		inode_identity_idmap_seen |= hook;
+	else
+		inode_idmapped_mount_seen |= hook;
+	return 0;
+}
+
+SEC("lsm/inode_create")
+int BPF_PROG(test_inode_create, struct mnt_idmap *idmap, struct inode *dir,
+	     struct dentry *dentry, umode_t mode, int ret)
+{
+	return record_inode_idmap(idmap, INODE_IDMAP_CREATE, ret);
+}
+
+SEC("lsm/inode_link")
+int BPF_PROG(test_inode_link, struct mnt_idmap *idmap,
+	     struct dentry *old_dentry, struct inode *dir,
+	     struct dentry *new_dentry, int ret)
+{
+	return record_inode_idmap(idmap, INODE_IDMAP_LINK, ret);
+}
+
+SEC("lsm/inode_symlink")
+int BPF_PROG(test_inode_symlink, struct mnt_idmap *idmap, struct inode *dir,
+	     struct dentry *dentry, const char *old_name, int ret)
+{
+	return record_inode_idmap(idmap, INODE_IDMAP_SYMLINK, ret);
+}
+
+SEC("lsm/inode_mkdir")
+int BPF_PROG(test_inode_mkdir, struct mnt_idmap *idmap, struct inode *dir,
+	     struct dentry *dentry, umode_t mode, int ret)
+{
+	return record_inode_idmap(idmap, INODE_IDMAP_MKDIR, ret);
+}
+
+SEC("lsm/inode_mknod")
+int BPF_PROG(test_inode_mknod, struct mnt_idmap *idmap, struct inode *dir,
+	     struct dentry *dentry, umode_t mode, dev_t dev, int ret)
+{
+	return record_inode_idmap(idmap, INODE_IDMAP_MKNOD, ret);
+}
+
+SEC("lsm/inode_permission")
+int BPF_PROG(test_inode_permission, struct mnt_idmap *idmap,
+	     struct inode *inode, int mask, int ret)
+{
+	return record_inode_idmap(idmap, INODE_IDMAP_PERMISSION, ret);
+}
 
 SEC("lsm/file_mprotect")
 int BPF_PROG(test_int_hook, struct vm_area_struct *vma,

-- 
2.54.0

