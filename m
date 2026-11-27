MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-bt-smp-n-v1-2-e123c04c15be@certik.com>
References: <20261127-bt-smp-n-v1-0-e123c04c15be@certik.com>
In-Reply-To: <20261127-bt-smp-n-v1-0-e123c04c15be@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 15:33:13 +0000
Subject: [PATCH bluetooth-next 2/2] Bluetooth: SMP: Keep pending LTKs
 private
To: linux-bluetooth@vger.kernel.org
Cc: Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795814356; l=9793;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=V2WTdTWxdvQ0QhhLVufYRW9+oLkCoU/8WLC9m9Yc4qc=;
 b=PW6xLAt/eTb4X38gdt9KgeaCQjXNdc9MGjdYaFQjLY1kls+swGH9fMdIi6w+G2Pmd2lLSymVP
 JJ+vLllizJkDGYGT3/G6PD7BIfBrUvhsZMS2z1xk+1kBE+vhSBFCFPY
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hci_add_ltk() can return an existing stored entry. SMP keeps the
returned pointer until pairing completes and removes it if pairing fails. A
concurrent pairing can update or remove the same entry through CTKD or an
STK request.

Allocate pending LTKs separately and publish them only when pairing
completes. Let an LE connection use its own pending Secure Connections key
for an LTK request. Re-pairing still updates the stored entry at
completion.

Fixes: 35d702719d64 ("Bluetooth: Move SMP LTK notification after key distribution")
Fixes: b5ae344d4c0f ("Bluetooth: Add full SMP BR/EDR support")
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

 include/net/bluetooth/hci_core.h |  5 +++
 net/bluetooth/hci_core.c         | 76 +++++++++++++++++++++++++-------
 net/bluetooth/hci_event.c        | 16 +++++--
 net/bluetooth/smp.c              | 34 +++++++++++---
 4 files changed, 105 insertions(+), 26 deletions(-)

