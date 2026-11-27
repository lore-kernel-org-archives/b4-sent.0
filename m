MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-kvt1-virtio-d-v1-2-bfa9ce1cece5@certik.com>
References: <20261127-kvt1-virtio-d-v1-0-bfa9ce1cece5@certik.com>
In-Reply-To: <20261127-kvt1-virtio-d-v1-0-bfa9ce1cece5@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 02:56:40 +0000
Subject: [PATCH kvmtool 2/3] virtio: 9p: Validate unsigned string lengths
To: will@kernel.org, kvm@vger.kernel.org
Cc: julien.thierry.kdev@gmail.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795779125; l=11371;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=o6X0HtkOcoY2kDoDcooOC1li281WYIXjPWL9hzAPaTU=;
 b=Cs1ifiRQqXrjYlRQGAuYaaxZukL64A6F8LaiWDaGPzgzFZIV8lIvf8zxqKKEhDWvsQf5KnCUe
 3qVd2VgtHt8BCHsGUJg+LOVCcVHH7b1KIsD12+R4Krb8dM9zTlDzjA9
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A guest can provide a 9p string length that exceeds the remaining
request. The decoder may then copy incomplete data and use a malformed
string. Lengths with the high bit set are valid unsigned protocol
values when the complete string is present. Truncated fixed-width
fields can also leave decoded values uninitialized, including string
pointers that handlers free on decode errors.

Decode string lengths as unsigned 16-bit values and check all bytes
before allocating or copying. Report truncated fixed-width reads
through the decoder so callers can reject partial fields. Initialize
cleanup-owned string pointers before decoding.

Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 virtio/9p-pdu.c |  59 +++++++++++++++++++++-------
 virtio/9p.c     | 100 ++++++++++++++++++++++++++++++++----------------
 2 files changed, 114 insertions(+), 45 deletions(-)

diff --git a/virtio/9p-pdu.c b/virtio/9p-pdu.c
index c0b95e0..2e8c12f 100644
--- a/virtio/9p-pdu.c
+++ b/virtio/9p-pdu.c
@@ -7,10 +7,11 @@
 #include <linux/compiler.h>
 #include <linux/9p.h>
 
-static void virtio_p9_pdu_read(struct p9_pdu *pdu, void *data, size_t size)
+static int virtio_p9_pdu_read(struct p9_pdu *pdu, void *data, size_t size)
 {
 	size_t len;
-	int i, copied = 0;
+	size_t copied = 0;
+	int i;
 	u16 iov_cnt = pdu->out_iov_cnt;
 	size_t offset = pdu->read_offset;
 	struct iovec *iov = pdu->out_iov;
@@ -29,6 +30,7 @@ static void virtio_p9_pdu_read(struct p9_pdu *pdu, void *data, size_t size)
 		}
 	}
 	pdu->read_offset += copied;
+	return size ? EINVAL : 0;
 }
 
 static void virtio_p9_pdu_write(struct p9_pdu *pdu,
@@ -64,55 +66,86 @@ static void virtio_p9_wstat_free(struct p9_wstat *stbuf)
 	free(stbuf->muid);
 }
 
