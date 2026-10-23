From: In-Ho Yi <chajath@gmail.com>
Date: Fri, 23 Oct 2026 12:01:14 -0700
Subject: [PATCH] ceph: drop local lock records on unlock when the inode is
 shut down
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-b4-ceph-lock-shutdown-v1-1-f9b1fd9ec026@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPmu22oC/yXMQQ6CMBBA0auQWTsJHYiiVzEsShnoqGlJB5SEc
 HerLN/i/w2Uk7DCrdgg8VtUYsgwpwKct2FklD4bqKSzKanCrkbHk8dXdE9Uv8x9/AQkso1tqsF
 cLwS5nRIPsv6/9/awLt2D3fybwb5/AVnniR95AAAA
X-Change-ID: 20261023-b4-ceph-lock-shutdown-22a8a83f1972
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: Jeff Layton <jlayton@kernel.org>, Chuck Lever <cel@kernel.org>, 
 ceph-devel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 In-Ho Yi <chajath@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792782073; l=7346;
 i=chajath@gmail.com; s=20261023; h=from:subject:message-id;
 bh=+pvZYq2uetz94bDu77OTApmOEKJmxic7xGUKyuCGZsU=;
 b=Rqo6VGr6IO5+tAuvi9T5578N78QGo8tFgPEsuDl7JtEauaFcqQtha9MP9taxnpE4knYG/8vC9
 rG5H1YuhaT+DIH6Nii0T9ateBSVKSomKTY2UWhzvqJUxh8bRP0EUg3F
X-Developer-Key: i=chajath@gmail.com; a=ed25519;
 pk=4pEtHrGeq+cVNkwaKkqXc/36aMjHqHRtQSsE85awtG0=
X-Endpoint-Received: by B4 Relay for chajath@gmail.com/20261023 with auth_id=1295
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_lock() and ceph_flock() return -ESTALE as soon as
ceph_inode_is_shutdown() is true. That refuses unlocks too, so the lock
record the VFS keeps for the inode is never removed.

On close, locks_remove_posix() and locks_remove_flock() send an F_UNLCK
through ->lock and ->flock and ignore the result: the filesystem has to
drop its local records whether or not the server can be told. nfs and
cifs do so, and ceph itself does when CEPH_I_ERROR_FILELOCK is set. On a
shut-down inode, __fput() only warns "Leaked POSIX lock" or "Leaked
FLOCK lock" and frees the file. The record stays on the inode's lock
list and on the global file_lock_list with flc_file pointing at the
freed file. It also keeps the inode reference taken by
ceph_fl_copy_lock(), so the final unmount reports "VFS: Busy inodes
after unmount of ceph", and nothing ever frees the record.

The next read of /proc/locks follows the stale flc_file. Once the
file's memory has been reused, lock_get_status() faults on the inode
pointer it reads from it, with file_rwsem held for write and
blocked_lock_lock held by locks_start(). After that oops every flock(),
fcntl() lock and /proc/locks read on the machine hangs:

  BUG: unable to handle page fault for address: 0000006600667248
  RIP: 0010:lock_get_status+0x124/0x340
  Call Trace:
   locks_show+0xaa/0x140
   seq_read_iter+0x2ce/0x4a0
   proc_reg_read_iter+0x5c/0xb0
   vfs_read+0x270/0x3a0

A mount is shut down by umount -f (ceph_umount_begin() runs even when
the unmount then fails with EBUSY), while a recover_session=clean
reconnect runs, and on CEPH_MOUNT_FENCE_IO; a single inode is shut down
when its async create fails. We hit this after the MDS blocklisted a
client: recovery ran umount -f on the dead mount while processes still
held flock() locks on it, and they closed their files later. The kernel
logged six "Leaked FLOCK lock" warnings after three such remounts.

Drop the local record for unlock requests before returning -ESTALE, as
the CEPH_I_ERROR_FILELOCK path already does.

Fixes: 5d6451b1489a ("ceph: shut down access to inode when async create fails")
Cc: stable@vger.kernel.org
Signed-off-by: In-Ho Yi <chajath@gmail.com>
---
We hit this on a CephFS kernel client running Ubuntu's 7.0.0-38 kernel,
whose fs/ceph/locks.c and fs/locks.c are identical to v7.0.

The MDS evicted and blocklisted the client. Our recovery ran umount -f
on the dead mount (it was busy, so it fell back to umount -l) while
processes on it still held flock() locks: the kernel logged "Leaked
FLOCK lock" six times, 25 to 45 minutes after each of three such
remounts (Oct 14, 15 and 16), on the three remounted superblocks
(dev 0x0:0x3c, 0x42, 0x43). Six days later the old
superblock's last user exited: "umount timed out", then "VFS: Busy
inodes after unmount of ceph". Seven hours after that, an awk reading
/proc/locks oopsed in lock_get_status() while holding file_rwsem and
blocked_lock_lock, and every file lock operation on the machine hung
until a power cycle.

