From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH v2 0/2] ceph: keep the inode, not the name, when a dentry
 lease expires
Date: Tue, 25 Aug 2026 22:23:36 -0700
Message-Id: <20260825-b4-b4-ceph-dentry-caps-v2-0-41201d7a4868@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7RhaiwVX3sOwKNNBapSSFomEc
 HcpHsDkb17y/38LRA6OI1yyBQJPLjrfbyAPGVBn+jujsxuDzOU5L6XARqUQDx1a7scwI5khorF
 K6ZOybMoCtvEQuHWf/fhW/zi+mwfTmN5So3Nx9GHezZNIvb+SSaDAtq0arQshqNJXes7RH8m/o
 F7X9QuHbja9zgAAAA==
X-Change-ID: 20260821-b4-b4-ceph-dentry-caps-ad44734dea85
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, Jeff Layton <jlayton@kernel.org>, 
 David Howells <dhowells@redhat.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787721829; l=18593;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=3bxbsZifR+DARcFgAmWmnZqBvXUAl6HcHWDJqi9RwQ0=;
 b=zoTafdRW+lYVA2YH6G6D8NFiDFbqd8fQNuYuxjQCUCUl8SkJxUk1QnemyIwMQDbiBVFDkU9XB
 pXM/zyLtuuMCXEFH+wbVTTkiyh+c+vhz4BFbChJFLUvghk5d/N54of2
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a dentry lease expires, ceph_d_delete() unhashes the dentry and,
because ceph uses inode_just_drop() for ->drop_inode, that last dput()
evicts the inode too, discarding a page cache that the inode's caps
still vouch for.  A workload that opens and closes files repeatedly
therefore re-reads everything from the OSDs after every dentry purge
(30s lease by default on the MDS side), even though both the caps and
the pages were still valid.

v1 kept the expired name hashed in the dcache instead.  Alex Markuze
pointed out that this breaks the d_find_alias()-based cap auth in
ceph_open() and __ceph_setattr(), and that the retention bound claimed
in the changelog did not exist.  v2 therefore leaves dentry lifetime
alone and moves the retention to the inode: the expired dentry is
unhashed exactly as before, and the next lookup reattaches to the same
inode via iget5_locked() on the vino, with the page cache intact.

Patch 1 marks the superblock active after mounting.  ceph_get_tree()
calls sget_fc() directly and so never goes through vfs_get_super(),
which is what sets SB_ACTIVE; the flag has been missing since the new
mount API conversion (Fixes: 82995cc6c5ae) and the bug was invisible
because ceph's ->drop_inode() always asked for eviction.  Patch 2 makes
->drop_inode() able to retain inodes, so it needs the flag to work.

Patch 2 restores ceph_drop_inode() (removed in 52dd0f1b3f94) and keeps
a regular file's inode while it still has cached pages and still holds
real caps.  The retention is bounded by the page cache itself: an
inode holding real folios is not shrinkable, so page reclaim empties
the mapping first and only then can the inode shrinker evict it, and
unmount evicts it regardless.  trim_caps_cb() gets an explicit
override in the one-shot CEPH_I_EVICT_ON_FINAL_IPUT_BIT, which
ceph_drop_inode() consumes with test_and_clear_bit(), so an MDS cap
recall still evicts the inode and releases its caps.

Verified on a vstart cluster: after drop_caches the inode and its cap
survive and a reopen is served from the page cache (no OSD reads); an
MDS cap recall runs the full chain (trim_caps_cb -> EVICT_ON_FINAL_IPUT
-> ceph_drop_inode -> ceph_evict_inode -> __ceph_remove_caps) in both
the no-alias and the d_prune_aliases() cases; and the reopen after the
trim reads from the OSDs again.

---
Changes in v2:
- dropped the dentry change entirely; expired names are unhashed
  exactly as before, so d_find_alias() never sees a stale hashed name
- moved the retention from dentry lifetime to inode lifetime (restore
  ceph_drop_inode())
- added patch 1 fixing the missing SB_ACTIVE, a prerequisite for the
  retain branch in iput_final()
