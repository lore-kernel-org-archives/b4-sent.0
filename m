From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 20 Oct 2026 03:38:41 +0200
Subject: [PATCH] ceph: read ahead along the stride of strided record reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-b4-wip-ceph-ra-stride-v1-1-6314b013d3b8@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw6CQBBF0a2QGltJf9CoWzEOmuYh5QA7VfhJC
 Hu30eEZ3LuQQQVG52YhxUtMHlOF3zWUxzTdwNJXU3Dh4F1w3LX8lsIZZWRNbLNKD95HN5w8jhE
 pUm2LYpDP73u5/m3P7o48bzNa1y+xfdYVeQAAAA==
X-Change-ID: 20261020-b4-wip-ceph-ra-stride-530f91e83ea3
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792460336; l=9737;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=6bQgoYjGpIWD5NadHM+Vv5XzETA6hE53g2TCAn0os7s=;
 b=SOO6JtIS+wjvgVhsuEhyw9Jw16boEwHiAalUkc6XyJ1KsgxXdPPEhrOWSg8dPS2LB9cGyrdwk
 CYRN8JlGyUIA52uSgzZQE8OLSI4tFcfb0PEDyPxKZ8F2fEFueM+gISk
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_netfs_expand_readahead() rounds every readahead request out to the
stripe unit, 4 MiB by default.  When several clients read interleaved
records of a shared file, a record that misses the page cache drags in
the whole object around it, and most of that are records the other
clients read.  IO500's ior-hard-read does exactly this: 16 reader
processes spread over 4 clients read 47008-byte records, each process
every 16th record.  Every client ends up reading the whole file: the
OSDs return 4x the data that is asked for and the read runs at a third
of what the disks can do.

Simply not expanding such a read is not enough.  The generic readahead
sees each record as a small random read and reads it as is, so every
record becomes a synchronous round trip; with one reader process per
client that is half as fast as the over-reading it replaces.

So detect the pattern and read ahead along it:

 - ceph_read_iter() notes, per open file, the position and length of
   every buffered read.  A read of the same length as the previous one,
   starting as far after it as that one did after its predecessor, with
   at least a page left out in between, for the second time in a row,
   marks the file as strided.  The detection looks at the read() calls
   and not at the page cache misses, because which reads miss depends on
   what readahead already brought in.  Sequential reads leave no gap and
   random reads have no fixed stride, so neither is affected.

 - While a file is strided, ceph_netfs_expand_readahead() leaves its
   requests alone, and ceph_stride_readahead() reads the next records of
   the stride ahead, about a readahead window of them (at most 64), each
   on its own with page_cache_ra_unbounded(), so that the records in
   between are never read.

Quick ior-hard runs, 28 GiB, 3 OSDs, ior-hard-read MiB/s.  Each client
is a separate kernel client mount (its own client instance):

  +--------------------------------+---------+--------+-------+
  | Readers                        | Mount   | Before | After |
  +--------------------------------+---------+--------+-------+
  | 16 processes on 4 clients      | default |    487 |  2364 |
  | 16 processes on 4 clients      | lazyio  |    468 |  2388 |
  | 1 process on each of 4 clients | lazyio  |    732 |  1354 |
  +--------------------------------+---------+--------+-------+

The OSDs now read about the data that is asked for instead of 3.6-4x.
ior-easy-read (sequential) and ior-rnd4K-easy-read (random 4 KiB) are
unchanged, and no read of either was taken as strided.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c  | 52 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 fs/ceph/file.c  | 29 +++++++++++++++++++++++++++++
 fs/ceph/super.h | 15 +++++++++++++++
 3 files changed, 96 insertions(+)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index dd2bd8ed2424..737f9a5025f8 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -196,6 +196,15 @@ static void ceph_netfs_expand_readahead(struct netfs_io_request *rreq)
 		else
 			max_pages = priv->file_ra_pages;
 
