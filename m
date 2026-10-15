From: Patrick Dahlke <me@patrickdahlke.com>
Date: Thu, 15 Oct 2026 06:26:45 +0000
Subject: [PATCH can] can: j1939: don't drop the last ECU reference without
 priv->lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-j1939-ecu-release-lock-v1-1-39dcb8a0f2f9@patrickdahlke.com>
X-B4-Tracking: v=1; b=H4sIACRy0GoC/22MywrCMBBFf6XM2oEmPjD+iriYjLc2WlKZoBRK/
 72pa5fncs+ZqcASCl2amQzfVNKYK7hdQ9pLfoDTvTL51p9c6478dGEfGPphwwAp4GHUF3cHD3c
 OGiGeqvw2dGn6ha+kkulWx7jdo0nWfmv+T9GyrD3vCKKWAAAA
X-Change-ID: 20261015-j1939-ecu-release-lock-f42e189cbea2
To: Robin van der Gracht <robin@protonic.nl>, 
 Oleksij Rempel <o.rempel@pengutronix.de>, kernel@pengutronix.de, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sashiko <sashiko-bot@kernel.org>, 
 Patrick Dahlke <me@patrickdahlke.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792045615; l=10600;
 i=me@patrickdahlke.com; s=20261015; h=from:subject:message-id;
 bh=rIm4qsiF6lwK/DC0sVTHNeX/QSG5Yicgzko5BW1kjmM=;
 b=hH3VYirwmkeS8eyOai2s/5tB2ALcykf0ASSpDFq2KqJlwBzXsjqELL+BHq5FVSY/NtZUeOqtQ
 aSvw4w0jttJAEgmjxP5ilvPMqmjAB2c7MwONZ8JhzYYnm+enVmhuYSo
X-Developer-Key: i=me@patrickdahlke.com; a=ed25519;
 pk=x8W424q5IZ8w2J9xyeOSiBmEMGsxLCt5IRXLXt/V/Gc=
X-Endpoint-Received: by B4 Relay for me@patrickdahlke.com/20261015 with auth_id=1190
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct j1939_ecu objects are linked into priv->ecus, which is protected
by priv->lock. __j1939_ecu_release() unlinks the ECU with list_del(), so
the final j1939_ecu_put() must happen with priv->lock held for writing.

j1939_ac_recv() and j1939_ac_fixup() violate this. They look up an ECU
with j1939_ecu_get_by_addr() or j1939_ecu_get_by_name(), which take a
reference under the read lock and return with the lock released, and
then drop that reference with j1939_ecu_put() without holding the lock.
If the ECU is unmapped concurrently, e.g. by an address claim processed
on another CPU, the transient reference becomes the last one and the
ECU is unlinked from priv->ecus while other CPUs may be walking or
modifying the list under priv->lock, which can corrupt the list.

This can be shown on vcan with two threads on different CPUs: one sends
frames from SA 0x20, so that j1939_ac_recv() resolves the source name
for each of them, while the other repeatedly claims SA 0x20 and then
releases it with an idle address claim (SA 0xfe) for the same NAME.
With an mdelay() between the lookup and j1939_ecu_put() in
j1939_ac_recv() to widen the window, a lockdep_assert_held_write() in
__j1939_ecu_release() fires on every release cycle:

  WARNING: net/can/j1939/bus.c:22 at __j1939_ecu_release+0x254/0x2e8
  Call trace:
   __j1939_ecu_release+0x254/0x2e8 (P)
   j1939_ecu_put+0x80/0xac
   j1939_ac_recv+0x17c/0x5c0
   j1939_can_recv+0x5a4/0x848
   can_rcv_filter+0x1ec/0x760
   can_receive+0x160/0x360
   can_rcv+0x1c8/0x2c0

Neither caller needs a reference that outlives the lock.
j1939_ac_recv() only needs the NAME of the ECU mapped at an address, so
add j1939_addr_to_name(), the counterpart of j1939_name_to_addr(), which
copies it under the read lock. This also drops two atomic reference
count updates per received frame. j1939_ac_fixup() unmaps the ECU, so
do the lookup, unmap and put under the write lock.

Remove the now unused j1939_ecu_get_by_addr(), j1939_ecu_get_by_name()
and j1939_ecu_unmap(), and document the locking rule with
lockdep_assert_held_write() in __j1939_ecu_release().

The unlocked list_del() was pointed out by the sashiko AI review bot in
its reviews of several j1939 patches on the linux-can list.

Fixes: 9d71dd0c7009 ("can: add support of SAE J1939 protocol")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20260803101503.21023-1-f3lix.dev@gmx.de
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Patrick Dahlke <me@patrickdahlke.com>
---
Testing (arm64 QEMU, 4 vCPUs, KASAN + DEBUG_LIST + PROVE_LOCKING + kmemleak):
- Unpatched linux-can main with the lockdep_assert_held_write() and an
  mdelay(20) in j1939_ac_recv(): the assertion fires on every
  claim/idle-claim cycle of the reproducer described above, from
  j1939_ac_recv() in softirq context.
