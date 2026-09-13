From: Norbert Szetei <norbert@doyensec.com>
Subject: [PATCH v2 0/2] RDMA/rxe: fix ADVISE_MR prefetch on non-ODP MRs
Date: Sun, 13 Sep 2026 13:45:14 +0200
Message-Id: <20260913-rxe-advise-mr-v2-v2-0-b806c789871c@doyensec.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QpFUBCF4VfRXJvaRpHzKjoXZhuM4mg2UvLut
 uPyq7X+E4KYSoBPcoLJrkF/cwSlCfihmXtBbaOBHBWuynK0Q7Bp41BwMtwJq5IzR1wyFx7ibTH
 p9Pgn6+/rsPEofn06cF03ttphCXQAAAA=
X-Change-ID: 20260913-rxe-advise-mr-v2-97b102b7bb6c
To: Zhu Yanjun <zyjzyj2000@gmail.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Leon Romanovsky <leon@kernel.org>, Bob Pearson <rpearsonhpe@gmail.com>, 
 Daisuke Matsuda <dskmtsd@gmail.com>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Zhu Yanjun <yanjun.zhu@linux.dev>, Norbert Szetei <norbert@doyensec.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789300003; l=1834;
 i=norbert@doyensec.com; s=20260913; h=from:subject:message-id;
 bh=q5TKN32g5tRPa2GMvzux/v2i38wCpGQecf0oQjVNALs=;
 b=hYZWDWlFLXaBI0EBj3Qojkc7OJTzdrFVGyn1hLQBFgsM8nyjMZbg769prDM6MvJJzaw7+VGFM
 1pi10Pm4MuBA3qGdFcAnNjy5Tfa9lm6aLX0LzuWnDBtrq/gEOm6fd9l
X-Developer-Key: i=norbert@doyensec.com; a=ed25519;
 pk=c6ZqJ+mhvi5FloJOiMJUcIPPjT7tczbglx5gruwpVi8=
X-Endpoint-Received: by B4 Relay for norbert@doyensec.com/20260913 with auth_id=1029
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ADVISE_MR prefetch on a plain MR runs to_ib_umem_odp() on a struct
ib_umem, giving a KASAN slab-out-of-bounds read in
ib_umem_odp_map_dma_and_lock() (splat in patch 2).

v1 checked is_odp_mr() after lookup_mr(). Leon asked for lookup_mr() to
do the check itself, off mr->access. That only holds once mr->access
cannot disagree with the umem, so patch 1 stops the two paths that
assign mr->access after registration from touching IB_ACCESS_ON_DEMAND,
and patch 2 passes the flag to lookup_mr() in both prefetch arms.

Patch 1 adds another failure return to rxe_rereg_user_mr(), so it
depends on ae36a5b609ae ("RDMA/rxe: validate access flags before
swapping the MR's PD"), which moved the validation above the
mr->ibmr.pd swap. The series is based on for-rc.

v1 -> v2:
 - patch 1 (new): reject IB_ACCESS_ON_DEMAND in rxe_rereg_user_mr() and
   rxe_reg_fast_mr(), so mr->access keeps agreeing with the umem
 - patch 2: use lookup_mr(..., IB_ACCESS_ON_DEMAND) instead of an
   explicit is_odp_mr() check; a non-ODP MR now fails with -EINVAL from
   lookup_mr() rather than -EOPNOTSUPP
 - dropped Zhu Yanjun's Reviewed-by, the implementation changed

v1: https://lore.kernel.org/all/521D5E74-89E3-43C0-81C7-AC0BE52591E7@doyensec.com/

Signed-off-by: Norbert Szetei <norbert@doyensec.com>
---
Norbert Szetei (2):
      RDMA/rxe: Reject IB_ACCESS_ON_DEMAND changes after MR creation
      RDMA/rxe: Reject prefetch of a non-ODP MR

 drivers/infiniband/sw/rxe/rxe_mr.c    | 6 ++++++
 drivers/infiniband/sw/rxe/rxe_odp.c   | 4 ++--
 drivers/infiniband/sw/rxe/rxe_verbs.c | 6 ++++++
 3 files changed, 14 insertions(+), 2 deletions(-)
---
base-commit: e22a3627b7151754f07f90ea3d1ab6e85f5d93f4
change-id: 20260913-rxe-advise-mr-v2-97b102b7bb6c

Best regards,
--  
Norbert Szetei <norbert@doyensec.com>

