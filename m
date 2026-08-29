From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 29 Aug 2026 05:32:48 -0700
Subject: [PATCH v2] ceph: unregister aborted requests in
 ceph_mdsc_wait_request()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-b4-ceph-fix-abort-request-uaf-new-v2-1-b5e73c6b2550@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42OQQ6CMBBFr0Jm7ZjSIBZX3sOwKGWQGqXYKSgh3
 N2Cce/yJS///RmYvCWGUzKDp9GydV0EuUvAtLq7Eto6Mkghc6HkEasMDfUtNvaNunI+oKfnQBx
 w0A129EJdqEaZvNZCEMSd3lOUt8al/DIP1Y1MWIdXo7UcnJ+2E2O6er+e+qM3pphikVOmRH3QQ
 qqzuU/s9sY9oFyW5QMb7r0P5AAAAA==
X-Change-ID: 20260827-b4-ceph-fix-abort-request-uaf-new-a98f8c6da00e
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, Sage Weil <sage@newdream.net>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788006773; l=7813;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=mBoO7K1ap0h6DlokydHpLEcESCw/nur8ebMFieXG6bo=;
 b=d9o9w7RunICDeuUzbpHrLymQmVwqt5Kfo0dpJh4MhhIkiBJmBX1KzYrri4REmHOcvU2M9Kjf4
 nFQ1x0wgP40D1U6bXfBVDPXKZTkqQb34TTpanfO79DOh5QHn/Bwd8zf
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a request is aborted because the waiter was killed or the wait
timed out, the abort path marks it with CEPH_MDS_R_ABORTED but leaves
it parked on a wait list (r_wait) and registered in the request tree.
The waiter's put can then be the last reference while the request is
still linked, freeing it with r_wait non-empty:

  WARNING: fs/ceph/mds_client.c:1233 ceph_mdsc_release_request+0x247/0x250
  WARN_ON_ONCE(!list_empty(&req->r_wait))

The freed request stays behind as a dangling entry on the session's
waiting list, and the next __wake_requests() or kick_requests() walk
uses it after free (a stress test that SIGKILLs waiters during MDS
failovers reproduces this reliably).

Fix the abort path so that the request is removed from its wait list
and from the request tree when the waiter gives up, making the waiter's
put the final reference on a request that is no longer linked anywhere.
Both operations happen under mdsc->mutex; a racing reply or forward may
already have unregistered the request, so only unregister it when it is
still in the tree.

Fixes: e1518c7c0a67a ("ceph: clean up mds reply, error handling")
Cc: stable@vger.kernel.org
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
The full call trace:

 ------------[ cut here ]------------
 refcount_t: addition on 0; use-after-free.
 WARNING: lib/refcount.c:25 at refcount_warn_saturate+0x6a/0x90, CPU#1: kworker/1:1/99
 Modules linked in: ceph libceph krb5 netfs xsk_diag vsock_diag uinput snd_seq_dummy snd_hrtimer rfkill nf_conntrack_netbios_ns nf_conntrack_broadcast nft_fib_inet nft_fib_ipv4 nft_fib_ipv6 nft_fib nft_reject_inet nf_reject_ipv4 nf_reject_ipv6 nft_reject nft_ct nft_chain_nat nf_nat nf_conntrack nf_defrag_ipv6 nf_defrag_ipv4 nf_tables qrtr sunrpc intel_rapl_msr intel_rapl_common intel_uncore_frequency_common intel_pmc_core pmt_telemetry pmt_discovery pmt_class intel_pmc_ssram_telemetry intel_pmc_pwrm_telemetry intel_vsec kvm_intel kvm snd_hda_codec_generic irqbypass snd_hda_intel rapl snd_hda_codec snd_hda_core snd_intel_dspcfg snd_intel_sdw_acpi snd_hwdep snd_seq iTCO_wdt snd_seq_device intel_pmc_bxt snd_pcm i2c_i801 snd_timer pcspkr i2c_smbus snd lpc_ich virtio_balloon soundcore joydev zram lz4hc_compress vmw_vsock_virtio_transport vmw_vsock_virtio_transport_common vsock virtio_net net_failover virtio_gpu failover virtio_dma_buf serio_raw i2c_dev qemu_fw_cfg virtiofs fuse
 CPU: 1 UID: 0 PID: 99 Comm: kworker/1:1 Tainted: G      D             7.2.0-rc7-lockdep+ #13 PREEMPT(lazy)
 Tainted: [D]=DIE
 Hardware name: QEMU Standard PC (Q35 + ICH9, 2009), BIOS 1.17.0-10.fc44 06/10/2025
 Workqueue: ceph-msgr ceph_con_workfn [libceph]
 RIP: 0010:refcount_warn_saturate+0x6a/0x90
 Code: cc 48 8d 3d b8 f6 d4 01 67 48 0f b9 3a c3 cc cc cc cc 48 8d 3d b7 f6 d4 01 67 48 0f b9 3a c3 cc cc cc cc 48 8d 3d b6 f6 d4 01 <67> 48 0f b9 3a c3 cc cc cc cc 48 8d 3d b5 f6 d4 01 67 48 0f b9 3a
 RSP: 0018:ffffcdb6403a7cc0 EFLAGS: 00010246
 RAX: 0000000000000000 RBX: ffff8d5e6441c000 RCX: ffff8d5e43de6a60
 RDX: ffff8d5e5afbd468 RSI: 0000000000000002 RDI: ffffffffa7fbe040
 RBP: ffffcdb6403a7ce8 R08: 0000000000000001 R09: ffff8d5e5afbd550
 R10: ffffcdb6403a7cc8 R11: 0000000000000000 R12: ffff8d5e6441c000
 R13: ffff8d5e5afbd028 R14: ffff8d5e515c0000 R15: ffff8d5e5a621008
 FS:  0000000000000000(0000) GS:ffff8d61f7904000(0000) knlGS:0000000000000000
 CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
 CR2: 00007f0541dbf000 CR3: 000000011ad8b005 CR4: 0000000000772ef0
 PKRU: 55555554
 Call Trace:
  <TASK>
  __wake_requests+0x3af/0x3d0 [ceph]
  mds_dispatch+0xad/0x240 [ceph]
  ceph_con_process_message+0x88/0x1c0 [libceph]
  ceph_con_v1_try_read+0x316/0x6f0 [libceph]
  ceph_con_workfn+0x1f4/0x500 [libceph]
  ? process_one_work+0x20d/0x600
  process_one_work+0x234/0x600
  worker_thread+0x1e5/0x3c0
  ? __pfx_worker_thread+0x10/0x10
  kthread+0xf5/0x130
  ? __pfx_kthread+0x10/0x10
  ret_from_fork+0x24a/0x360
  ? __pfx_kthread+0x10/0x10
  ret_from_fork_asm+0x1a/0x30
  </TASK>
 irq event stamp: 7923424
 hardirqs last  enabled at (7923423): [<ffffffffa6d5b2a8>] _raw_spin_unlock_irq+0x28/0x50
 hardirqs last disabled at (7923424): [<ffffffffa6d4cdb5>] __schedule+0x685/0x820