- replaced the bogus 60s caps_wanted_delay_max bound with a bound by
  the page cache itself
- Link to v1: https://patch.msgid.link/20260821-b4-b4-ceph-dentry-caps-v1-1-ff9b77511c97@clyso.com

Test program
------------
The script below runs the whole scenario on a vstart cluster and prints
PASS/FAIL per case (Test C: retention, MDS recall override, post-trim
re-read from the OSDs; Test B: both trim_caps_cb() exits).  The last
section needs the CEPHDBG debug patch included below (not part of this
series) to print the per-inode chain from dmesg.

#!/bin/bash
#
# Test B/C for "ceph: keep the inode, not the name, when a dentry lease
# expires".
#
# Build the test kernel with /tmp/ceph-v2-debug-trace.patch applied and
# run this on the client:
#
#     sudo bash /tmp/ceph-v2-test-bc.sh <cephfs-mountpoint> [mds-rank]
#
# Test C proves the retention + MDS-trim-override lifecycle:
#   write+close -> dentry/prune -> reopen reads page cache (no OSD read)
#   -> MDS cap recall -> inode evicted, its cap line gone from
#   /sys/kernel/debug/ceph/*/caps -> reopen reads from OSDs again.
#
# Test B covers the two trim_caps_cb() exits:
#   case 1: no alias at all   (drop_caches=2 frees the dentry, the parked
#                               inode keeps its pages, so it is NOT on the
#                               inode LRU and survives)
#   case 2: alias still present (d_prune_aliases() path)
#
# Each case prints PASS/FAIL. With the debug patch, dmesg should show the
# full chain per inode:
#   CEPHDBG trim_caps X set EVICT_ON_FINAL_IPUT
#   CEPHDBG drop_inode X consumed EVICT_ON_FINAL_IPUT -> drop
#   CEPHDBG evict_inode X
#   CEPHDBG remove_caps X

set -u

MNT="${1:?usage: $0 <cephfs-mountpoint> [mds-rank]}"
MDS_RANK="${2:-0}"

# Prefer the system ceph CLI (it knows /etc/ceph/ceph.conf); the
# developer-mode build CLI needs the cluster conf on its own.  Override
# with CEPH_CLI=/path/to/ceph if needed.
CEPH_CLI="${CEPH_CLI:-}"
if [ -z "$CEPH_CLI" ]; then
	CEPH_CLI=$(command -v ceph)
	[ -n "$CEPH_CLI" ] || CEPH_CLI="/home/xiubli/workspace/ceph/build/bin/ceph"
fi
[ -x "$CEPH_CLI" ] || { echo "SKIP: ceph CLI not found (set CEPH_CLI=/path/to/ceph)"; exit 2; }

