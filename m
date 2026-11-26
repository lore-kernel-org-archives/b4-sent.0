From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Thu, 26 Nov 2026 21:29:24 +0100
Subject: [PATCH v2 1/4] common: add support for the ntfs driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-ntfs-reproducers-v2-1-7d5fa5a688b9@proton.me>
References: <20261126-ntfs-reproducers-v2-0-7d5fa5a688b9@proton.me>
In-Reply-To: <20261126-ntfs-reproducers-v2-0-7d5fa5a688b9@proton.me>
To: fstests@vger.kernel.org, Zorro Lang <zlang@kernel.org>
Cc: ntfs@lists.linux.dev, Namjae Jeon <linkinjeon@kernel.org>, 
 Hyunchul Lee <hyc.lee@gmail.com>, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6464;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=EJOWWC3+INgpg6US8htRjDSFVUJETm2MZUNjhCKiGF4=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmyOaUumFD+bta376opdS/OCdomL3XnzTj9nfsWs28pGO
 rMnVZyI6ChlYRDjYpAVU2Tp+H8jxCfk26dlcVp9MHNYmUCGMHBxCsBEOCcw/M9u/mDZmn384IQD
 EQXXg5PeLDna4PboGce6bT6dnnoMZn2MDIe+Pbq2gWnGvWfVXwPYnH9Ui18/aMjdqx2/pT94duN
 9Tk4A
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Volumes for the ntfs driver (fs/ntfs) are made and checked with mkfs.ntfs
and fsck.ntfs from ntfsprogs-plus, but FSTYP=ntfs only gets the generic
fallbacks today. mkfs.ntfs zeroes the whole device unless it is given
--quick and refuses a device that is not a partition unless it is given
--force, _scratch_mkfs_sized and _scratch_mkfs_blocksized skip every test
that calls them, and the tests that require metadata journaling run
although the driver only checks and empties $LogFile at mount and never
logs a change. Call mkfs.ntfs directly with --quick and --force and filter
its warnings about the device geometry, pass the size to mkfs.ntfs in
sectors of the size -s gives, or else of the device's, and the block size
as the cluster size unless MKFS_OPTIONS sets one (mkfs.ntfs refuses a
second -c), check that mkfs.ntfs and fsck.ntfs are installed, and list ntfs
among the filesystems without metadata journaling.
Pass -i in _mount() when FSTYP, or the base filesystem under overlayfs,
is ntfs, so that every mount and remount uses the kernel driver and never
a mount.ntfs helper, whatever the mount options are.
The check keeps the generic "fsck -t ntfs -n" path, which runs ntfsck.

Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 common/config |  9 +++++++++
 common/rc     | 52 +++++++++++++++++++++++++++++++++++++++++++++++++---
 2 files changed, 58 insertions(+), 3 deletions(-)

diff --git a/common/config b/common/config
index 69e5d833..8d5c7178 100644
--- a/common/config
+++ b/common/config
@@ -335,6 +335,8 @@ export MKFS_AFS_PROG="false"
 export MKFS_CIFS_PROG="false"
 export MKFS_OVERLAY_PROG="false"
 export MKFS_REISER4_PROG=$(type -P mkfs.reiser4)
+# shellcheck disable=SC2155 # written like the other _PROG lines
+export MKFS_NTFS_PROG=$(type -P mkfs.ntfs)
 export E2FSCK_PROG=$(type -P e2fsck)
 export TUNE2FS_PROG=$(type -P tune2fs)
 export FSCK_OVERLAY_PROG=$(type -P fsck.overlay)
@@ -409,6 +411,9 @@ _common_mount_opts()
 	ubifs)
 		echo $UBIFS_MOUNT_OPTIONS
 		;;
+	ntfs)
+		echo "$NTFS_MOUNT_OPTIONS"
+		;;
 	*)
 		;;
 	esac
@@ -550,6 +555,10 @@ _source_specific_fs()
 		;;
 	pvfs2)
 		;;
+	ntfs)
+		[ "$MKFS_NTFS_PROG" = "" ] && _fatal "mkfs.ntfs not found"
+		type -P fsck.ntfs >/dev/null || _fatal "fsck.ntfs not found"
+		;;
 	ubifs)
 		[ "$UBIUPDATEVOL_PROG" = "" ] && _fatal "ubiupdatevol not found"
 		. ./common/ubifs
diff --git a/common/rc b/common/rc
index 750a8d83..891ca779 100644
--- a/common/rc
+++ b/common/rc
@@ -310,10 +310,16 @@ _has_dmesg_since_option()
 
 _mount()
 {
-	$MOUNT_PROG "$@"
+	local opts=()
+
+	# mount(8) hands an ntfs mount to a mount.ntfs helper when one is
+	# installed; -i keeps every mount and remount on the kernel driver,
+	# including the base filesystem under overlayfs
+	[ "$FSTYP" = "ntfs" ] || [ "$OVL_BASE_FSTYP" = "ntfs" ] && opts=(-i)
+	$MOUNT_PROG "${opts[@]}" "$@"
 	ret=$?
 	if [ "$ret" -ne 0 ]; then
-		echo "\"$MOUNT_PROG $*\" failed at $(date)" >> "$seqres.mountfail?"
+		echo "\"$MOUNT_PROG ${opts[*]} $*\" failed at $(date)" >> "$seqres.mountfail?"
 		if _has_dmesg_since_option; then
 			dmesg --since '30s ago' >> "$seqres.mountfail?"
 		else
@@ -904,6 +910,10 @@ _test_mkfs()
     btrfs)
         $MKFS_BTRFS_PROG $MKFS_OPTIONS $* $TEST_DEV > /dev/null
 	;;