---
Changes in v2:
- Closed a race between the new abort-path unregister and
  handle_reply()'s trace fill: the fill path links
  r_unsafe_target_item onto the inode's unsafe list without
  mdsc->mutex, so the abort path can list_del_init() the item before
  it is ever linked (a no-op), after which the fill links it and no
  one is left to unlink it -- the item then dangles past the request's
  lifetime and the next link on that inode trips DEBUG_LIST ("list_add
  corruption") (reproduced under victim-kill + failover stress).  Take
  mdsc->mutex around the link and only link when the request is not
  aborted and is still registered in the request tree.
- Link to v1: https://patch.msgid.link/20260828-b4-ceph-fix-abort-request-uaf-new-v1-1-96e480d5a028@clyso.com

To: Ilya Dryomov <idryomov@gmail.com>
To: Alex Markuze <amarkuze@redhat.com>
To: Viacheslav Dubeyko <slava@dubeyko.com>
To: Sage Weil <sage@newdream.net>
Cc: ceph-devel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 fs/ceph/mds_client.c | 39 +++++++++++++++++++++++++++++++++++----
 1 file changed, 35 insertions(+), 4 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 85f8ceb10377..7e545e4a3750 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -4024,6 +4024,19 @@ int ceph_mdsc_wait_request(struct ceph_mds_client *mdsc,
 		if (req->r_parent &&
 		    (req->r_op & CEPH_MDS_OP_WRITE))
 			ceph_invalidate_dir_request(req);
+
+		/*
+		 * The waiter is about to drop its reference, which is
+		 * the last one held by the request's caller.  Make sure
+		 * the request is no longer parked on a wait list or
+		 * registered in the request tree, or it could be walked
+		 * (and in the tree case, replied to) after it is freed.
+		 * A racing reply may already have unregistered it, in
+		 * which case it is no longer in the tree.
+		 */
+		list_del_init(&req->r_wait);
+		if (lookup_request(&mdsc->request_tree, req->r_tid) == req)
+			__unregister_request(mdsc, req);
 	} else {
 		err = req->r_err;
 	}
@@ -4268,10 +4281,28 @@ static void handle_reply(struct ceph_mds_session *session, struct ceph_msg *msg)
 		    test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags)) {
 			struct ceph_inode_info *ci =
 				ceph_inode(req->r_target_inode);
-			spin_lock(&ci->i_unsafe_lock);
-			list_add_tail(&req->r_unsafe_target_item,
-				      &ci->i_unsafe_iops);
-			spin_unlock(&ci->i_unsafe_lock);
+
+			/*
+			 * The waiter may have aborted the request while we
+			 * were filling the trace above, in which case
+			 * __unregister_request() has already unlinked
+			 * r_unsafe_target_item (a no-op, the item was not
+			 * linked yet) and removed the request from the
+			 * request tree.  Only link the item onto the
+			 * inode's unsafe list when the request is still
+			 * registered, so that a later __unregister_request()
+			 * is the one to unlink it.
+			 */
+			mutex_lock(&mdsc->mutex);
+			if (!test_bit(CEPH_MDS_R_ABORTED, &req->r_req_flags) &&
+			    lookup_request(&mdsc->request_tree,
+					   req->r_tid) == req) {
+				spin_lock(&ci->i_unsafe_lock);
+				list_add_tail(&req->r_unsafe_target_item,
+					      &ci->i_unsafe_iops);
+				spin_unlock(&ci->i_unsafe_lock);
+			}
+			mutex_unlock(&mdsc->mutex);
 		}
 
 		ceph_unreserve_caps(mdsc, &req->r_caps_reservation);

---
base-commit: dee30ce1286a0d18b14545ecac345e4cf4a80511
change-id: 20260827-b4-ceph-fix-abort-request-uaf-new-a98f8c6da00e

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