# The client's debugfs dir is named <fsid>.<clientid>; pick the one for
# this mount.  The fsid lives in the device field of /proc/mounts, e.g.
#   admin@0819baf2-55c8-40c7-a480-3ff47b20180d.a=/   (or with a mon list
#   and optional @ before the fsid, as in mon1,mon2@<fsid>.a=/).
CFG="$(grep -m1 " $MNT " /proc/mounts)"
FSID=$(echo "$CFG" | awk '{print $1}' | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')
[ -n "$FSID" ] || { echo "FAIL: cannot find fsid for $MNT"; exit 2; }
DBG=$(find /sys/kernel/debug/ceph -maxdepth 1 -type d -name "$FSID.*" 2>/dev/null | head -1)
[ -d "$DBG" ] || { echo "FAIL: no debugfs dir for $MNT (is debugfs mounted?)"; exit 2; }

CAPS="$DBG/caps"
METRICS_FILE="$DBG/metrics/file"
METRICS_LAT="$DBG/metrics/latency"

WORK="$MNT/.v2-retention-test.$$"
FILE="$WORK/t.bin"
SIZE=$((4*1024*1024))

fail() { echo "FAIL: $*"; exit 1; }

# per-inode cap line from debugfs caps: "0x<ino> <mds> <issued> <implemented>"
cap_line_for() {
	local ino="$1"
	grep -E "^0x$ino " "$CAPS" || true
}

# per-inode debug line from dmesg
dmesg_line_for() {
	dmesg | grep -E "$1" | tail -1
}

wait_for() { # desc, timeout_s, check_fn...
	local desc="$1" timeout="$2"; shift 2
	local deadline=$((SECONDS + timeout))
	while ! "$@" 2>/dev/null; do
		[ $SECONDS -lt $deadline ] || return 1
		sleep 1
	done
	return 0
}

reads_total() { awk '/^read[ \t]/{print $2}' "$METRICS_LAT" | head -1; }
inodes_total() { awk '/total inodes/{print $3}' "$METRICS_FILE"; }

# Trigger an MDS cap recall.  The MDS only recalls a session down to
# mds_min_caps_per_client caps (default 100), so a kernel client with a
# handful of caps must have both knobs lowered: mds_recall_max_caps so
# one recall message is enough, and mds_min_caps_per_client so the
# session may actually be trimmed.  Old values are restored at exit.
RECALL_OLD_MAX=""
RECALL_OLD_MIN=""

recall_caps() {
	RECALL_OLD_MAX=$("$CEPH_CLI" config get mds mds_recall_max_caps 2>/dev/null | tail -1)
	RECALL_OLD_MIN=$("$CEPH_CLI" config get mds mds_min_caps_per_client 2>/dev/null | tail -1)
	[ -n "$RECALL_OLD_MAX" ] || RECALL_OLD_MAX=30000
	[ -n "$RECALL_OLD_MIN" ] || RECALL_OLD_MIN=100
	# Lower the knobs FIRST: with the defaults the MDS answers "Success"
	# but recalls 0 caps, because mds_min_caps_per_client is the floor a
	# session is never trimmed below.
	if ! "$CEPH_CLI" config set mds mds_recall_max_caps 1 >/dev/null 2>&1; then
		return 1
	fi
	if ! "$CEPH_CLI" config set mds mds_min_caps_per_client 0 >/dev/null 2>&1; then
		return 1
	fi
	"$CEPH_CLI" tell "mds.${MDS_RANK}" cache drop >/dev/null 2>&1 || return 1
	return 0
}

restore_recall() {
	if [ -n "$RECALL_OLD_MAX" ]; then
		"$CEPH_CLI" config set mds mds_recall_max_caps "$RECALL_OLD_MAX" >/dev/null 2>&1 || true
	fi
	if [ -n "$RECALL_OLD_MIN" ]; then
		"$CEPH_CLI" config set mds mds_min_caps_per_client "$RECALL_OLD_MIN" >/dev/null 2>&1 || true
	fi
	RECALL_OLD_MAX=""
	RECALL_OLD_MIN=""
}
trap restore_recall EXIT

# --- setup ---------------------------------------------------------------
mkdir -p "$WORK" || fail "mkdir $WORK"
dd if=/dev/urandom of="$FILE" bs=1M count=$((SIZE/1024/1024)) status=none || fail dd
ino=$(stat -c %i "$FILE")
INOX=$(printf '%llx' "$ino")

echo "== mount=$MNT debugfs=$DBG ino=0x$INOX size=$SIZE =="
echo "== MDS knobs: recall_max_caps=$("$CEPH_CLI" config get mds mds_recall_max_caps 2>/dev/null | tail -1) min_caps_per_client=$("$CEPH_CLI" config get mds mds_min_caps_per_client 2>/dev/null | tail -1) =="

# --- Test C: retention, then trim, then OSD read --------------------------
echo
echo "== Test C: page cache retained, trim override, re-read from OSD =="

rm -f /tmp/v2-test-read.$$ /tmp/v2-test-read2.$$
dd if=/dev/urandom of="$FILE" bs=1M count=$((SIZE/1024/1024)) conv=notrunc status=none
sync
echo 1 > /proc/sys/vm/drop_caches   # force the first read to go to the OSDs
cat "$FILE" > /tmp/v2-test-read.$$ || fail "read 1"
R0=$(reads_total); [ -n "$R0" ] || fail "cannot read metrics/latency"
echo "  reads after first read:   $R0"

# Free the dentry; the inode keeps its pages, so it must NOT be evicted.
echo 2 > /proc/sys/vm/drop_caches
sleep 1
I1=$(inodes_total)
[ "$(cap_line_for "$INOX")" ] || fail "cap already gone after drop_caches"
# NB: "total inodes" is not a reliable retention signal: it has been
# observed reading 0 while a live inode with a cap is still cached
# (the metric drifts across recall/evict cycles).  The cap line above
# and the read counts below are the real assertions.
[ -n "$I1" ] && (( I1 >= 1 )) \
	|| echo "  note: total inodes = ${I1:-?} (metric unreliable on this box, ignoring)"

cat "$FILE" > /tmp/v2-test-read2.$$ || fail "read 2"
R1=$(reads_total)
echo "  reads after reopen:       $R1"
if [ "$R1" -eq "$R0" ]; then
	echo "  PASS: reopen served from page cache (no OSD read)"
else
	fail "reopen read from OSDs ($R0 -> $R1)"
fi

recall_caps || fail "could not trigger MDS cap recall"
wait_for "cap removed after recall" 30 test -z "$(cap_line_for "$INOX")" \
	|| fail "cap line for 0x$INOX still present 30s after recall"
I2=$(inodes_total)
[ "$I2" -lt "$I1" ] 2>/dev/null \
	|| echo "  note: total inodes $I1 -> $I2 (did not drop?)"
echo "  PASS: recall evicted the inode and its cap"

cat "$FILE" > /tmp/v2-test-read3.$$ || fail "read 3"
R2=$(reads_total)
echo "  reads after post-trim reopen: $R2"
if [ "$R2" -gt "$R1" ]; then
	echo "  PASS: post-trim reopen read from OSDs"
else
	fail "post-trim reopen did not read from OSDs ($R1 -> $R2)"
fi

echo
echo "== Test B: the two trim_caps_cb() exits =="

# --- Test B case 2: alias still present -----------------------------------
echo "-- case 2: alias present (d_prune_aliases path) --"
echo 3 > /proc/sys/vm/drop_caches
dd if=/dev/urandom of="$FILE" bs=1M count=$((SIZE/1024/1024)) conv=notrunc status=none
cat "$FILE" > /dev/null
# keep the dentry around (no drop_caches after this)
[ "$(cap_line_for "$INOX")" ] || fail "no cap after setup (case 2)"
recall_caps || fail "recall (case 2)"
if wait_for "cap removed" 30 test -z "$(cap_line_for "$INOX")"; then
	echo "  PASS: d_prune_aliases + EVICT_ON_FINAL_IPUT released the cap"
else
	echo "  FAIL: cap still present 30s after recall"
fi

# --- Test B case 1: no alias at all ---------------------------------------
echo "-- case 1: no alias (d_find_any_alias() == NULL path) --"
dd if=/dev/urandom of="$FILE" bs=1M count=$((SIZE/1024/1024)) conv=notrunc status=none
cat "$FILE" > /dev/null
echo 2 > /proc/sys/vm/drop_caches       # dentry gone, pages stay, inode parked
sleep 1
[ "$(cap_line_for "$INOX")" ] || fail "no cap after setup (case 1)"
recall_caps || fail "recall (case 1)"
if wait_for "cap removed" 30 test -z "$(cap_line_for "$INOX")"; then
	echo "  PASS: no-alias parked inode was marked and evicted"
else
	echo "  FAIL: no-alias inode keeps its cap 30s after recall"
fi

# --- dmesg chain (debug patch only) ---------------------------------------
echo
echo "== dmesg chain for 0x$INOX (expect all four lines, in this order) =="
for pat in "CEPHDBG trim_caps ${INOX}" \
	   "CEPHDBG drop_inode ${INOX}.*consumed" \
	   "CEPHDBG evict_inode ${INOX}" \
	   "CEPHDBG remove_caps ${INOX}"; do
	dmesg_line_for "$pat" || echo "  (no CEPHDBG line matching: '$pat' — debug patch not applied?)"
done

# --- cleanup ---------------------------------------------------------------
rm -rf "$WORK" /tmp/v2-test-read.$$ /tmp/v2-test-read2.$$ /tmp/v2-test-read3.$$
echo
echo "== done =="

Debug patch
-----------
Apply to the test kernel to get the CEPHDBG per-inode chain in dmesg.
Not part of this series.

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index 6466e11ca783..ba3a373342b8 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1427,6 +1427,7 @@ void __ceph_remove_caps(struct ceph_inode_info *ci)
 	/* lock i_ceph_lock, because ceph_d_revalidate(..., LOOKUP_RCU)
 	 * may call __ceph_caps_issued_mask() on a freeing inode. */
 	spin_lock(&ci->i_ceph_lock);
+	pr_info("CEPHDBG remove_caps %llx.%llx\n", ceph_vinop(inode));
 	p = rb_first(&ci->i_caps);
 	while (p) {
 		struct ceph_cap *cap = rb_entry(p, struct ceph_cap, ci_node);
diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index 0b1aaf38886f..8a0fedc1635e 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -741,6 +741,7 @@ void ceph_evict_inode(struct inode *inode)
 	struct rb_node *n;

 	doutc(cl, "%p ino %llx.%llx\n", inode, ceph_vinop(inode));
+	pr_info("CEPHDBG evict_inode %llx.%llx\n", ceph_vinop(inode));

 	percpu_counter_dec(&mdsc->metric.total_inodes);

@@ -820,11 +821,15 @@ void ceph_evict_inode(struct inode *inode)
 int ceph_drop_inode(struct inode *inode)
 {
 	struct ceph_inode_info *ci = ceph_inode(inode);
+	int ret;

 	/* the MDS asked for this one back */
 	if (test_and_clear_bit(CEPH_I_EVICT_ON_FINAL_IPUT_BIT,
-			       &ci->i_ceph_flags))
+			       &ci->i_ceph_flags)) {
+		pr_info("CEPHDBG drop_inode %llx.%llx consumed EVICT_ON_FINAL_IPUT -> drop\n",
+			ceph_vinop(inode));
 		return 1;
+	}

 	if (inode_generic_drop(inode))
 		return 1;
@@ -837,7 +842,17 @@ int ceph_drop_inode(struct inode *inode)
 		return 1;

 	/* keep the pages only while the inode still holds real caps */
-	return !__ceph_is_any_real_caps(ci);
+	ret = !__ceph_is_any_real_caps(ci);
+	pr_info("CEPHDBG drop_inode %llx.%llx nrpages=%lu -> %s\n",
+		ceph_vinop(inode), inode->i_data.nrpages,
+		ret ? "drop" : "KEEP");
+	if (!ret)
+		pr_info("CEPHDBG keep_state %llx.%llx state=%#lx shrinkable=%d empty=%d caps=%d\n",
+			ceph_vinop(inode), inode_state_read(inode),
+			mapping_shrinkable(&inode->i_data),
+			mapping_empty(&inode->i_data),
+			__ceph_is_any_real_caps(ci));
+	return ret;
 }

 static inline blkcnt_t calc_inode_blocks(u64 size)
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index f5d0590df8b2..20463e229ce4 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -2346,9 +2346,12 @@ static int trim_caps_cb(struct inode *inode, int mds, void *arg)
 			 * then runs ceph_evict_inode(), which is what hands
 			 * the cap back.
 			 */
