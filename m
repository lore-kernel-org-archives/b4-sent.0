From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:16:54 -0400
Subject: [PATCH] pstore: publish big_oops_buf after max_compressed_size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-pstore-v1-1-46f9a6129d58@vt.edu>
X-B4-Tracking: v=1; b=H4sIAAXXsWoC/yXMQQrCMBCF4auUWTvSxGjQq4iLJJ3aEUzLTC1C6
 d1N6vJ7PP4VlIRJ4dasILSw8pgLzKGBNIT8JOSuGGxrL+3VGnxHnHQehdB7is6cXWd6C+U/CfX
 83Vv3x9/6iS9Kcw3URwxKGCXkNNRp5+KPJ5TkYNt+uXfH4I0AAAA=
X-Change-ID: 20260921-mb-pstore-77eb4154d1f2
To: Kees Cook <kees@kernel.org>, Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039820; l=1864;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=26FmX6iupwLCuZy1xu2UL820vauzL5xEatEEuA4DQrg=;
 b=daBzOeeHWyv0ierrs8BW70+IyumHw4HDFye9fWH5NBlG1tj9K/EapyfiCjjoQyA5DXuwMCRPN
 dGZBWnZn7tlAZk2JXtY8vn8xX/b6zYDp7CRbODJAXGEHcWMDMtItP+n
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

allocate_buf_for_compression() stores big_oops_buf and then
max_compressed_size, both with plain stores. pstore_dump() runs from
kmsg_dump on any CPU, tests big_oops_buf without psinfo_lock and then
reads max_compressed_size.

Store the size first and publish the buffer with smp_store_release(),
paired with smp_load_acquire() in pstore_dump().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 fs/pstore/platform.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/fs/pstore/platform.c b/fs/pstore/platform.c
index 1d76c9d92..1ad6e40f4 100644
--- a/fs/pstore/platform.c
+++ b/fs/pstore/platform.c
@@ -240,9 +240,14 @@ static void allocate_buf_for_compression(void)
 		return;
 	}
 
-	/* A non-NULL big_oops_buf indicates compression is available. */
-	big_oops_buf = buf;
 	max_compressed_size = compressed_size;
+	/*
+	 * A non-NULL big_oops_buf indicates compression is available.
+	 * pstore_dump() tests it without psinfo_lock and then reads
+	 * max_compressed_size, which is stored above. Publish the buffer
+	 * with release semantics.
+	 */
+	smp_store_release(&big_oops_buf, buf);
 
 	pr_info("Using crash dump compression: %s\n", compress);
 }
@@ -316,7 +321,8 @@ static void pstore_dump(struct kmsg_dumper *dumper,
 		record.part = part;
 		record.buf = psinfo->buf;
 
-		dst = big_oops_buf ?: psinfo->buf;
+		/* Pairs with the smp_store_release() in allocate_buf_for_compression(). */
+		dst = smp_load_acquire(&big_oops_buf) ?: psinfo->buf;
 		dst_size = max_compressed_size ?: psinfo->bufsize;
 
 		/* Write dump header. */

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-pstore-77eb4154d1f2

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

