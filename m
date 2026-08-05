From: Junrui Luo <moonafterrain@outlook.com>
Date: Wed, 05 Aug 2026 21:29:36 +0800
Subject: [PATCH net 1/2] ovpn: don't deref NULL key slot in
 ovpn_crypto_kill_key()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-ovpn-fixes-v1-1-763f8c237fb9@outlook.com>
References: <20260805-ovpn-fixes-v1-0-763f8c237fb9@outlook.com>
In-Reply-To: <20260805-ovpn-fixes-v1-0-763f8c237fb9@outlook.com>
To: Antonio Quartulli <antonio@openvpn.net>, 
 Sabrina Dubroca <sd@queasysnail.net>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2265;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=+hGqRph43hI3EHGuSRr41Hxklz8QgbQe6xejFC8nD6M=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrGKrq+bzZ1za/uR7WKBIdV648vGfem4OZ3e3RTixn
 TKvkZnzpaWjlIVBjItBVkyR5XjBpW8Wvlt0t/hsSYaZw8oEMoSBi1MAJtL5geGv4MEPbu4BBvpu
 CT8DTn1h1Pn0L3Cny/WtV41aNS+yymysYfinVNTwdt7Do2ffrFrp2lolu2PtsqecEw+KcTudc/O
 NmmPDDgAw3E0t
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ovpn_crypto_kill_key() is reached from ovpn_encrypt_post() when the
packet ID space of the key in use has been exhausted and
ovpn_pktid_xmit_next() returns -ERANGE. It locates the slot holding the
given key ID by reading cs->slots[0] and cs->slots[1] and comparing
->key_id, but it dereferences both pointers without first checking them
for NULL.

An empty key slot is a perfectly normal state. Both
ovpn_crypto_key_slot_delete() and ovpn_crypto_state_release() install
NULL, and the ordinary rekeying sequence - install a new key in the
secondary slot, swap, then delete the retired one - leaves primary_idx
at 1 with slots[0] empty. In that state the very first comparison
dereferences NULL. key_id sits at offset 0 of struct
ovpn_crypto_key_slot, so this faults on a read of address 0.

Every other slot accessor in this file already guards the pointer before
touching it, e.g. ovpn_crypto_key_id_to_slot():

	ks = rcu_dereference(cs->slots[idx]);
	if (ks && ks->key_id == key_id)

Use the same NULL-safe form here.

Fixes: 89d3c0e4612a ("ovpn: kill key and notify userspace in case of IV exhaustion")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/net/ovpn/crypto.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ovpn/crypto.c b/drivers/net/ovpn/crypto.c
index 90580e32052f..2c56fb180ed8 100644
--- a/drivers/net/ovpn/crypto.c
+++ b/drivers/net/ovpn/crypto.c
@@ -60,10 +60,12 @@ bool ovpn_crypto_kill_key(struct ovpn_crypto_state *cs, u8 key_id)
 	struct ovpn_crypto_key_slot *ks = NULL;
 
 	spin_lock_bh(&cs->lock);
-	if (rcu_access_pointer(cs->slots[0])->key_id == key_id) {
+	if (rcu_access_pointer(cs->slots[0]) &&
+	    rcu_access_pointer(cs->slots[0])->key_id == key_id) {
 		ks = rcu_replace_pointer(cs->slots[0], NULL,
 					 lockdep_is_held(&cs->lock));
-	} else if (rcu_access_pointer(cs->slots[1])->key_id == key_id) {
+	} else if (rcu_access_pointer(cs->slots[1]) &&
+		   rcu_access_pointer(cs->slots[1])->key_id == key_id) {
 		ks = rcu_replace_pointer(cs->slots[1], NULL,
 					 lockdep_is_held(&cs->lock));
 	}

-- 
2.51.2

