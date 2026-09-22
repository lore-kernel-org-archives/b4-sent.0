From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:15:46 -0400
Subject: [PATCH] fs/buffer: publish max_buffer_heads with release semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-fs-buffer-v1-1-e9ce65e8df43@vt.edu>
X-B4-Tracking: v=1; b=H4sIAMHWsWoC/yXMwQ6CMBAE0F8he3ZNW7SIv2I8tHUrNbGSXSEkh
 H+3xeObzMwKQpxI4NqswDQnSZ9coA8NhMHlJ2F6FINRxqreaHx7jIJ+ipEYleu1vSjdWTpDmYx
 MMS373e3+t0z+ReFbP2rDOyH07HIYarRz7o4tcjjBtv0A/mia5JAAAAA=
X-Change-ID: 20260921-mb-fs-buffer-0a91680176e5
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039748; l=1742;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=aRDf9KVPAsphuf/RAWoLyikBZPnCUsIfRRlozDHhW4k=;
 b=hvfED0FmnfL4E5CMvNxgMWkLqHHkZEzP1hlzq5Ot1WwUxAg/nQius6FuuFx4zDJiFZenRkovx
 8dfqYU5rU0PD00m6R8Rbt42WXUL6bOK+v7zKOSVSvPFJE2WYily6HEe
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

buffer_init() creates bh_cachep and then computes max_buffer_heads, both
with plain stores. recalc_bh_state() reads max_buffer_heads with a plain
load from alloc_buffer_head() and free_buffer_head(), on any CPU.

Store it with smp_store_release() and read it with smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 fs/buffer.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/fs/buffer.c b/fs/buffer.c
index ed966fa73..bf5a674c1 100644
--- a/fs/buffer.c
+++ b/fs/buffer.c
@@ -2864,7 +2864,8 @@ static void recalc_bh_state(void)
 	__this_cpu_write(bh_accounting.ratelimit, 0);
 	for_each_online_cpu(i)
 		tot += per_cpu(bh_accounting, i).nr;
-	buffer_heads_over_limit = (tot > max_buffer_heads);
+	/* Pairs with the smp_store_release() in buffer_init(). */
+	buffer_heads_over_limit = (tot > smp_load_acquire(&max_buffer_heads));
 }
 
 struct buffer_head *alloc_buffer_head(gfp_t gfp_flags)
@@ -2998,7 +2999,9 @@ void __init buffer_init(void)
 	 * Limit the bh occupancy to 10% of ZONE_NORMAL
 	 */
 	nrpages = (nr_free_buffer_pages() * 10) / 100;
-	max_buffer_heads = nrpages * (PAGE_SIZE / sizeof(struct buffer_head));
+	/* Pairs with the smp_load_acquire() in recalc_bh_state(). */
+	smp_store_release(&max_buffer_heads,
+			  nrpages * (PAGE_SIZE / sizeof(struct buffer_head)));
 	ret = cpuhp_setup_state_nocalls(CPUHP_FS_BUFF_DEAD, "fs/buffer:dead",
 					NULL, buffer_exit_cpu_dead);
 	WARN_ON(ret < 0);

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-fs-buffer-0a91680176e5

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

