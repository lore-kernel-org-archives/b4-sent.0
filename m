From: Satish Kharat <satishkh@cisco.com>
Date: Tue, 04 Mar 2025 19:56:41 -0500
Subject: [PATCH net-next v2 5/8] enic : remove unused function
 cq_enet_wq_desc_dec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-enic_cleanup_and_ext_cq-v2-5-85804263dad8@cisco.com>
References: <20250304-enic_cleanup_and_ext_cq-v2-0-85804263dad8@cisco.com>
In-Reply-To: <20250304-enic_cleanup_and_ext_cq-v2-0-85804263dad8@cisco.com>
To: Christian Benvenuti <benve@cisco.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Satish Kharat <satishkh@cisco.com>, Nelson Escobar <neescoba@cisco.com>, 
 John Daley <johndale@cisco.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741136202; l=1103;
 i=satishkh@cisco.com; s=20250226; h=from:subject:message-id;
 bh=+dPGv5N9MWqWyMEvqnn1fc2Fu6Bu+7Wi7gCqqsYQK6M=;
 b=VUI8+9j9uSWTnuX0XkDjSnpylJM3UmNKFGC2BgFkqo51jBGh6s0MF6lZxQGvgwP0oNuEo9ecf
 BkoPODpIiujDxscGTYHs3kaauq7nDlkK+AocADPC2p3vnVManRBN2vq
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=lkxzORFYn5ejiy0kzcsfkpGoXZDcnHMc4n3YK7jJnJo=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/20250226 with auth_id=351
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Removes cq_enet_wq_desc_dec, not needed anymore.

Co-developed-by: Nelson Escobar <neescoba@cisco.com>
Signed-off-by: Nelson Escobar <neescoba@cisco.com>
Co-developed-by: John Daley <johndale@cisco.com>
Signed-off-by: John Daley <johndale@cisco.com>
Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/cq_enet_desc.h | 7 -------
 1 file changed, 7 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/cq_enet_desc.h b/drivers/net/ethernet/cisco/enic/cq_enet_desc.h
index 809a3f30b87f78285414990a2a42c9a30a8662c6..50787cff29db0cc9041093521385781cf557e4cc 100644
--- a/drivers/net/ethernet/cisco/enic/cq_enet_desc.h
+++ b/drivers/net/ethernet/cisco/enic/cq_enet_desc.h
@@ -17,13 +17,6 @@ struct cq_enet_wq_desc {
 	u8 type_color;
 };
 
-static inline void cq_enet_wq_desc_dec(struct cq_enet_wq_desc *desc,
-	u8 *type, u8 *color, u16 *q_number, u16 *completed_index)
-{
-	cq_desc_dec((struct cq_desc *)desc, type,
-		color, q_number, completed_index);
-}
-
 /*
  * Defines and Capabilities for CMD_CQ_ENTRY_SIZE_SET
  */

-- 
2.48.1

