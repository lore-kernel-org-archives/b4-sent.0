From: Daan De Meyer <daan@amutable.com>
Date: Tue, 03 Nov 2026 14:06:18 +0100
Subject: [PATCH] btrfs: add io_uring interface for BTRFS_IOC_DEFRAG_RANGE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-btrfs-uring-defrag-v1-1-50bf656a71cd@amutable.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBBFr1Jm7UBTmypeRVwk6SQdwSgzqQild
 zfR5fv89zZQEiaFS7eB0JuVn7mCOXQQFpcTIc+VYeiHyZj+iL5IVFyFc8KZoriEwziGkzXnyTo
 LVXwJRf78otfbn3X1dwqlldrDOyX04nJY2vRwWkhg37/J++NjjwAAAA==
X-Change-ID: 20261103-btrfs-uring-defrag-244c751865a5
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jens Axboe <axboe@kernel.dk>, io-uring@vger.kernel.org, 
 Daan De Meyer <daan@amutable.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793711183; l=9013;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=aeyr1gniHen92wxzU6GnzI504bi8iU5pRP9wYYntiMQ=;
 b=yUWn9HAoPS04U7CjCiZznhQO6x7z32uO3IkcDEHe8u/k2X0GC0XiZtQGjYgEWOp3xa9h2i14F
 pIL0BwTPdscAdIYTH8gUvDYIREo38Swtwq+IrFVyJF8C2cPgDAnY9mK
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

btrfs_uring_cmd() only handles the encoded read and write ioctls, so a
program that drives its I/O through io_uring has to defragment a file
with the ioctl from a separate thread. We're working on a
systemd-journald change that needs this. On btrfs, every writeback of a
journal file allocates a new extent, and journald defragments each
finished part of the file from a helper thread with
BTRFS_IOC_DEFRAG_RANGE.

Let's accept BTRFS_IOC_DEFRAG_RANGE as a uring command. The command
calls btrfs_ioctl_defrag(), so it runs the same checks in the same order
and returns the same errors as the ioctl. Before that, it calls the LSM
ioctl hook like the ioctl syscall does, so that a policy that denies the
ioctl also denies the command. security_uring_cmd() isn't enough for
that. Smack checks read access in security_uring_cmd(), and it checks
write access in the ioctl hook for this ioctl. A caller with
CAP_SYS_ADMIN also skips inode_permission(), so nothing else checks the
label. overlayfs calls security_file_ioctl() the same way.

The arguments are passed inline in the command area of a 128-byte SQE,
either on an IORING_SETUP_SQE128 ring or as IORING_OP_URING_CMD128 on an
IORING_SETUP_SQE_MIXED ring. The 48-byte struct doesn't fit in the 16
bytes of command data of a 64-byte SQE. The encoded commands pass a
pointer in addr instead, but the command would then read the arguments in
io-wq after io_uring_enter() has returned. That breaks the promise of
IORING_FEAT_SUBMIT_STABLE. io_uring copies the SQE before it queues the
command to io-wq, so inline arguments are stable on every path, including
IOSQE_ASYNC. The other SQE fields and the rest of the command area must be
zero, so that they can carry flags later.

The command only handles regular files. The ioctl on a directory
defragments the subvolume tree, which isn't an operation on the file.
btrfs_dir_file_operations has no uring_cmd, so io_uring returns
-EOPNOTSUPP for a directory.

btrfs_defrag_file() takes the inode lock, reads pages and throttles on
dirty pages, and mnt_want_write_file() sleeps while the filesystem is
frozen. Like the encoded write command, the command returns -EAGAIN when
io_uring issues it with IO_URING_F_NONBLOCK. It does all of its work when
io_uring issues it again from io-wq, and it keeps nothing in the PDU in
between.

struct btrfs_ioctl_defrag_range_args has no padding, and pahole shows the
same layout and a size of 48 bytes on i386 and on x86-64. The command
therefore needs no compat variant.

We tested the command with a liburing program on a loop-mounted btrfs.
It gave the same results and the same errors as the ioctl, on fragmented
files, on invalid arguments, on read-only mounts and under Smack.