In that build, lock_get_status+0x124 loads inode->i_sb, with inode =
flc->flc_file->f_inode read from freed and reused memory: a lock record
was still on file_lock_list after its file had been freed. The commit
message explains how ceph leaves it there. Since 5d6451b1489a,
ceph_lock() and ceph_flock() refuse unlocks with -ESTALE once the mount
is shut down, and the VFS ignores the result on close. The fix does
what the CEPH_I_ERROR_FILELOCK branch already does: drop the local
record, then return the error.

Testing: reproduced and verified in an arm64 VM on Ubuntu's
7.0.0-38-generic kernel (fs/ceph/locks.c and fs/locks.c as in v7.0),
with the kernel client on a single-node Ceph 19.2.3 (squid) cluster.
The steps were: take an flock() and an fcntl() write lock on CephFS,
run umount -f (it fails with EBUSY), kill the holders, run umount -l,
then read /proc/locks.

Without the patch (both the stock ceph.ko and a rebuild from the same
source), unlocks after umount -f fail with ESTALE. Each close logs
"Leaked FLOCK lock" or "Leaked POSIX lock", and the records stay in
/proc/locks under the dead owners' pids. Once their struct file slots
are reused, the records report other files' dev:ino. umount -l then
warns "VFS: Busy inodes after unmount of ceph". The next /proc/locks
read oopsed in lock_get_status(). Before the file memory was reused,
it faulted on the poisoned i_sb (dead000000000105). After churning the
filp slab, it faulted loading i_sb through a garbage f_inode, as in
our crash. Each time file locking then hung machine-wide. On a
KASAN + SLUB_RCU_DEBUG build of the same source, the first /proc/locks
read after the holders exited reported "slab-use-after-free in
lock_get_status": an 8-byte read of f_inode from a filp object freed
by the holder's __fput().

With the patch, the unlocks still return ESTALE but drop the records.
Nothing is leaked, /proc/locks stays clean under the same churn,
umount -l gives no busy inodes, and ceph.ko unloads cleanly (four
runs, plus one on the KASAN build with no report). Lock contention,
F_GETLK, unlock and close on a normal mount behave the same with and
without the patch. It also builds without warnings (W=1) for x86_64
on mainline 734bef548a96, but has not been run on x86_64.

The patch is against mainline 734bef548a96. It conflicts trivially with
the ceph_blog_exit() calls in ceph-client's testing branch; I have a
version against testing if that is easier to apply.

Jeff, Chuck: Cc'd for file locking, and Jeff as the author of
5d6451b1489a. locks_remove_file() already finds such leftover records
(that is what prints "Leaked ... lock") but leaves them linked to a
file that is about to be freed. Would you want it to unlink them as a
safety net? I can send that separately.
---
 fs/ceph/locks.c | 17 +++++++++++++++--
 1 file changed, 15 insertions(+), 2 deletions(-)

diff --git a/fs/ceph/locks.c b/fs/ceph/locks.c
index 677221bd64e..a4c1e3e5112 100644
--- a/fs/ceph/locks.c
+++ b/fs/ceph/locks.c
@@ -259,8 +259,17 @@ int ceph_lock(struct file *file, int cmd, struct file_lock *fl)
 	if (!(fl->c.flc_flags & FL_POSIX))
 		return -ENOLCK;
 
-	if (ceph_inode_is_shutdown(inode))
+	if (ceph_inode_is_shutdown(inode)) {
+		/*
+		 * The MDS can't be told any more, but an unlock must still
+		 * drop the local lock record: on close the VFS ignores our
+		 * return value and frees the file, and a record left behind
+		 * would keep pointing at it from the global lock list.
+		 */
+		if (!IS_GETLK(cmd) && lock_is_unlock(fl))
+			posix_lock_file(file, fl, NULL);
 		return -ESTALE;
+	}
 
 	doutc(cl, "fl_owner: %p\n", fl->c.flc_owner);
 
@@ -328,8 +337,12 @@ int ceph_flock(struct file *file, int cmd, struct file_lock *fl)
 	if (!(fl->c.flc_flags & FL_FLOCK))
 		return -ENOLCK;
 
-	if (ceph_inode_is_shutdown(inode))
+	if (ceph_inode_is_shutdown(inode)) {
+		/* See ceph_lock(): an unlock must drop the local record. */
+		if (lock_is_unlock(fl))
+			locks_lock_file_wait(file, fl);
 		return -ESTALE;
+	}
 
 	doutc(cl, "fl_file: %p\n", fl->c.flc_file);
 

---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261023-b4-ceph-lock-shutdown-22a8a83f1972

Best regards,
--  
In-Ho Yi <chajath@gmail.com>