+		/*
+		 * A file read in records at a fixed stride: the records in
+		 * between are typically read by other clients, so rounding
+		 * the request out to the stripe unit would mostly read data
+		 * this client never uses.  ceph_stride_readahead() reads the
+		 * next records of the stride ahead instead.
+		 */
+		if (priv->file_ra_strided)
+			return;
 	}
 
 	/* Readahead is disabled */
@@ -221,6 +230,48 @@ static void ceph_netfs_expand_readahead(struct netfs_io_request *rreq)
 	}
 }
 
+/*
+ * Read ahead for a file that is read in records at a fixed stride, as
+ * several clients reading interleaved records of a shared file do.  The
+ * generic readahead sees each record as a small random read and reads it
+ * as is, and ceph_netfs_expand_readahead() leaves strided files alone, so
+ * without this each record would be a synchronous round trip to the OSDs.
+ * Read the next records of the stride ahead instead, about a readahead
+ * window of them, each on its own so that the records in between are not
+ * read.  page_cache_ra_unbounded() skips the pages that are already cached.
+ *
+ * The caller holds the read caps and has registered its rw context.
+ */
+void ceph_stride_readahead(struct file *filp, struct ceph_file_info *fi,
+			   loff_t pos, size_t len)
+{
+	struct address_space *mapping = filp->f_mapping;
+	loff_t isize = i_size_read(mapping->host);
+	unsigned long window = (unsigned long)filp->f_ra.ra_pages << PAGE_SHIFT;
+	loff_t stride = fi->ra_stride, next, end;
+	unsigned int nr;
+
+	if (!fi->ra_strided || !window || (filp->f_mode & FMODE_RANDOM))
+		return;
+	nr = clamp_t(unsigned long, window / len, 1, CEPH_STRIDE_RA_MAX);
+	end = pos + stride * nr;
+	/* continue after the records already read ahead */
+	next = fi->ra_stride_next;
+	if (next <= pos || next > end)
+		next = pos + stride;
+
+	filemap_invalidate_lock_shared(mapping);
+	for (; next <= end && next < isize; next += stride) {
+		pgoff_t first = next >> PAGE_SHIFT;
+		pgoff_t last = (min(next + (loff_t)len, isize) - 1) >> PAGE_SHIFT;
+		DEFINE_READAHEAD(ractl, filp, &filp->f_ra, mapping, first);
+
+		page_cache_ra_unbounded(&ractl, last - first + 1, 0);
+	}
+	filemap_invalidate_unlock_shared(mapping);
+	fi->ra_stride_next = next;
+}
+
 static void finish_netfs_read(struct ceph_osd_request *req)
 {
 	struct inode *inode = req->r_inode;
@@ -525,6 +576,7 @@ static int ceph_init_request(struct netfs_io_request *rreq, struct file *file)
 	if (fi) {
 		priv->file_ra_pages = file->f_ra.ra_pages;
 		priv->file_ra_disabled = file->f_mode & FMODE_RANDOM;
+		priv->file_ra_strided = READ_ONCE(fi->ra_strided);
 
 		/*
 		 * ceph_read_iter() and ceph_filemap_fault() hold caps and
diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index 856710c63765..8b8f0a458993 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -2203,6 +2203,33 @@ ceph_sync_write(struct kiocb *iocb, struct iov_iter *from, loff_t pos,
  *
  * Hmm, the sync read case isn't actually async... should it be?
  */
+/*
+ * Is this file read in records at a fixed stride?  Look at the read()
+ * calls themselves, not at the page cache misses: those depend on what
+ * readahead has already brought in.  A read of the same length as the
+ * previous one, starting as far after it as that one did after its
+ * predecessor, with at least a page left out in between, for the second
+ * time in a row.  Sequential reads leave no gap and random reads have no
+ * fixed stride, so neither matches.
+ */
+static void ceph_note_read_stride(struct ceph_file_info *fi, loff_t pos,
+				  size_t len)
+{
+	loff_t stride = pos - fi->ra_prev_pos;
+
+	if (fi->ra_prev_len && len == fi->ra_prev_len &&
+	    stride >= (loff_t)len + PAGE_SIZE && stride == fi->ra_stride) {
+		if (fi->ra_stride_hits < 2)
+			fi->ra_stride_hits++;
+	} else {
+		fi->ra_stride_hits = 0;
+	}
+	fi->ra_stride = stride;
+	fi->ra_prev_pos = pos;
+	fi->ra_prev_len = len;
+	WRITE_ONCE(fi->ra_strided, fi->ra_stride_hits >= 2);
+}
+
 static ssize_t ceph_read_iter(struct kiocb *iocb, struct iov_iter *to)
 {
 	struct file *filp = iocb->ki_filp;
@@ -2278,7 +2305,9 @@ static ssize_t ceph_read_iter(struct kiocb *iocb, struct iov_iter *to)
 		boutc(cl, "async %p %llx.%llx %llu~%u got cap refs on %s\n",
 		      inode, ceph_vinop(inode), iocb->ki_pos, (unsigned)len,
 		      ceph_cap_string(got));
+		ceph_note_read_stride(fi, iocb->ki_pos, len);
 		ceph_add_rw_context(fi, &rw_ctx);
+		ceph_stride_readahead(filp, fi, iocb->ki_pos, len);
 		ret = generic_file_read_iter(iocb, to);
 		ceph_del_rw_context(fi, &rw_ctx);
 	}
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index 458fd63dd79f..f10520a3422a 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -69,6 +69,7 @@
  * CEPH_MSG_MAX_DATA_LEN should be small enough. */
 #define CEPH_MAX_WRITE_SIZE		CEPH_MSG_MAX_DATA_LEN
 #define CEPH_RASIZE_DEFAULT             (8192*1024)    /* max readahead */
+#define CEPH_STRIDE_RA_MAX              64             /* records read ahead on a stride */
 #define CEPH_MAX_READDIR_DEFAULT        1024
 #define CEPH_MAX_READDIR_BYTES_DEFAULT  (512*1024)
 #define CEPH_SNAPDIRNAME_DEFAULT        ".snap"
@@ -567,6 +568,9 @@ struct ceph_netfs_request_data {
 
 	/* Set it if fadvise disables file readahead entirely */
 	bool file_ra_disabled;
+
+	/* Set it if the file is read in records at a fixed stride */
+	bool file_ra_strided;
 };
 
 static inline struct ceph_inode_info *
@@ -893,6 +897,9 @@ static inline bool __ceph_is_any_real_caps(const struct ceph_inode_info *ci)
 }
 
 extern int __ceph_caps_issued(struct ceph_inode_info *ci, int *implemented);
+struct ceph_file_info;
+extern void ceph_stride_readahead(struct file *filp, struct ceph_file_info *fi,
+				  loff_t pos, size_t len);
 extern int __ceph_caps_issued_mask(struct ceph_inode_info *ci, int mask, int t);
 extern int __ceph_caps_issued_mask_metric(struct ceph_inode_info *ci, int mask,
 					  int t);
@@ -987,6 +994,14 @@ struct ceph_file_info {
 	struct list_head rw_contexts;
 
 	u32 filp_gen;
+
+	/* stride detection of buffered reads, see ceph_note_read_stride() */
+	loff_t ra_prev_pos;
+	loff_t ra_stride;
+	size_t ra_prev_len;
+	unsigned int ra_stride_hits;
+	bool ra_strided;
+	loff_t ra_stride_next;	/* next record to read ahead */
 };
 
 struct ceph_dir_file_info {

---
base-commit: ed0502cb11f84fff29f374238e526ae94d9bdfde
change-id: 20261020-b4-wip-ceph-ra-stride-530f91e83ea3

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

