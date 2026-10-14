From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 14 Oct 2026 16:29:58 +0900
Subject: [PATCH v2 2/7] nfsd: answer NFS4ERR_DELAY instead of waiting for a
 layout recall
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-nfsd-layout-recall-v2-2-764462bddfd1@samsung.com>
References: <20261014-nfsd-layout-recall-v2-0-764462bddfd1@samsung.com>
In-Reply-To: <20261014-nfsd-layout-recall-v2-0-764462bddfd1@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <bcodding@redhat.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791962996; l=15821;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=xwZgXlSRB+M1tQduSY0swmScIMGtozdCamDRlwpKzU4=;
 b=surx21+y6WC+JMOul6kgpUI8dGptL3+DssdRYgwsDOfIMs8zW7NThLBUHIim9JfgeO+aopes2
 7kunojV8Sc3BiDcHHr8wMy03Z0eCqm76f354hNzEd8tOOIWgrJ/3AuY
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A WRITE, a SETATTR that changes the size (also an OPEN that truncates
and an NFSv2 or NFSv3 CREATE of an existing file with a size), an
ALLOCATE, a DEALLOCATE, a CLONE and a COPY make XFS recall the layouts
of the file and wait in __break_lease() until they are returned or the
lease break times out: xfs_break_leased_layouts(), and
xfs_iolock_two_inodes_and_break_layout() for both files of a clone. The
nfsd thread serving the request sleeps there too. The client decides
when it returns its layout, so a few such requests can occupy every nfsd
thread, and the server then cannot process the LAYOUTRETURN that would
release them.

Before calling into the filesystem, recall the layouts without waiting,
as nfsd_open_break_lease() does for delegations, and return
-EWOULDBLOCK while a layout is held, which nfserrno() maps to
NFS4ERR_DELAY (NFS3ERR_JUKEBOX for NFSv3), so that the client retries.
When this starts the recall of a layout of another client, first give
the layouts NFSD_LAYOUTRETURN_TIMEOUT to come back, the 30 ms that
nfsd_wait_for_delegreturn() allows a delegation: a client that is not
doing I/O through its layout returns it within a few milliseconds, and
the retry would cost the client of the request at least 100 ms. Do not
wait for a recall that is already under way, nor when the client of
the request holds a layout of the file itself: it returns that layout
only after its own I/O through it has completed. nfsd4_close_layout()
wakes the waiter when a layout lease is removed. For a COPY or a CLONE,
both recalls are started before the wait. For a SETATTR, the recall
comes before inode_lock, which the LAYOUTCOMMIT that a client sends
before its LAYOUTRETURN takes. A file without leases costs one lockless
check of its lease list; a file with other leases, such as
delegations, a walk of that list under flc_lock.

Answering NFS4ERR_DELAY here was discussed in 2023 (second Link).
Passing a non-blocking flag down to the break in the filesystem would
need VFS and XFS changes and a way through notify_change(),
vfs_fallocate() and the remap path; breaking before the call, as
nfsd_open_break_lease() does for delegations, needs neither.

An nfsd thread can still block in the filesystem when a LAYOUTGET
completes between this check and the recall in the filesystem. No
layout lease can be added while a recall is pending, so this takes a
file that had no layout when nfsd checked. A recall that meets a
LAYOUTGET in progress fails that LAYOUTGET (previous patch), so the
layout it would have handed out is not left unrecalled. An asynchronous
COPY runs in its own kthread and is not changed; OFFLOAD_CANCEL and
client teardown wait for that kthread.

