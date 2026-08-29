From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 29 Aug 2026 05:27:59 -0700
Subject: [PATCH v2 1/2] ceph: handle a NULL oldest snap context in
 writeback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-b4-ceph-fix-null-oldest-snapc-new-v2-1-71fb4aa49968@clyso.com>
References: <20260829-b4-ceph-fix-null-oldest-snapc-new-v2-0-71fb4aa49968@clyso.com>
In-Reply-To: <20260829-b4-ceph-fix-null-oldest-snapc-new-v2-0-71fb4aa49968@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, Sage Weil <sage@newdream.net>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788006479; l=3943;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=HF4KbSvHgEDNcTxwHUOqMHQZO3ow5XW+gXbNdyu1xOs=;
 b=5th70nFzCO8v/xARejsG0oK9eRHUxklVyWb8VbOitIgDM/MPwpNz8EBzu6IfWI8B1/Bhc//0y
 DeqfbU7McHZDL1r8492rGXNUr04soW7T0+H/A+fKLpJsYBp/lIgIs5Q
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_oldest_context() returns NULL when the inode has no dirty capsnaps
and no head writeback references.  That is a legal return value that
context_is_writeable_or_written() handles explicitly, but
ceph_find_incompatible() and write_folio_nounlock() dereference the
returned pointer without checking:

  BUG: kernel NULL pointer dereference, address: 0000000000000008
  #PF: supervisor read access in kernel mode
  ...
  RIP: 0010:ceph_find_incompatible+0x75/0x1d0 [ceph]

Skip the sequence comparison when there is no oldest context: with no
dirty accounting there is nothing for the folio's snap context to
conflict with and the folio is writable.  In write_folio_nounlock()
also fill the writeback ctl with the inode's current size and truncate
state in that case, since get_oldest_context() only fills it on the
capsnap and head paths and the uninitialized ctl would otherwise be
used for the EOF check and the OSD request.

Fixes: 80e755fedebc ("ceph: allow writeback of snapped pages older than 'oldest' snapc")
Cc: stable@vger.kernel.org
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c | 19 +++++++++++++++++--
 fs/ceph/caps.c | 13 ++++++++++---
 2 files changed, 27 insertions(+), 5 deletions(-)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index 534a7a377b2f..38db91459440 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -769,7 +769,7 @@ static int write_folio_nounlock(struct folio *folio,
 		return 0;
 	}
 	oldest = get_oldest_context(inode, &ceph_wbc, snapc);
-	if (snapc->seq > oldest->seq) {
+	if (oldest && snapc->seq > oldest->seq) {
 		doutc(cl, "%llx.%llx folio %p snapc %p not writeable - noop\n",
 		      ceph_vinop(inode), folio, snapc);
 		/* we should only noop if called by kswapd */
@@ -780,6 +780,21 @@ static int write_folio_nounlock(struct folio *folio,
 	}
 	ceph_put_snap_context(oldest);
 
+	if (!oldest) {
+		/*
+		 * No dirty capsnap and no head writeback refs: there is
+		 * nothing to conflict with and the folio is writable.
+		 * Fill in the ctl as for the head context, since
+		 * get_oldest_context() only does so on the capsnap and
+		 * head paths.
+		 */
+		ceph_wbc.i_size = i_size_read(inode);
+		ceph_wbc.truncate_size = ci->i_truncate_size;
+		ceph_wbc.truncate_seq = ci->i_truncate_seq;
+		ceph_wbc.size_stable = false;
+		ceph_wbc.head_snapc = true;
+	}
+
 	/* is this a partial page at end of file? */
 	if (page_off >= ceph_wbc.i_size) {
 		doutc(cl, "%llx.%llx folio at %lu beyond eof %llu\n",
@@ -1869,7 +1884,7 @@ ceph_find_incompatible(struct folio *folio)
 		 * context!  is it writeable now?
 		 */
 		oldest = get_oldest_context(inode, NULL, NULL);
-		if (snapc->seq > oldest->seq) {
+		if (oldest && snapc->seq > oldest->seq) {
 			/* not writeable -- return it for the caller to deal with */
 			ceph_put_snap_context(oldest);
 			doutc(cl, " %llx.%llx folio %p snapc %p not current or oldest\n",
diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index 1847badddd87..d07a80674a17 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -3447,10 +3447,17 @@ void ceph_put_wrbuffer_cap_refs(struct ceph_inode_info *ci, int nr,
 
 		if (!capsnap) {
 			/*
-			 * The capsnap should already be removed when removing
-			 * auth cap in the case of a forced unmount.
+			 * The cap_snap may be gone even though the auth cap
+			 * is present: a session loss removes all cap_snaps
+			 * (ceph_purge_inode_cap()), but the dirty folios
+			 * referencing their contexts can survive in the
+			 * page cache.  Once the session reconnects and the
+			 * inode gets a new auth cap, those folios write
+			 * back and no longer find a matching cap_snap
+			 * here.  There is nothing left to account for.
 			 */
-			WARN_ON_ONCE(ci->i_auth_cap);
+			doutc(cl, "%p %llx.%llx snapc %p no cap_snap\n",
+			      inode, ceph_vinop(inode), snapc);
 			goto unlock;
 		}
 

-- 
2.53.0

