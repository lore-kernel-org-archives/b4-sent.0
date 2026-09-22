From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:26:21 -0400
Subject: [PATCH] random: publish crng_init with release semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-random-v1-1-6af174739807@vt.edu>
X-B4-Tracking: v=1; b=H4sIADzZsWoC/yWMQQ6CMBBFr0Jm7RjaGqRexbhoh1FqQjEzSkwId
 7fF5ft5/62gLIkVLs0KwkvSNOcC5tAAjSE/GNNQGGxru9Zbg1NECXmYJ/TRePLGdb3rofgv4Xv
 67q3r7c/6iU+mdw1UIwZljOVOY512XM5Hh0In2LYf0k1ZAI0AAAA=
X-Change-ID: 20260921-mb-random-9b19c9136838
To: Theodore Ts'o <tytso@mit.edu>, "Jason A. Donenfeld" <Jason@zx2c4.com>
Cc: linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040381; l=2443;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=f2zwRmBbzcu+Qd4/ZF0dmOL97OWEvzW9sCoURGH83Zk=;
 b=YJrnRWwULdMlclhEJRrsM324aoKMRvEXQo82zaQyUdz2bSp+j3D5jPRwK0wG3XQR+RIeLy6sZ
 ZKMlradyj48C7RvV3zFjx1mPW5Z7VKE47qo+p0kIlXo2uhF2PlafW5L
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

crng_reseed() writes the new base key and bumps base_crng.generation
under base_crng.lock, then sets crng_init to CRNG_READY with a plain
store. crng_ready() reads crng_init with a plain load and without the
lock, on the get_random_u8(), u16(), u32() and u64() fast paths and in
crng_make_state().

Set the state with smp_store_release() and read it with
smp_load_acquire(), so that a reader observing CRNG_READY also observes
the key and the generation written before it. crng_ready() becomes a
static inline function so that the acquire can carry its comment.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/char/random.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/drivers/char/random.c b/drivers/char/random.c
index b4da1fb97..2418c787c 100644
--- a/drivers/char/random.c
+++ b/drivers/char/random.c
@@ -83,7 +83,11 @@ static enum {
 	CRNG_READY = 2  /* Fully initialized with POOL_READY_BITS collected */
 } crng_init __read_mostly = CRNG_EMPTY;
 static DEFINE_STATIC_KEY_FALSE(crng_is_ready);
-#define crng_ready() (static_branch_likely(&crng_is_ready) || crng_init >= CRNG_READY)
+static inline bool crng_ready(void)
+{
+	/* Pairs with the smp_store_release() of crng_init in crng_reseed(). */
+	return static_branch_likely(&crng_is_ready) || smp_load_acquire(&crng_init) >= CRNG_READY;
+}
 /* Various types of waiters for crng_init->CRNG_READY transition. */
 static DECLARE_WAIT_QUEUE_HEAD(crng_init_wait);
 static struct fasync_struct *fasync;
@@ -282,8 +286,14 @@ static void crng_reseed(struct work_struct *work)
 	if (IS_ENABLED(CONFIG_VDSO_GETRANDOM))
 		smp_store_release((unsigned long *)&vdso_k_rng_data->generation, next_gen + 1);
 
-	if (!static_branch_likely(&crng_is_ready))
-		crng_init = CRNG_READY;
+	if (!static_branch_likely(&crng_is_ready)) {
+		/*
+		 * crng_ready() tests crng_init without base_crng.lock on the
+		 * fast paths. Publish the state after the new key and the
+		 * generation with release semantics.
+		 */
+		smp_store_release(&crng_init, CRNG_READY);
+	}
 	spin_unlock_irqrestore(&base_crng.lock, flags);
 	memzero_explicit(key, sizeof(key));
 }

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-random-9b19c9136838

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

