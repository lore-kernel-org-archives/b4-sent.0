From: David Crawshaw <david@exe.dev>
Date: Fri, 27 Nov 2026 04:08:39 +0000
Subject: [PATCH 1/2] fuse: update i_size before unlocking the EOF folio in
 write-through writes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-fuse-wt-eof-v1-1-e055e2af652d@exe.dev>
References: <20261127-b4-fuse-wt-eof-v1-0-e055e2af652d@exe.dev>
In-Reply-To: <20261127-b4-fuse-wt-eof-v1-0-e055e2af652d@exe.dev>
To: Miklos Szeredi <miklos@szeredi.hu>, 
 "Darrick J. Wong" <djwong@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, 
 Joanne Koong <joannelkoong@gmail.com>, Shuah Khan <shuah@kernel.org>
Cc: fuse-devel@lists.linux.dev, linux-kselftest@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, regressions@lists.linux.dev, 
 David Crawshaw <david@exe.dev>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795752531; l=3912;
 i=david@exe.dev; s=20261127; h=from:subject:message-id;
 bh=aneCOpdxoK+BoX+KlAWJghFJrKt6ILqgZAIYQqmiW0I=;
 b=pZh3gDBUojjRGzwL5hg+aYbb26zpqEM71Wd+/shQt6BrHzKj9HuOjKvTby6mb6BA9RCczfdJ0
 lSNoakYmogFAEnBL4QI0J56eiQi7rzmRlhRFMuxLCktZNcYpBh3J7L4
X-Developer-Key: i=david@exe.dev; a=ed25519;
 pk=eQfKiR9S2peqiHuuNGCAaWlxwP+RerhKT2wVxakCrjQ=
X-Endpoint-Received: by B4 Relay for david@exe.dev/20261127 with auth_id=1661
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since FUSE writeback was converted to iomap, a write-through write
that extends the file within the folio holding the current EOF can
lose its data if writeback of that folio starts while the FUSE_WRITE
request is in flight.

fuse_perform_write() copies the data into the page cache folio, unlocks
it in fuse_fill_write_pages(), sends FUSE_WRITE, and only updates
i_size after the reply has arrived.  If the folio is dirty, writeback
can lock it in between, and iomap_writeback_handle_eof() zeroes the
folio from the old i_size to its end.

Depending on timing:

 - the page cache is left with zeroes where the write's data should be,
 - the FUSE_WRITE request itself carries zeroes, as its pages are the
   page cache folios and are only copied when the server reads the
   request, so the server stores zeroes,
 - a later writeback of the zeroed folio overwrites the server data.

In each case the write returns success.  Before iomap, FUSE writeback
never modified the folio and cropped the request to i_size at send time,
so this window was harmless.  iomap, on the other hand, expects i_size
to cover the data in a folio before the folio is unlocked, as
iomap_write_iter() does for the writeback cache path.

Fix it the same way for write-through writes: keep a folio that
straddles i_size locked over the request when the write extends the
file within it and update i_size from fuse_send_write_pages() before
the folios are unlocked.

Reproducer: a thread repeatedly stores into the EOF page through a
shared mapping and calls sync_file_range(SYNC_FILE_RANGE_WRITE) on it,
while another thread pwrite()s a few bytes past EOF within that page;
with a server that delays FUSE_WRITE by 200us the data was lost in
493/500 runs (the selftest added in the next patch fails reliably), and in
0/3000 runs with this patch.

This patch written with an AI coding assistant (Shelley using Opus 5.5).
I reviewed and tested it.

Fixes: ef7e7cbb323f ("fuse: use iomap for writeback")
Cc: stable@vger.kernel.org # v6.17+
Signed-off-by: David Crawshaw <david@exe.dev>
---
 fs/fuse/file.c | 21 ++++++++++++++++++++-
 1 file changed, 20 insertions(+), 1 deletion(-)

diff --git a/fs/fuse/file.c b/fs/fuse/file.c
index 993a1d2b315..ee3bdc3cb04 100644
--- a/fs/fuse/file.c
+++ b/fs/fuse/file.c
@@ -1287,6 +1287,15 @@ static ssize_t fuse_send_write_pages(struct fuse_io_args *ia,
 	if (!err && ia->write.out.size > count)
 		err = -EIO;
 
+	/*
+	 * Extend i_size before unlocking the last folio, so that writeback
+	 * cannot see the newly written data beyond i_size and zero it.  See
+	 * fuse_fill_write_pages().
+	 */
+	if (!err)
+		fuse_write_update_attr(inode, pos + ia->write.out.size,
+				       ia->write.out.size);
+
 	for (i = 0; i < ap->num_folios; i++) {
 		struct folio *folio = ap->folios[i];
 
@@ -1305,6 +1314,7 @@ static ssize_t fuse_fill_write_pages(struct fuse_io_args *ia,
 {
 	struct fuse_args_pages *ap = &ia->ap;
 	struct fuse_conn *fc = get_fuse_conn(mapping->host);
+	loff_t isize = i_size_read(mapping->host);
 	size_t count = 0;
 	unsigned int num;
 	int err = 0;
@@ -1366,7 +1376,16 @@ static ssize_t fuse_fill_write_pages(struct fuse_io_args *ia,
 		if (tmp == folio_size(folio))
 			iomap_folio_mark_uptodate(folio);
 
-		if (folio_test_uptodate(folio)) {
+		/*
+		 * Keep the folio locked until the reply if it is not uptodate,
+		 * or if it straddles i_size and this write extends the file
+		 * within it: writeback zeroes a folio beyond i_size
+		 * (iomap_writeback_handle_eof()), which would wipe the data
+		 * just copied, both in the page cache and in the request,
+		 * while i_size has not yet been updated.
+		 */
+		if (folio_test_uptodate(folio) &&
+		    !(folio_pos(folio) < isize && pos > isize)) {
 			folio_unlock(folio);
 		} else {
 			ia->write.folio_locked = true;

-- 
2.43.0

