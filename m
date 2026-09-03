From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 02 Sep 2026 23:59:02 -0700
Subject: [PATCH v7 2/2] ceph: add 'lazyio' mount option to kclient
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260902-lazyio-v7-2-18c2afa06352@clyso.com>
References: <20260902-lazyio-v7-0-18c2afa06352@clyso.com>
In-Reply-To: <20260902-lazyio-v7-0-18c2afa06352@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788418742; l=28002;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=L/4vOWF5T8yL6iOaiyMOxkagdrBdS3DMo2PDy2dUTmg=;
 b=1mPQvXdHI9134UAhlx/vomcYBnRgXRdditQi1iAhZmBNPNB9tucTkbtW9MLpWIX/cIWK1LWZd
 7zSB9UqGSICD/I0oGV4abFFL+CFd0KrbtUDVKcT5t30XRydPCWyjXYK
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a 'lazyio' mount option to the kernel Ceph client that enables
LazyIO globally for all regular file opens on a mount. This is the
kclient equivalent of the 'client_force_lazyio=true' config option
in the ceph-fuse userspace client.

When 'lazyio' is specified, CEPH_FILE_MODE_LAZY is automatically
added to every regular file's fmode at open time in ceph_open() and
ceph_atomic_open(), causing the I/O paths to request
CEPH_CAP_FILE_LAZYIO from the MDS. This permits buffered I/O via
the page cache even when multiple clients have the file open for
write — beneficial for HPC workloads that can tolerate relaxed
cache coherency.

The mount option is exposed as 'lazyio' / 'nolazyio' via the VFS
fsparam_flag_no mechanism and supports remount.

Link: https://tracker.ceph.com/issues/77594
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c               | 138 +++++++++++++++++++++++++++
 fs/ceph/caps.c               | 218 ++++++++++++++++++++++++++++++++++++++++---
 fs/ceph/file.c               |  33 ++++++-
 fs/ceph/super.c              |  15 +++
 fs/ceph/super.h              |  17 ++++
 fs/ceph/util.c               |   4 -
 include/linux/ceph/ceph_fs.h |   1 +
 7 files changed, 406 insertions(+), 20 deletions(-)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index f8844390f88d..b4bfef11ac6f 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -500,6 +500,10 @@ static int ceph_init_request(struct netfs_io_request *rreq, struct file *file)
 			rreq->netfs_priv = priv;
 			return 0;
 		}
+
+		/* If this is a lazy fd, also try to get LAZYIO caps */
+		if (fi->fmode & CEPH_FILE_MODE_LAZY)
+			want |= CEPH_CAP_FILE_LAZYIO;
 	}
 
 	/*
@@ -1990,6 +1994,42 @@ static void ceph_restore_sigs(sigset_t *oldset)
 	sigprocmask(SIG_SETMASK, oldset, NULL);
 }
 
+/*
+ * True if the page cache is only being kept alive by LAZYIO: CACHE is no
+ * longer present in the implemented cap set, while LAZYIO still is, so
+ * handle_cap_grant() left the pages in place for the lazy openers.
+ *
+ * Such pages are only valid under the lazy semantics, and a non-lazy reader
+ * must not be served from them.  try_get_cap_refs() already refuses to
+ * satisfy a non-lazy CACHE want with LAZYIO for read_iter()/write_iter();
+ * faults need the same gate.
+ *
+ * Unlike __prep_cap(), which has to reason about a single cap, the question
+ * here is whether the cached data can have gone stale, so the aggregate of
+ * all caps is the right granularity: as long as any one of them still has
+ * CACHE implemented, its revocation has not been ACKed and the MDS cannot
+ * have handed CACHE to another client.  Note that __ceph_caps_issued()
+ * reports i_snap_caps in "have" only and not in "implemented", hence the
+ * OR; snap caps never include LAZYIO, so folding them in can only make this
+ * more conservative.
+ */
+static bool ceph_pages_retained_for_lazyio(struct inode *inode)
+{
+	struct ceph_inode_info *ci = ceph_inode(inode);
+	int have, implemented;
+
+	if (!inode->i_data.nrpages)
+		return false;
+
+	spin_lock(&ci->i_ceph_lock);
+	have = __ceph_caps_issued(ci, &implemented);
+	implemented |= have;
+	spin_unlock(&ci->i_ceph_lock);
+
+	return !(implemented & CEPH_CAP_FILE_CACHE) &&
+	       (implemented & CEPH_CAP_FILE_LAZYIO);
+}
+
 /*
  * vm ops
  */
