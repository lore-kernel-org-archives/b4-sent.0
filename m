From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 13 Oct 2026 16:28:52 +0900
Subject: [PATCH] ext4: spread files of sibling directories over a flex
 group
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-ialloc-flex-spread-v1-1-9ea1d86961aa@samsung.com>
X-B4-Tracking: v=1; b=H4sIALPdzWoC/x2MWwqAIBAArxL73YIPkOwq0YfaWgtioRBBePekz
 xmYeaFSYaowDy8UurnymTvIcYBwuLwT8tYZlFBGCqmRXUpnwJjowXoVchta66MxatLkNfSw28j
 PP13W1j4GiS1CZAAAAA==
To: Theodore Ts'o <tytso@mit.edu>, linux-ext4@vger.kernel.org
Cc: Andreas Dilger <adilger.kernel@dilger.ca>, 
 Baokun Li <libaokun@linux.alibaba.com>, Jan Kara <jack@suse.cz>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, 
 "Ritesh Harjani (IBM)" <ritesh.list@gmail.com>, 
 Zhang Yi <yi.zhang@huawei.com>, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791876531; l=13463;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=mg/jfcNmWC8pM2DqUSNjC3QdbFh17Yt6NVqwfCiSRWw=;
 b=DYXmceJO8oubJijr9D10tb4scZy6oHObK6+XrsbhEIPFW2aMqYGD2xksCvHgVaNKNCDO+7hyt
 31XhkmwsaF/BHnGW3EqJlGxvQVSXOKd91Kfn3ApJRS3e0c9HUtbcBiW
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a flex_bg file system, find_group_other() puts a new file in the
first group of the parent's flex group that has a free inode. Orlov
usually keeps a directory below the top level in its parent's flex group
and packs directory inodes at its start, so the files of sibling
directories come from the same group and get consecutive inode numbers.
The flex_bg path was added by commit a4912123b688 ("ext4: New
inode/block allocation algorithms for flex_bg filesystems"). The
non-flex_bg path instead adds the parent's inode number to the starting
group once the parent's own group has no free inode or block, so that
the files of different directories which share a group land in
different groups.

When several tasks create files in sibling directories at the same time,
their new inodes share inode table blocks. __ext4_get_inode_loc() skips
reading an inode table block only when no other inode in that block is
in use in the inode bitmap. The bit of another task's new inode defeats
that check, so the block is read from disk under the buffer lock while
the other creators wait for the lock. When the other inodes in use in
the block are new as well, as on a freshly made file system, the read
is wasted, because ext4_do_update_inode() clears the on-disk copy of a
new inode before filling it in.

With 16 tasks each creating 60000 empty files in its own directory under
a common parent on NVMe, the creators read inode table blocks from disk
50000 times, nine in ten of their context switches were in lock_buffer()
in __ext4_get_inode_loc(), and the throughput was 290k files/s.

Pick the group inside the flex group by the parent's inode number first.
When that group is full, keep using the group last picked for the
directory, and after that prefer a group with no inode in use, which no
other directory uses yet. Do the same inside the flex group last used
and inside the one Orlov picks when those are full. The inode tables of
a flex group are normally contiguous, so the inodes stay in the same
region of the disk (32MiB for 16 groups with the mke2fs defaults), and
the files of a directory mostly share inode table blocks with each other
rather than with other directories. The data block goal from
ext4_inode_to_goal_block() does not move for flex_bg sizes of 4 and
more: it starts regular files at the second group of the flex group
regardless of the inode's group. An external xattr block starts at the
inode's own group, and the mballoc stream goal slot is picked by inode
number.

In the test above, the creators read inode table blocks 260 to 530
times and the throughput is 780k files/s.

When find_group_other() fails in the last flex group and the number of
groups is a multiple of the flex size, it leaves *group, and so
i_last_alloc_group, equal to the number of groups: parent_group +
flex_size was reset to 0 only when it was larger, and
find_group_orlov() does not read the value. Nothing used that value as
a group before. The retry now passes it to find_group_in_flex() as the
first group of a flex group, so reset it when it is equal too, and
retry only with a group below the number of groups.

Update the description in Documentation/filesystems/ext4/allocators.rst.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested on ext4 dev 35aefefd7aba in a QEMU guest (32 vCPUs, 16G) with
a Samsung 990 PRO partition passed through (cache=none, aio=native),
mkfs.ext4 -E nodiscard with otherwise default options on 64G (4k
blocks, flex_bg size 16), mounted with -o noinit_itable to keep the
background inode table zeroing out of the timing, three runs each. Each
task creates 60000 empty files with open(O_CREAT | O_EXCL) and close()
in its own directory p/d<i>. "reads" are ext4_load_inode events during
the creates, which matched the read I/Os on the disk there.

  tasks  before                         after
      8  238k-244k files/s, 17.5k-18.3k  373k-403k files/s, 1.2k-1.8k
     16  290k-292k files/s, 49.6k-50.6k  779k-783k files/s, 0.3k-0.5k
     32  457k-459k files/s, 102k         984k-1023k files/s, 15.5k-16.3k

With the default mount options, 16 tasks: 286k-288k files/s before and
774k-782k after (ext4lazyinit zeroed 164-230 and 53-79 inode tables
during the runs).

After a remount (first run of 8/16/32 tasks), "ls -l" of one of those
directories took 0.61/0.76/1.04 s before and 0.50/0.49/0.50 s after
(read I/Os 3093/5879/11357 before, 805/757/1209 after). stat of every
file took 2.63/5.77/10.93 s before and 2.75/5.49/11.37 s after (one run
each), and e2fsck -fn the same or slightly less time.

Extracting a kernel tree (96039 files, 6283 directories) with one tar
took 2.3 s before (one 3.5 s first run) and 2.2-2.3 s after. With 8 tars
into sibling directories at once: 6.5-8.0 s before, 6.0-6.1 s after,
inode table reads 20.5k-22.6k before and 1.4k-1.6k after. After a
remount, stat of every file, "du -s drivers/" and e2fsck -fn took the
same time, but inode table loads went up 7-33% and read I/Os 0.5-7%,
presumably because a directory's files are no longer in the directory's
own group.

16 tasks writing 256 files of 1 MiB each (fallocate, buffered, O_DIRECT)
or 32 files of 16 MiB (buffered), one directory each: the same or less
time, the same extents per file and one group scanned per allocation in
mb_stats on both.

After deleting half of the files of each of 16 directories and
remounting, refilling the holes with 16 tasks (file-backed, three runs)
took 0.60-0.70 s before and 0.27 s after, with 12.1k-12.6k read I/Os
before and 3.0k-3.2k after.

One task creating 600000 files round-robin over 16 or 100 sibling
directories (commit=1, file-backed, two runs): the same time and the
same journal blocks per transaction. 16 tasks with mkfs -G 4 and -G 64
(file-backed, one run each): 49840 -> 23506 and 49926 -> 1164 inode
table reads; with -G 256 (three runs): 287k-331k files/s and 49.3k-49.9k
reads before, 788k-800k files/s and 0-101 reads after. Running out of
inodes with 1 to 16 creators (4G with -N 32768, 2G with -N 16384, one
run each) creates the same number of files on both, with no EXT4-fs
error, WARNING or BUG in dmesg. mkfs -O ^flex_bg is unchanged.

xfstests -g quick (MKFS_OPTIONS=-F, TEST_DEV with -O fast_commit): the
same results before and after, 341 passed, 335 not run, generic/563 and
generic/791 fail on both (no CONFIG_CGROUP_WRITEBACK and no
CONFIG_FANOTIFY in the test kernel).

Why not skip the read in __ext4_get_inode_loc() instead: the inode
bitmap and bg_itable_unused cannot tell a new inode that is still being
set up from one on disk. The inode cache could (EXT4_STATE_NEW, as
ext4_update_other_inodes_time() looks up the other inodes of a block),
but only helps when every other inode in the block is new. Spreading
also helps when they are old files (the hole refill above) and makes a
cold "ls -l" of one directory faster. Creators in a single directory do
not hit this; the VFS serializes them.

Rotating disks were not tested. This is the case of
https://lore.kernel.org/r/20131001160817.GA2295@kvack.org (round-robin
creates over 100 directories), but the patch does not spread across
flex groups, so the inodes stay within the flex group's inode tables,
and the first data block goal does not change.

