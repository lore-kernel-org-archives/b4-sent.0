From: =?utf-8?q?Nguy=E1=BB=85n_V=C4=83n_Cao_Nguy=C3=AAn?= <nguyennvc@greennode.ai>
Date: Wed, 30 Sep 2026 14:51:42 +0700
Subject: [PATCH rdma-rc] RDMA/irdma: Do not move a fresh RoCE QP to ERROR
 on RESET
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260930-irdma-reset-fresh-qp-v1-1-065327274e2b@greennode.ai>
X-B4-Tracking: v=1; b=H4sIAI2/vGoC/yWMuwqAMAwAf0UyG4gtFfRXxKG0UTP4SkUE8d8tO
 h033N2QWIUTtMUNyqckWZcsVVlAmPwyMkrMDoZMTY0lFI2zR+XEBw4ZE+4bBm+DI0fRGwc53ZQ
 Hub5tB38QoH+eFwU3w5FvAAAA
To: Tatyana Nikolova <tatyana.e.nikolova@intel.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>, 
 Mustafa Ismail <mustafa.ismail@intel.com>, 
 Shiraz Saleem <shiraz.saleem@intel.com>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Nguy=E1=BB=85n_V=C4=83n_Cao_Nguy=C3=AAn?= <nguyennvc@greennode.ai>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790754706; l=5208;
 i=nguyennvc@greennode.ai; s=20260930; h=from:subject:message-id;
 bh=pUE5++VACMAhAd/B/N8p6SNGcTyho6T0u18DfMJ9e8c=;
 b=MLszr+tiHZjO7nMpJnFB1NebNcFIp/nLvyNLgLgHasmznmeBmZOyoUUErj3z/tgw2DBpqtBnC
 AZXmGr882NbDCkNIk14NLs2AOBREwEOIWEpp0LEWLWYTxHZYeoo/IcP
X-Developer-Key: i=nguyennvc@greennode.ai; a=ed25519;
 pk=hD0bkhMDmCDDJQqc7LPqtK8Z3nB2eAmgkZt+R9cGcDY=
X-Endpoint-Received: by B4 Relay for nguyennvc@greennode.ai/20260930 with auth_id=1084
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

irdma_modify_qp_roce() handles IB_QPS_RESET like IB_QPS_ERR and moves
the QP to ERROR. On a QP that was never moved to INIT, this makes the
following RESET->INIT fail with -EINVAL, while ibv_query_qp() still
reports RESET.

RESET->RESET is a valid transition. The Mooncake transfer engine
resets every new QP before INIT, so it cannot connect over an E810,
while mlx5 accepts the same sequence:

  ibv_create_qp(RC)        -> RESET
  ibv_modify_qp(RESET)     -> 0
  ibv_modify_qp(INIT, ...) -> -EINVAL

Skip the hardware modify when the QP has not been moved to INIT yet
(iwarp_state is IRDMA_QP_STATE_INVALID), as there is nothing to flush.
RESET after INIT still goes to ERROR.

Fixes: b48c24c2d710 ("RDMA/irdma: Implement device supported verb APIs")
Assisted-by: LLM
Signed-off-by: Nguyễn Văn Cao Nguyên <nguyennvc@greennode.ai>
---
Tested on an E810 (firmware 1.74, RoCEv2), backported to Ubuntu
6.8.0-142 as a module. RESET (once or twice) on a fresh QP, then
INIT->RTR->RTS and an RDMA WRITE+READ: stock fails INIT with EINVAL,
patched round-trips the data, over loopback and to a second host.
RESET after INIT, RTS or ERR fails INIT with EINVAL on both drivers,
unchanged. No irdma messages in dmesg. A ConnectX-6 Dx (mlx5) passes
unpatched. Builds with W=1 on for-rc (7.3-rc5). Not tested on a for-rc
kernel.

Not changed: the iWARP path, and RESET after INIT, so INIT->RESET->INIT
and ERROR->RESET->INIT still fail. A QP in INIT may already have
receive WQEs posted, and irdma does not clear its queues on RESET, so
skipping ERROR there is not safe. A real reset would need the hardware
QP to be rebuilt. Is that worth a follow-up?

