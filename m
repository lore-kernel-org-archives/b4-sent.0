From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 14 Oct 2026 16:30:00 +0900
Subject: [PATCH v2 4/7] nfsd: run the fence script when a block layout
 lease break times out
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-nfsd-layout-recall-v2-4-764462bddfd1@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791962996; l=12794;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=qanCpdJpxGG0ielFDh6VvrGSYi2r2QkGlV2NHrTwNhQ=;
 b=X42+EPd2UiRXLwKHv+5iQW0I3ibgD+oYB86RQHsBzr/obU5C06btyxx7dVsVQTaRORQKN8cK7
 mjtQ5ebw8HTDP+mbVBshHTaxFmDy+4+ETQJb48yKijks3tfPRFs9rR4
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a lease break has waited for fs.lease-break-time,
nfsd4_layout_lm_breaker_timedout() has the client that holds the layout
fenced before the breaker goes on. For a layout type without
->fence_client, which is the block layout, it returns true at once: the
lease is removed and the operation on the server goes on while the
client still holds the layout. /sbin/nfsd-recall-failed, which
Documentation/admin-guide/nfs/pnfs-block-server.rst names as the way to
fence such a client, is only run when the CB_LAYOUTRECALL fails.

This hits a client that keeps answering the recall with NFS4_OK or
NFS4ERR_DELAY for longer than fs.lease-break-time, 45 seconds by
default, for example because its path to the device is cut. With the
previous patch the recall is polled for two lease periods, 180 seconds
by default, so the lease break times out first. A Linux client before
v6.8 answers that way (read from the code, not run), and with the next
patch every Linux client is polled that way; until now a client from
v6.8 on has the recall fail after 10 ms.

Let the fence worker run the script for a layout type without
->fence_client, and give up the lease after that. As on the recall
failure path, the exit status of the script is not looked at. The
same document says that the server retries a failed fence and keeps
the file from other clients meanwhile; that is what the fence worker
does with ->fence_client(). Doing it for the script would block the
file for good on a server that has no /sbin/nfsd-recall-failed, so
this patch leaves it as the recall failure path has it.

As for the SCSI layout since the commit this fixes, the client is then
fenced after fs.lease-break-time. That is shorter than one lease
period by default, while RFC 8881 section 12.5.5 has the server wait
one lease period after a recall before it takes further action.
Setting fs.lease-break-time to at least the lease time gives that wait
for both layout types.

The script runs on its own workqueue, nfsd4_fence, in a work item that
keeps copies of the client address and the device name and nothing of
the layout stateid or the client. The fence worker checks every 100 ms
whether it is done. Tearing down the client waits for the fence worker
since "nfsd: drain pNFS fence work during state teardown", and the
script may be what tears the client down, through
/proc/fs/nfsd/clients/<clid>/ctl: run by the fence worker itself, such a
script would wait for itself. A script that does not exit keeps the
lease, so the operation that broke it waits as long, as it does while a
SCSI fence keeps failing, and unloading nfsd waits for it too.

The recall failure path is not changed. nfsd4_cb_layout_done() still
runs the script in rpciod while the callback is in flight, and tearing
down the client waits for that callback in nfsd4_shutdown_callback(), so
a script that expires the client it fences still hangs there, as it does
without this patch: in a test with a lease time of 15 seconds, where the
recall reaches its time limit before the lease break times out, the
script stayed in its write to the ctl file, in
nfsd4_shutdown_callback(), and rpciod in call_usermodehelper_exec().
After a lease break has fenced a client, that path can also run the
script a second time, if the client does not return the layout within
the time limit of the recall.

This makes a lease break wait longer, and the next patch more so. Apply
it only together with "nfsd: answer NFS4ERR_DELAY instead of waiting for
a layout recall", earlier in this series, which keeps nfsd threads out
of that wait.

Tested together with the next patch: a client writing through a block
layout whose path to the device is cut for 70 seconds while it can still
talk to the server, default lease and lease break times, and a 4 KiB
write to the file on the server. Without this patch (the time limit and
the next patch on nfsd-testing 32eb1a60b456) the write on the server
goes on after 47 seconds and /sbin/nfsd-recall-failed is not run. With
it the script is run after 47 seconds and the write goes on then. In
both runs the client returns the layout when its path is back, and the
recall completes. With a script that expires the client it fences
through its ctl file, the script was done 36 ms after it started, and
the write on the server went on 46 seconds after it started.

