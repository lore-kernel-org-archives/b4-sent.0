MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-kvt1-virtio-d-v1-3-bfa9ce1cece5@certik.com>
References: <20261127-kvt1-virtio-d-v1-0-bfa9ce1cece5@certik.com>
In-Reply-To: <20261127-kvt1-virtio-d-v1-0-bfa9ce1cece5@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 02:56:40 +0000
Subject: [PATCH kvmtool 3/3] virtio: Reject invalid 9p buffers and queue
 indices
To: will@kernel.org, kvm@vger.kernel.org
Cc: julien.thierry.kdev@gmail.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795779125; l=15331;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=Jk6cr/MJvOtXITKDkkOORdERn7+E0Z/qQdQtVN1Gink=;
 b=tfOmuzzAY7uHyVsDwhQujEdjxectAPY1jomB/GcpEsuhrLVOB3vMbKiKqs670PSyHmtLJukG3
 uvCxeIdxHpUBU5A7crDKcRCTOyQIwEnId82uediWt4UYXTPss8EjvoK
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A guest can supply an unmapped 9p request or reply descriptor, notify
a queue index beyond the device count, or send a short 9p header whose
missing tag would be read for an error reply. A short first 9p iovec
can also underflow the Tread or Twrite data adjustment. An invalid
modern MMIO queue selector reaches out-of-range queue memory through
selected-queue registers.

Complete invalid requests without data and require a full header
before dispatch. Check decoded fields before handlers use them. Skip
Tread and Twrite headers across bounded iovecs, preserving valid split
requests. Ignore out-of-range modern PCI and MMIO notifications and
reject invalid modern MMIO queue selections.

Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 virtio/9p-pdu.c      |   2 +
 virtio/9p.c          | 238 +++++++++++++++++++++++++++++--------------
 virtio/core.c        |   3 +
 virtio/mmio-modern.c |   9 +-
 virtio/pci-modern.c  |   3 +
 5 files changed, 178 insertions(+), 77 deletions(-)

diff --git a/virtio/9p-pdu.c b/virtio/9p-pdu.c
index 2e8c12f..4939b67 100644
--- a/virtio/9p-pdu.c
+++ b/virtio/9p-pdu.c
@@ -47,6 +47,8 @@ static void virtio_p9_pdu_write(struct p9_pdu *pdu,
 			offset -= iov[i].iov_len;
 			continue;
 		} else {
+			if (!iov[i].iov_base)
+				return;
 			len = MIN(iov[i].iov_len - offset, size);
 			memcpy(iov[i].iov_base + offset, data, len);
 			size -= len;
diff --git a/virtio/9p.c b/virtio/9p.c
index 9bcc31d..2adcff8 100644
--- a/virtio/9p.c
+++ b/virtio/9p.c
@@ -6,6 +6,7 @@
 #include "kvm/virtio-9p.h"
 #include "kvm/guest_compat.h"
 #include "kvm/builtin-setup.h"
+#include "kvm/iovec.h"
 
 #include <stdio.h>
 #include <stdlib.h>
@@ -129,20 +130,36 @@ static void virtio_p9_set_reply_header(struct p9_pdu *pdu, u32 size)
 	virtio_p9_pdu_writef(pdu, "dbw", size, cmd + 1, tag);
 }
 