Signed-off-by: Daan De Meyer <daan@amutable.com>
---
This lets a program that drives its I/O through io_uring defragment a btrfs
file without a thread for the ioctl. A systemd-journald change we're working
on defragments each finished part of a journal file and needs this.

The command takes struct btrfs_ioctl_defrag_range_args inline in a 128-byte
SQE, either on an IORING_SETUP_SQE128 ring or as IORING_OP_URING_CMD128 on an
IORING_SETUP_SQE_MIXED ring. A pointer in addr would be read in io-wq after
io_uring_enter() returns, which breaks IORING_FEAT_SUBMIT_STABLE. The
unused SQE fields and the rest of the command area must be zero.

The command calls the LSM ioctl hook and then btrfs_ioctl_defrag() from
io-wq, so it runs the same checks in the same order and returns the same
errors as the ioctl. A liburing test compared both paths on fragmented
files, invalid arguments, read-only snapshots, read-only mounts, read-only
filesystems, unprivileged callers and a Smack policy, and found no
difference. The ioctl results match an unpatched kernel.
---
 fs/btrfs/ioctl.c | 88 ++++++++++++++++++++++++++++++++++++++++++++------------
 1 file changed, 69 insertions(+), 19 deletions(-)

diff --git a/fs/btrfs/ioctl.c b/fs/btrfs/ioctl.c
index f3e2afe221be..49429946804d 100644
--- a/fs/btrfs/ioctl.c
+++ b/fs/btrfs/ioctl.c
@@ -2442,7 +2442,8 @@ static noinline int btrfs_ioctl_snap_destroy(struct file *file,
 	return ret;
 }
 
-static int btrfs_ioctl_defrag(struct file *file, void __user *argp)
+static int btrfs_ioctl_defrag(struct file *file, void __user *argp,
+			      const struct btrfs_ioctl_defrag_range_args *args)
 {
 	struct inode *inode = file_inode(file);
 	struct btrfs_root *root = BTRFS_I(inode)->root;
@@ -2487,30 +2488,32 @@ static int btrfs_ioctl_defrag(struct file *file, void __user *argp)
 			goto out;
 		}
 