Fixes: f52792f484ba ("NFSD: Enforce timeout on layout recall and integrate lease manager fencing")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 126 +++++++++++++++++++++++++++++++++++++++++++++-----
 fs/nfsd/state.h       |   4 ++
 2 files changed, 119 insertions(+), 11 deletions(-)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index f05e8f3c0f..8bcf4d5380 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -24,6 +24,22 @@ struct nfs4_layout {
 
 static struct kmem_cache *nfs4_layout_cache;
 static struct kmem_cache *nfs4_layout_stateid_cache;
+static struct workqueue_struct *nfsd4_fence_wq;
+
+/*
+ * A fence script run for a layout stateid. It keeps copies of what the
+ * script needs and none of the stateid or the client, which tearing down
+ * the client frees.
+ */
+struct nfsd4_fence_script {
+	struct work_struct	work;
+	refcount_t		ref;
+	bool			done;
+	char			addr[INET6_ADDRSTRLEN];
+	char			s_id[sizeof_field(struct super_block, s_id)];
+};
+
+#define NFSD4_FENCE_SCRIPT_POLL	(HZ / 10)
 
 static const struct nfsd4_callback_ops nfsd4_cb_layout_ops;
 static const struct lease_manager_operations nfsd4_layouts_lm_ops;
@@ -741,10 +757,8 @@ nfsd4_return_all_file_layouts(struct nfs4_client *clp, struct nfs4_file *fp)
 }
 
 static void