-			if (S_ISREG(inode->i_mode) && inode->i_data.nrpages)
+			if (S_ISREG(inode->i_mode) && inode->i_data.nrpages) {
 				set_bit(CEPH_I_EVICT_ON_FINAL_IPUT_BIT,
 					&ci->i_ceph_flags);
+				pr_info("CEPHDBG trim_caps %llx.%llx set EVICT_ON_FINAL_IPUT\n",
+					ceph_vinop(inode));
+			}

 			count = icount_read_once(inode);
 			if (count == 1)
diff --git a/fs/inode.c b/fs/inode.c
index 31c5b9ee3a81..7c691510e094 100644
--- a/fs/inode.c
+++ b/fs/inode.c
@@ -23,6 +23,7 @@
 #include <linux/rw_hint.h>
 #include <linux/seq_file.h>
 #include <linux/debugfs.h>
+#include <linux/magic.h>	/* CEPHDBG test probe only */
 #include <trace/events/writeback.h>
 #define CREATE_TRACE_POINTS
 #include <trace/events/timestamp.h>
@@ -990,6 +991,12 @@ static enum lru_status inode_lru_isolate(struct list_head *item,
 	}

 	WARN_ON(inode_state_read(inode) & I_NEW);
+	pr_info("CEPHDBG lru_evict ino=%lx state=%#lx nrpages=%lu shrinkable=%d empty=%d count=%d\n",
+		inode->i_ino, inode_state_read(inode),
+		inode->i_data.nrpages,
+		mapping_shrinkable(&inode->i_data),
+		mapping_empty(&inode->i_data),
+		icount_read(inode));
 	inode_state_set(inode, I_FREEING);
 	list_lru_isolate_move(lru, &inode->i_lru, freeable);
 	spin_unlock(&inode->i_lock);
