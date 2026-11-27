From: David Crawshaw <david@exe.dev>
Date: Fri, 27 Nov 2026 04:08:40 +0000
Subject: [PATCH 2/2] selftests/fuse: test a write extending the file beside
 writeback of the EOF page
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-fuse-wt-eof-v1-2-e055e2af652d@exe.dev>
References: <20261127-b4-fuse-wt-eof-v1-0-e055e2af652d@exe.dev>
In-Reply-To: <20261127-b4-fuse-wt-eof-v1-0-e055e2af652d@exe.dev>
To: Miklos Szeredi <miklos@szeredi.hu>, 
 "Darrick J. Wong" <djwong@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, 
 Joanne Koong <joannelkoong@gmail.com>, Shuah Khan <shuah@kernel.org>
Cc: fuse-devel@lists.linux.dev, linux-kselftest@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, regressions@lists.linux.dev, 
 David Crawshaw <david@exe.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795752531; l=3427;
 i=david@exe.dev; s=20261127; h=from:subject:message-id;
 bh=qOOaxwLFrTNcXJw6jwuVCpa0ioptdiRJjfw7LoJ36Lo=;
 b=lUPu83Z510dHQTNWuk9cevLfzHjsmK7gaY92o0YHNjiKjFxSVcDPgRoVktzevq2e/LUTUP+vs
 Kw2OR1BGXmUCM+tFUal4usiKBneN/Kx+87y6ynTAS0uu/Ysqp7RYc4G
X-Developer-Key: i=david@exe.dev; a=ed25519;
 pk=eQfKiR9S2peqiHuuNGCAaWlxwP+RerhKT2wVxakCrjQ=
X-Endpoint-Received: by B4 Relay for david@exe.dev/20261127 with auth_id=1661
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a case to write_extend_eof_test: while a pwrite() that extends the
file inside its mmap-dirtied EOF page is held by the server, write that
page back with sync_file_range().  The written data must be in the page
cache afterwards, and on the server after fsync().

Written with an AI coding assistant (Shelley using Opus 5.5).

Signed-off-by: David Crawshaw <david@exe.dev>
---
 .../filesystems/fuse/write_extend_eof_test.c       | 71 ++++++++++++++++++++++
 1 file changed, 71 insertions(+)

diff --git a/tools/testing/selftests/filesystems/fuse/write_extend_eof_test.c b/tools/testing/selftests/filesystems/fuse/write_extend_eof_test.c
index d6d5de8dac2..cdefe459359 100644
--- a/tools/testing/selftests/filesystems/fuse/write_extend_eof_test.c
+++ b/tools/testing/selftests/filesystems/fuse/write_extend_eof_test.c
@@ -57,6 +57,8 @@ struct backing_file {
 struct server {
 	int fd;
 	unsigned int copy_ops;			/* FUSE_COPY_FILE_RANGE* seen */
+	uint64_t hold_off;			/* delay the WRITE at this offset */
+	int held;				/* ... and set this when it came */
 	struct backing_file file[2];		/* FILE_INO, SRC_INO */
 };
 
@@ -179,6 +181,13 @@ static void *server_thread(void *arg)
 			uint64_t off = in->offset;
 			uint32_t size = in->size;
 
+			/* Leave time for writeback while the write is pending. */
+			if (s->hold_off && off == s->hold_off &&
+			    !(in->write_flags & FUSE_WRITE_CACHE)) {
+				__atomic_store_n(&s->held, 1, __ATOMIC_SEQ_CST);
+				usleep(200 * 1000);
+			}
+
 			if (off < BACKING_SIZE) {
 				uint32_t c = size;
 
@@ -472,4 +481,66 @@ TEST_F(fuse, extend_into_eof_page_preserves_data)
 	free(rd);
 }
 
+struct writeback_args {
+	struct server *srv;
+	char *map;
+	int fd;
+	off_t base;
+	long page;
+};
+
+/* Once the extending WRITE is pending, dirty the EOF page and write it back. */
+static void *writeback_thread(void *arg)
+{
+	struct writeback_args *a = arg;
+	int i;
+
+	for (i = 0; i < 5000; i++) {
+		if (__atomic_load_n(&a->srv->held, __ATOMIC_SEQ_CST))
+			break;
+		usleep(1000);
+	}
+	a->map[a->page - 1] = 1;
+	sync_file_range(a->fd, a->base, a->page, SYNC_FILE_RANGE_WRITE);
+	return NULL;
+}
+
+/*
+ * Writeback of the mmap-dirtied EOF page that starts while a write extending
+ * the file within that page is in flight must not zero the written data:
+ * the write has copied it into the page cache, but i_size is only updated
+ * once the server has replied, and writeback zeroes the page past i_size.
+ */
+TEST_F(fuse, extend_beside_writeback)
+{
+	struct writeback_args a;
+	pthread_t t;
+	off_t base, wr;
+	char rd[4];
+
+	pollute_eof_tail(_metadata, self);
+	base = self->eof & ~(self->page - 1);
+	wr = self->eof + 100;			/* in the EOF page, past EOF */
+	ASSERT_LT(wr + 4, base + self->page);
+
+	a.srv = self->srv;
+	a.map = self->map;
+	a.fd = self->fd;
+	a.base = base;
+	a.page = self->page;
+	self->srv->hold_off = wr;
+	ASSERT_EQ(0, pthread_create(&t, NULL, writeback_thread, &a));
+
+	ASSERT_EQ(4, pwrite(self->fd, "data", 4, wr));
+	pthread_join(t, NULL);
+	ASSERT_EQ(1, self->srv->held);
+
+	ASSERT_EQ(4, pread(self->fd, rd, 4, wr));
+	ASSERT_EQ(0, memcmp(rd, "data", 4));
+
+	ASSERT_EQ(0, fsync(self->fd));
+	ASSERT_EQ(wr + 4, self->srv->file[0].size);
+	ASSERT_EQ(0, memcmp(self->srv->file[0].data + wr, "data", 4));
+}
+
 TEST_HARNESS_MAIN

-- 
2.43.0