- Patched, on linux-can/main (a7bfaba4823e) and on
  linux-can-next-for-7.4-20261009: no lockdep, KASAN or DEBUG_LIST reports
  while running the reproducer, address claims sent from two j1939
  sockets sharing one NAME (exercising the j1939_ac_fixup() unmap path),
  and the C reproducer of syzbot bug 489e907b2a026a6f5fa0 for 60s.
  Function profiling confirmed ~1.1M j1939_addr_to_name() calls and
  20-30 ECU releases per run.
- Without an injected delay: KCSAN kernel (lockdep + DEBUG_LIST, booted
  with kcsan.skip_watch=40 kcsan.udelay_interrupt=200, so watchpoint
  stalls widen the window between the lookup and the put), running a
  stress test that claims and idle-releases 96 addresses while three
  CPUs send frames from and to them. Unpatched can-next with only the
  lockdep_assert_held_write() added: the assertion fired 6 and 8 times
  in two 180s runs (~5.5k ECU releases each), always from
  j1939_ac_recv(). Patched: no hits in 180s (~5.8k ECU releases) and no
  KCSAN reports in net/can/j1939/.
- The J1939 kselftests posted to linux-can ("selftests: can: add J1939
  socket and transport tests" v1) pass (35/35) on patched can-next.
- allmodconfig W=1 build of net/can/ on arm64 and x86_64, sparse and
  checkpatch --strict: no new warnings.

Without KCSAN or an injected delay, I was not able to hit the race or
observe actual list corruption; the race window is the few instructions
between read_unlock_bh() and the final j1939_ecu_put().
---
 net/can/j1939/address-claim.c | 40 +++++++++++++++------------------
 net/can/j1939/bus.c           | 51 +++++++++++++++++++------------------------
 net/can/j1939/j1939-priv.h    |  4 +---
 3 files changed, 41 insertions(+), 54 deletions(-)

diff --git a/net/can/j1939/address-claim.c b/net/can/j1939/address-claim.c
index ca4ad6cdd5cbfd323bbdf49ad8cf413cb39ad083..bcc9e7728557a39a0056b334a5b186ea96e1f75e 100644
--- a/net/can/j1939/address-claim.c
+++ b/net/can/j1939/address-claim.c
@@ -90,14 +90,20 @@ int j1939_ac_fixup(struct j1939_priv *priv, struct sk_buff *skb)
 		/* return both when failure & when successful */
 		if (ret < 0)
 			return ret;
-		ecu = j1939_ecu_get_by_name(priv, skcb->addr.src_name);
-		if (!ecu)
-			return -ENODEV;
-
-		if (ecu->addr != skcb->addr.sa)
-			/* hold further traffic for ecu, remove from parent */
-			j1939_ecu_unmap(ecu);
-		j1939_ecu_put(ecu);
+
+		ret = -ENODEV;
+		write_lock_bh(&priv->lock);
+		ecu = j1939_ecu_get_by_name_locked(priv, skcb->addr.src_name);
+		if (ecu) {
+			if (ecu->addr != skcb->addr.sa)
+				/* hold further traffic for ecu, remove from parent */
+				j1939_ecu_unmap_locked(ecu);
+			j1939_ecu_put(ecu);
+			ret = 0;
+		}
+		write_unlock_bh(&priv->lock);
+		if (ret)
+			return ret;
 	} else if (skcb->addr.src_name) {
 		/* assign source address */
 		addr = j1939_name_to_addr(priv, skcb->addr.src_name);
@@ -247,24 +253,14 @@ static void j1939_ac_process(struct j1939_priv *priv, struct sk_buff *skb)
 void j1939_ac_recv(struct j1939_priv *priv, struct sk_buff *skb)
 {
 	struct j1939_sk_buff_cb *skcb = j1939_skb_to_cb(skb);
-	struct j1939_ecu *ecu;
 
 	/* network mgmt */
-	if (skcb->addr.pgn == J1939_PGN_ADDRESS_CLAIMED) {
+	if (skcb->addr.pgn == J1939_PGN_ADDRESS_CLAIMED)
 		j1939_ac_process(priv, skb);
-	} else if (j1939_address_is_unicast(skcb->addr.sa)) {
+	else
 		/* assign source name */
-		ecu = j1939_ecu_get_by_addr(priv, skcb->addr.sa);
-		if (ecu) {
-			skcb->addr.src_name = ecu->name;
-			j1939_ecu_put(ecu);
-		}
-	}
+		skcb->addr.src_name = j1939_addr_to_name(priv, skcb->addr.sa);
 
 	/* assign destination name */
-	ecu = j1939_ecu_get_by_addr(priv, skcb->addr.da);
-	if (ecu) {
-		skcb->addr.dst_name = ecu->name;
-		j1939_ecu_put(ecu);
-	}
+	skcb->addr.dst_name = j1939_addr_to_name(priv, skcb->addr.da);
 }
diff --git a/net/can/j1939/bus.c b/net/can/j1939/bus.c
index cdc3c0a71937935eacfcfbf2f8350a7987ee6790..ec8ee0f980fb464fa9d1455fd4aa340e0aed4c69 100644
--- a/net/can/j1939/bus.c
+++ b/net/can/j1939/bus.c
@@ -19,6 +19,11 @@ static void __j1939_ecu_release(struct kref *kref)
 	struct j1939_ecu *ecu = container_of(kref, struct j1939_ecu, kref);
 	struct j1939_priv *priv = ecu->priv;
 
+	/* priv->ecus is protected by priv->lock, so the last reference
+	 * must only be dropped with priv->lock held for writing.
+	 */
+	lockdep_assert_held_write(&priv->lock);
+
 	list_del(&ecu->list);
 	netdev_put(priv->ndev, &ecu->priv_dev_tracker);
 	kfree(ecu);
@@ -89,13 +94,6 @@ void j1939_ecu_unmap_locked(struct j1939_ecu *ecu)
 	j1939_ecu_put(ecu);
 }
 