@@ -1986,6 +1993,13 @@ static void iput_final(struct inode *inode)
 	else
 		drop = inode_generic_drop(inode);

+	if (sb->s_magic == CEPH_SUPER_MAGIC)
+		pr_info("CEPHDBG iput_final ino=%lx drop=%d dontcache=%d sb_active=%d state=%#lx\n",
+			inode->i_ino, drop,
+			!!(inode_state_read(inode) & I_DONTCACHE),
+			!!(sb->s_flags & SB_ACTIVE),
+			inode_state_read(inode));
+
 	if (!drop &&
 	    !(inode_state_read(inode) & I_DONTCACHE) &&
 	    (sb->s_flags & SB_ACTIVE)) {

Test results
------------
Full run of the test program on a vstart cluster (kernel built with the
debug patch; the script lowers mds_recall_max_caps/mds_min_caps_per_client
for the recall and restores them on exit):

  PASS: reopen served from page cache (no OSD read)
  PASS: recall evicted the inode and its cap
  PASS: post-trim reopen read from OSDs
  PASS: d_prune_aliases + EVICT_ON_FINAL_IPUT released the cap
  PASS: no-alias parked inode was marked and evicted

Retention, from dmesg:

  CEPHDBG drop_inode 1000000020c.fffffffffffffffe nrpages=1024 -> KEEP
  CEPHDBG keep_state 1000000020c.fffffffffffffffe state=0x0 shrinkable=0 empty=0 caps=1
  CEPHDBG iput_final ino=1000000020c drop=0 dontcache=0 sb_active=1 state=0x0

Trim chain, from dmesg:

  CEPHDBG trim_caps 1000000020c.fffffffffffffffe set EVICT_ON_FINAL_IPUT
  CEPHDBG drop_inode 1000000020c.fffffffffffffffe consumed EVICT_ON_FINAL_IPUT -> drop
  CEPHDBG evict_inode 1000000020c.fffffffffffffffe
  CEPHDBG remove_caps 1000000020c.fffffffffffffffe

---
Xiubo Li (2):
      ceph: mark the superblock active after mounting
      ceph: keep the inode, not the name, when a dentry lease expires

 fs/ceph/inode.c      | 48 ++++++++++++++++++++++++++++++++++++++++++++++++
 fs/ceph/mds_client.c | 37 +++++++++++++++++++++++++++++++------
 fs/ceph/super.c      | 11 ++++++++++-
 fs/ceph/super.h      |  2 ++
 4 files changed, 91 insertions(+), 7 deletions(-)
---
base-commit: 86f405187248b7a5a2104eba07f941d27593893e
change-id: 20260821-b4-b4-ceph-dentry-caps-ad44734dea85

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