-nfsd4_cb_layout_fail(struct nfs4_layout_stateid *ls, struct nfsd_file *file)
+nfsd4_run_fence_script(char *addr_str, char *s_id)
 {
-	struct nfs4_client *clp = ls->ls_stid.sc_client;
-	char addr_str[INET6_ADDRSTRLEN];
 	static char const nfsd_recall_failed[] = "/sbin/nfsd-recall-failed";
 	static char *envp[] = {
 		"HOME=/",
@@ -755,15 +769,13 @@ nfsd4_cb_layout_fail(struct nfs4_layout_stateid *ls, struct nfsd_file *file)
 	char *argv[8];
 	int error;
 
-	rpc_ntop((struct sockaddr *)&clp->cl_addr, addr_str, sizeof(addr_str));
-
 	printk(KERN_WARNING
 		"nfsd: client %s failed to respond to layout recall. "
 		"  Fencing..\n", addr_str);
 
 	argv[0] = (char *)nfsd_recall_failed;
 	argv[1] = addr_str;
-	argv[2] = file->nf_file->f_path.mnt->mnt_sb->s_id;
+	argv[2] = s_id;
 	argv[3] = NULL;
 
 	error = call_usermodehelper(nfsd_recall_failed, argv, envp,
@@ -774,6 +786,57 @@ nfsd4_cb_layout_fail(struct nfs4_layout_stateid *ls, struct nfsd_file *file)
 	}
 }
 
+static void
+nfsd4_cb_layout_fail(struct nfs4_layout_stateid *ls, struct nfsd_file *file)
+{
+	struct nfs4_client *clp = ls->ls_stid.sc_client;
+	char addr_str[INET6_ADDRSTRLEN];
+
+	rpc_ntop((struct sockaddr *)&clp->cl_addr, addr_str, sizeof(addr_str));
+	nfsd4_run_fence_script(addr_str,
+			       file->nf_file->f_path.mnt->mnt_sb->s_id);
+}
+
+static void nfsd4_fence_script_put(struct nfsd4_fence_script *fs)
+{
+	if (refcount_dec_and_test(&fs->ref))
+		kfree(fs);
+}
+
+static void nfsd4_fence_script_work(struct work_struct *work)
+{
+	struct nfsd4_fence_script *fs =
+		container_of(work, struct nfsd4_fence_script, work);
+
+	nfsd4_run_fence_script(fs->addr, fs->s_id);
+	/* Pairs with the smp_load_acquire() in nfsd4_layout_fence_worker() */
+	smp_store_release(&fs->done, true);
+	nfsd4_fence_script_put(fs);
+}
+
+/*
+ * Run the fence script on nfsd4_fence_wq rather than in the fence worker,
+ * which only checks whether it is done. Tearing down the client waits for
+ * the fence worker, and the script may be what tears the client down,
+ * through /proc/fs/nfsd/clients/<clid>/ctl.
+ */
+static struct nfsd4_fence_script *
+nfsd4_start_fence_script(struct nfs4_layout_stateid *ls, struct nfsd_file *nf)
+{
+	struct nfs4_client *clp = ls->ls_stid.sc_client;
+	struct nfsd4_fence_script *fs;
+
+	fs = kzalloc_obj(*fs);
+	if (!fs)
+		return NULL;
+	refcount_set(&fs->ref, 2);
+	rpc_ntop((struct sockaddr *)&clp->cl_addr, fs->addr, sizeof(fs->addr));
+	strscpy(fs->s_id, nf->nf_file->f_path.mnt->mnt_sb->s_id);
+	INIT_WORK(&fs->work, nfsd4_fence_script_work);
+	queue_work(nfsd4_fence_wq, &fs->work);
+	return fs;
+}
+
 static bool
 nfsd4_cb_layout_prepare(struct nfsd4_callback *cb)
 {
@@ -911,6 +974,13 @@ nfsd4_layout_lm_open_conflict(struct file *filp, int arg)
 
 static void nfsd4_layout_fence_done(struct nfs4_layout_stateid *ls)
 {
+	struct nfsd4_fence_script *fs = ls->ls_fence_script;
+
+	/* The script runs on, but nothing waits for it any more. */
+	ls->ls_fence_script = NULL;
+	if (fs)
+		nfsd4_fence_script_put(fs);
+
 	/* Unlock the lease so that tasks waiting on it can proceed. */
 	nfsd4_close_layout(ls);
 
@@ -954,6 +1024,7 @@ static void nfsd4_layout_fence_worker(struct work_struct *work)
 	struct delayed_work *dwork = to_delayed_work(work);
 	struct nfs4_layout_stateid *ls = container_of(dwork,
 			struct nfs4_layout_stateid, ls_fence_work);
+	const struct nfsd4_layout_ops *ops;
 	struct nfsd_file *nf;
 	struct block_device *bdev;
 	struct nfs4_client *clp;
@@ -977,7 +1048,33 @@ static void nfsd4_layout_fence_worker(struct work_struct *work)
 	clp = ls->ls_stid.sc_client;
 	nn = net_generic(clp->net, nfsd_net_id);
 	bdev = nf->nf_file->f_path.mnt->mnt_sb->s_bdev;
-	if (nfsd4_layout_ops[ls->ls_layout_type]->fence_client(ls, nf)) {
+	ops = nfsd4_layout_ops[ls->ls_layout_type];
+	if (!ops->fence_client) {
+		struct nfsd4_fence_script *fs = ls->ls_fence_script;
+
+		/*
+		 * The layout type cannot fence. Run the fence script, as a
+		 * failed recall does, and give the lease up once it is done.
+		 */
+		if (!fs) {
+			fs = nfsd4_start_fence_script(ls, nf);
+			ls->ls_fence_script = fs;
+		}
+		nfsd_file_put(nf);
+		/* Pairs with nfsd4_fence_script_work() */
+		if (fs && smp_load_acquire(&fs->done))
+			goto dispose;
+		spin_lock(&ls->ls_lock);
+		if (ls->ls_fence_stopped) {
+			spin_unlock(&ls->ls_lock);
+			goto dispose;
+		}
+		mod_delayed_work(system_dfl_wq, &ls->ls_fence_work,
+				 NFSD4_FENCE_SCRIPT_POLL);
+		spin_unlock(&ls->ls_lock);
+		return;
+	}
+	if (ops->fence_client(ls, nf)) {
 		/* fenced ok */
 		nfsd_file_put(nf);
 		pr_warn("%s: FENCED client[%pISpc] clid[%d] to device[%s]\n",
@@ -1029,8 +1126,9 @@ static void nfsd4_layout_fence_worker(struct work_struct *work)
  * nfsd4_layout_lm_breaker_timedout - The layout recall has timed out.
  * @fl: file to check
  *
- * If the layout type supports a fence operation, schedule a worker to
- * fence the client from accessing the block device.
+ * Schedule a worker to fence the client from accessing the block device.
+ * If the layout type has no fence operation, the worker runs the fence
+ * script instead.
  *
  * This function runs under the protection of the spin_lock flc_lock.
  * At this time, the file_lease associated with the layout stateid is
@@ -1052,8 +1150,6 @@ nfsd4_layout_lm_breaker_timedout(struct file_lease *fl)
 {
 	struct nfs4_layout_stateid *ls = fl->c.flc_owner;
 
-	if (!nfsd4_layout_ops[ls->ls_layout_type]->fence_client)
-		return true;
 	/*
 	 * Make sure layout has not been returned yet before
 	 * taking a reference count on the layout stateid. The
@@ -1107,6 +1203,13 @@ nfsd4_init_pnfs(void)
 		kmem_cache_destroy(nfs4_layout_cache);
 		return -ENOMEM;
 	}
+
+	nfsd4_fence_wq = alloc_workqueue("nfsd4_fence", WQ_UNBOUND, 0);
+	if (!nfsd4_fence_wq) {
+		kmem_cache_destroy(nfs4_layout_stateid_cache);
+		kmem_cache_destroy(nfs4_layout_cache);
+		return -ENOMEM;
+	}
 	return 0;
 }
 
@@ -1115,6 +1218,7 @@ nfsd4_exit_pnfs(void)
 {
 	int i;
 
+	destroy_workqueue(nfsd4_fence_wq);
 	kmem_cache_destroy(nfs4_layout_cache);
 	kmem_cache_destroy(nfs4_layout_stateid_cache);
 
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index 0920c83857..45bd5c122c 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -843,6 +843,8 @@ static inline struct nfs4_ol_stateid *openlockstateid(struct nfs4_stid *s)
 	return container_of(s, struct nfs4_ol_stateid, st_stid);
 }
 
+struct nfsd4_fence_script;
+
 struct nfs4_layout_stateid {
 	struct nfs4_stid		ls_stid;
 	struct list_head		ls_perclnt;
@@ -863,6 +865,8 @@ struct nfs4_layout_stateid {
 	bool				ls_fenced;
 	bool				ls_fence_inflight;
 	bool				ls_fence_stopped;
+	/* The fence script the fence worker waits for */
+	struct nfsd4_fence_script	*ls_fence_script;
 };
 
 static inline struct nfs4_layout_stateid *layoutstateid(struct nfs4_stid *s)

-- 
2.43.0