@@ -2025,6 +2065,43 @@ static vm_fault_t ceph_filemap_fault(struct vm_fault *vmf)
 	doutc(cl, "%llx.%llx %llu got cap refs on %s\n", ceph_vinop(inode),
 	      off, ceph_cap_string(got));
 
+	/*
+	 * Don't fault a non-lazy mapping in from page cache that only LAZYIO
+	 * covers.  The "every opener is lazy" gate in handle_cap_grant() can't
+	 * catch this on its own: an open that happens after the cache was
+	 * retained sends no cap message, so nothing re-evaluates the decision.
+	 * Drop the range here instead and let the fault below re-read it.
+	 */
+	if (!(fi->fmode & CEPH_FILE_MODE_LAZY) &&
+	    !(got & CEPH_CAP_FILE_CACHE) &&
+	    ceph_pages_retained_for_lazyio(inode)) {
+		struct address_space *mapping = inode->i_mapping;
+
+		doutc(cl, "%llx.%llx %llu dropping LAZYIO page cache\n",
+		      ceph_vinop(inode), off);
+		err = invalidate_inode_pages2_range(mapping, vmf->pgoff,
+						    vmf->pgoff);
+		if (err == -EBUSY) {
+			/*
+			 * The folio is dirty and ceph has no launder_folio(),
+			 * so invalidate_inode_pages2_range() cannot drop it.
+			 * Write it back and retry -- handing a folio that only
+			 * LAZYIO covers to a non-lazy vma is not an option.
+			 */
+			err = filemap_write_and_wait_range(mapping, off,
+							   off + PAGE_SIZE - 1);
+			if (!err)
+				err = invalidate_inode_pages2_range(mapping,
+						vmf->pgoff, vmf->pgoff);
+		}
+		if (err) {
+			doutc(cl, "%llx.%llx %llu failed to drop LAZYIO page cache: %d\n",
+			      ceph_vinop(inode), off, err);
+			ceph_put_cap_refs(ci, got);
+			goto out_restore;
+		}
+	}
+
 	if ((got & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO)) ||
 	    !ceph_has_inline_data(ci)) {
 		CEPH_DEFINE_RW_CONTEXT(rw_ctx, got);
@@ -2084,6 +2161,30 @@ static vm_fault_t ceph_filemap_fault(struct vm_fault *vmf)
 	return ret;
 }
 
+/*
+ * Return true if the MDS has issued us a cap that covers buffered
+ * dirtying: either BUFFER, or LAZYIO (as long as LAZYIO itself is not
+ * being revoked).  This mirrors the conditions under which
+ * try_get_cap_refs() will hand out a BUFFER or LAZYIO ref.
+ */
+static bool ceph_have_dirtyable_caps(struct inode *inode)
+{
+	struct ceph_inode_info *ci = ceph_inode(inode);
+	int have, implemented;
+	bool ret = false;
+
+	spin_lock(&ci->i_ceph_lock);
+	have = __ceph_caps_issued(ci, &implemented);
+	if (have & CEPH_CAP_FILE_BUFFER) {
+		ret = true;
+	} else if ((have & CEPH_CAP_FILE_LAZYIO) &&
+		   !((implemented & ~have) & CEPH_CAP_FILE_LAZYIO)) {
+		ret = true;
+	}
+	spin_unlock(&ci->i_ceph_lock);
+	return ret;
+}
+
 static vm_fault_t ceph_page_mkwrite(struct vm_fault *vmf)
 {
 	struct vm_area_struct *vma = vmf->vma;
@@ -2122,6 +2223,7 @@ static vm_fault_t ceph_page_mkwrite(struct vm_fault *vmf)
 	else
 		want = CEPH_CAP_FILE_BUFFER;
 
+retry_caps:
 	got = 0;
 	err = ceph_get_caps(vma->vm_file, CEPH_CAP_FILE_WR, want, off + len, &got);
 	if (err < 0)
@@ -2130,6 +2232,42 @@ static vm_fault_t ceph_page_mkwrite(struct vm_fault *vmf)
 	doutc(cl, "%llx.%llx %llu~%zd got cap refs on %s\n", ceph_vinop(inode),
 	      off, len, ceph_cap_string(got));
 
+	/*
+	 * ceph_write_iter() makes the same check and falls back to
+	 * synchronous writes, but a page fault has no such fallback:
+	 * dirtying the folio without BUFFER or LAZYIO would leave dirty
+	 * data uncovered by any issued cap (e.g. while LAZYIO is being
+	 * revoked, or after it has been released).  Wait for the MDS to
+	 * (re)grant a covering cap, matching how the exclude gate in
+	 * try_get_cap_refs() blocks buffered writes while BUFFER is
+	 * revoking.
+	 */
+	if ((fi->fmode & CEPH_FILE_MODE_LAZY) &&
+	    (got & (CEPH_CAP_FILE_BUFFER | CEPH_CAP_FILE_LAZYIO)) == 0) {
+		ceph_put_cap_refs(ci, got);
+		got = 0;
+		doutc(cl, "%llx.%llx %llu~%zd waiting for BUFFER or LAZYIO\n",
+		      ceph_vinop(inode), off, len);
+		/*
+		 * Bail out if the inode is being shut down: the caps are gone
+		 * for good, so ceph_have_dirtyable_caps() would never become
+		 * true again.  Note that we cannot rely on ceph_get_caps()
+		 * failing with -ESTALE on the retry either -- if WR is still
+		 * held it would succeed without BUFFER or LAZYIO and send us
+		 * straight back here.
+		 */
+		err = wait_event_killable(ci->i_cap_wq,
+					  ceph_have_dirtyable_caps(inode) ||
+					  ceph_inode_is_shutdown(inode));
+		if (err)
+			goto out_free;
+		if (ceph_inode_is_shutdown(inode)) {
+			err = -ESTALE;
+			goto out_free;
+		}
+		goto retry_caps;
+	}
+
 	/* Update time before taking folio lock */
 	file_update_time(vma->vm_file);
 	inode_inc_iversion_raw(inode);
diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index 1847badddd87..131a23edbf95 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1028,6 +1028,53 @@ int __ceph_caps_used(struct ceph_inode_info *ci)
 	return used;
 }
 
