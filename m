From: Alexander Andreev <carzil@yandex.ru>
Date: Mon, 12 Oct 2026 00:12:40 +0300
Subject: [PATCH] xfs: return -EIO from xfs_log_force_inode() after a
 shutdown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-xfs-dir-fsync-shutdown-v1-1-79b5905f5280@yandex.ru>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ6DMAxA4asgz1hKIoTaXgUxQOwUdwgo5leIu
 ze04ze8d4JyElZ4FSckXkVljBm2LMAPXXwzCmWDM662xlrcgyJJwqBH9KjDMtO4Rawr6o17PEP
 lCHI8JQ6y/8ZN+7cu/Yf9fN/gur6M+3R3egAAAA==
X-Change-ID: 20261011-xfs-dir-fsync-shutdown-64db0289f42d
To: linux-xfs@vger.kernel.org
Cc: Carlos Maiolino <cem@kernel.org>, Dave Chinner <david@fromorbit.com>, 
 Christoph Hellwig <hch@lst.de>, linux-kernel@vger.kernel.org, 
 Alexander Andreev <carzil@yandex.ru>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791753183; l=4345;
 i=carzil@yandex.ru; s=20261011; h=from:subject:message-id;
 bh=LURA8bDLkdqfdDM1Pbeo2MYn4rNLssDbzZm/qD+GEZ4=;
 b=tLY4NEd50Ku6Gq1jkSMYdmTvdoMGBpYElx50ZrH34rKJfNi6hjUc8zzHFmuRwL2qanPA+xml+
 +D+6uhpf4VXDHd94T0XoTCbSIG1OEK9L6mEA/LSeFjjmcJekW+Y2HmR
X-Developer-Key: i=carzil@yandex.ru; a=ed25519;
 pk=sdOm34vmqWa+IJ2OaVfz4PiCxQffyz8vX78oj7ww7F0=
X-Endpoint-Received: by B4 Relay for carzil@yandex.ru/20261011 with auth_id=1162
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fsync() of a directory can return 0 after a log I/O error has shut the
filesystem down, although the change it was asked to persist never
reached the log:

  task A                          task B
  fd = open("dir")
  rename("dir/a", "dir/b")
                                  syncfs(fd2) = -EIO
                                  (log write fails, fs shut down)
  fsync(fd) = 0

Task B can be anything that writes the log: syncfs(2), fsync() of
another file, the background CIL push. Once the device is back and the
filesystem is mounted again, "dir/b" is gone.

xfs_dir_fsync() calls xfs_log_force_inode(), which forces the log only
if the inode has a commit sequence. The shutdown aborts the CIL and
unpins the inode, which clears the sequence, so there is nothing to
force. A sequence read just before the abort ends the same way, as
xlog_cil_force_seq() then returns NULLCOMMITLSN.

xfs_file_fsync() checks for a shutdown, but xfs_dir_fsync() does not.
Adding the check was discussed in 2014 [1].

Fix this by checking for a log shutdown in xfs_log_force_inode() after
the force. That also gives -EIO to its other callers that rely on it for
durability: NFS ->commit_metadata, fallocate() on synchronous files and
pNFS block allocation.

Link: https://lore.kernel.org/all/535E8344.2070209@redhat.com/ [1]
Fixes: 1da2f2dbf2d2 ("xfs: optimize fsync on directories")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Alexander Andreev <carzil@yandex.ru>
---
Found with fault injection on a network block device. On v7.3-rc6 the
reproducer below prints "fsync(dir) = 0" and the rename is gone after
the remount. With the patch fsync() returns EIO.
fstests on xfs: the same 13 of 1017 tests fail with and without the
patch in -g quick, and the same 2 of 127 in -g shutdown,log,recoveryloop.
If you want a new fstests test for this, I can send it as a separate
patch.

I don't know xfs well, so please tell me if this should be done
differently. An LLM helped trace the code and write the patch. I
reviewed and tested it.

#!/bin/bash
# fsync() of a directory returns 0 after a log I/O error, and the rename is lost.
# Usage: ./repro.sh xfs|ext4  (as root, needs dmsetup and python3)
set -e
fs=${1:-xfs}
img=/tmp/repro.img mnt=/tmp/repro.mnt dev=/dev/mapper/repro
sectors=$((512 * 2048))

# Swap the dm table under the mounted filesystem without freezing it.
dm_table() {
	dmsetup reload repro --table "0 $sectors $1"
	dmsetup suspend --nolockfs --noflush repro
	dmsetup resume repro
}

# A filesystem on dm-linear over a loop device, with "a" on disk.
rm -f $img && truncate -s 512M $img && mkdir -p $mnt
loop=$(losetup -f --show $img)
dmsetup create repro --table "0 $sectors linear $loop 0"
mkfs.$fs -q $dev && mount $dev $mnt
echo data > $mnt/a && sync -f $mnt

# Open the directory, rename a -> b, then make the device fail.
exec 3< $mnt
mv $mnt/a $mnt/b
dm_table error

# Something else hits the error first, then fsync() the open directory.
sync -f $mnt || true
if python3 -c 'import os; os.fsync(3)' 2>/dev/null; then
	echo "fsync(dir) = 0"
else
	echo "fsync(dir) failed"
fi
exec 3<&-

# Bring the device back: if fsync() returned 0, "b" must be there.
umount $mnt && dm_table "linear $loop 0" && mount $dev $mnt
ls $mnt
umount $mnt && dmsetup remove repro && losetup -d $loop
---
 fs/xfs/xfs_inode.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/fs/xfs/xfs_inode.c b/fs/xfs/xfs_inode.c
index 621513d72..bb3d727f6 100644
--- a/fs/xfs/xfs_inode.c
+++ b/fs/xfs/xfs_inode.c
@@ -2677,6 +2677,7 @@ xfs_log_force_inode(
 {
 	struct xfs_inode_log_item *iip = ip->i_itemp;
 	xfs_csn_t		seq = 0;
+	int			error = 0;
 
 	if (!iip)
 		return 0;
@@ -2685,9 +2686,12 @@ xfs_log_force_inode(
 	seq = iip->ili_commit_seq;
 	spin_unlock(&iip->ili_lock);
 
-	if (!seq)
-		return 0;
-	return xfs_log_force_seq(ip->i_mount, seq, XFS_LOG_SYNC, NULL);
+	if (seq)
+		error = xfs_log_force_seq(ip->i_mount, seq, XFS_LOG_SYNC, NULL);
+
+	if (!error && xlog_is_shutdown(ip->i_mount->m_log))
+		error = -EIO;
+	return error;
 }
 
 /*

---
base-commit: b88c841d11641923fa3a4da011d7202cd89df68a
change-id: 20261011-xfs-dir-fsync-shutdown-64db0289f42d

Best regards,
--  
Alexander Andreev <carzil@yandex.ru>