+    ntfs)
+	# shellcheck disable=SC2048,SC2086 # one word may hold several options
+	$MKFS_NTFS_PROG --quick --force $MKFS_OPTIONS $* "$TEST_DEV" > /dev/null
+	;;
     ext2|ext3|ext4)
 	$MKFS_PROG -t $FSTYP -- -F $MKFS_OPTIONS $* $TEST_DEV
 	;;
@@ -953,6 +963,10 @@ _try_mkfs_dev()
     btrfs)
         $MKFS_BTRFS_PROG $MKFS_OPTIONS $*
 	;;
+    ntfs)
+	# shellcheck disable=SC2048,SC2086 # one word may hold several options
+	$MKFS_NTFS_PROG --quick --force $MKFS_OPTIONS $*
+	;;
     ext2|ext3|ext4)
 	$MKFS_PROG -t $FSTYP -- -F $MKFS_OPTIONS $*
 	;;
@@ -1069,6 +1083,15 @@ _scratch_mkfs()
 		mkfs_cmd="$MKFS_BCACHEFS_PROG"
 		mkfs_filter="cat"
 		;;
+	ntfs)
+		# --quick skips zeroing the whole device, --force formats a
+		# device that is not a partition; drop the warnings about that
+		# and about the boot geometry of such a device
+		mkfs_cmd="$MKFS_NTFS_PROG --quick --force"
+		mkfs_filter="grep -v -e \"is entire device\" -e \"forced anyway\""
+		mkfs_filter+=" -e \"could not be obtained automatically\""
+		mkfs_filter+=" -e \"boot from\""
+		;;
 	*)
 		mkfs_cmd="yes | $MKFS_PROG -t $FSTYP --"
 		mkfs_filter="cat"
@@ -1313,6 +1336,9 @@ _try_scratch_mkfs_sized()
 		# If no block size is given by local.confg or parameter, blocksize_opt is empty.
 		# Let MKFS_BCACHEFS_PROG decide block size on its own.
 		;;
+	ntfs)
+		def_blksz=$(echo "$MKFS_OPTIONS" | sed -rn 's/(.* )?(-c|--cluster-size)[ =]?([0-9]+).*/\3/p')
+		;;
 	esac
 
 	[ -n "$def_blksz" ] && blocksize=$def_blksz
@@ -1425,6 +1451,19 @@ _try_scratch_mkfs_sized()
 	bcachefs)
 		$MKFS_BCACHEFS_PROG $MKFS_OPTIONS --fs_size=$fssize $blocksize_opt "$@" $SCRATCH_DEV
 		;;
+	ntfs)
+		# mkfs.ntfs refuses a second -c, and takes the size after the
+		# device, in sectors of the size -s gives or else of the device's
+		local cluster_opt=(-c "$blocksize")
+		local sector_size
+
+		sector_size=$(echo "$MKFS_OPTIONS" | sed -rn 's/(.* )?(-s|--sector-size)[ =]?([0-9]+).*/\3/p')
+		[ -n "$sector_size" ] || sector_size=$(blockdev --getss "$SCRATCH_DEV")
+		[ -n "$def_blksz" ] && cluster_opt=()
+		# shellcheck disable=SC2086 # MKFS_OPTIONS holds several options
+		$MKFS_NTFS_PROG --quick --force $MKFS_OPTIONS "${cluster_opt[@]}" "$@" \
+			"$SCRATCH_DEV" $((fssize / sector_size))
+		;;
 	*)
 		_notrun "Filesystem $FSTYP not supported in _scratch_mkfs_sized"
 		;;
@@ -1517,6 +1556,13 @@ _scratch_mkfs_blocksized()
 	udf)
 		_scratch_mkfs -b $blocksize
 		;;
+	ntfs)
+		# mkfs.ntfs refuses a second -c, so the size asked for here
+		# replaces one in MKFS_OPTIONS
+		MKFS_OPTIONS=$(echo "$MKFS_OPTIONS" | \
+			sed -E 's/(^| )(-c|--cluster-size)[ =]?[0-9]+//') \
+			_scratch_mkfs -c "$blocksize"
+		;;
 	*)
 		_notrun "Filesystem $FSTYP not supported in _scratch_mkfs_blocksized"
 		;;
@@ -4386,7 +4432,7 @@ _has_metadata_journaling()
 	fi
 
 	case "$FSTYP" in
-	ext2|vfat|msdos|udf|exfat|tmpfs|hfs|hfsplus)
+	ext2|vfat|msdos|udf|exfat|ntfs|tmpfs|hfs|hfsplus)
 		echo "$FSTYP does not support metadata journaling"
 		return 1
 		;;

-- 
2.56.1

