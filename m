From: Harrison Crosse <harrison@crosse.dev>
Date: Wed, 18 Nov 2026 16:56:42 -0500
Subject: [PATCH 2/2] selftests/mm: add a test for populating a page that
 cannot be read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-mmpop-populate-v1-2-9c561d178d11@crosse.dev>
References: <20261118-mmpop-populate-v1-0-9c561d178d11@crosse.dev>
In-Reply-To: <20261118-mmpop-populate-v1-0-9c561d178d11@crosse.dev>
To: David Hildenbrand <david@kernel.org>, Jason Gunthorpe <jgg@ziepe.ca>, 
 John Hubbard <jhubbard@nvidia.com>, Peter Xu <peterx@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Shuah Khan <shuah@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Josef Bacik <josef@toxicpanda.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Jan Kara <jack@suse.cz>, 
 Harrison Crosse <harrison@crosse.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795039163; l=15821;
 i=harrison@crosse.dev; s=20261117; h=from:subject:message-id;
 bh=ozpf4+RjmEWsr6XVU7gtEDTBOVvOljQv4enrF13umZI=;
 b=z5iQcgQhQloMXQM8vhSIzkjjnfSBQGFpYstK5hSaIVrlJgBaxIGDWxo3ahHhSUpqOrxRqVh5U
 4yRWa2VPjxxBSVwyb7lGNG2FVp2pNtGxF4IlfTAi4S2F2PjSSefjwpD
X-Developer-Key: i=harrison@crosse.dev; a=ed25519;
 pk=fwi/XME2YaW/BDBQ76FmKgF9xHZwRb+dxlVCbxuyojo=
X-Endpoint-Received: by B4 Relay for harrison@crosse.dev/20261117 with auth_id=1552
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add populate_eio, which serves a FUSE file system from the test itself
on /dev/fuse, without libfuse. Its one file has a page whose reads
always fail with -EIO. FUSE handles faults on mapped files with
filemap_fault(), so a fault on that page releases the mmap_lock for the
read and, on a first attempt, returns VM_FAULT_RETRY whatever the
result.

The test checks that MADV_POPULATE_READ fails with EFAULT, that
mmap(MAP_POPULATE) returns the mapping and that mlock() fails with
ENOMEM. Each call runs in a child with a timeout, so a kernel that
retries the read endlessly fails the test instead of hanging it.
Without the previous patch, the mmap(MAP_POPULATE) and mlock() checks
fail this way.

The mlock() check is skipped if the test cannot lock an anonymous
mapping of the same size, and the whole test is skipped if /dev/fuse
cannot be opened or the file system cannot be created, for example
without CAP_SYS_ADMIN. The file system is created with fsmount() and
never attached to a mount point, so it goes away with the test's
processes. If a child does not exit after SIGKILL because the server
read its request and stopped, the test kills the server, which aborts
the connection. CONFIG_FUSE_FS is added to the mm selftest config.

This test and its changelog were prepared with the help of an AI coding
assistant (Claude).

Signed-off-by: Harrison Crosse <harrison@crosse.dev>
---
Tested on x86_64 under QEMU (TCG), with 4K pages. On v7.4-rc3 without
the previous patch, and on 6.12.117 with the test built with the
v7.4-rc3 FUSE header, MADV_POPULATE_READ passes and the
mmap(MAP_POPULATE) and mlock() checks fail with no return within 5 s;
with the previous patch on v7.4-rc3, all three pass. Two faults were
tried on v7.4-rc3 without the previous patch, and neither left a
process or FUSE connection. With the server stopped by SIGSTOP after it
read the bad page's read request, the test killed the server and ended
in about 7 s. The other fault killed the test process with SIGKILL.
Without CAP_IPC_LOCK and with RLIMIT_MEMLOCK at 0, the mlock() check is
skipped. On arm64 v7.4-rc3 under QEMU (TCG), also with 4K pages, the
three checks give the same results without and with the previous patch.

Not tested: architectures other than x86_64 and arm64, other page
sizes, unprivileged user namespaces, and kernels older than 6.12.
---
 tools/testing/selftests/mm/Makefile       |   1 +
 tools/testing/selftests/mm/config         |   1 +
 tools/testing/selftests/mm/populate_eio.c | 410 ++++++++++++++++++++++++++++++
 tools/testing/selftests/mm/run_vmtests.sh |   1 +
 4 files changed, 413 insertions(+)