Per directory rather than per CPU or hash slot as suggested in
https://lore.kernel.org/r/6200e067-0ad1-4dc4-9694-05ee1e977f4c@huawei.com:
a directory's files stay together for later lookups. It does change
which mballoc stream goal slot (i_ino % s_mb_nr_global_goals)
concurrently created files use: with 8192 inodes per group and 32
slots, the n-th file of every sibling directory now has the same slot.
The large-file runs above show no difference in time or extents.
---
 Documentation/filesystems/ext4/allocators.rst |  6 +-
 fs/ext4/ialloc.c                              | 91 ++++++++++++++++++++++-----
 2 files changed, 80 insertions(+), 17 deletions(-)

diff --git a/Documentation/filesystems/ext4/allocators.rst b/Documentation/filesystems/ext4/allocators.rst
index 7aa85152ac..70a3930ca5 100644
--- a/Documentation/filesystems/ext4/allocators.rst
+++ b/Documentation/filesystems/ext4/allocators.rst
@@ -38,7 +38,11 @@ file's data blocks to begin I/O operations.
 The fourth trick is that all the inodes in a directory are placed in the
 same block group as the directory, when feasible. The working assumption
 here is that all the files in a directory might be related, therefore it
-is useful to try to keep them all together.
+is useful to try to keep them all together. With flex_bg, the files of a
+directory are kept in the directory's flex group instead, in a block
+group chosen by the directory's inode number, so that the files of
+different directories in the same flex group are less likely to share
+inode table blocks.
 
 The fifth trick is that the disk volume is cut up into 128MB block
 groups; these mini-containers are used as outlined above to try to
