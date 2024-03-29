From: =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.neuschaefer@gmx.net>
Date: Fri, 29 Mar 2024 17:26:27 +0100
Subject: [PATCH] rhashtable: Improve grammar
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240329-misc-rhashtable-v1-1-5862383ff798@gmx.net>
X-B4-Tracking: v=1; b=H4sIALLrBmYC/x3MTQqAIBBA4avErBPMEqurRAvTMQf6w4kIorsnL
 b/Few8wJkKGvngg4UVM+5ZRlQW4aLcZBflsUFI1sladWImdSNFyPO20oPBGmxbboNBryNWRMND
 9H4fxfT9eQrX2YQAAAA==
To: Thomas Graf <tgraf@suug.ch>, Herbert Xu <herbert@gondor.apana.org.au>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.neuschaefer@gmx.net>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711729602; l=2864;
 i=j.neuschaefer@gmx.net; s=20240329; h=from:subject:message-id;
 bh=ll377MzgwIQchZuz5guGR9RosFjEvQ8Y2LJidGKOZAc=;
 b=AKOA/sMoOEeDv3OZC6kh4SdqPyBCnKK/fx9cHhz8d/3X5L9//4ew+HbZUu8eK/ktTA2IFyyDA
 e9q1mpM3YX0A+c3gyOeENJ0NEGnPe00oAjnnQ0ysO6FLUW3oE3b0/AX
X-Developer-Key: i=j.neuschaefer@gmx.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.neuschaefer@gmx.net/20240329 with auth_id=149
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change "a" to "an" according to the usual rules, fix an "if" that was
mistyped as "in", improve grammar in "considerable slow" ->
"considerably slower".

Signed-off-by: Jonathan Neuschäfer <j.neuschaefer@gmx.net>
---
 include/linux/rhashtable.h | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/include/linux/rhashtable.h b/include/linux/rhashtable.h
index 5b5357c0bd8c4..8463a128e2f48 100644
--- a/include/linux/rhashtable.h
+++ b/include/linux/rhashtable.h
@@ -633,7 +633,7 @@ static inline struct rhash_head *__rhashtable_lookup(
  * @params:	hash table parameters
  *
  * Computes the hash value for the key and traverses the bucket chain looking
- * for a entry with an identical key. The first matching entry is returned.
+ * for an entry with an identical key. The first matching entry is returned.
  *
  * This must only be called under the RCU read lock.
  *
@@ -655,7 +655,7 @@ static inline void *rhashtable_lookup(
  * @params:	hash table parameters
  *
  * Computes the hash value for the key and traverses the bucket chain looking
- * for a entry with an identical key. The first matching entry is returned.
+ * for an entry with an identical key. The first matching entry is returned.
  *
  * Only use this function when you have other mechanisms guaranteeing
  * that the object won't go away after the RCU read lock is released.
@@ -682,7 +682,7 @@ static inline void *rhashtable_lookup_fast(
  * @params:	hash table parameters
  *
  * Computes the hash value for the key and traverses the bucket chain looking
- * for a entry with an identical key.  All matching entries are returned
+ * for an entry with an identical key.  All matching entries are returned
  * in a list.
  *
  * This must only be called under the RCU read lock.
@@ -699,7 +699,7 @@ static inline struct rhlist_head *rhltable_lookup(
 }
 
 /* Internal function, please use rhashtable_insert_fast() instead. This
- * function returns the existing element already in hashes in there is a clash,
+ * function returns the existing element already in hashes if there is a clash,
  * otherwise it returns an error via ERR_PTR().
  */
 static inline void *__rhashtable_insert_fast(
@@ -1130,7 +1130,7 @@ static inline int rhashtable_remove_fast(
  *
  * Since the hash chain is single linked, the removal operation needs to
  * walk the bucket chain upon removal. The removal operation is thus
- * considerable slow if the hash table is not correctly sized.
+ * considerably slower if the hash table is not correctly sized.
  *
  * Will automatically shrink the table if permitted when residency drops
  * below 30%

---
base-commit: 4cece764965020c22cff7665b18a012006359095
change-id: 20240329-misc-rhashtable-d7578e8f2ed5

Best regards,
-- 
Jonathan Neuschäfer <j.neuschaefer@gmx.net>

