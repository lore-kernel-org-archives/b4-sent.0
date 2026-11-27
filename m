MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-bt-smp-n-v1-1-e123c04c15be@certik.com>
References: <20261127-bt-smp-n-v1-0-e123c04c15be@certik.com>
In-Reply-To: <20261127-bt-smp-n-v1-0-e123c04c15be@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 15:31:51 +0000
Subject: [PATCH bluetooth-next 1/2] Bluetooth: SMP: Defer IRK updates until
 pairing completes
To: linux-bluetooth@vger.kernel.org
Cc: Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795814356; l=3994;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=xcwj8WZ/dFluIe0JR28QFFTUFzVXNxId8GhbSTKloLk=;
 b=elCItR9I9cQpbQOSPaUKRzfG+rE3idU7JaqIJ6IfCPuwosMaBlsp1BbJtNExgZnfUv6hZ91jP
 Bc02eR2U7Y4C47Tq3iJV/NbMjspnft0Xc1hdGp3aqmmt1I5Sp2mDjCS
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hci_add_irk() can return an existing entry when two pairing contexts
distribute the same identity. Both contexts save that pointer in
remote_irk. If either pairing fails, smp_chan_destroy() removes and frees
the shared entry, leaving the other context with a dangling pointer.

Keep the received IRK in the pairing context and add or update the
resolving list only when pairing completes. Incomplete contexts no longer
share list entries, while completed re-pairings still update an existing
IRK.

Fixes: 759331d7cc66 ("Bluetooth: Fix clearing SMP keys if pairing fails")
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

 net/bluetooth/smp.c | 39 ++++++++++++++++++++-------------------
 1 file changed, 20 insertions(+), 19 deletions(-)

diff --git a/net/bluetooth/smp.c b/net/bluetooth/smp.c
index 62a6b1e8f7cb..3a0fbc291878 100644
--- a/net/bluetooth/smp.c
+++ b/net/bluetooth/smp.c
@@ -111,7 +111,7 @@ struct smp_chan {
 	struct smp_csrk	*responder_csrk;
 	struct smp_ltk	*ltk;
 	struct smp_ltk	*responder_ltk;
-	struct smp_irk	*remote_irk;
+	bool		remote_irk_pending;
 	u8		*link_key;
 	unsigned long	flags;
 	u8		method;
@@ -763,11 +763,6 @@ static void smp_chan_destroy(struct l2cap_conn *conn)
 			list_del_rcu(&smp->responder_ltk->list);
 			kfree_rcu(smp->responder_ltk, rcu);
 		}
-
-		if (smp->remote_irk) {
-			list_del_rcu(&smp->remote_irk->list);
-			kfree_rcu(smp->remote_irk, rcu);
-		}
 	}
 
 	chan->data = NULL;
@@ -1043,16 +1038,29 @@ static void smp_notify_keys(struct l2cap_conn *conn)
 				SMP_AUTH_BONDING);
 	}
 
-	if (smp->remote_irk) {
-		mgmt_new_irk(hdev, smp->remote_irk, persistent);
+	if (smp->remote_irk_pending) {
+		struct smp_irk *irk;
+		bdaddr_t rpa;
+
+		if (hci_bdaddr_is_rpa(&hcon->dst, hcon->dst_type))
+			bacpy(&rpa, &hcon->dst);
+		else
+			bacpy(&rpa, BDADDR_ANY);
+
+		irk = hci_add_irk(hdev, &smp->id_addr, smp->id_addr_type,
+				  smp->irk, &rpa);
+		if (!irk)
+			goto notify_csrk;
+
+		mgmt_new_irk(hdev, irk, persistent);
 
 		/* Now that user space can be considered to know the
 		 * identity address track the connection based on it
 		 * from now on (assuming this is an LE link).
 		 */
 		if (hcon->type == LE_LINK) {
-			bacpy(&hcon->dst, &smp->remote_irk->bdaddr);
-			hcon->dst_type = smp->remote_irk->addr_type;
+			bacpy(&hcon->dst, &irk->bdaddr);
+			hcon->dst_type = irk->addr_type;
 			/* Use a short delay to make sure the new address is
 			 * propagated _before_ the channels.
 			 */
@@ -1062,6 +1070,7 @@ static void smp_notify_keys(struct l2cap_conn *conn)
 		}
 	}
 
+notify_csrk:
 	if (smp->csrk) {
 		smp->csrk->bdaddr_type = hcon->dst_type;
 		bacpy(&smp->csrk->bdaddr, &hcon->dst);
@@ -2540,7 +2549,6 @@ int smp_cancel_and_remove_pairing(struct hci_dev *hdev, bdaddr_t *bdaddr,
 		 * remove and free already invalidated rcu list entries. */
 		smp->ltk = NULL;
 		smp->responder_ltk = NULL;
-		smp->remote_irk = NULL;
 
 		if (test_bit(SMP_FLAG_COMPLETE, &smp->flags))
 			smp_failure(conn, 0);
@@ -2656,7 +2664,6 @@ static int smp_cmd_ident_addr_info(struct l2cap_conn *conn,
 	struct l2cap_chan *chan = conn->smp;
 	struct smp_chan *smp = chan->data;
 	struct hci_conn *hcon = conn->hcon;
-	bdaddr_t rpa;
 
 	bt_dev_dbg(hcon->hdev, "");
 
@@ -2703,13 +2710,7 @@ static int smp_cmd_ident_addr_info(struct l2cap_conn *conn,
 	bacpy(&smp->id_addr, &info->bdaddr);
 	smp->id_addr_type = info->addr_type;
 
-	if (hci_bdaddr_is_rpa(&hcon->dst, hcon->dst_type))
-		bacpy(&rpa, &hcon->dst);
-	else
-		bacpy(&rpa, BDADDR_ANY);
-
-	smp->remote_irk = hci_add_irk(conn->hcon->hdev, &smp->id_addr,
-				      smp->id_addr_type, smp->irk, &rpa);
+	smp->remote_irk_pending = true;
 
 distribute:
 	if (!(smp->remote_key_dist & KEY_DIST_MASK))
