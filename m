From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Wed, 25 Nov 2026 20:03:45 +0100
Subject: [PATCH 3/4] generic: test fallocate after a buffered write that
 faulted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-ntfs-reproducers-v1-3-0cc67533d803@proton.me>
References: <20261125-ntfs-reproducers-v1-0-0cc67533d803@proton.me>
In-Reply-To: <20261125-ntfs-reproducers-v1-0-0cc67533d803@proton.me>
To: fstests@vger.kernel.org, Zorro Lang <zlang@kernel.org>
Cc: ntfs@lists.linux.dev, Namjae Jeon <linkinjeon@kernel.org>, 
 Hyunchul Lee <hyc.lee@gmail.com>, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8316;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=FmK8rQ9PgJraA67rXGYnPFTdM50KCBK5+eC5GNA44Uw=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmx2Q75HjAsMH5ycPJfnbIuqy895AlyTuw6wFGjXrX8vu
 OWJqJt9RykLgxgXg6yYIkvH/xshPiHfPi2L0+qDmcPKBDKEgYtTACYSd5bhf8L+Ta/lZ+xY1Wrx
 b4754zOi0zT8RTbvvHVbSDdinwPnX3aG/3mPVZ8Fdy+6+CPoyOOy46kH/ha3zfEJ05nSbnAlve1
 6JA8A
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A buffered write into a hole may reserve or map space before it copies from
the user buffer, and when the copy faults on the first byte the write fails
with EFAULT and must leave nothing behind. On ntfs the delayed allocation
run it set up stayed in the runlist without any dirty data, and punching,
collapsing or inserting a range through it shifted the run onto clusters of
other files, so the file read their contents and ntfsck found the cluster
bitmap inconsistent. The fixes are "ntfs: punch out the delalloc
reservation of a failed buffered write" and "ntfs: do not shift the cluster
number of a delalloc run on split" from the ntfs delayed allocation series,
not merged yet. Fail a write over the first half of a sparse file, then
punch, collapse, insert or write a range inside that half, and compare each
file with its expected contents after a remount. The new helper
src/pwrite-short-copy calls pwrite(2) once from a buffer whose readable
part ends a given number of bytes in, and prints what it returned.

Link: https://lore.kernel.org/all/20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me/
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 .gitignore              |   1 +
 src/Makefile            |   2 +-
 src/pwrite-short-copy.c | 101 ++++++++++++++++++++++++++++++++++++++++++++++++
 tests/generic/817       |  83 +++++++++++++++++++++++++++++++++++++++
 tests/generic/817.out   |   2 +
 5 files changed, 188 insertions(+), 1 deletion(-)

diff --git a/.gitignore b/.gitignore
index cdcfa06e..afce03d4 100644
--- a/.gitignore
+++ b/.gitignore
@@ -123,6 +123,7 @@ tags
 /src/preallo_rw_pattern_reader
 /src/preallo_rw_pattern_writer
 /src/punch-alternating
+/src/pwrite-short-copy
 /src/pwrite_mmap_blocked
 /src/randholes
 /src/readdir-while-renames
diff --git a/src/Makefile b/src/Makefile
index a1fc38d8..0b031620 100644
--- a/src/Makefile
+++ b/src/Makefile
@@ -38,7 +38,7 @@ LINUX_TARGETS = dirstress fill fill2 getpagesize holes lstat64 \
 	detached_mounts_propagation ext4_resize t_readdir_3 splice2pipe \
 	uuid_ioctl t_snapshot_deleted_subvolume fiemap-fault min_dio_alignment \
 	rw_hint btrfs_ioctl refluxfs xfs-exchange-to-eof \
-	xfs-exchange-to-dirty-eof xfs-swapext-reflink
+	xfs-exchange-to-dirty-eof xfs-swapext-reflink pwrite-short-copy
 
 EXTRA_EXECS = dmerror fill2attr fill2fs fill2fs_check scaleread.sh \
 	      btrfs_crc32c_forged_name.py popdir.pl popattr.py \