-static u16 virtio_p9_update_iov_cnt(struct iovec iov[], u32 count, int iov_cnt)
+static int virtio_p9_data_iov(const struct iovec src[], u16 count,
+			      size_t skip, size_t limit, bool require_full,
+			      struct iovec dst[])
 {
-	int i;
-	u32 total = 0;
-	for (i = 0; (i < iov_cnt) && (total < count); i++) {
-		if (total + iov[i].iov_len > count) {
-			/* we don't need this iov fully */
-			iov[i].iov_len -= ((total + iov[i].iov_len) - count);
-			i++;
-			break;
+	size_t total = 0;
+	u16 i;
+	int used = 0;
+
+	for (i = 0; i < count; i++) {
+		if (src[i].iov_len > SIZE_MAX - total)
+			return -1;
+		total += src[i].iov_len;
+	}
+	if (total < skip || (require_full && total - skip < limit))
+		return -1;
+
+	for (i = 0; i < count && limit; i++) {
+		size_t len = src[i].iov_len;
+
+		if (skip >= len) {
+			skip -= len;
+			continue;
 		}
-		total += iov[i].iov_len;
+		dst[used].iov_base = (char *)src[i].iov_base + skip;
+		dst[used].iov_len = MIN(len - skip, limit);
+		limit -= dst[used].iov_len;
+		skip = 0;
+		used++;
 	}
-	return i;
+	return used;
 }
 
 static void virtio_p9_error_reply(struct p9_dev *p9dev,
@@ -199,7 +216,10 @@ static void virtio_p9_clunk(struct p9_dev *p9dev,
 {
 	u32 fid;
 
-	virtio_p9_pdu_readf(pdu, "d", &fid);
+	if (virtio_p9_pdu_readf(pdu, "d", &fid)) {
+		virtio_p9_error_reply(p9dev, pdu, EINVAL, outlen);
+		return;
+	}
 	close_fid(p9dev, fid);
 
 	*outlen = pdu->write_offset;
@@ -298,7 +318,9 @@ static void virtio_p9_open(struct p9_dev *p9dev,
 	struct p9_fid *new_fid;
 
 
-	virtio_p9_pdu_readf(pdu, "dd", &fid, &flags);
+	errno = virtio_p9_pdu_readf(pdu, "dd", &fid, &flags);
+	if (errno)
+		goto err_out;
 	new_fid = get_fid(p9dev, fid);
 
 	if (lstat(new_fid->abs_path, &st) < 0)
@@ -459,7 +481,9 @@ static void virtio_p9_walk(struct p9_dev *p9dev,
 	u32 fid_val, newfid_val;
 
 
-	virtio_p9_pdu_readf(pdu, "ddw", &fid_val, &newfid_val, &nwname);
+	errno = virtio_p9_pdu_readf(pdu, "ddw", &fid_val, &newfid_val, &nwname);
+	if (errno)
+		goto err_out;
 	new_fid	= get_fid(p9dev, newfid_val);
 
 	nwqid = 0;
@@ -593,36 +617,39 @@ static void virtio_p9_read(struct p9_dev *p9dev,
 {
 	u64 offset;
 	u32 fid_val;
-	u16 iov_cnt;
-	void *iov_base;
-	size_t iov_len;
+	struct iovec data_iov[VIRTQUEUE_NUM];
+	int data_count;
 	u32 count, rcount;
+	ssize_t res;
 	struct p9_fid *fid;
 
-
+	if (virtio_p9_data_iov(pdu->out_iov, pdu->out_iov_cnt,
+			       sizeof(struct p9_msg) + sizeof(u32) + sizeof(u64) +
+			       sizeof(u32), 0, false, data_iov) < 0 ||
+	    virtio_p9_data_iov(pdu->in_iov, pdu->in_iov_cnt,
+			       VIRTIO_9P_HDR_LEN + sizeof(u32), 0, false,
+			       data_iov) < 0) {
+		*outlen = 0;
+		return;
+	}
 	rcount = 0;
-	virtio_p9_pdu_readf(pdu, "dqd", &fid_val, &offset, &count);
+	if (virtio_p9_pdu_readf(pdu, "dqd", &fid_val, &offset, &count)) {
+		virtio_p9_error_reply(p9dev, pdu, EINVAL, outlen);
+		return;
+	}
 	fid = get_fid(p9dev, fid_val);
 
-	iov_base = pdu->in_iov[0].iov_base;
-	iov_len  = pdu->in_iov[0].iov_len;
-	iov_cnt  = pdu->in_iov_cnt;
-	pdu->in_iov[0].iov_base += VIRTIO_9P_HDR_LEN + sizeof(u32);
-	pdu->in_iov[0].iov_len -= VIRTIO_9P_HDR_LEN + sizeof(u32);
-	pdu->in_iov_cnt = virtio_p9_update_iov_cnt(pdu->in_iov,
-						   count,
-						   pdu->in_iov_cnt);
-	rcount = preadv(fid->fd, pdu->in_iov,
-			pdu->in_iov_cnt, offset);
+	data_count = virtio_p9_data_iov(pdu->in_iov, pdu->in_iov_cnt,
+					VIRTIO_9P_HDR_LEN + sizeof(u32), count,
+					false, data_iov);
+	res = preadv(fid->fd, data_iov, data_count, offset);
+	if (res < 0) {
+		virtio_p9_error_reply(p9dev, pdu, errno, outlen);
+		return;
+	}
+	rcount = res;
 	if (rcount > count)
 		rcount = count;
-	/*
-	 * Update the iov_base back, so that rest of
-	 * pdu_writef works correctly.
-	 */
-	pdu->in_iov[0].iov_base = iov_base;
-	pdu->in_iov[0].iov_len  = iov_len;
-	pdu->in_iov_cnt         = iov_cnt;
 
 	pdu->write_offset = VIRTIO_9P_HDR_LEN;
 	virtio_p9_pdu_writef(pdu, "d", rcount);
@@ -651,7 +678,9 @@ static void virtio_p9_readdir(struct p9_dev *p9dev,
 	u64 offset, old_offset;
 
 	rcount = 0;
-	virtio_p9_pdu_readf(pdu, "dqd", &fid_val, &offset, &count);
+	errno = virtio_p9_pdu_readf(pdu, "dqd", &fid_val, &offset, &count);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 
 	if (!is_dir(fid)) {
@@ -708,7 +737,9 @@ static void virtio_p9_getattr(struct p9_dev *p9dev,
 	struct p9_fid *fid;
 	struct p9_stat_dotl statl;
 
-	virtio_p9_pdu_readf(pdu, "dq", &fid_val, &request_mask);
+	errno = virtio_p9_pdu_readf(pdu, "dq", &fid_val, &request_mask);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 	if (lstat(fid->abs_path, &st) < 0)
 		goto err_out;
@@ -756,7 +787,9 @@ static void virtio_p9_setattr(struct p9_dev *p9dev,
 	struct p9_fid *fid;
 	struct p9_iattr_dotl p9attr;
 
-	virtio_p9_pdu_readf(pdu, "dI", &fid_val, &p9attr);
+	errno = virtio_p9_pdu_readf(pdu, "dI", &fid_val, &p9attr);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 
 	if (p9attr.valid & ATTR_MODE) {
@@ -829,33 +862,34 @@ static void virtio_p9_write(struct p9_dev *p9dev,
 	u32 fid_val;
 	u32 count;
 	ssize_t res;
-	u16 iov_cnt;
-	void *iov_base;
-	size_t iov_len;
+	struct iovec data_iov[VIRTQUEUE_NUM];
+	int data_count;
 	struct p9_fid *fid;
 	/* u32 fid + u64 offset + u32 count */
 	int twrite_size = sizeof(u32) + sizeof(u64) + sizeof(u32);
 
-	virtio_p9_pdu_readf(pdu, "dqd", &fid_val, &offset, &count);
+	if (virtio_p9_data_iov(pdu->out_iov, pdu->out_iov_cnt,
+			       sizeof(struct p9_msg) + twrite_size, 0, false,
+			       data_iov) < 0 ||
+	    virtio_p9_data_iov(pdu->in_iov, pdu->in_iov_cnt,
+			       VIRTIO_9P_HDR_LEN + sizeof(u32), 0, false,
+			       data_iov) < 0) {
+		*outlen = 0;
+		return;
+	}
+	errno = virtio_p9_pdu_readf(pdu, "dqd", &fid_val, &offset, &count);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 
-	iov_base = pdu->out_iov[0].iov_base;
-	iov_len  = pdu->out_iov[0].iov_len;
-	iov_cnt  = pdu->out_iov_cnt;
-
-	/* Adjust the iovec to skip the header and meta data */
-	pdu->out_iov[0].iov_base += (sizeof(struct p9_msg) + twrite_size);
-	pdu->out_iov[0].iov_len -=  (sizeof(struct p9_msg) + twrite_size);
-	pdu->out_iov_cnt = virtio_p9_update_iov_cnt(pdu->out_iov, count,
-						    pdu->out_iov_cnt);
-	res = pwritev(fid->fd, pdu->out_iov, pdu->out_iov_cnt, offset);
-	/*
-	 * Update the iov_base back, so that rest of
-	 * pdu_readf works correctly.
-	 */
-	pdu->out_iov[0].iov_base = iov_base;
-	pdu->out_iov[0].iov_len  = iov_len;
-	pdu->out_iov_cnt         = iov_cnt;
+	data_count = virtio_p9_data_iov(pdu->out_iov, pdu->out_iov_cnt,
+					sizeof(struct p9_msg) + twrite_size,
+					 count, true, data_iov);
+	if (data_count < 0) {
+		errno = EINVAL;
+		goto err_out;
+	}
+	res = pwritev(fid->fd, data_iov, data_count, offset);
 
 	if (res < 0)
 		goto err_out;
@@ -875,7 +909,9 @@ static void virtio_p9_remove(struct p9_dev *p9dev,
 	u32 fid_val;
 	struct p9_fid *fid;
 
-	virtio_p9_pdu_readf(pdu, "d", &fid_val);
+	errno = virtio_p9_pdu_readf(pdu, "d", &fid_val);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 
 	ret = remove(fid->abs_path);
@@ -927,7 +963,9 @@ static void virtio_p9_readlink(struct p9_dev *p9dev,
 	struct p9_fid *fid;
 	char target_path[PATH_MAX];
 
-	virtio_p9_pdu_readf(pdu, "d", &fid_val);
+	errno = virtio_p9_pdu_readf(pdu, "d", &fid_val);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 
 	memset(target_path, 0, PATH_MAX);
@@ -953,7 +991,9 @@ static void virtio_p9_statfs(struct p9_dev *p9dev,
 	struct p9_fid *fid;
 	struct statfs stat_buf;
 
-	virtio_p9_pdu_readf(pdu, "d", &fid_val);
+	errno = virtio_p9_pdu_readf(pdu, "d", &fid_val);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 
 	ret = statfs(fid->abs_path, &stat_buf);
@@ -1026,7 +1066,9 @@ static void virtio_p9_fsync(struct p9_dev *p9dev,
 	struct p9_fid *fid;
 	u32 fid_val, datasync;
 
-	virtio_p9_pdu_readf(pdu, "dd", &fid_val, &datasync);
+	errno = virtio_p9_pdu_readf(pdu, "dd", &fid_val, &datasync);
+	if (errno)
+		goto err_out;
 	fid = get_fid(p9dev, fid_val);
 
 	if (fid->dir)
@@ -1300,7 +1342,10 @@ static void virtio_p9_flush(struct p9_dev *p9dev,
 {
 	u16 tag, oldtag;
 
-	virtio_p9_pdu_readf(pdu, "ww", &tag, &oldtag);
+	if (virtio_p9_pdu_readf(pdu, "ww", &tag, &oldtag)) {
+		virtio_p9_error_reply(p9dev, pdu, EINVAL, outlen);
+		return;
+	}
 	virtio_p9_pdu_writef(pdu, "w", tag);
 	*outlen = pdu->write_offset;
 	virtio_p9_set_reply_header(pdu, *outlen);
@@ -1351,6 +1396,18 @@ static p9_handler *virtio_9p_dotl_handler [] = {
 	[P9_TRENAME]      = virtio_p9_rename,
 };
 
+static bool virtio_p9_iov_valid(struct iovec iov[], u16 count)
+{
+	u16 i;
+
+	for (i = 0; i < count; i++) {
+		if (iov[i].iov_len && !iov[i].iov_base)
+			return false;
+	}
+
+	return true;
+}
+
 static struct p9_pdu *virtio_p9_pdu_init(struct kvm *kvm, struct virt_queue *vq)
 {
 	struct p9_pdu *pdu = calloc(1, sizeof(*pdu));
@@ -1364,18 +1421,41 @@ static struct p9_pdu *virtio_p9_pdu_init(struct kvm *kvm, struct virt_queue *vq)
 					ARRAY_SIZE(pdu->in_iov), pdu->out_iov,
 					ARRAY_SIZE(pdu->out_iov),
 					&pdu->in_iov_cnt, &pdu->out_iov_cnt);
+	if (!virtio_p9_iov_valid(pdu->in_iov, pdu->in_iov_cnt) ||
+	    !virtio_p9_iov_valid(pdu->out_iov, pdu->out_iov_cnt))
+		pdu->out_iov_cnt = 0;
 	return pdu;
 }
 
-static u8 virtio_p9_get_cmd(struct p9_pdu *pdu)
+static bool virtio_p9_get_cmd(struct p9_pdu *pdu, u8 *cmd)
 {
-	struct p9_msg *msg;
-	/*
-	 * we can peek directly into pdu for a u8
-	 * value. The host endianess won't be an issue
-	 */
-	msg = pdu->out_iov[0].iov_base;
-	return msg->cmd;
+	size_t offset = sizeof(u32);
+	size_t remaining = VIRTIO_9P_HDR_LEN;
+	u16 i;
+
+	for (i = 0; i < pdu->out_iov_cnt && remaining; i++) {
+		if (pdu->out_iov[i].iov_len >= remaining)
+			remaining = 0;
+		else
+			remaining -= pdu->out_iov[i].iov_len;
+	}
+	if (remaining)
+		return false;
+
+	for (i = 0; i < pdu->out_iov_cnt; i++) {
+		if (offset >= pdu->out_iov[i].iov_len) {
+			offset -= pdu->out_iov[i].iov_len;
+			continue;
+		}
+
+		if (!pdu->out_iov[i].iov_base)
+			return false;
+
+		*cmd = *((u8 *)pdu->out_iov[i].iov_base + offset);
+		return true;
+	}
+
+	return false;
 }
 
 static bool virtio_p9_do_io_request(struct kvm *kvm, struct p9_dev_job *job)
@@ -1391,7 +1471,14 @@ static bool virtio_p9_do_io_request(struct kvm *kvm, struct p9_dev_job *job)
 	p9dev = job->p9dev;
 
 	p9pdu = virtio_p9_pdu_init(kvm, vq);
-	cmd = virtio_p9_get_cmd(p9pdu);
+	if (!p9pdu)
+		return false;
+	if (iov_size(p9pdu->in_iov, p9pdu->in_iov_cnt) <
+	    VIRTIO_9P_HDR_LEN || !virtio_p9_get_cmd(p9pdu, &cmd)) {
+		virt_queue__set_used_elem(vq, p9pdu->queue_head, 0);
+		free(p9pdu);
+		return true;
+	}
 
 	if ((cmd >= ARRAY_SIZE(virtio_9p_dotl_handler)) ||
 	    !virtio_9p_dotl_handler[cmd])
@@ -1412,7 +1499,8 @@ static void virtio_p9_do_io(struct kvm *kvm, void *param)
 	struct virt_queue *vq  = job->vq;
 
 	while (virt_queue__available(vq)) {
-		virtio_p9_do_io_request(kvm, job);
+		if (!virtio_p9_do_io_request(kvm, job))
+			break;
 	}
 
 	if (virtio_queue__should_signal(vq))
diff --git a/virtio/core.c b/virtio/core.c
index 6d1eeea..67520d4 100644
--- a/virtio/core.c
+++ b/virtio/core.c
@@ -456,6 +456,9 @@ bool virtio_queue__should_signal(struct virt_queue *vq)
 {
 	u16 old_idx, new_idx, event_idx;
 
+	if (!vq->enabled)
+		return false;
+
 	/*
 	 * Use mb to assure used idx has been increased before we signal the
 	 * guest, and we don't read a stale value for used_event. Without a mb
diff --git a/virtio/mmio-modern.c b/virtio/mmio-modern.c
index 7787508..fa20c98 100644
--- a/virtio/mmio-modern.c
+++ b/virtio/mmio-modern.c
@@ -81,9 +81,13 @@ static void virtio_mmio_config_out(struct kvm_cpu *vcpu,
 	switch (addr) {
 	case VIRTIO_MMIO_DEVICE_FEATURES_SEL:
 	case VIRTIO_MMIO_DRIVER_FEATURES_SEL:
-	case VIRTIO_MMIO_QUEUE_SEL:
 		*(u32 *)(((void *)&vmmio->hdr) + addr) = val;
 		break;
+	case VIRTIO_MMIO_QUEUE_SEL:
+		if (val >= vdev->ops->get_vq_count(kvm, vmmio->dev))
+			break;
+		vmmio->hdr.queue_sel = val;
+		break;
 	case VIRTIO_MMIO_STATUS:
 		vmmio->hdr.status = val;
 		virtio_notify_status(kvm, vdev, vmmio->dev, val);
@@ -108,7 +112,8 @@ static void virtio_mmio_config_out(struct kvm_cpu *vcpu,
 			virtio_mmio_exit_vq(kvm, vdev, vmmio->hdr.queue_sel);
 		break;
 	case VIRTIO_MMIO_QUEUE_NOTIFY:
-		vdev->ops->notify_vq(vmmio->kvm, vmmio->dev, val);
+		if (val < vdev->ops->get_vq_count(vmmio->kvm, vmmio->dev))
+			vdev->ops->notify_vq(vmmio->kvm, vmmio->dev, val);
 		break;
 	case VIRTIO_MMIO_INTERRUPT_ACK:
 		vmmio->hdr.interrupt_state &= ~val;
diff --git a/virtio/pci-modern.c b/virtio/pci-modern.c
index 2b234a7..94bee60 100644
--- a/virtio/pci-modern.c
+++ b/virtio/pci-modern.c
@@ -128,6 +128,9 @@ static bool virtio_pci__notify_write(struct virtio_device *vdev,
 	u16 vq = ioport__read16(data);
 	struct virtio_pci *vpci = vdev->virtio;
 
+	if (vq >= vdev->ops->get_vq_count(vpci->kvm, vpci->dev))
+		return true;
+
 	vdev->ops->notify_vq(vpci->kvm, vpci->dev, vq);
 
 	return true;