diff --git a/fs/ext4/ialloc.c b/fs/ext4/ialloc.c
index f97a2f4904..fbe11dcd03 100644
--- a/fs/ext4/ialloc.c
+++ b/fs/ext4/ialloc.c
@@ -569,11 +569,70 @@ static int find_group_orlov(struct super_block *sb, struct inode *parent,
 	return -1;
 }
 
+static bool ext4_group_has_free_inode(struct super_block *sb, ext4_group_t g)
+{
+	struct ext4_group_desc *desc = ext4_get_group_desc(sb, g, NULL);
+
+	return desc && ext4_free_inodes_count(sb, desc);
+}
+
+/*
+ * Pick a group with a free inode in the flex group that starts at @first.
+ * First try the group chosen by the parent's inode number, so that the
+ * files of different directories in a flex group are less likely to share
+ * an inode bitmap and inode table blocks. Once that group is full, keep
+ * using @last, the group last picked for this directory, if it is in this
+ * flex group, then prefer a group with no inode in use, which no other
+ * directory uses yet, then take any group with a free inode. Return -1 if
+ * no group in the flex group has a free inode.
+ */
+static int find_group_in_flex(struct super_block *sb, struct inode *parent,
+			      ext4_group_t first, ext4_group_t last,
+			      int flex_size, ext4_group_t *group)
+{
+	ext4_group_t ngroups = ext4_get_groups_count(sb);
+	ext4_group_t n = min_t(ext4_group_t, flex_size, ngroups - first);
+	ext4_group_t start = (unsigned int)parent->i_ino % n;
+	ext4_group_t i, g, avail = ngroups;
+
+	if (ext4_group_has_free_inode(sb, first + start)) {
+		*group = first + start;
+		return 0;
+	}
+	if (last >= first && last < first + n &&
+	    ext4_group_has_free_inode(sb, last)) {
+		*group = last;
+		return 0;
+	}
+	for (i = 1; i < n; i++) {
+		struct ext4_group_desc *desc;
+		unsigned int nr_free;
+
+		if (++start == n)
+			start = 0;
+		g = first + start;
+		desc = ext4_get_group_desc(sb, g, NULL);
+		if (!desc)
+			continue;
+		nr_free = ext4_free_inodes_count(sb, desc);
+		if (nr_free == EXT4_INODES_PER_GROUP(sb)) {
+			*group = g;
+			return 0;
+		}
+		if (nr_free && avail == ngroups)
+			avail = g;
+	}
+	if (avail == ngroups)
+		return -1;
+	*group = avail;
+	return 0;
+}
+
 static int find_group_other(struct super_block *sb, struct inode *parent,
 			    ext4_group_t *group, umode_t mode)
 {
 	ext4_group_t parent_group = EXT4_I(parent)->i_block_group;
-	ext4_group_t i, last, ngroups = ext4_get_groups_count(sb);
+	ext4_group_t i, ngroups = ext4_get_groups_count(sb);
 	struct ext4_group_desc *desc;
 	int flex_size = ext4_flex_bg_size(EXT4_SB(sb));
 
@@ -585,34 +644,34 @@ static int find_group_other(struct super_block *sb, struct inode *parent,
 	 * group for future allocations.
 	 */
 	if (flex_size > 1) {
+		ext4_group_t last_alloc = EXT4_I(parent)->i_last_alloc_group;
 		int retry = 0;
 
 	try_again:
 		parent_group &= ~(flex_size-1);
-		last = parent_group + flex_size;
-		if (last > ngroups)
-			last = ngroups;
-		for  (i = parent_group; i < last; i++) {
-			desc = ext4_get_group_desc(sb, i, NULL);
-			if (desc && ext4_free_inodes_count(sb, desc)) {
-				*group = i;
-				return 0;
-			}
-		}
-		if (!retry && EXT4_I(parent)->i_last_alloc_group != ~0) {
+		if (!find_group_in_flex(sb, parent, parent_group, last_alloc,
+					flex_size, group))
+			return 0;
+		if (!retry && last_alloc < ngroups) {
 			retry = 1;
-			parent_group = EXT4_I(parent)->i_last_alloc_group;
+			parent_group = last_alloc;
 			goto try_again;
 		}
 		/*
 		 * If this didn't work, use the Orlov search algorithm
 		 * to find a new flex group; we pass in the mode to
-		 * avoid the topdir algorithms.
+		 * avoid the topdir algorithms. Then pick the group inside
+		 * the flex group Orlov chose the same way as above.
 		 */
 		*group = parent_group + flex_size;
-		if (*group > ngroups)
+		if (*group >= ngroups)
 			*group = 0;
-		return find_group_orlov(sb, parent, group, mode, NULL);
+		if (find_group_orlov(sb, parent, group, mode, NULL))
+			return -1;
+		/* Keep Orlov's group if its flex group has no free inode now */
+		find_group_in_flex(sb, parent, *group & ~(flex_size - 1),
+				   last_alloc, flex_size, group);
+		return 0;
 	}
 
 	/*

---
base-commit: 35aefefd7aba0801bab635b11943f932626be3b2
change-id: 20261013-ialloc-flex-spread-99bf66283eb3

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