-void j1939_ecu_unmap(struct j1939_ecu *ecu)
-{
-	write_lock_bh(&ecu->priv->lock);
-	j1939_ecu_unmap_locked(ecu);
-	write_unlock_bh(&ecu->priv->lock);
-}
-
 void j1939_ecu_unmap_all(struct j1939_priv *priv)
 {
 	int i;
@@ -195,17 +193,6 @@ struct j1939_ecu *j1939_ecu_get_by_addr_locked(struct j1939_priv *priv, u8 addr)
 	return ecu;
 }
 
-struct j1939_ecu *j1939_ecu_get_by_addr(struct j1939_priv *priv, u8 addr)
-{
-	struct j1939_ecu *ecu;
-
-	read_lock_bh(&priv->lock);
-	ecu = j1939_ecu_get_by_addr_locked(priv, addr);
-	read_unlock_bh(&priv->lock);
-
-	return ecu;
-}
-
 /* get pointer to ecu without increasing ref counter */
 static struct j1939_ecu *j1939_ecu_find_by_name_locked(struct j1939_priv *priv,
 						       name_t name)
@@ -239,17 +226,6 @@ struct j1939_ecu *j1939_ecu_get_by_name_locked(struct j1939_priv *priv,
 	return ecu;
 }
 
-struct j1939_ecu *j1939_ecu_get_by_name(struct j1939_priv *priv, name_t name)
-{
-	struct j1939_ecu *ecu;
-
-	read_lock_bh(&priv->lock);
-	ecu = j1939_ecu_get_by_name_locked(priv, name);
-	read_unlock_bh(&priv->lock);
-
-	return ecu;
-}
-
 u8 j1939_name_to_addr(struct j1939_priv *priv, name_t name)
 {
 	struct j1939_ecu *ecu;
@@ -269,6 +245,23 @@ u8 j1939_name_to_addr(struct j1939_priv *priv, name_t name)
 	return addr;
 }
 
+name_t j1939_addr_to_name(struct j1939_priv *priv, u8 addr)
+{
+	struct j1939_ecu *ecu;
+	name_t name = 0;
+
+	if (!j1939_address_is_unicast(addr))
+		return 0;
+
+	read_lock_bh(&priv->lock);
+	ecu = j1939_ecu_find_by_addr_locked(priv, addr);
+	if (ecu)
+		name = ecu->name;
+	read_unlock_bh(&priv->lock);
+
+	return name;
+}
+
 /* TX addr/name accounting
  * Transport protocol needs to know if a SA is local or not
  * These functions originate from userspace manipulating sockets,
diff --git a/net/can/j1939/j1939-priv.h b/net/can/j1939/j1939-priv.h
index cf26352d1d8ce6cba0ec1231ca9b321e898d71c3..40b3a61e6743f314e2fd24e5196a1dc387bee506 100644
--- a/net/can/j1939/j1939-priv.h
+++ b/net/can/j1939/j1939-priv.h
@@ -124,15 +124,13 @@ static inline bool j1939_pgn_is_pdu1(pgn_t pgn)
 
 /* utility to correctly unmap an ECU */
 void j1939_ecu_unmap_locked(struct j1939_ecu *ecu);
-void j1939_ecu_unmap(struct j1939_ecu *ecu);
 
 u8 j1939_name_to_addr(struct j1939_priv *priv, name_t name);
+name_t j1939_addr_to_name(struct j1939_priv *priv, u8 addr);
 struct j1939_ecu *j1939_ecu_find_by_addr_locked(struct j1939_priv *priv,
 						u8 addr);
-struct j1939_ecu *j1939_ecu_get_by_addr(struct j1939_priv *priv, u8 addr);
 struct j1939_ecu *j1939_ecu_get_by_addr_locked(struct j1939_priv *priv,
 					       u8 addr);
-struct j1939_ecu *j1939_ecu_get_by_name(struct j1939_priv *priv, name_t name);
 struct j1939_ecu *j1939_ecu_get_by_name_locked(struct j1939_priv *priv,
 					       name_t name);
 

---
base-commit: a7bfaba4823e3c165bb2004c74eff7c096672bc7
change-id: 20261015-j1939-ecu-release-lock-f42e189cbea2

Best regards,
-- 
Patrick Dahlke <me@patrickdahlke.com>