The cost is on a request that conflicts with a layout. When the layout
does not come back within 30 ms, or the client of the request holds it,
the request completes only when the client sends it again. The Linux
client does that after at least 100 ms for NFSv4 (NFS4_POLL_RETRY_MIN)
and after 5 seconds for NFSv3 (NFS_JUKEBOX_RETRY_TIME), where it used to
wait only until the layout was returned. An NFSv2 WRITE has its reply
dropped, as for any NFSERR_JUKEBOX, and an NFSv2 SETATTR or CREATE is
answered as for a delegation conflict. The recall now also comes before
the checks that would fail the request: a COPY recalls the layouts of
its source as well, because the filesystem may do it as a clone, also
where it cannot, and a CLONE on a filesystem without reflink can get
NFS4ERR_DELAY before NFS4ERR_NOTSUPP. An NFSv2 or NFSv3 CREATE of an
existing file with a size does the SETATTR with the parent directory
locked and holds it during the wait.

With 4 nfsd threads, a client that holds a layout of a file and has
lost its path to the device, and another client (NFSv4.0) that sends 8
4 KiB WRITEs to that file through the metadata server while it reads
4 KiB of another file every second: the WRITEs take about 45 seconds
with and without this patch, as they wait for the lease break, and
without it the reads of the other file wait as long. With it the
longest of 84 reads takes 31 ms, and 0.22 seconds with 64 WRITEs. With
the second client on NFSv3, the longest read takes 21 ms instead of 47
seconds, and the WRITEs take 51 seconds instead of 47, as the client
waits 5 seconds after NFS3ERR_JUKEBOX.

A client that writes to a file both through its layout and through the
server recalls its own layout with each such WRITE. About half of its
LAYOUTGETs then meet that recall and get NFS4ERR_RECALLCONFLICT, as
before; the others are in progress when the WRITE breaks the lease, and
the previous patch fails them. The Linux client waits up to 15 seconds
between LAYOUTGETs that fail with NFS4ERR_RECALLCONFLICT. Writing 1 MiB
blocks through its layout and 512 bytes through the server for 30
seconds, such a client wrote 48, 46 and 4 blocks through the layout in
three runs, against 534, 537 and 505 without this series. There most
recalls of its layout ended in the failure path, and 7, 4 and 20 of the
blocks read back as zeroes after a successful fsync(); none did with
this series.

Writes to a file without leases are not changed: fio with O_DIRECT,
NFSv4.0, 10 runs of 30 seconds, without KASAN and lockdep, gave median
65.8 and 67.5 MiB/s for 1 MiB sequential writes without and with an
earlier revision of this series (the same path for such a file), and 262
and 263 IOPS for 4 KiB random writes.

Fixes: c5c707f96fc9 ("nfsd: implement pNFS layout recalls")
Suggested-by: Chuck Lever <cel@kernel.org>
Link: https://lore.kernel.org/r/63ef8d7c-086f-4cc8-84bb-72c1b23bf596@slotpi15m67
Link: https://lore.kernel.org/r/ZVdj2U+kJ7DlI22g@infradead.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 58 +++++++++++++++++++++++++++++++++++-
 fs/nfsd/nfs4proc.c    |  8 +++++
 fs/nfsd/pnfs.h        | 15 ++++++++++
 fs/nfsd/state.h       |  1 +
 fs/nfsd/vfs.c         | 81 ++++++++++++++++++++++++++++++++++++++++++++++++++-
 fs/nfsd/vfs.h         |  1 +
 6 files changed, 162 insertions(+), 2 deletions(-)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index 72b53eebd1..035ab79faa 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -153,13 +153,69 @@ void nfsd4_close_layout(struct nfs4_layout_stateid *ls)
 	spin_unlock(&ls->ls_stid.sc_file->fi_lock);
 
 	if (fl) {
-		if (!nfsd4_layout_ops[ls->ls_layout_type]->disable_recalls)
+		if (!nfsd4_layout_ops[ls->ls_layout_type]->disable_recalls) {
 			kernel_setlease(fl->nf_file, F_UNLCK, NULL,
 					(void **)&ls);
+			/*
+			 * For nfsd_break_layouts(). No barrier needed: its
+			 * waiter rechecks under flc_lock, which removing the
+			 * lease took.
+			 */
+			wake_up_var(file_inode(fl->nf_file));
+		}
 		nfsd_file_put(fl);
 	}
 }
 
