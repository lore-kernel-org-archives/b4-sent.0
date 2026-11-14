From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 14 Nov 2026 14:09:28 -0500
Subject: [PATCH net v2 1/2] dibs: loopback: reset the client id when the
 owner unregisters a DMB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-disp-4e6374c2-v2-1-3b7050bddef7@proton.me>
References: <20261114-b4-disp-4e6374c2-v2-0-3b7050bddef7@proton.me>
In-Reply-To: <20261114-b4-disp-4e6374c2-v2-0-3b7050bddef7@proton.me>
To: Dust Li <dust.li@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>
Cc: Hidayath Khan <hidayath@linux.ibm.com>, linux-kernel@vger.kernel.org, 
 linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, Tony Lu <tonylu@linux.alibaba.com>, 
 Wen Gu <guwen@linux.alibaba.com>, linux-s390@vger.kernel.org, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Julian Ruess <julianr@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794683367; l=2169;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=KBghDMOoyAS0OHozRJLfnD9xGKdfuhieCEeZH/+0AEo=;
 b=/9l8QPQYZLAIou3waAEOmy+zpFjlJVw19f5ZDrxH/n1Pdo4KNR8nNujFrK+VzFgABmShbGPew
 W6a1rVU+4TLC7ExKV491fm+hkAuA4Or/R3n7Sqkr50NmdSy6nTUKyVp
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dibs_lo_unregister_dmb() resets the DMB's dmb_clientid_arr[] entry only
on the last put. If an attacher still holds the DMB, as when an SMC link
group is freed while a peer is still attached, the entry stays set after
the attacher's dibs_lo_detach_dmb() frees the DMB.
dibs_unregister_client() then warns at rmmod smc and returns -EBUSY,
which smc_ism_exit() ignores: smc stays in clients[] and dibs->subs[],
and a later dibs_dev_add() or dibs_dev_del() (rmmod dibs, ISM hotplug)
calls into the unloaded module.

Reset the entry when the owner unregisters, before its put, as
ism_unregister_dmb() does. The index stays allocated until the last put,
and the attacher's writes no longer raise an interrupt for a client that
gave the DMB up.

Fixes: cc21191b584c ("dibs: Move data path to dibs layer")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/dibs/dibs_loopback.c | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)

diff --git a/drivers/dibs/dibs_loopback.c b/drivers/dibs/dibs_loopback.c
index 44a2e74c2efc..566e61a013d0 100644
--- a/drivers/dibs/dibs_loopback.c
+++ b/drivers/dibs/dibs_loopback.c
@@ -138,6 +138,13 @@ static int dibs_lo_unregister_dmb(struct dibs_dev *dibs, struct dibs_dmb *dmb)
 
 	ldev = dibs->drv_priv;
 
+	/* Reset before the owner's put: after it, an attacher's detach can
+	 * free the index for a new DMB.
+	 */
+	spin_lock_irqsave(&dibs->lock, flags);
+	dibs->dmb_clientid_arr[dmb->idx] = NO_DIBS_CLIENT;
+	spin_unlock_irqrestore(&dibs->lock, flags);
+
 	/* find dmb from hash table */
 	write_lock_bh(&ldev->dmb_ht_lock);
 	hash_for_each_possible(ldev->dmb_ht, tmp_node, list, dmb->dmb_tok) {
@@ -155,13 +162,8 @@ static int dibs_lo_unregister_dmb(struct dibs_dev *dibs, struct dibs_dmb *dmb)
 		hash_del(&dmb_node->list);
 	write_unlock_bh(&ldev->dmb_ht_lock);
 
-	if (last) {
-		spin_lock_irqsave(&dibs->lock, flags);
-		dibs->dmb_clientid_arr[dmb_node->sba_idx] = NO_DIBS_CLIENT;
-		spin_unlock_irqrestore(&dibs->lock, flags);
-
+	if (last)
 		dibs_lo_free_dmb(ldev, dmb_node);
-	}
 	return 0;
 }
 

-- 
2.56.0