diff --git a/include/net/bluetooth/hci_core.h b/include/net/bluetooth/hci_core.h
index 4aa0b49ae104..99d7a5b0defe 100644
--- a/include/net/bluetooth/hci_core.h
+++ b/include/net/bluetooth/hci_core.h
@@ -772,6 +772,7 @@ struct hci_conn {
 	__u8		pending_sec_level;
 	__u8		pin_length;
 	__u8		enc_key_size;
+	struct smp_ltk __rcu *pending_ltk;
 	__u8		mic_len;
 	__u8		req_mic_len;
 	__u8		io_capability;
@@ -1957,6 +1958,10 @@ struct link_key *hci_add_link_key(struct hci_dev *hdev, struct hci_conn *conn,
 struct smp_ltk *hci_add_ltk(struct hci_dev *hdev, bdaddr_t *bdaddr,
 			    u8 addr_type, u8 type, u8 authenticated,
 			    u8 tk[16], u8 enc_size, __le16 ediv, __le64 rand);
+struct smp_ltk *hci_new_ltk(bdaddr_t *bdaddr, u8 addr_type, u8 type,
+			    u8 authenticated, u8 tk[16], u8 enc_size,
+			    __le16 ediv, __le64 rand);
+struct smp_ltk *hci_store_ltk(struct hci_dev *hdev, struct smp_ltk *key);
 struct smp_ltk *hci_find_ltk(struct hci_dev *hdev, bdaddr_t *bdaddr,
 			     u8 addr_type, u8 role);
 int hci_remove_ltk(struct hci_dev *hdev, bdaddr_t *bdaddr, u8 bdaddr_type);
diff --git a/net/bluetooth/hci_core.c b/net/bluetooth/hci_core.c
index 024960e9af66..e0204b88d491 100644
--- a/net/bluetooth/hci_core.c
+++ b/net/bluetooth/hci_core.c
@@ -1408,22 +1408,10 @@ struct link_key *hci_add_link_key(struct hci_dev *hdev, struct hci_conn *conn,
 	return key;
 }
 
-struct smp_ltk *hci_add_ltk(struct hci_dev *hdev, bdaddr_t *bdaddr,
-			    u8 addr_type, u8 type, u8 authenticated,
-			    u8 tk[16], u8 enc_size, __le16 ediv, __le64 rand)
+static void hci_update_ltk(struct smp_ltk *key, bdaddr_t *bdaddr,
+			   u8 addr_type, u8 type, u8 authenticated,
+			   u8 tk[16], u8 enc_size, __le16 ediv, __le64 rand)
 {
-	struct smp_ltk *key, *old_key;
-	u8 role = ltk_role(type);
-
-	old_key = hci_find_ltk(hdev, bdaddr, addr_type, role);
-	if (old_key)
-		key = old_key;
-	else {
-		key = kzalloc_obj(*key);
-		if (!key)
-			return NULL;
-	}
-
 	bacpy(&key->bdaddr, bdaddr);
 	key->bdaddr_type = addr_type;
 	memcpy(key->val, tk, sizeof(key->val));
@@ -1432,9 +1420,63 @@ struct smp_ltk *hci_add_ltk(struct hci_dev *hdev, bdaddr_t *bdaddr,
 	key->rand = rand;
 	key->enc_size = enc_size;
 	key->type = type;
+}
 
-	if (!old_key)
-		list_add_rcu(&key->list, &hdev->long_term_keys);
+struct smp_ltk *hci_new_ltk(bdaddr_t *bdaddr, u8 addr_type, u8 type,
+			    u8 authenticated, u8 tk[16], u8 enc_size,
+			    __le16 ediv, __le64 rand)
+{
+	struct smp_ltk *key;
+
+	key = kzalloc_obj(*key);
+	if (!key)
+		return NULL;
+
+	INIT_LIST_HEAD(&key->list);
+	hci_update_ltk(key, bdaddr, addr_type, type, authenticated, tk,
+		       enc_size, ediv, rand);
+
+	return key;
+}
+
+struct smp_ltk *hci_store_ltk(struct hci_dev *hdev, struct smp_ltk *key)
+{
+	struct smp_ltk *old_key;
+	u8 role = ltk_role(key->type);
+
+	old_key = hci_find_ltk(hdev, &key->bdaddr, key->bdaddr_type, role);
+	if (old_key) {
+		hci_update_ltk(old_key, &key->bdaddr, key->bdaddr_type, key->type,
+			       key->authenticated, key->val, key->enc_size,
+			       key->ediv, key->rand);
+		kfree_rcu(key, rcu);
+		return old_key;
+	}
+
+	list_add_rcu(&key->list, &hdev->long_term_keys);
+
+	return key;
+}
+
+struct smp_ltk *hci_add_ltk(struct hci_dev *hdev, bdaddr_t *bdaddr,
+			    u8 addr_type, u8 type, u8 authenticated,
+			    u8 tk[16], u8 enc_size, __le16 ediv, __le64 rand)
+{
+	struct smp_ltk *key;
+
+	key = hci_find_ltk(hdev, bdaddr, addr_type, ltk_role(type));
+	if (key) {
+		hci_update_ltk(key, bdaddr, addr_type, type, authenticated, tk,
+			       enc_size, ediv, rand);
+		return key;
+	}
+
+	key = hci_new_ltk(bdaddr, addr_type, type, authenticated, tk,
+			  enc_size, ediv, rand);
+	if (!key)
+		return NULL;
+
+	list_add_rcu(&key->list, &hdev->long_term_keys);
 
 	return key;
 }
diff --git a/net/bluetooth/hci_event.c b/net/bluetooth/hci_event.c
index a9b6a6ccaa03..1b93e778912f 100644
--- a/net/bluetooth/hci_event.c
+++ b/net/bluetooth/hci_event.c
@@ -7495,18 +7495,23 @@ static void hci_le_ltk_request_evt(struct hci_dev *hdev, void *data,
 	if (conn == NULL)
 		goto not_found;
 
-	ltk = hci_find_ltk(hdev, &conn->dst, conn->dst_type, conn->role);
+	rcu_read_lock();
+
+	ltk = rcu_dereference(conn->pending_ltk);
 	if (!ltk)
-		goto not_found;
+		ltk = hci_find_ltk(hdev, &conn->dst, conn->dst_type,
+				   conn->role);
+	if (!ltk)
+		goto not_found_unlock;
 
 	if (smp_ltk_is_sc(ltk)) {
 		/* With SC both EDiv and Rand are set to zero */
 		if (ev->ediv || ev->rand)
-			goto not_found;
+			goto not_found_unlock;
 	} else {
 		/* For non-SC keys check that EDiv and Rand match */
 		if (ev->ediv != ltk->ediv || ev->rand != ltk->rand)
-			goto not_found;
+			goto not_found_unlock;
 	}
 
 	memcpy(cp.ltk, ltk->val, ltk->enc_size);
@@ -7533,10 +7538,13 @@ static void hci_le_ltk_request_evt(struct hci_dev *hdev, void *data,
 		clear_bit(HCI_CONN_STK_ENCRYPT, conn->flags);
 	}
 
+	rcu_read_unlock();
 	hci_dev_unlock(hdev);
 
 	return;
 
+not_found_unlock:
+	rcu_read_unlock();
 not_found:
 	neg.handle = ev->handle;
 	hci_send_cmd(hdev, HCI_OP_LE_LTK_NEG_REPLY, sizeof(neg), &neg);
diff --git a/net/bluetooth/smp.c b/net/bluetooth/smp.c
index 3a0fbc291878..cda15a4e28e9 100644
--- a/net/bluetooth/smp.c
+++ b/net/bluetooth/smp.c
@@ -742,6 +742,9 @@ static void smp_chan_destroy(struct l2cap_conn *conn)
 
 	crypto_free_kpp(smp->tfm_ecdh);
 
+	if (rcu_access_pointer(hcon->pending_ltk) == smp->ltk)
+		rcu_assign_pointer(hcon->pending_ltk, NULL);
+
 	/* Ensure that we don't leave any debug key around if debug key
 	 * support hasn't been explicitly enabled.
 	 */
@@ -1086,12 +1089,17 @@ static void smp_notify_keys(struct l2cap_conn *conn)
 	if (smp->ltk) {
 		smp->ltk->bdaddr_type = hcon->dst_type;
 		bacpy(&smp->ltk->bdaddr, &hcon->dst);
+		if (rcu_access_pointer(hcon->pending_ltk) == smp->ltk)
+			rcu_assign_pointer(hcon->pending_ltk, NULL);
+		smp->ltk = hci_store_ltk(hdev, smp->ltk);
 		mgmt_new_ltk(hdev, smp->ltk, persistent);
 	}
 
 	if (smp->responder_ltk) {
 		smp->responder_ltk->bdaddr_type = hcon->dst_type;
 		bacpy(&smp->responder_ltk->bdaddr, &hcon->dst);
+		smp->responder_ltk = hci_store_ltk(hdev,
+						   smp->responder_ltk);
 		mgmt_new_ltk(hdev, smp->responder_ltk, persistent);
 	}
 
@@ -1145,9 +1153,10 @@ static void sc_add_ltk(struct smp_chan *smp)
 	else
 		auth = 0;
 
-	smp->ltk = hci_add_ltk(hcon->hdev, &hcon->dst, hcon->dst_type,
-			       key_type, auth, smp->tk, smp->enc_key_size,
-			       0, 0);
+	smp->ltk = hci_new_ltk(&hcon->dst, hcon->dst_type, key_type, auth,
+			       smp->tk, smp->enc_key_size, 0, 0);
+	if (smp->ltk)
+		rcu_assign_pointer(hcon->pending_ltk, smp->ltk);
 }
 
 static void sc_generate_link_key(struct smp_chan *smp)
@@ -1307,7 +1316,7 @@ static void smp_distribute_keys(struct smp_chan *smp)
 		smp_send_cmd(conn, SMP_CMD_ENCRYPT_INFO, sizeof(enc), &enc);
 
 		authenticated = hcon->sec_level == BT_SECURITY_HIGH;
-		ltk = hci_add_ltk(hdev, &hcon->dst, hcon->dst_type,
+		ltk = hci_new_ltk(&hcon->dst, hcon->dst_type,
 				  SMP_LTK_RESPONDER, authenticated, enc.ltk,
 				  smp->enc_key_size, ediv, rand);
 		smp->responder_ltk = ltk;
@@ -2515,6 +2524,20 @@ bool smp_pairing_in_progress(struct hci_conn *hcon)
 	return pending;
 }
 
+static void smp_free_pending_ltks(struct hci_conn *hcon,
+				  struct smp_chan *smp)
+{
+	if (!smp || test_bit(SMP_FLAG_COMPLETE, &smp->flags))
+		return;
+
+	if (rcu_access_pointer(hcon->pending_ltk) == smp->ltk)
+		rcu_assign_pointer(hcon->pending_ltk, NULL);
+	if (smp->ltk)
+		kfree_rcu(smp->ltk, rcu);
+	if (smp->responder_ltk)
+		kfree_rcu(smp->responder_ltk, rcu);
+}
+
 int smp_cancel_and_remove_pairing(struct hci_dev *hdev, bdaddr_t *bdaddr,
 				  u8 addr_type)
 {
@@ -2544,6 +2567,7 @@ int smp_cancel_and_remove_pairing(struct hci_dev *hdev, bdaddr_t *bdaddr,
 	l2cap_chan_lock(chan);
 
 	smp = chan->data;
+	smp_free_pending_ltks(hcon, smp);
 	if (smp) {
 		/* Set keys to NULL to make sure smp_failure() does not try to
 		 * remove and free already invalidated rcu list entries. */
@@ -2618,7 +2642,7 @@ static int smp_cmd_initiator_ident(struct l2cap_conn *conn, struct sk_buff *skb)
 	skb_pull(skb, sizeof(*rp));
 
 	authenticated = (hcon->sec_level == BT_SECURITY_HIGH);
-	ltk = hci_add_ltk(hdev, &hcon->dst, hcon->dst_type, SMP_LTK,
+	ltk = hci_new_ltk(&hcon->dst, hcon->dst_type, SMP_LTK,
 			  authenticated, smp->tk, smp->enc_key_size,
 			  rp->ediv, rp->rand);
 	smp->ltk = ltk;