Reproducer (userspace, libibverbs):

  // gcc -o reset_then_init reset_then_init.c -libverbs && ./reset_then_init <rdma device>
  #include <stdio.h>
  #include <string.h>
  #include <infiniband/verbs.h>

  static const char *st(int s) {
      static const char *n[] = {"RESET", "INIT", "RTR", "RTS", "SQD", "SQE", "ERR"};
      return s >= 0 && s < 7 ? n[s] : "?";
  }

  static int state(struct ibv_qp *qp) {
      struct ibv_qp_attr a; struct ibv_qp_init_attr i;
      return ibv_query_qp(qp, &a, IBV_QP_STATE, &i) ? -1 : (int)a.qp_state;
  }

  int main(int argc, char **argv) {
      if (argc != 2) { fprintf(stderr, "usage: %s <rdma device>\n", argv[0]); return 2; }
      int n; struct ibv_device **l = ibv_get_device_list(&n), *d = NULL;
      for (int i = 0; i < n; i++) if (!strcmp(ibv_get_device_name(l[i]), argv[1])) d = l[i];
      if (!d) { fprintf(stderr, "%s: no such device\n", argv[1]); return 2; }

      struct ibv_context *c = ibv_open_device(d);
      struct ibv_pd *pd = c ? ibv_alloc_pd(c) : NULL;
      struct ibv_cq *cq = pd ? ibv_create_cq(c, 16, NULL, NULL, 0) : NULL;
      struct ibv_qp_init_attr qa = { .send_cq = cq, .recv_cq = cq, .qp_type = IBV_QPT_RC,
                                     .cap = { .max_send_wr = 16, .max_recv_wr = 16, .max_send_sge = 1, .max_recv_sge = 1 } };
      struct ibv_qp *qp = cq ? ibv_create_qp(pd, &qa) : NULL;
      if (!qp) { perror("setup"); return 2; }
      printf("%s (%s): created QP %u, state %s\n", argv[1], d->name, qp->qp_num, st(state(qp)));

      struct ibv_qp_attr r = { .qp_state = IBV_QPS_RESET };
      int rc = ibv_modify_qp(qp, &r, IBV_QP_STATE);
      printf("modify -> RESET: rc=%d (%s), state now %s\n", rc, rc ? strerror(rc) : "ok", st(state(qp)));

      struct ibv_qp_attr a = { .qp_state = IBV_QPS_INIT, .port_num = 1, .pkey_index = 0,
                               .qp_access_flags = IBV_ACCESS_LOCAL_WRITE | IBV_ACCESS_REMOTE_READ | IBV_ACCESS_REMOTE_WRITE };
      rc = ibv_modify_qp(qp, &a, IBV_QP_STATE | IBV_QP_PKEY_INDEX | IBV_QP_PORT | IBV_QP_ACCESS_FLAGS);
      printf("modify -> INIT:  rc=%d (%s), state now %s\n", rc, rc ? strerror(rc) : "ok", st(state(qp)));

ibv_destroy_qp(qp); ibv_destroy_cq(cq); ibv_dealloc_pd(pd); ibv_close_device(c); ibv_free_device_list(l);
      return rc ? 1 : 0;
  }
---
 drivers/infiniband/hw/irdma/verbs.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/infiniband/hw/irdma/verbs.c b/drivers/infiniband/hw/irdma/verbs.c
index 5d71300da0ff..646fddd022b1 100644
--- a/drivers/infiniband/hw/irdma/verbs.c
+++ b/drivers/infiniband/hw/irdma/verbs.c
@@ -1576,9 +1576,17 @@ int irdma_modify_qp_roce(struct ib_qp *ibqp, struct ib_qp_attr *attr,
 			issue_modify_qp = 1;
 			iwqp->suspend_pending = true;
 			break;
+		case IB_QPS_RESET:
+			/*
+			 * A QP that was never moved to INIT has nothing to
+			 * flush, so skip the hardware modify. Moving it to
+			 * ERROR would make the following INIT fail.
+			 */
+			if (iwqp->iwarp_state == IRDMA_QP_STATE_INVALID)
+				break;
+			fallthrough;
 		case IB_QPS_SQE:
 		case IB_QPS_ERR:
-		case IB_QPS_RESET:
 			if (iwqp->iwarp_state == IRDMA_QP_STATE_ERROR) {
 				iwqp->ibqp_state = attr->qp_state;
 				spin_unlock_irqrestore(&iwqp->lock, flags);

---
base-commit: 72d3fcf802c45d00b300f25b848a93c3a2bd7c7e
change-id: 20260930-irdma-reset-fresh-qp-ca3c5050da25

Best regards,
-- 
Nguyễn Văn Cao Nguyên <nguyennvc@greennode.ai>