+static size_t virtio_p9_pdu_remaining(struct p9_pdu *pdu)
+{
+	size_t total = 0;
+	u16 i;
+
+	for (i = 0; i < pdu->out_iov_cnt; i++)
+		total += pdu->out_iov[i].iov_len;
+
+	return total > pdu->read_offset ? total - pdu->read_offset : 0;
+}
+
 static int virtio_p9_decode(struct p9_pdu *pdu, const char *fmt, va_list ap)
 {
 	int retval = 0;
 	const char *ptr;
 
-	for (ptr = fmt; *ptr; ptr++) {
+	for (ptr = fmt; *ptr && !retval; ptr++) {
 		switch (*ptr) {
 		case 'b':
 		{
 			int8_t *val = va_arg(ap, int8_t *);
-			virtio_p9_pdu_read(pdu, val, sizeof(*val));
+			retval = virtio_p9_pdu_read(pdu, val, sizeof(*val));
 		}
 		break;
 		case 'w':
 		{
 			int16_t le_val;
 			int16_t *val = va_arg(ap, int16_t *);
-			virtio_p9_pdu_read(pdu, &le_val, sizeof(le_val));
-			*val = le16toh(le_val);
+			retval = virtio_p9_pdu_read(pdu, &le_val, sizeof(le_val));
+			if (!retval)
+				*val = le16toh(le_val);
 		}
 		break;
 		case 'd':
 		{
 			int32_t le_val;
 			int32_t *val = va_arg(ap, int32_t *);
-			virtio_p9_pdu_read(pdu, &le_val, sizeof(le_val));
-			*val = le32toh(le_val);
+			retval = virtio_p9_pdu_read(pdu, &le_val, sizeof(le_val));
+			if (!retval)
+				*val = le32toh(le_val);
 		}
 		break;
 		case 'q':
 		{
 			int64_t le_val;
 			int64_t *val = va_arg(ap, int64_t *);
-			virtio_p9_pdu_read(pdu, &le_val, sizeof(le_val));
-			*val = le64toh(le_val);
+			retval = virtio_p9_pdu_read(pdu, &le_val, sizeof(le_val));
+			if (!retval)
+				*val = le64toh(le_val);
 		}
 		break;
 		case 's':
 		{
-			int16_t len;
+			u16 len, le_len;
 			char **str = va_arg(ap, char **);
+			*str = NULL;
 
-			virtio_p9_pdu_readf(pdu, "w", &len);
+			if (virtio_p9_pdu_remaining(pdu) < sizeof(len)) {
+				retval = EINVAL;
+				break;
+			}
+			retval = virtio_p9_pdu_read(pdu, &le_len, sizeof(le_len));
+			if (retval)
+				break;
+			len = le16toh(le_len);
+			if (virtio_p9_pdu_remaining(pdu) < len) {
+				retval = EINVAL;
+				break;
+			}
 			*str = malloc(len + 1);
 			if (*str == NULL) {
 				retval = ENOMEM;
 				break;
 			}
-			virtio_p9_pdu_read(pdu, *str, len);
+			retval = virtio_p9_pdu_read(pdu, *str, len);
+			if (retval) {
+				free(*str);
+				*str = NULL;
+				break;
+			}
 			(*str)[len] = 0;
 		}
 		break;
diff --git a/virtio/9p.c b/virtio/9p.c
index 07dd244..9bcc31d 100644
--- a/virtio/9p.c
+++ b/virtio/9p.c
@@ -171,8 +171,14 @@ static void virtio_p9_version(struct p9_dev *p9dev,
 			      struct p9_pdu *pdu, u32 *outlen)
 {
 	u32 msize;
-	char *version;
-	virtio_p9_pdu_readf(pdu, "ds", &msize, &version);
+	char *version = NULL;
+	int err;
+
+	err = virtio_p9_pdu_readf(pdu, "ds", &msize, &version);
+	if (err) {
+		virtio_p9_error_reply(p9dev, pdu, err, outlen);
+		return;
+	}
 	/*
 	 * reply with the same msize the client sent us
 	 * Error out if the request is not for 9P2000.L
@@ -327,7 +333,7 @@ static void virtio_p9_create(struct p9_dev *p9dev,
 			     struct p9_pdu *pdu, u32 *outlen)
 {
 	int fd, ret;
-	char *name;
+	char *name = NULL;
 	size_t size;
 	struct stat st;
 	struct p9_qid qid;
@@ -336,8 +342,10 @@ static void virtio_p9_create(struct p9_dev *p9dev,
 	char *tmp_path;
 	u32 dfid_val, flags, mode, gid;
 
-	virtio_p9_pdu_readf(pdu, "dsddd", &dfid_val,
-			    &name, &flags, &mode, &gid);
+	errno = virtio_p9_pdu_readf(pdu, "dsddd", &dfid_val,
+				    &name, &flags, &mode, &gid);
+	if (errno)
+		goto err_out;
 	dfid = get_fid(p9dev, dfid_val);
 
 	if (get_full_path(full_path, sizeof(full_path), dfid, name) != 0)
@@ -388,15 +396,17 @@ static void virtio_p9_mkdir(struct p9_dev *p9dev,
 			    struct p9_pdu *pdu, u32 *outlen)
 {
 	int ret;
-	char *name;
+	char *name = NULL;
 	struct stat st;
 	struct p9_qid qid;
 	struct p9_fid *dfid;
 	char full_path[PATH_MAX];
 	u32 dfid_val, mode, gid;
 
-	virtio_p9_pdu_readf(pdu, "dsdd", &dfid_val,
-			    &name, &mode, &gid);
+	errno = virtio_p9_pdu_readf(pdu, "dsdd", &dfid_val,
+				    &name, &mode, &gid);
+	if (errno)
+		goto err_out;
 	dfid = get_fid(p9dev, dfid_val);
 
 	if (get_full_path(full_path, sizeof(full_path), dfid, name) != 0)
@@ -469,7 +479,9 @@ static void virtio_p9_walk(struct p9_dev *p9dev,
 			char *str;
 			int ret;
 
-			virtio_p9_pdu_readf(pdu, "s", &str);
+			errno = virtio_p9_pdu_readf(pdu, "s", &str);
+			if (errno)
+				goto err_out;
 
 			/* Format the new path we're 'walk'ing into */
 			ret = snprintf(tmp, sizeof(tmp), "%s/%s", new_fid->path, str);
@@ -517,18 +529,20 @@ err_out:
 static void virtio_p9_attach(struct p9_dev *p9dev,
 			     struct p9_pdu *pdu, u32 *outlen)
 {
-	char *uname;
-	char *aname;
+	char *uname = NULL;
+	char *aname = NULL;
 	struct stat st;
 	struct p9_qid qid;
 	struct p9_fid *fid;
 	u32 fid_val, afid, uid;
 
-	virtio_p9_pdu_readf(pdu, "ddssd", &fid_val, &afid,
-			    &uname, &aname, &uid);
+	errno = virtio_p9_pdu_readf(pdu, "ddssd", &fid_val, &afid,
+				    &uname, &aname, &uid);
 
 	free(uname);
 	free(aname);
+	if (errno)
+		goto err_out;
 
 	if (lstat(p9dev->root_dir, &st) < 0)
 		goto err_out;
@@ -884,7 +898,9 @@ static void virtio_p9_rename(struct p9_dev *p9dev,
 	struct p9_fid *fid, *new_fid;
 	char full_path[PATH_MAX], *new_name;
 
-	virtio_p9_pdu_readf(pdu, "dds", &fid_val, &new_fid_val, &new_name);
+	errno = virtio_p9_pdu_readf(pdu, "dds", &fid_val, &new_fid_val, &new_name);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 	new_fid = get_fid(p9dev, new_fid_val);
 
@@ -963,15 +979,17 @@ static void virtio_p9_mknod(struct p9_dev *p9dev,
 			    struct p9_pdu *pdu, u32 *outlen)
 {
 	int ret;
-	char *name;
+	char *name = NULL;
 	struct stat st;
 	struct p9_fid *dfid;
 	struct p9_qid qid;
 	char full_path[PATH_MAX];
 	u32 fid_val, mode, major, minor, gid;
 
-	virtio_p9_pdu_readf(pdu, "dsdddd", &fid_val, &name, &mode,
-			    &major, &minor, &gid);
+	errno = virtio_p9_pdu_readf(pdu, "dsdddd", &fid_val, &name, &mode,
+				    &major, &minor, &gid);
+	if (errno)
+		goto err_out;
 
 	dfid = get_fid(p9dev, fid_val);
 
@@ -1039,9 +1057,11 @@ static void virtio_p9_symlink(struct p9_dev *p9dev,
 	struct p9_qid qid;
 	struct p9_fid *dfid;
 	char new_name[PATH_MAX];
-	char *old_path, *name;
+	char *old_path = NULL, *name = NULL;
 
-	virtio_p9_pdu_readf(pdu, "dssd", &fid_val, &name, &old_path, &gid);
+	errno = virtio_p9_pdu_readf(pdu, "dssd", &fid_val, &name, &old_path, &gid);
+	if (errno)
+		goto err_out;
 
 	dfid = get_fid(p9dev, fid_val);
 
@@ -1073,12 +1093,14 @@ static void virtio_p9_link(struct p9_dev *p9dev,
 			   struct p9_pdu *pdu, u32 *outlen)
 {
 	int ret;
-	char *name;
+	char *name = NULL;
 	u32 fid_val, dfid_val;
 	struct p9_fid *dfid, *fid;
 	char full_path[PATH_MAX];
 
-	virtio_p9_pdu_readf(pdu, "dds", &dfid_val, &fid_val, &name);
+	errno = virtio_p9_pdu_readf(pdu, "dds", &dfid_val, &fid_val, &name);
+	if (errno)
+		goto err_out;
 
 	dfid = get_fid(p9dev, dfid_val);
 	fid =  get_fid(p9dev, fid_val);
@@ -1104,12 +1126,17 @@ static void virtio_p9_lock(struct p9_dev *p9dev,
 			   struct p9_pdu *pdu, u32 *outlen)
 {
 	u8 ret;
+	int err;
 	u32 fid_val;
 	struct p9_flock flock;
 
-	virtio_p9_pdu_readf(pdu, "dbdqqds", &fid_val, &flock.type,
-			    &flock.flags, &flock.start, &flock.length,
-			    &flock.proc_id, &flock.client_id);
+	err = virtio_p9_pdu_readf(pdu, "dbdqqds", &fid_val, &flock.type,
+				  &flock.flags, &flock.start, &flock.length,
+				  &flock.proc_id, &flock.client_id);
+	if (err) {
+		virtio_p9_error_reply(p9dev, pdu, err, outlen);
+		return;
+	}
 
 	/* Just return success */
 	ret = P9_LOCK_SUCCESS;
@@ -1123,11 +1150,16 @@ static void virtio_p9_lock(struct p9_dev *p9dev,
 static void virtio_p9_getlock(struct p9_dev *p9dev,
 			      struct p9_pdu *pdu, u32 *outlen)
 {
+	int err;
 	u32 fid_val;
 	struct p9_getlock glock;
-	virtio_p9_pdu_readf(pdu, "dbqqds", &fid_val, &glock.type,
-			    &glock.start, &glock.length, &glock.proc_id,
-			    &glock.client_id);
+	err = virtio_p9_pdu_readf(pdu, "dbqqds", &fid_val, &glock.type,
+				  &glock.start, &glock.length, &glock.proc_id,
+				  &glock.client_id);
+	if (err) {
+		virtio_p9_error_reply(p9dev, pdu, err, outlen);
+		return;
+	}
 
 	/* Just return success */
 	glock.type = F_UNLCK;
@@ -1193,14 +1225,16 @@ static void virtio_p9_renameat(struct p9_dev *p9dev,
 			       struct p9_pdu *pdu, u32 *outlen)
 {
 	int ret;
-	char *old_name, *new_name;
+	char *old_name = NULL, *new_name = NULL;
 	u32 old_dfid_val, new_dfid_val;
 	struct p9_fid *old_dfid, *new_dfid;
 	char old_full_path[PATH_MAX], new_full_path[PATH_MAX];
 
 
-	virtio_p9_pdu_readf(pdu, "dsds", &old_dfid_val, &old_name,
-			    &new_dfid_val, &new_name);
+	errno = virtio_p9_pdu_readf(pdu, "dsds", &old_dfid_val, &old_name,
+				    &new_dfid_val, &new_name);
+	if (errno)
+		goto err_out;
 
 	old_dfid = get_fid(p9dev, old_dfid_val);
 	new_dfid = get_fid(p9dev, new_dfid_val);
@@ -1235,12 +1269,14 @@ static void virtio_p9_unlinkat(struct p9_dev *p9dev,
 			       struct p9_pdu *pdu, u32 *outlen)
 {
 	int ret;
-	char *name;
+	char *name = NULL;
 	u32 fid_val, flags;
 	struct p9_fid *fid;
 	char full_path[PATH_MAX];
 
-	virtio_p9_pdu_readf(pdu, "dsd", &fid_val, &name, &flags);
+	errno = virtio_p9_pdu_readf(pdu, "dsd", &fid_val, &name, &flags);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 
 	if (get_full_path(full_path, sizeof(full_path), fid, name) != 0)