+/**
+ * nfsd4_layout_holders - Report which clients hold layout leases on a file
+ * @inode: file whose layout leases are checked
+ *
+ * The client of the request being processed is the one of its compound.
+ * Without one, as for NFSv3, every layout counts as another client's.
+ *
+ * Context: Takes the flc_lock of @inode.
+ *
+ * Return: a mask of NFSD_LAYOUTS_OWN if that client holds a layout lease
+ * on @inode, NFSD_LAYOUTS_OTHER if another client holds one, and
+ * NFSD_LAYOUTS_IDLE if a lease of another client is not being broken yet.
+ */
+unsigned int nfsd4_layout_holders(struct inode *inode)
+{
+	struct file_lock_context *ctx = locks_inode_context(inode);
+	struct nfs4_client *clp = NULL;
+	unsigned int holders = 0;
+	struct svc_rqst *rqstp;
+	struct file_lease *fl;
+
+	if (!ctx || list_empty_careful(&ctx->flc_lease))
+		return 0;
+	rqstp = nfsd_current_rqst();
+	if (nfsd_v4client(rqstp)) {
+		struct nfsd_thread_local_info *ntli = rqstp->rq_private;
+
+		clp = *ntli->ntli_lease_breaker;
+	}
+
+	spin_lock(&ctx->flc_lock);
+	for_each_file_lock(fl, &ctx->flc_lease) {
+		struct nfs4_layout_stateid *ls = fl->c.flc_owner;
+
+		if (fl->fl_lmops != &nfsd4_layouts_lm_ops)
+			continue;
+		if (clp && ls->ls_stid.sc_client == clp) {
+			holders |= NFSD_LAYOUTS_OWN;
+			continue;
+		}
+		holders |= NFSD_LAYOUTS_OTHER;
+		if (!(fl->c.flc_flags &
+		      (FL_UNLOCK_PENDING | FL_DOWNGRADE_PENDING)))
+			holders |= NFSD_LAYOUTS_IDLE;
+	}
+	spin_unlock(&ctx->flc_lock);
+	return holders;
+}
+
 static void
 nfsd4_free_layout_stateid(struct nfs4_stid *stid)
 {
diff --git a/fs/nfsd/nfs4proc.c b/fs/nfsd/nfs4proc.c
index 0848baad68..4c0788b450 100644
--- a/fs/nfsd/nfs4proc.c
+++ b/fs/nfsd/nfs4proc.c
@@ -2384,6 +2384,14 @@ nfsd4_copy(struct svc_rqst *rqstp, struct nfsd4_compound_state *cstate,
 		spin_unlock(&async_copy->cp_copy.cp_clp->async_lock);
 		status = nfs_ok;
 	} else {
+		struct inode *src = file_inode(copy->nf_src->nf_file);
+		struct inode *dst = file_inode(copy->nf_dst->nf_file);
+
+		/* A copy can be done as a clone, which breaks both files */
+		status = nfserrno(nfsd_break_layouts(src,
+						     dst != src ? dst : NULL));
+		if (status)
+			goto out;
 		status = nfsd4_do_copy(copy, copy->nf_src->nf_file,
 				       copy->nf_dst->nf_file, true);
 		if ((READ_ONCE(copy->nf_dst->nf_file->f_mode) &
diff --git a/fs/nfsd/pnfs.h b/fs/nfsd/pnfs.h
index 559df0e5b7..220ab25986 100644
--- a/fs/nfsd/pnfs.h
+++ b/fs/nfsd/pnfs.h
@@ -72,12 +72,22 @@ int nfsd4_set_deviceid(struct nfsd4_deviceid *id, const struct svc_fh *fhp,
 struct nfsd4_deviceid_map *nfsd4_find_devid_map(int idx);
 #endif /* CONFIG_NFSD_V4 */
 
+/*
+ * What nfsd4_layout_holders() returns: the client of the request holds a
+ * layout lease (OWN), another client holds one (OTHER), a lease of another
+ * client is not being broken yet (IDLE).
+ */
+#define NFSD_LAYOUTS_OWN	0x1
+#define NFSD_LAYOUTS_OTHER	0x2
+#define NFSD_LAYOUTS_IDLE	0x4
+
 #ifdef CONFIG_NFSD_PNFS
 void nfsd4_setup_layout_type(struct svc_export *exp);
 void nfsd4_return_all_client_layouts(struct nfs4_client *);
 void nfsd4_return_all_file_layouts(struct nfs4_client *clp,
 		struct nfs4_file *fp);
 void nfsd4_close_layout(struct nfs4_layout_stateid *ls);
+unsigned int nfsd4_layout_holders(struct inode *inode);
 void nfsd4_stop_layout_fence(struct nfs4_layout_stateid *ls);
 int nfsd4_init_pnfs(void);
 void nfsd4_exit_pnfs(void);
@@ -101,6 +111,11 @@ static inline void nfsd4_close_layout(struct nfs4_layout_stateid *ls)
 {
 }
 
+static inline unsigned int nfsd4_layout_holders(struct inode *inode)
+{
+	return 0;
+}
+
 static inline void nfsd4_stop_layout_fence(struct nfs4_layout_stateid *ls)
 {
 }
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index 79dfa47b82..3df871d301 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -62,6 +62,7 @@
 #define	NFS4_CLIENTS_PER_GB		1024
 #define NFSD_DELEGRETURN_TIMEOUT	(HZ / 34)	/* 30ms */
 #define	NFSD_CB_GETATTR_TIMEOUT		NFSD_DELEGRETURN_TIMEOUT
+#define	NFSD_LAYOUTRETURN_TIMEOUT	NFSD_DELEGRETURN_TIMEOUT
 
 typedef struct {
 	u32             cl_boot;
diff --git a/fs/nfsd/vfs.c b/fs/nfsd/vfs.c
index f4069da853..a3303d896d 100644
--- a/fs/nfsd/vfs.c
+++ b/fs/nfsd/vfs.c
@@ -46,6 +46,7 @@
 #include "netns.h"
 #include "stats.h"
 #include "vfs.h"
+#include "pnfs.h"
 #include "filecache.h"
 #include "trace.h"
 
@@ -583,6 +584,15 @@ nfsd_setattr(struct svc_rqst *rqstp, struct svc_fh *fhp,
 		err = nfsd_get_write_access(fhp);
 		if (err)
 			return err;
+		/*
+		 * Not under inode_lock: the LAYOUTCOMMIT that a client sends
+		 * before it returns its layout takes it.
+		 */
+		err = nfserrno(nfsd_break_layouts(inode, NULL));
+		if (err) {
+			put_write_access(inode);
+			return err;
+		}
 	}
 
 	inode_lock(inode);
@@ -721,6 +731,14 @@ int nfsd_clone_file_range(struct file *src, u64 src_pos, struct file *dst,
 			  u64 dst_pos, u64 count, errseq_t *since)
 {
 	loff_t cloned;
+	int ret;
+
+	/* The filesystem breaks the layouts of both files */
+	ret = nfsd_break_layouts(file_inode(src),
+				 file_inode(dst) != file_inode(src) ?
+				 file_inode(dst) : NULL);
+	if (ret)
+		return ret;
 
 	*since = READ_ONCE(dst->f_wb_err);
 	cloned = vfs_clone_file_range(src, src_pos, dst, dst_pos, count, 0);
@@ -794,7 +812,9 @@ __be32 nfsd4_vfs_fallocate(struct svc_rqst *rqstp, struct svc_fh *fhp,
 	if (!S_ISREG(file_inode(file)->i_mode))
 		return nfserr_inval;
 
-	error = vfs_fallocate(file, flags, offset, len);
+	error = nfsd_break_layouts(file_inode(file), NULL);
+	if (!error)
+		error = vfs_fallocate(file, flags, offset, len);
 	if (!error)
 		error = commit_metadata(fhp);
 
@@ -881,6 +901,61 @@ int nfsd_open_break_lease(struct inode *inode, int access)
 	return break_lease(inode, mode | O_NONBLOCK);
 }
 
+static bool nfsd_other_layouts(struct inode *inode)
+{
+	return nfsd4_layout_holders(inode) & NFSD_LAYOUTS_OTHER;
+}
+
+/**
+ * nfsd_break_layouts - Recall the layouts of one or two files
+ * @inode: file that is about to be modified
+ * @inode2: the other file of a COPY or CLONE, or NULL
+ *
+ * A filesystem that hands out layouts recalls them before it modifies a
+ * file, and waits until they are returned or the lease break times out.
+ * The client decides how long that takes, so an nfsd thread must not wait
+ * there. Start the recalls here without waiting. When this starts the
+ * recall of layouts of other clients, give them a short time to come back,
+ * as nfsd_wait_for_delegreturn() does for delegations. Do not wait for a
+ * recall that is already under way, nor for the layouts of the client of
+ * this request, which returns them only once its I/O through them is done.
+ *
+ * Context: Process context. Sleeps for up to NFSD_LAYOUTRETURN_TIMEOUT.
+ *
+ * Return: zero if no layout is left, -EWOULDBLOCK, which nfserrno() turns
+ * into NFS4ERR_DELAY, or -ENOMEM
+ */
+int nfsd_break_layouts(struct inode *inode, struct inode *inode2)
+{
+	long timeout = NFSD_LAYOUTRETURN_TIMEOUT;
+	unsigned int holders;
+	int ret, ret2 = 0;
+
+	holders = nfsd4_layout_holders(inode);
+	if (inode2)
+		holders |= nfsd4_layout_holders(inode2);
+	if (!holders)
+		return 0;
+
+	ret = break_layout(inode, false);
+	if (inode2)
+		ret2 = break_layout(inode2, false);
+	if (ret != -EWOULDBLOCK && ret2 != -EWOULDBLOCK)
+		return ret ? ret : ret2;
+	if ((holders & NFSD_LAYOUTS_OWN) || !(holders & NFSD_LAYOUTS_IDLE))
+		return -EWOULDBLOCK;
+
+	timeout = wait_var_event_timeout(inode, !nfsd_other_layouts(inode),
+					 timeout);
+	if (inode2 && timeout)
+		wait_var_event_timeout(inode2, !nfsd_other_layouts(inode2),
+				       timeout);
+	ret = break_layout(inode, false);
+	if (!ret && inode2)
+		ret = break_layout(inode2, false);
+	return ret;
+}
+
 /*
  * Open an existing file or directory.
  * The may_flags argument indicates the type of open (read/write/lock)
@@ -1490,6 +1565,10 @@ nfsd_vfs_write(struct svc_rqst *rqstp, struct svc_fh *fhp,
 		goto out_nfserr;
 	}
 
+	host_err = nfsd_break_layouts(file_inode(file), NULL);
+	if (host_err)
+		goto out_nfserr;
+
 	since = READ_ONCE(file->f_wb_err);
 	if (verf)
 		nfsd_copy_write_verifier(verf, nn);
diff --git a/fs/nfsd/vfs.h b/fs/nfsd/vfs.h
index eb75e4c823..1f05c83a3e 100644
--- a/fs/nfsd/vfs.h
+++ b/fs/nfsd/vfs.h
@@ -171,6 +171,7 @@ __be32		nfsd_setxattr(struct svc_rqst *rqstp, struct svc_fh *fhp,
 			    char *name, void *buf, u32 len, u32 flags);
 #endif
 int 		nfsd_open_break_lease(struct inode *, int);
+int		nfsd_break_layouts(struct inode *inode, struct inode *inode2);
 __be32		nfsd_open(struct svc_rqst *, struct svc_fh *, umode_t,
 				int, struct file **);
 int		nfsd_open_verified(struct svc_fh *fhp, umode_t type, int may_flags,

-- 
2.43.0