diff --git a/tools/testing/selftests/mm/Makefile b/tools/testing/selftests/mm/Makefile
index 0ea72e997..2efb61d51 100644
--- a/tools/testing/selftests/mm/Makefile
+++ b/tools/testing/selftests/mm/Makefile
@@ -71,6 +71,7 @@ TEST_GEN_FILES += khugepaged
 TEST_GEN_FILES += madv_populate
 TEST_GEN_FILES += map_fixed_noreplace
 TEST_GEN_FILES += map_populate
+TEST_GEN_FILES += populate_eio
 ifneq (,$(filter $(ARCH),arm64 riscv riscv64 x86 x86_64 loongarch32 loongarch64))
 TEST_GEN_FILES += memfd_secret
 endif
diff --git a/tools/testing/selftests/mm/config b/tools/testing/selftests/mm/config
index 06f78bd23..08a5ba29b 100644
--- a/tools/testing/selftests/mm/config
+++ b/tools/testing/selftests/mm/config
@@ -14,3 +14,4 @@ CONFIG_UPROBES=y
 CONFIG_MEMORY_FAILURE=y
 CONFIG_HWPOISON_INJECT=m
 CONFIG_PROC_MEM_ALWAYS_FORCE=y
+CONFIG_FUSE_FS=y
diff --git a/tools/testing/selftests/mm/populate_eio.c b/tools/testing/selftests/mm/populate_eio.c
new file mode 100644
index 000000000..1099bd7ed
--- /dev/null
+++ b/tools/testing/selftests/mm/populate_eio.c
@@ -0,0 +1,410 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Populate a file mapping with a page whose reads always fail.
+ *
+ * A minimal FUSE server on /dev/fuse serves one file and fails every
+ * read of one of its pages with -EIO. MADV_POPULATE_READ must fail with
+ * EFAULT, mmap(MAP_POPULATE) must return the mapping and mlock() must
+ * fail with ENOMEM, rather than retry the read until the task is killed.
+ *
+ * The file system is created with fsopen() and fsmount() and never
+ * attached to a mount point, so it goes away with the test's processes.
+ */
+#define _GNU_SOURCE
+#include <errno.h>
+#include <fcntl.h>
+#include <linux/fuse.h>
+#include <linux/mman.h>
+#include <linux/mount.h>
+#include <signal.h>
+#include <stdint.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <sys/mman.h>
+#include <sys/prctl.h>
+#include <sys/resource.h>
+#include <sys/stat.h>
+#include <sys/syscall.h>
+#include <sys/uio.h>
+#include <sys/wait.h>
+#include <unistd.h>
+#include "kselftest.h"
+
+#define NR_PAGES	8
+#define BAD_PAGE	3
+#define FILE_INO	2
+#define TIMEOUT_S	5
+#define GRACE_S		2
+
+/*
+ * Kernels before FUSE 7.47 accept only this size of open reply; 7.47
+ * appended backing_id_64 and accepts the shorter reply as well.
+ */
+#define OPEN_OUT_SIZE	16
+
+/* child exit status: 0 if the call succeeded, its errno, or this */
+#define EXIT_SETUP	200
+
+/* run_call() results other than an exit status */
+#define RUN_TIMEOUT	-1
+#define RUN_SIGNALED	-2
+
+enum call { CALL_MADV_POPULATE_READ, CALL_MAP_POPULATE, CALL_MLOCK };
+
+static size_t page_size;
+static pid_t parent, server;
+
+static int sys_fsopen(const char *fsname, unsigned int flags)
+{
+	return syscall(__NR_fsopen, fsname, flags);
+}
+
+static int sys_fsconfig(int fd, unsigned int cmd, const char *key,
+			const char *value)
+{
+	return syscall(__NR_fsconfig, fd, cmd, key, value, 0);
+}
+
+static int sys_fsmount(int fd, unsigned int flags, unsigned int attr_flags)
+{
+	return syscall(__NR_fsmount, fd, flags, attr_flags);
+}
+
+/* Recheck getppid() in case parent exited before PR_SET_PDEATHSIG. */
+static void die_with_parent(void)
+{
+	if (prctl(PR_SET_PDEATHSIG, SIGKILL) || getppid() != parent)
+		_exit(EXIT_SETUP);
+}
+
+static void fuse_reply(int fd, uint64_t unique, int error,
+		       const void *arg, size_t len)
+{
+	struct fuse_out_header out = {
+		.len = sizeof(out) + len,
+		.error = error,
+		.unique = unique,
+	};
+	struct iovec iov[] = {
+		{ .iov_base = &out, .iov_len = sizeof(out) },
+		{ .iov_base = (void *)arg, .iov_len = len },
+	};
+
+	/* ENOENT: the request was interrupted or aborted */
+	if (writev(fd, iov, len ? 2 : 1) < 0 && errno != ENOENT)
+		ksft_print_msg("FUSE reply of %zu bytes rejected: %s\n",
+			       len, strerror(errno));
+}
+
+static void fill_attr(struct fuse_attr *attr, uint64_t ino)
+{
+	memset(attr, 0, sizeof(*attr));
+	attr->ino = ino;
+	attr->blksize = page_size;
+	if (ino == FUSE_ROOT_ID) {
+		attr->mode = S_IFDIR | 0755;
+		attr->nlink = 2;
+	} else {
+		attr->mode = S_IFREG | 0444;
+		attr->nlink = 1;
+		attr->size = NR_PAGES * page_size;
+		attr->blocks = attr->size / 512;
+	}
+}
+
+static void fuse_read(int fd, uint64_t unique, const struct fuse_read_in *read_in,
+		      const char *data)
+{
+	uint64_t size = NR_PAGES * page_size;
+	uint64_t bad = BAD_PAGE * page_size;
+	uint64_t start = read_in->offset;
+	uint64_t end = start + read_in->size;
+
+	if (start < bad + page_size && end > bad) {
+		fuse_reply(fd, unique, -EIO, NULL, 0);
+		return;
+	}
+	if (end > size)
+		end = size;
+	fuse_reply(fd, unique, 0, data, start < end ? end - start : 0);
+}
+
+static __noreturn void fuse_serve(int fd)
+{
+	size_t bufsize = FUSE_MIN_READ_BUFFER + page_size;
+	struct fuse_in_header *in;
+	char *data;
+	void *arg;
+
+	die_with_parent();
+	in = malloc(bufsize);
+	data = calloc(NR_PAGES, page_size);
+	if (!in || !data)
+		_exit(1);
+	arg = in + 1;
+
+	for (;;) {
+		ssize_t n = read(fd, in, bufsize);
+
+		if (n < 0 && (errno == EINTR || errno == ENOENT))
+			continue;
+		/* read() fails with ENODEV once the connection is gone */
+		if (n < (ssize_t)sizeof(*in))
+			_exit(0);
+
+		switch (in->opcode) {
+		case FUSE_INIT: {
+			const struct fuse_init_in *init_in = arg;
+			struct fuse_init_out init_out = {
+				.major = FUSE_KERNEL_VERSION,
+				.minor = FUSE_KERNEL_MINOR_VERSION,
+				.max_readahead = init_in->max_readahead,
+				.max_write = page_size,
+				.time_gran = 1,
+			};
+
+			if (init_in->minor < init_out.minor)
+				init_out.minor = init_in->minor;
+			fuse_reply(fd, in->unique, 0, &init_out, sizeof(init_out));
+			break;
+		}
+		case FUSE_LOOKUP: {
+			struct fuse_entry_out entry = {
+				.nodeid = FILE_INO,
+				.generation = 1,
+				.entry_valid = 3600,
+				.attr_valid = 3600,
+			};
+
+			if (in->nodeid != FUSE_ROOT_ID || strcmp(arg, "file")) {
+				fuse_reply(fd, in->unique, -ENOENT, NULL, 0);
+				break;
+			}
+			fill_attr(&entry.attr, FILE_INO);
+			fuse_reply(fd, in->unique, 0, &entry, sizeof(entry));
+			break;
+		}
+		case FUSE_GETATTR: {
+			struct fuse_attr_out attr_out = { .attr_valid = 3600 };
+
+			fill_attr(&attr_out.attr, in->nodeid);
+			fuse_reply(fd, in->unique, 0, &attr_out, sizeof(attr_out));
+			break;
+		}
+		case FUSE_OPEN: {
+			struct fuse_open_out open_out = { .fh = 1 };
+
+			fuse_reply(fd, in->unique, 0, &open_out, OPEN_OUT_SIZE);
+			break;
+		}
+		case FUSE_READ:
+			fuse_read(fd, in->unique, arg, data);
+			break;
+		case FUSE_FORGET:
+		case FUSE_BATCH_FORGET:
+			break;
+		default:
+			fuse_reply(fd, in->unique, -ENOSYS, NULL, 0);
+		}
+	}
+}
+
+/*
+ * do_mlock() can fail with ENOMEM from RLIMIT_MEMLOCK before reaching
+ * __mm_populate(), which would falsely pass CALL_MLOCK without CAP_IPC_LOCK.
+ */
+static bool can_mlock(size_t size)
+{
+	struct rlimit rlim;
+	bool locked;
+	void *p;
+
+	if (!getrlimit(RLIMIT_MEMLOCK, &rlim) && rlim.rlim_cur < size) {
+		rlim.rlim_cur = rlim.rlim_max;
+		setrlimit(RLIMIT_MEMLOCK, &rlim);
+	}
+	p = mmap(NULL, size, PROT_READ | PROT_WRITE,
+		 MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
+	if (p == MAP_FAILED)
+		return false;
+	locked = !mlock(p, size);
+	munmap(p, size);
+	return locked;
+}
+
+static __noreturn void do_call(enum call call, int mnt_fd)
+{
+	size_t size = NR_PAGES * page_size;
+	int flags = MAP_SHARED;
+	char *p;
+	int fd;
+
+	die_with_parent();
+	fd = openat(mnt_fd, "file", O_RDONLY);
+	if (fd < 0)
+		_exit(EXIT_SETUP);
+	if (call == CALL_MAP_POPULATE)
+		flags |= MAP_POPULATE;
+	p = mmap(NULL, size, PROT_READ, flags, fd, 0);
+	if (p == MAP_FAILED)
+		_exit(call == CALL_MAP_POPULATE ? errno : EXIT_SETUP);
+	if (call == CALL_MADV_POPULATE_READ && madvise(p, size, MADV_POPULATE_READ))
+		_exit(errno);
+	if (call == CALL_MLOCK && mlock(p, size))
+		_exit(errno);
+	_exit(0);
+}
+
+static bool reap(pid_t pid, int *status, int timeout_ms)
+{
+	int i;
+
+	for (i = 0; i < timeout_ms / 10; i++) {
+		pid_t ret = waitpid(pid, status, WNOHANG);
+
+		if (ret == pid)
+			return true;
+		if (ret < 0 && errno != EINTR)
+			ksft_exit_fail_perror("waitpid");
+		usleep(10000);
+	}
+	return false;
+}
+
+/*
+ * A caller whose request the server read but did not answer waits for
+ * the answer even after SIGKILL. Killing the server closes the last
+ * /dev/fuse file descriptor, which aborts the connection and ends such
+ * requests.
+ */
+static void stop_server(void)
+{
+	if (!server)
+		return;
+	kill(server, SIGKILL);
+	while (waitpid(server, NULL, 0) < 0 && errno == EINTR)
+		;
+	server = 0;
+}
+
+static int run_call(enum call call, int mnt_fd, int *sig)
+{
+	int status;
+	pid_t pid;
+
+	pid = fork();
+	if (pid < 0)
+		ksft_exit_fail_perror("fork");
+	if (!pid)
+		do_call(call, mnt_fd);
+
+	if (!reap(pid, &status, TIMEOUT_S * 1000)) {
+		kill(pid, SIGKILL);
+		if (!reap(pid, &status, GRACE_S * 1000)) {
+			ksft_print_msg("child alive %d s after SIGKILL, killing the server\n",
+				       GRACE_S);
+			stop_server();
+			while (waitpid(pid, &status, 0) < 0 && errno == EINTR)
+				;
+		}
+		return RUN_TIMEOUT;
+	}
+	if (WIFSIGNALED(status)) {
+		*sig = WTERMSIG(status);
+		return RUN_SIGNALED;
+	}
+	return WEXITSTATUS(status);
+}
+
+static void check(const char *name, enum call call, int mnt_fd, int expected)
+{
+	int sig = 0, ret;
+
+	if (!server) {
+		ksft_test_result_fail("%s: not run, the FUSE server was killed\n", name);
+		return;
+	}
+	ret = run_call(call, mnt_fd, &sig);
+	if (ret == RUN_TIMEOUT)
+		ksft_print_msg("%s: no return within %d s\n", name, TIMEOUT_S);
+	else if (ret == RUN_SIGNALED)
+		ksft_print_msg("%s: killed by %s\n", name, strsignal(sig));
+	else if (ret == EXIT_SETUP)
+		ksft_print_msg("%s: openat() or mmap() failed\n", name);
+	else if (ret >= 0 && ret != expected)
+		ksft_print_msg("%s: %s\n", name, ret ? strerror(ret) : "the call succeeded");
+	ksft_test_result(ret == expected, "%s\n", name);
+}
+
+static bool unavailable(int err)
+{
+	return err == ENOENT || err == ENODEV || err == ENXIO ||
+	       err == EPERM || err == EACCES || err == ENOSYS;
+}
+
+int main(void)
+{
+	char fd_str[16], uid_str[16], gid_str[16];
+	int fd, fs_fd, mnt_fd;
+
+	ksft_print_header();
+	page_size = getpagesize();
+	parent = getpid();
+
+	fd = open("/dev/fuse", O_RDWR | O_CLOEXEC);
+	if (fd < 0 && unavailable(errno))
+		ksft_exit_skip("cannot open /dev/fuse: %s\n", strerror(errno));
+	if (fd < 0)
+		ksft_exit_fail_perror("open /dev/fuse");
+	fs_fd = sys_fsopen("fuse", FSOPEN_CLOEXEC);
+	if (fs_fd < 0 && unavailable(errno))
+		ksft_exit_skip("cannot create a FUSE file system: %s\n", strerror(errno));
+	if (fs_fd < 0)
+		ksft_exit_fail_perror("fsopen");
+
+	snprintf(fd_str, sizeof(fd_str), "%d", fd);
+	snprintf(uid_str, sizeof(uid_str), "%u", getuid());
+	snprintf(gid_str, sizeof(gid_str), "%u", getgid());
+	if (sys_fsconfig(fs_fd, FSCONFIG_SET_STRING, "fd", fd_str) ||
+	    sys_fsconfig(fs_fd, FSCONFIG_SET_STRING, "rootmode", "40000") ||
+	    sys_fsconfig(fs_fd, FSCONFIG_SET_STRING, "user_id", uid_str) ||
+	    sys_fsconfig(fs_fd, FSCONFIG_SET_STRING, "group_id", gid_str))
+		ksft_exit_fail_perror("fsconfig");
+	if (sys_fsconfig(fs_fd, FSCONFIG_CMD_CREATE, NULL, NULL)) {
+		if (unavailable(errno))
+			ksft_exit_skip("cannot mount FUSE: %s\n", strerror(errno));
+		ksft_exit_fail_perror("fsconfig create");
+	}
+	mnt_fd = sys_fsmount(fs_fd, FSMOUNT_CLOEXEC,
+			     MOUNT_ATTR_NOSUID | MOUNT_ATTR_NODEV);
+	if (mnt_fd < 0 && unavailable(errno))
+		ksft_exit_skip("cannot mount FUSE: %s\n", strerror(errno));
+	if (mnt_fd < 0)
+		ksft_exit_fail_perror("fsmount");
+	close(fs_fd);
+
+	server = fork();
+	if (server < 0)
+		ksft_exit_fail_perror("fork");
+	if (!server) {
+		close(mnt_fd);
+		fuse_serve(fd);
+	}
+	close(fd);
+
+	ksft_set_plan(3);
+	check("MADV_POPULATE_READ fails with EFAULT", CALL_MADV_POPULATE_READ,
+	      mnt_fd, EFAULT);
+	check("mmap(MAP_POPULATE) returns the mapping", CALL_MAP_POPULATE,
+	      mnt_fd, 0);
+	if (can_mlock(NR_PAGES * page_size))
+		check("mlock() fails with ENOMEM", CALL_MLOCK, mnt_fd, ENOMEM);
+	else
+		ksft_test_result_skip("mlock() fails with ENOMEM: cannot mlock() %zu bytes\n",
+				      NR_PAGES * page_size);
+
+	close(mnt_fd);
+	stop_server();
+	ksft_finished();
+}
diff --git a/tools/testing/selftests/mm/run_vmtests.sh b/tools/testing/selftests/mm/run_vmtests.sh
index a1b45a3de..3ac9f9336 100755
--- a/tools/testing/selftests/mm/run_vmtests.sh
+++ b/tools/testing/selftests/mm/run_vmtests.sh
@@ -291,6 +291,7 @@ else
 fi
 
 CATEGORY="mmap" run_test ./map_populate
+CATEGORY="mmap" run_test ./populate_eio
 CATEGORY="mmap" run_test ./droppable
 
 CATEGORY="mlock" run_test ./mlock-random-test

-- 
2.56.1

