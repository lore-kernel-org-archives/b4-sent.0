From: Or Gerlitz <ogerlitz@ddn.com>
Date: Wed, 17 Jun 2026 14:21:05 +0300
Subject: [PATCH] RDMA/cma: Fix hardware address comparison length in
 netevent callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-fix-cma-ipoib-v1-1-03f869344304@ddn.com>
X-B4-Tracking: v=1; b=H4sIACCDMmoC/x2MQQqAIBAAvxJ7bkGFzPpKdDBbaw+ZKEQg/j3pO
 DAzBTIlpgxzVyDRw5nv0ED2HbjThoOQ98aghNJCyxE9v+guixxv3pC0NZsnOUzeQGtioib8v2W
 t9QNPEWSSXwAAAA==
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: Mark Zhang <markzhang@nvidia.com>, 
 Patrisious Haddad <phaddad@nvidia.com>, linux-rdma@vger.kernel.org, 
 Or Gerlitz <ogerlitz@ddn.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781695275; l=1464;
 i=ogerlitz@ddn.com; s=20260617; h=from:subject:message-id;
 bh=Eul/kAmRxSqGsEJ0XdQgVAd1WB0lVIsCRtMGHfKU1no=;
 b=kOS53BKFaY/FyQaD+n3SK5eJq5/rIgdmG6ymtW+l0nEHqFAWXMq9RKIMUiXCOE9ISguq8aGOC
 7ydJIoPU8k+DxMrZoDv+XdHJPD5gEtgKSWwR3LvBLn1q7v4Kcdrk2rO
X-Developer-Key: i=ogerlitz@ddn.com; a=ed25519;
 pk=BoS0g+wKx47O0XreZWOYeg+RkV6n1KWInCJyT9csyic=
X-Endpoint-Received: by B4 Relay for ogerlitz@ddn.com/20260617 with auth_id=826
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cited commit hardcoded the hardware address comparison len to ETH_ALEN.

This breaks IPoIB, which uses 20-byte addresses. By truncating the
memcmp, the CMA may incorrectly assume the target address is
unchanged and fails to abort the stalled connection.

Fix this by replacing ETH_ALEN with the dynamic neigh->dev->addr_len
to correctly evaluate the full address regardless of the link layer.

Fixes: 925d046e7e52 ("RDMA/core: Add a netevent notifier to cma")
Signed-off-by: Or Gerlitz <ogerlitz@ddn.com>
---
I caught this while reviewing the RoCE netevent callback, 
the patch is compile-tested only..
---
 drivers/infiniband/core/cma.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/infiniband/core/cma.c b/drivers/infiniband/core/cma.c
index 9480d1a51c11..e88d3efb967b 100644
--- a/drivers/infiniband/core/cma.c
+++ b/drivers/infiniband/core/cma.c
@@ -5270,7 +5270,7 @@ static int cma_netevent_callback(struct notifier_block *self,
 
 	list_for_each_entry(current_id, &ips_node->id_list, id_list_entry) {
 		if (!memcmp(current_id->id.route.addr.dev_addr.dst_dev_addr,
-			   neigh->ha, ETH_ALEN))
+			   neigh->ha, neigh->dev->addr_len))
 			continue;
 		cma_id_get(current_id);
 		if (!queue_work(cma_wq, &current_id->id.net_work))

---
base-commit: 4b99990cdf9560e8a071640baf19f312e6ae02f4
change-id: 20260617-fix-cma-ipoib-e6a8bfe159f8

Best regards,
-- 
Or Gerlitz <ogerlitz@ddn.com>