+/*
+ * Substitute LAZYIO for CACHE/BUFFER when they are not issued.
+ * If we have LAZYIO but not CACHE/BUFFER, report LAZYIO as used instead
+ * so the MDS knows we're fine with the weaker consistency guarantee.
+ *
+ * Base the substitution on "implemented" rather than "issued": while
+ * LAZYIO is being revoked, "issued" no longer contains it but
+ * "implemented" still does.  If used reverted to CACHE/BUFFER at that
+ * point, ceph_check_caps() would see (revoking & cap_used) == 0 and
+ * ACK the revoke while dirty or stale pages were still present.  Only
+ * once the revoke is ACKed does "implemented" drop LAZYIO.
+ *
+ * Caller must hold i_ceph_lock.
+ */
+static inline int ceph_adjust_caps_used_for_lazyio(struct ceph_inode_info *ci,
+						   int used, int issued,
+						   int implemented)
+{
+	if (!(used & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_BUFFER)))
+		return used;
+	if (!(implemented & CEPH_CAP_FILE_LAZYIO))
+		return used;
+	/*
+	 * While LAZYIO is still issued, it only covers the cached data if
+	 * every opener has accepted the lazy semantics.  With a non-lazy
+	 * opener around, keep reporting CACHE/BUFFER so that a pending
+	 * revocation is not ACKed before the invalidation queued by
+	 * handle_cap_grant() has emptied the page cache.
+	 *
+	 * Once LAZYIO is itself being revoked ("implemented" has it but
+	 * "issued" no longer does) the substitution is unconditional: the
+	 * revoke must not be ACKed while pages are still around, no matter
+	 * who has the file open.
+	 */
+	if ((issued & CEPH_CAP_FILE_LAZYIO) && !__ceph_all_opens_lazy(ci))
+		return used;
+	if (!(issued & CEPH_CAP_FILE_CACHE)) {
+		used &= ~CEPH_CAP_FILE_CACHE;
+		used |= CEPH_CAP_FILE_LAZYIO;
+	}
+	if (!(issued & CEPH_CAP_FILE_BUFFER)) {
+		used &= ~CEPH_CAP_FILE_BUFFER;
+		used |= CEPH_CAP_FILE_LAZYIO;
+	}
+	return used;
+}
+
 #define FMODE_WAIT_BIAS 1000
 
 /*
@@ -1449,6 +1496,20 @@ static void __prep_cap(struct cap_msg_args *arg, struct ceph_inode_info *ci,
 	 * dirty pages _before_ allowing sync writes to avoid reordering.
 	 */
 	arg->wake = cap->implemented & ~cap->issued;