-		if (argp) {
+		if (args) {
+			range = *args;
+		} else if (argp) {
 			if (copy_from_user(&range, argp, sizeof(range))) {
 				ret = -EFAULT;
 				goto out;
 			}
-			if (range.flags & ~BTRFS_DEFRAG_RANGE_FLAGS_SUPP) {
-				ret = -EOPNOTSUPP;
-				goto out;
-			}
-			if ((range.flags & BTRFS_DEFRAG_RANGE_COMPRESS) &&
-			    (range.flags & BTRFS_DEFRAG_RANGE_NOCOMPRESS)) {
-				ret = -EINVAL;
-				goto out;
-			}
-			/* Compression or no-compression require to start the IO. */
-			if ((range.flags & BTRFS_DEFRAG_RANGE_COMPRESS) ||
-			    (range.flags & BTRFS_DEFRAG_RANGE_NOCOMPRESS)) {
-				range.flags |= BTRFS_DEFRAG_RANGE_START_IO;
-				range.extent_thresh = (u32)-1;
-			}
 		} else {
 			/* the rest are all set to zero by kzalloc */
 			range.len = (u64)-1;
 		}
+		if (range.flags & ~BTRFS_DEFRAG_RANGE_FLAGS_SUPP) {
+			ret = -EOPNOTSUPP;
+			goto out;
+		}
+		if ((range.flags & BTRFS_DEFRAG_RANGE_COMPRESS) &&
+		    (range.flags & BTRFS_DEFRAG_RANGE_NOCOMPRESS)) {
+			ret = -EINVAL;
+			goto out;
+		}
+		/* Compression or no-compression require to start the IO. */
+		if ((range.flags & BTRFS_DEFRAG_RANGE_COMPRESS) ||
+		    (range.flags & BTRFS_DEFRAG_RANGE_NOCOMPRESS)) {
+			range.flags |= BTRFS_DEFRAG_RANGE_START_IO;
+			range.extent_thresh = (u32)-1;
+		}
 		ret = btrfs_defrag_file(BTRFS_I(file_inode(file)), &file->f_ra,
 					&range, BTRFS_OLDEST_GENERATION, 0);
 		if (ret > 0)
@@ -4999,6 +5002,50 @@ static int btrfs_uring_encoded_write(struct io_uring_cmd *cmd, unsigned int issu
 	return ret;
 }
 
+static int btrfs_uring_defrag(struct io_uring_cmd *cmd, unsigned int issue_flags)
+{
+	const size_t cmd_size = 2 * sizeof(struct io_uring_sqe) -
+				offsetof(struct io_uring_sqe, cmd);
+	const struct io_uring_sqe *sqe = cmd->sqe;
+	const struct btrfs_ioctl_defrag_range_args *args;
+	int ret;
+
+	/*
+	 * btrfs_ioctl_defrag() sleeps on the inode lock and on page reads, and
+	 * mnt_want_write_file() sleeps while the filesystem is frozen. We return
+	 * -EAGAIN so that io_uring issues the command again from io-wq.
+	 */
+	if (issue_flags & IO_URING_F_NONBLOCK)
+		return -EAGAIN;
+
+	/*
+	 * The arguments don't fit in the command area of a 64-byte SQE, so they
+	 * are passed inline in a 128-byte SQE. We don't take a pointer to the
+	 * arguments. io-wq would read them after io_uring_enter() has returned,
+	 * and the application may have reused the memory by then. io_uring
+	 * copies the SQE itself before it queues the command to io-wq.
+	 */
+	if (!(issue_flags & IO_URING_F_SQE128))
+		return -EINVAL;
+	if (sqe->addr || sqe->len || sqe->uring_cmd_flags || sqe->buf_index ||
+	    sqe->file_index)
+		return -EINVAL;
+	args = io_uring_sqe128_cmd(sqe, struct btrfs_ioctl_defrag_range_args);
+	if (memchr_inv(sqe->cmd + sizeof(*args), 0, cmd_size - sizeof(*args)))
+		return -EINVAL;
+
+	/*
+	 * The ioctl syscall calls the LSM ioctl hook before btrfs_ioctl(). We
+	 * call it too, so that a policy that denies the ioctl also denies the
+	 * command.
+	 */
+	ret = security_file_ioctl(cmd->file, BTRFS_IOC_DEFRAG_RANGE, 0);
+	if (ret)
+		return ret;
+
+	return btrfs_ioctl_defrag(cmd->file, NULL, args);
+}
+
 int btrfs_uring_cmd(struct io_uring_cmd *cmd, unsigned int issue_flags)
 {
 	if (btrfs_is_shutdown(inode_to_fs_info(file_inode(cmd->file))))
@@ -5016,6 +5063,9 @@ int btrfs_uring_cmd(struct io_uring_cmd *cmd, unsigned int issue_flags)
 	case BTRFS_IOC_ENCODED_WRITE_32:
 #endif
 		return btrfs_uring_encoded_write(cmd, issue_flags);
+
+	case BTRFS_IOC_DEFRAG_RANGE:
+		return btrfs_uring_defrag(cmd, issue_flags);
 	}
 
 	return -EINVAL;
@@ -5558,9 +5608,9 @@ long btrfs_ioctl(struct file *file, unsigned int
 	case BTRFS_IOC_DEFAULT_SUBVOL:
 		return btrfs_ioctl_default_subvol(file, argp);
 	case BTRFS_IOC_DEFRAG:
-		return btrfs_ioctl_defrag(file, NULL);
+		return btrfs_ioctl_defrag(file, NULL, NULL);
 	case BTRFS_IOC_DEFRAG_RANGE:
-		return btrfs_ioctl_defrag(file, argp);
+		return btrfs_ioctl_defrag(file, argp, NULL);
 	case BTRFS_IOC_RESIZE:
 		return btrfs_ioctl_resize(file, argp);
 	case BTRFS_IOC_ADD_DEV:

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261103-btrfs-uring-defrag-244c751865a5

Best regards,
--  
Daan De Meyer <daan@amutable.com>

