From: Norbert Szetei <norbert@doyensec.com>
Subject: [PATCH v3 0/2] RDMA/rxe: fix ADVISE_MR prefetch on non-ODP MRs
Date: Wed, 23 Sep 2026 16:40:48 +0200
Message-Id: <20260923-rxe-advise-mr-v3-v3-0-95e1a4077e4d@doyensec.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQrCMBCE4auUfXYhJkSiVyk+xGaqK9iWjZZCy
 d1N28cPZv6VMlSQ6daspJglyzhUuFND3SsOT7CkarLGXszVOtYFHFMdgj/Ks2PnfQwmIPhzT/U
 2KXpZ9mR7P5x/jze679ahUv62/cTIdAAAAA==
X-Change-ID: 20260923-rxe-advise-mr-v3-355a808e851f
To: Zhu Yanjun <zyjzyj2000@gmail.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Leon Romanovsky <leon@kernel.org>, Bob Pearson <rpearsonhpe@gmail.com>, 
 Daisuke Matsuda <dskmtsd@gmail.com>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Zhu Yanjun <yanjun.zhu@linux.dev>, stable@vger.kernel.org, 
 Norbert Szetei <norbert@doyensec.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790174657; l=1582;
 i=norbert@doyensec.com; s=20260913; h=from:subject:message-id;
 bh=mikozMaNBzqjOG66MSgnLM0I8SxLEQRRfu0yIks795g=;
 b=kCBAAm0NwJRgHGHCrOi500SN2mG6f8WxujQo3QKTKGfYEdueaEXnP7xf403Y3kAvcYVK740kG
 VQZX4OVn8C6C1oUQ+h8Td+5ebdwNPdKm8t3kZWNtjraESP8d5ILVHbI
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

Based on for-next. In rxe_rereg_user_mr() the new check rejects the
access flags before the mr->ibmr.pd swap, where for-rc's ae36a5b609ae
("RDMA/rxe: validate access flags before swapping the MR's PD") also
moved the existing validation.

v2 -> v3:
 - rebased on for-next, no functional change
v2: https://lore.kernel.org/all/20260913-rxe-advise-mr-v2-v2-0-b806c789871c@doyensec.com/
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
base-commit: 9dcacdc41083cccff74292851bf9fde999e0731a
change-id: 20260923-rxe-advise-mr-v3-355a808e851f

Best regards,
--  
Norbert Szetei <norbert@doyensec.com>