+	/*
+	 * "used" decides which of the revoked caps stay in cap->implemented,
+	 * i.e. which revocations this message does _not_ ack yet.  Callers on
+	 * the flush paths (try_flush_caps(), __kick_flushing_caps()) hand us
+	 * the raw __ceph_caps_used(), which reports CACHE/BUFFER as long as
+	 * the page cache is populated.  While LAZYIO is being revoked it is no
+	 * longer in cap->issued, so a raw used set would drop it from
+	 * cap->implemented and implicitly ack the revoke with pages still
+	 * cached -- the MDS could then hand CACHE to another client.  Report
+	 * LAZYIO as used instead, and only stop doing so once writeback and
+	 * invalidation have emptied the page cache.
+	 */
+	used = ceph_adjust_caps_used_for_lazyio(ci, used, cap->issued,
+						cap->implemented);
 	cap->implemented &= cap->issued | used;
 	cap->mds_wanted = want;
 
@@ -2094,6 +2155,7 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 	 * usually because they have outstanding references).
 	 */
 	issued = __ceph_caps_issued(ci, &implemented);
+
 	revoking = implemented & ~issued;
 
 	want = file_wanted;
@@ -2185,6 +2247,19 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 		if (ci->i_auth_cap && cap != ci->i_auth_cap)
 			cap_used &= ~ci->i_auth_cap->issued;
 
+		/*
+		 * Substitute LAZYIO for CACHE/BUFFER when they are not issued.
+		 * Do this per cap and not once for the whole inode: only the
+		 * cap that actually holds LAZYIO may report it as used.  A cap
+		 * that is revoking CACHE without holding LAZYIO must keep
+		 * reporting CACHE as used, or the (revoking & cap_used) test
+		 * below would treat the revocation as completed while the page
+		 * cache is still populated.
+		 */
+		cap_used = ceph_adjust_caps_used_for_lazyio(ci, cap_used,
+							   cap->issued,
+							   cap->implemented);
+
 		revoking = cap->implemented & ~cap->issued;
 		doutc(cl, " mds%d cap %p used %s issued %s implemented %s revoking %s\n",
 		      cap->mds, cap, ceph_cap_string(cap_used),
@@ -2209,10 +2284,13 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 			 * at most 5 seconds. That means the MDS needs to wait at
 			 * most 5 seconds to finished the Fb capability's revocation.
 			 *
-			 * Let's queue a writeback for it.
+			 * Let's queue a writeback for it.  The same applies when
+			 * LAZYIO is revoked while it was covering for BUFFER
+			 * (dirty pages exist, but BUFFER isn't issued).
 			 */
 			if (S_ISREG(inode->i_mode) && ci->i_wrbuffer_ref &&
-			    (revoking & CEPH_CAP_FILE_BUFFER))
+			    (revoking & (CEPH_CAP_FILE_BUFFER |
+					 CEPH_CAP_FILE_LAZYIO)))
 				queue_writeback = true;
 		}
 
@@ -2957,9 +3035,45 @@ static int try_get_cap_refs(struct inode *inode, int need, int want,
 				}
 				snap_rwsem_locked = true;
 			}
-			if ((have & want) == want)
+			/*
+			 * Allow LAZYIO to act as a substitute for
+			 * CACHE or BUFFER when those caps are not
+			 * issued, but only for callers that
+			 * explicitly requested LAZYIO.  This
+			 * prevents a non-lazy fd from having its
+			 * CACHE/BUFFER wants satisfied by LAZYIO
+			 * on an inode where a different fd is lazy.
+			 *
+			 * A missing LAZYIO cap, however, must never
+			 * cost us the CACHE/BUFFER refs that are
+			 * actually issued: the MDS only grants
+			 * LAZYIO for files opened with CEPH_O_LAZY
+			 * and it can be revoked at any time.  If we
+			 * made the whole want unsatisfiable without
+			 * it, the I/O paths would silently drop
+			 * CACHE/BUFFER (e.g. take no wrbuffer refs)
+			 * and degrade to synchronous writes.
+			 */
+			if ((have & (want & ~CEPH_CAP_FILE_LAZYIO)) ==
+			    (want & ~CEPH_CAP_FILE_LAZYIO)) {
+				*got = need | (want & ~exclude &
+					       ~CEPH_CAP_FILE_LAZYIO);
+				if ((want & CEPH_CAP_FILE_LAZYIO) &&
+				    (have & CEPH_CAP_FILE_LAZYIO) &&
+				    !(exclude & CEPH_CAP_FILE_LAZYIO))
+					*got |= CEPH_CAP_FILE_LAZYIO;
+			} else if ((want & CEPH_CAP_FILE_LAZYIO) &&
+				   (have & CEPH_CAP_FILE_LAZYIO) &&
+				   !(exclude & CEPH_CAP_FILE_LAZYIO) &&
+				   ((have & want) ==
+				    (want & ~(CEPH_CAP_FILE_CACHE |
+					      CEPH_CAP_FILE_BUFFER)))) {
+				/*
+				 * LAZYIO substitutes for missing CACHE/BUFFER;
+				 * it is already included via (want & ~exclude).
+				 */
 				*got = need | (want & ~exclude);
-			else
+			} else
 				*got = need;
 			ceph_take_cap_refs(ci, *got, true);
 			ret = 1;