diff --git a/src/pwrite-short-copy.c b/src/pwrite-short-copy.c
new file mode 100644
index 00000000..2f1c36a3
--- /dev/null
+++ b/src/pwrite-short-copy.c
@@ -0,0 +1,101 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Ernest Borowski <ernest.borowski.git@proton.me>.  All Rights Reserved.
+ *
+ * Call pwrite(2) once with a source buffer that ends in an inaccessible page,
+ * so that the copy from user space stops after a given number of bytes: the
+ * write comes up short, or fails with EFAULT when no byte is readable.
+ *
+ * usage: pwrite-short-copy [-p pattern] file offset length readable
+ *
+ * The first "readable" bytes of the buffer hold the pattern byte (default
+ * 0x5c), and the page after them is PROT_NONE.  The program prints what
+ * pwrite(2) returned: the number of bytes written, or minus the errno.
+ * It exits 0 in both cases, and 1 on a usage or setup error.
+ */
+#include <errno.h>
+#include <fcntl.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <sys/mman.h>
+#include <unistd.h>
+
+static void usage(const char *prog)
+{
+	fprintf(stderr,
+		"usage: %s [-p pattern] file offset length readable\n", prog);
+	exit(1);
+}
+
+static long long parse(const char *s, const char *prog)
+{
+	char *end;
+	long long v;
+
+	errno = 0;
+	v = strtoll(s, &end, 0);
+	if (errno || *end || v < 0)
+		usage(prog);
+	return v;
+}
+
+int main(int argc, char **argv)
+{
+	long long offset, length, readable;
+	size_t pagesize = getpagesize();
+	size_t npages;
+	int pattern = 0x5c;
+	char *map, *buf;
+	ssize_t ret;
+	int fd, c;
+
+	while ((c = getopt(argc, argv, "p:")) != -1) {
+		switch (c) {
+		case 'p':
+			pattern = parse(optarg, argv[0]) & 0xff;
+			break;
+		default:
+			usage(argv[0]);
+		}
+	}
+	if (argc - optind != 4)
+		usage(argv[0]);
+
+	offset = parse(argv[optind + 1], argv[0]);
+	length = parse(argv[optind + 2], argv[0]);
+	readable = parse(argv[optind + 3], argv[0]);
+
+	fd = open(argv[optind], O_WRONLY);
+	if (fd < 0) {
+		perror(argv[optind]);
+		return 1;
+	}
+
+	/* the readable bytes end where the last, inaccessible page starts */
+	npages = (readable + pagesize - 1) / pagesize + 1;
+	map = mmap(NULL, npages * pagesize, PROT_READ | PROT_WRITE,
+		   MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
+	if (map == MAP_FAILED) {
+		perror("mmap");
+		return 1;
+	}
+	buf = map + (npages - 1) * pagesize - readable;
+	memset(buf, pattern, readable);
+	if (mprotect(map + (npages - 1) * pagesize, pagesize, PROT_NONE)) {
+		perror("mprotect");
+		return 1;
+	}
+
+	ret = pwrite(fd, buf, length, offset);
+	if (ret < 0)
+		printf("%d\n", -errno);
+	else
+		printf("%zd\n", ret);
+
+	if (close(fd)) {
+		perror("close");
+		return 1;
+	}
+	return 0;
+}
diff --git a/tests/generic/817 b/tests/generic/817
new file mode 100755
index 00000000..dff08a28
--- /dev/null
+++ b/tests/generic/817
@@ -0,0 +1,83 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Ernest Borowski <ernest.borowski.git@proton.me>.  All Rights Reserved.
+#
+# FS QA Test No. 817
+#
+# A buffered write into a hole that fails with EFAULT, because not one byte of
+# its source buffer is readable, must not leave anything behind that later
+# operations trip over.  After such a write over the first half of a sparse
+# file, punch a hole through that range, collapse a range out of it, insert a
+# range into it or write into it, and check that after a remount the file
+# reads back as zeroes, apart from the data written.
+#
+. ./common/preamble
+_begin_fstest auto quick rw punch collapse insert
+
+_fixed_by_fs_commit ntfs xxxxxxxxxxxx \
+	"ntfs: punch out the delalloc reservation of a failed buffered write"
+_fixed_by_fs_commit ntfs xxxxxxxxxxxx \
+	"ntfs: do not shift the cluster number of a delalloc run on split"
+
+_require_scratch
+_require_test_program "pwrite-short-copy"
+_require_xfs_io_command "fpunch"
+_require_xfs_io_command "fcollapse"
+_require_xfs_io_command "finsert"
+
+_scratch_mkfs >> $seqres.full 2>&1
+_scratch_mount
+
+blksz=$(_get_file_block_size $SCRATCH_MNT)
+unit=$((blksz > 65536 ? blksz : 65536))
+size=$((16 * unit))
+piece=$((2 * unit))
+
+# Data in other files, so that blocks a broken mapping points to are not zero.
+for i in 1 2 3 4; do
+	$XFS_IO_PROG -f -c "pwrite -q -S 0x3$i 0 $((8 * unit))" \
+		$SCRATCH_MNT/other$i
+done
+_scratch_sync
+
+for op in none punch collapse insert write; do
+	file=$SCRATCH_MNT/$op
+	$XFS_IO_PROG -f -c "truncate $size" -c fsync $file
+
+	# EFAULT is errno 14
+	ret=$($here/src/pwrite-short-copy $file 0 $((size / 2)) 0)
+	[ "$ret" = "-14" ] || \
+		echo "$op: write from an unreadable buffer returned $ret"
+
+	newsize=$size
+	case $op in
+	punch)
+		$XFS_IO_PROG -c "fpunch $piece $piece" $file
+		;;
+	collapse)
+		$XFS_IO_PROG -c "fcollapse $piece $piece" $file
+		newsize=$((size - piece))
+		;;
+	insert)
+		$XFS_IO_PROG -c "finsert $piece $piece" $file
+		newsize=$((size + piece))
+		;;
+	write)
+		$XFS_IO_PROG -c "pwrite -q -S 0x77 $piece $unit" $file
+		;;
+	esac
+
+	$XFS_IO_PROG -f -c "truncate $newsize" $tmp.$op
+	[ $op = write ] && \
+		$XFS_IO_PROG -c "pwrite -q -S 0x77 $piece $unit" $tmp.$op
+done
+
+# Read everything back from the disk.
+_scratch_cycle_mount
+for op in none punch collapse insert write; do
+	cmp -s $SCRATCH_MNT/$op $tmp.$op || \
+		echo "$op: file contents differ after the failed write"
+done
+
+echo "Silence is golden"
+_exit 0
diff --git a/tests/generic/817.out b/tests/generic/817.out
new file mode 100644
index 00000000..86920a4f
--- /dev/null
+++ b/tests/generic/817.out
@@ -0,0 +1,2 @@
+QA output created by 817
+Silence is golden

-- 
2.56.1