@@ -3048,6 +3162,14 @@ static void check_max_size(struct inode *inode, loff_t endoff)
 		ceph_check_caps(ci, CHECK_CAPS_AUTHONLY);
 }
 
+/*
+ * The inverse of ceph_caps_for_mode().  LAZYIO has to be mapped back as
+ * well: __ceph_get_caps() feeds the result to ceph_get_fmode() to bias
+ * i_nr_by_mode[] by FMODE_WAIT_BIAS while it waits, and dropping LAZY
+ * here would bias the open count without biasing the lazy count, making
+ * __ceph_all_opens_lazy() report a phantom non-lazy opener for as long
+ * as a lazy fd is waiting for caps.
+ */
 static inline int get_used_fmode(int caps)
 {
 	int fmode = 0;
@@ -3055,6 +3177,8 @@ static inline int get_used_fmode(int caps)
 		fmode |= CEPH_FILE_MODE_RD;
 	if (caps & CEPH_CAP_FILE_WR)
 		fmode |= CEPH_FILE_MODE_WR;
+	if (caps & CEPH_CAP_FILE_LAZYIO)
+		fmode |= CEPH_FILE_MODE_LAZY;
 	return fmode;
 }
 
@@ -3616,13 +3740,29 @@ static void handle_cap_grant(struct inode *inode,
 
 
 	/*
-	 * If CACHE is being revoked, and we have no dirty buffers,
-	 * try to invalidate (once).  (If there are dirty buffers, we
-	 * will invalidate _after_ writeback.)
+	 * Check the revocation of *both* CACHE and LAZYIO, because
+	 * CACHE may have been revoked earlier and cap->issued no
+	 * longer contains it -- at that point only LAZYIO was
+	 * covering us.  If LAZYIO is now also being revoked and no
+	 * cache cap remains, we must invalidate the page cache.
+	 * Without this, a CACHE-revoked-then-LAZYIO-revoked sequence
+	 * leaves stale pages in memory until the next periodic
+	 * check_caps (up to 60s).  Also invalidate when we have no
+	 * dirty buffers (if dirty, invalidate after writeback).
+	 *
+	 * Keeping the page cache alive on a remaining LAZYIO is only
+	 * safe if every opener has accepted the lazy semantics: those
+	 * pages are retained for the lazy fds alone, and a non-lazy
+	 * reader (mmap, or an fd that never asked for LAZYIO) must not
+	 * be served from them.  So drop the cache as well whenever a
+	 * non-lazy opener is around.
 	 */
 	if (S_ISREG(inode->i_mode) && /* don't invalidate readdir cache */
-	    ((cap->issued & ~newcaps) & CEPH_CAP_FILE_CACHE) &&
-	    (newcaps & CEPH_CAP_FILE_LAZYIO) == 0 &&
+	    ((cap->issued & ~newcaps) &
+	     (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO)) &&
+	    !(newcaps & CEPH_CAP_FILE_CACHE) &&
+	    (!(newcaps & CEPH_CAP_FILE_LAZYIO) ||
+	     !__ceph_all_opens_lazy(ci)) &&
 	    !(ci->i_wrbuffer_ref || ci->i_wb_ref)) {
 		if (try_nonblocking_invalidate(inode)) {
 			/* there were locked pages.. invalidate later
@@ -3634,6 +3774,47 @@ static void handle_cap_grant(struct inode *inode,
 		}
 	}
 
+	/*
+	 * The counterpart on the grant arm: pages that survived a CACHE
+	 * revocation are only kept alive by LAZYIO, and they may have
+	 * gone stale while CACHE was away.  Once a later grant brings
+	 * CACHE back, ceph_pages_retained_for_lazyio() (addr.c) turns
+	 * false the moment CACHE shows up in the implemented set, and a
+	 * non-lazy opener would be served those folios as coherent
+	 * CACHE data.  Drop the cache here, before a non-lazy
+	 * read_iter/fault can use it.
+	 *
+	 * The aggregate check below still sees the pre-grant state:
+	 * cap->issued and cap->implemented are only updated further
+	 * down, so CACHE is absent from "implemented" here, exactly
+	 * as it was when the pages were retained.
+	 *
+	 * Dirty folios (this client's own lazy writes) are not
+	 * droppable -- ceph has no launder_folio() -- and are left in
+	 * place by the invalidate, which is fine: they hold current
+	 * local data.
+	 */
+	if (S_ISREG(inode->i_mode) &&
+	    ((newcaps & ~cap->issued) & CEPH_CAP_FILE_CACHE) &&
+	    inode->i_data.nrpages) {
+		int have, implemented;
+
+		have = __ceph_caps_issued(ci, &implemented);
+		implemented |= have;
+		if (!(implemented & CEPH_CAP_FILE_CACHE) &&
+		    (implemented & CEPH_CAP_FILE_LAZYIO) &&
+		    try_nonblocking_invalidate(inode)) {
+			/*
+			 * There were locked pages.. invalidate later in
+			 * a separate thread.
+			 */
+			if (ci->i_rdcache_revoking != ci->i_rdcache_gen) {
+				queue_invalidate = true;
+				ci->i_rdcache_revoking = ci->i_rdcache_gen;
+			}
+		}
+	}
+
 	if (was_stale)
 		cap->issued = cap->implemented = CEPH_CAP_PIN;
 
@@ -3766,6 +3947,8 @@ static void handle_cap_grant(struct inode *inode,
 	/* check cap bits */
 	wanted = __ceph_caps_wanted(ci);
 	used = __ceph_caps_used(ci);
+	used = ceph_adjust_caps_used_for_lazyio(ci, used, cap->issued,
+						cap->implemented);
 	dirty = __ceph_caps_dirty(ci);
 	doutc(cl, " my wanted = %s, used = %s, dirty %s\n",
 	      ceph_cap_string(wanted), ceph_cap_string(used),
@@ -3793,13 +3976,26 @@ static void handle_cap_grant(struct inode *inode,
 		doutc(cl, "revocation: %s -> %s (revoking %s)\n",
 		      ceph_cap_string(cap->issued), ceph_cap_string(newcaps),
 		      ceph_cap_string(revoking));
+		/*
+		 * If BUFFER is being revoked and we have dirty data,
+		 * trigger writeback before acking.  When LAZYIO was
+		 * covering for BUFFER (BUFFER not issued, dirty refs
+		 * held), also trigger writeback.  Clean cached pages
+		 * under LAZYIO are handled by queue_invalidate below.
+		 */
 		if (S_ISREG(inode->i_mode) &&
 		    (revoking & used & CEPH_CAP_FILE_BUFFER)) {
 			writeback = true;  /* initiate writeback; will delay ack */
 			revoke_wait = true;
+		} else if (S_ISREG(inode->i_mode) &&
+			   (revoking & used & CEPH_CAP_FILE_LAZYIO) &&
+			   (ci->i_wrbuffer_ref || ci->i_wb_ref)) {
+			/* LAZYIO was covering for dirty data — flush first */
+			writeback = true;
+			revoke_wait = true;
 		} else if (queue_invalidate &&
-			 revoking == CEPH_CAP_FILE_CACHE &&
-			 (newcaps & CEPH_CAP_FILE_LAZYIO) == 0) {
+			 (revoking & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO)) &&
+			 !(newcaps & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO))) {
 			revoke_wait = true; /* do nothing yet, invalidation will be queued */
 		} else if (cap == ci->i_auth_cap) {
 			check_caps = 1; /* check auth cap only */
diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index d5606456dbd5..132b5878f924 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -347,10 +347,6 @@ int ceph_renew_caps(struct inode *inode, int fmode)
 		flags = O_RDONLY;
 	else if (wanted & CEPH_CAP_FILE_WR)
 		flags = O_WRONLY;
-#ifdef O_LAZY
-	if (wanted & CEPH_CAP_FILE_LAZYIO)
-		flags |= O_LAZY;
-#endif
 
 	req = prepare_open_request(inode->i_sb, flags, 0);
 	if (IS_ERR(req)) {
@@ -358,6 +354,10 @@ int ceph_renew_caps(struct inode *inode, int fmode)
 		goto out;
 	}
 
+	if (wanted & CEPH_CAP_FILE_LAZYIO) {
+		req->r_fmode |= CEPH_FILE_MODE_LAZY;
+		req->r_args.open.flags |= cpu_to_le32(CEPH_O_LAZY);
+	}
 	req->r_inode = inode;
 	ihold(inode);
 	req->r_num_caps = 1;
@@ -409,6 +409,19 @@ int ceph_open(struct inode *inode, struct file *file)
 	doutc(cl, "%p %llx.%llx file %p flags %d (%d)\n", inode,
 	      ceph_vinop(inode), file, flags, file->f_flags);
 	fmode = ceph_flags_to_mode(flags);
+
+	/*
+	 * If lazyio mount option is set, enable lazyio for all regular
+	 * files.  Skip snapped files: snap caps never include LAZYIO,
+	 * so including it in wanted would force an unnecessary MDS
+	 * round-trip for every open of a snapped file.
+	 */
+	if (S_ISREG(inode->i_mode) &&
+	    ceph_snap(inode) == CEPH_NOSNAP &&
+	    (fsc->mount_options->flags & CEPH_MOUNT_OPT_LAZYIO)) {
+		fmode |= CEPH_FILE_MODE_LAZY;
+	}
+
 	wanted = ceph_caps_for_mode(fmode);
 
 	if (fmode & CEPH_FILE_MODE_WR)
@@ -485,13 +498,16 @@ int ceph_open(struct inode *inode, struct file *file)
 		err = PTR_ERR(req);
 		goto out;
 	}
+	req->r_fmode |= fmode & CEPH_FILE_MODE_LAZY;
+	if (fmode & CEPH_FILE_MODE_LAZY)
+		req->r_args.open.flags |= cpu_to_le32(CEPH_O_LAZY);
 	req->r_inode = inode;
 	ihold(inode);
 
 	req->r_num_caps = 1;
 	err = ceph_mdsc_do_request(mdsc, NULL, req);
 	if (!err)
-		err = ceph_init_file(inode, file, req->r_fmode);
+		err = ceph_init_file(inode, file, fmode);
 	ceph_mdsc_put_request(req);
 	doutc(cl, "open result=%d on %llx.%llx\n", err, ceph_vinop(inode));
 out:
@@ -836,6 +852,9 @@ int ceph_atomic_open(struct inode *dir, struct dentry *dentry,
 		} else {
 			int fmode = ceph_flags_to_mode(flags);
 
+			if (fsc->mount_options->flags & CEPH_MOUNT_OPT_LAZYIO)
+				fmode |= CEPH_FILE_MODE_LAZY;
+
 			mask = MAY_READ;
 			if (fmode & CEPH_FILE_MODE_WR)
 				mask |= MAY_WRITE;
@@ -878,6 +897,10 @@ int ceph_atomic_open(struct inode *dir, struct dentry *dentry,
 		err = PTR_ERR(req);
 		goto out_ctx;
 	}
+	if (fsc->mount_options->flags & CEPH_MOUNT_OPT_LAZYIO) {
+		req->r_fmode |= CEPH_FILE_MODE_LAZY;
+		req->r_args.open.flags |= cpu_to_le32(CEPH_O_LAZY);
+	}
 	req->r_dentry = dget(dentry);
 	req->r_num_caps = 2;
 	mask = CEPH_STAT_CAP_INODE | CEPH_CAP_AUTH_SHARED;
diff --git a/fs/ceph/super.c b/fs/ceph/super.c
index c631844828d3..108095ef68b4 100644
--- a/fs/ceph/super.c
+++ b/fs/ceph/super.c
@@ -181,6 +181,7 @@ enum {
 	Opt_pagecache,
 	Opt_sparseread,
 	Opt_nearfull_sync,
+	Opt_lazyio,
 };
 
 enum ceph_recover_session_mode {
@@ -207,6 +208,7 @@ static const struct fs_parameter_spec ceph_mount_parameters[] = {
 	fsparam_flag_no	("fsc",				Opt_fscache), // fsc|nofsc
 	fsparam_string	("fsc",				Opt_fscache), // fsc=...
 	fsparam_flag_no ("ino32",			Opt_ino32),
+	fsparam_flag_no	("lazyio",			Opt_lazyio),
 	fsparam_string	("mds_namespace",		Opt_mds_namespace),
 	fsparam_string	("mon_addr",			Opt_mon_addr),
 	fsparam_flag_no	("nearfull_sync",		Opt_nearfull_sync),
@@ -604,6 +606,12 @@ static int ceph_parse_mount_param(struct fs_context *fc,
 		else
 			fsopt->flags |= CEPH_MOUNT_OPT_NEARFULL_SYNC;
 		break;
+	case Opt_lazyio:
+		if (result.negated)
+			fsopt->flags &= ~CEPH_MOUNT_OPT_LAZYIO;
+		else
+			fsopt->flags |= CEPH_MOUNT_OPT_LAZYIO;
+		break;
 	case Opt_test_dummy_encryption:
 #ifdef CONFIG_FS_ENCRYPTION
 		fscrypt_free_dummy_policy(&fsopt->dummy_enc_policy);
@@ -762,6 +770,8 @@ static int ceph_show_options(struct seq_file *m, struct dentry *root)
 		seq_puts(m, ",sparseread");
 	if (fsopt->flags & CEPH_MOUNT_OPT_NEARFULL_SYNC)
 		seq_puts(m, ",nearfull_sync");
+	if (fsopt->flags & CEPH_MOUNT_OPT_LAZYIO)
+		seq_puts(m, ",lazyio");
 
 	fscrypt_show_test_dummy_encryption(m, ',', root->d_sb);
 
@@ -1437,6 +1447,11 @@ static int ceph_reconfigure_fc(struct fs_context *fc)
 	else
 		ceph_clear_mount_opt(fsc, NEARFULL_SYNC);
 
+	if (fsopt->flags & CEPH_MOUNT_OPT_LAZYIO)
+		ceph_set_mount_opt(fsc, LAZYIO);
+	else
+		ceph_clear_mount_opt(fsc, LAZYIO);
+
 	if (strcmp_null(fsc->mount_options->mon_addr, fsopt->mon_addr)) {
 		kfree(fsc->mount_options->mon_addr);
 		fsc->mount_options->mon_addr = fsopt->mon_addr;
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index f3d99027e193..2cf81934c891 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -46,6 +46,7 @@
 #define CEPH_MOUNT_OPT_NOPAGECACHE     (1<<16) /* bypass pagecache altogether */
 #define CEPH_MOUNT_OPT_SPARSEREAD      (1<<17) /* always do sparse reads */
 #define CEPH_MOUNT_OPT_NEARFULL_SYNC   (1<<18) /* sync writes when nearfull */
+#define CEPH_MOUNT_OPT_LAZYIO          (1<<19) /* force lazyio for all file opens */
 
 #define CEPH_MOUNT_OPT_DEFAULT			\
 	(CEPH_MOUNT_OPT_DCACHE |		\
@@ -927,6 +928,22 @@ static inline bool __ceph_is_file_opened(struct ceph_inode_info *ci)
 {
 	return ci->i_nr_by_mode[0];
 }
+
+/*
+ * True if the inode is open and every opener is a lazy one.  Bit 0 of
+ * i_nr_by_mode[] is set for every open regardless of mode (see
+ * ceph_get_fmode()), so it doubles as the total open count.
+ *
+ * Callers must hold i_ceph_lock.
+ */
+static inline bool __ceph_all_opens_lazy(struct ceph_inode_info *ci)
+{
+	int nr_open = ci->i_nr_by_mode[ffs(CEPH_FILE_MODE_PIN)];
+	int nr_lazy = ci->i_nr_by_mode[ffs(CEPH_FILE_MODE_LAZY)];
+
+	return nr_open > 0 && nr_lazy >= nr_open;
+}
+
 extern int __ceph_caps_file_wanted(struct ceph_inode_info *ci);
 extern int __ceph_caps_wanted(struct ceph_inode_info *ci);
 
diff --git a/fs/ceph/util.c b/fs/ceph/util.c
index 2c34875675bf..be3db3f20344 100644
--- a/fs/ceph/util.c
+++ b/fs/ceph/util.c
@@ -73,10 +73,6 @@ int ceph_flags_to_mode(int flags)
 		mode = CEPH_FILE_MODE_RDWR;
 		break;
 	}
-#ifdef O_LAZY
-	if (flags & O_LAZY)
-		mode |= CEPH_FILE_MODE_LAZY;
-#endif
 
 	return mode;
 }
diff --git a/include/linux/ceph/ceph_fs.h b/include/linux/ceph/ceph_fs.h
index 0adc526ec321..d70bbce1a1b2 100644
--- a/include/linux/ceph/ceph_fs.h
+++ b/include/linux/ceph/ceph_fs.h
@@ -414,6 +414,7 @@ extern const char *ceph_mds_op_name(int op);
 #define CEPH_O_CREAT		00000100
 #define CEPH_O_EXCL		00000200
 #define CEPH_O_TRUNC		00001000
+#define CEPH_O_LAZY		00020000
 #define CEPH_O_DIRECTORY	00200000
 #define CEPH_O_NOFOLLOW		00400000
 

-- 
2.53.0

