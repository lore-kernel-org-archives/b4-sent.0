MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-kvt1-virtio-d-v1-1-bfa9ce1cece5@certik.com>
References: <20261127-kvt1-virtio-d-v1-0-bfa9ce1cece5@certik.com>
In-Reply-To: <20261127-kvt1-virtio-d-v1-0-bfa9ce1cece5@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 02:38:53 +0000
Subject: [PATCH kvmtool 1/3] virtio: Bound descriptor chains and guest
 ranges
To: will@kernel.org, kvm@vger.kernel.org
Cc: julien.thierry.kdev@gmail.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795779125; l=29675;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=+yQ+8yI8aenIvI8cR3b90eJpUZex1xk0kc3/Sp5k6e8=;
 b=NPNCHrDj9wy5FlhjoL5UkzysN6iZyAz1RcJ9Qr4+PsQca2MCs61vgeX0QxPan7zBn46XVQ2Gd
 55xnhhSk6jKAgB5pRXNlbP+ybE/9I/AducMN8nmYywFlEfZW1yFDAub
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A guest can loop a direct or indirect descriptor chain past a device's
fixed iovec array. A descriptor table or data buffer can also extend
beyond mapped RAM. Short net RX headers, malformed net control chains,
and oversized balloon statistics can write beyond intended buffers or
use an uninitialized iovec.

Limit visited descriptors by queue size and caller capacity, validate
complete guest ranges and descriptor direction, and refuse rings whose
full layout is not safely mapped. Require enough writable space for a
net RX header, including split headers, and write the buffer count
across iovecs. Check both net control directions and copy complete
balloon statistics across bounded iovecs.

Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 include/kvm/virtio.h |   9 +-
 virtio/9p.c          |   7 +-
 virtio/balloon.c     |  59 +++++++--
 virtio/blk.c         |  18 ++-
 virtio/console.c     |   9 +-
 virtio/core.c        | 287 +++++++++++++++++++++++++++++++++++++------
 virtio/mmio.c        |   5 +-
 virtio/net.c         |  57 +++++++--
 virtio/pci.c         |   9 +-
 virtio/rng.c         |   5 +-
 virtio/scsi.c        |   3 +-
 virtio/vsock.c       |   3 +-
 12 files changed, 387 insertions(+), 84 deletions(-)

diff --git a/include/kvm/virtio.h b/include/kvm/virtio.h
index dd3117b..071af37 100644
--- a/include/kvm/virtio.h
+++ b/include/kvm/virtio.h
@@ -201,11 +201,12 @@ struct vring_used_elem *virt_queue__set_used_elem(struct virt_queue *queue, u32
 
 bool virtio_queue__should_signal(struct virt_queue *vq);
 u16 virt_queue__get_iov(struct virt_queue *vq, struct iovec iov[],
-			u16 *out, u16 *in, struct kvm *kvm);
+			unsigned int capacity, u16 *out, u16 *in, struct kvm *kvm);
 u16 virt_queue__get_head_iov(struct virt_queue *vq, struct iovec iov[],
-			     u16 *out, u16 *in, u16 head, struct kvm *kvm);
+			     unsigned int capacity, u16 *out, u16 *in, u16 head, struct kvm *kvm);
 u16 virt_queue__get_inout_iov(struct kvm *kvm, struct virt_queue *queue,
-			      struct iovec in_iov[], struct iovec out_iov[],
+			      struct iovec in_iov[], unsigned int in_capacity,
+			      struct iovec out_iov[], unsigned int out_capacity,
 			      u16 *in, u16 *out);
 int virtio__get_dev_specific_field(int offset, bool msix, u32 *config_off);
 
@@ -254,7 +255,7 @@ int __must_check virtio_init(struct kvm *kvm, void *dev, struct virtio_device *v
 void virtio_exit(struct kvm *kvm, struct virtio_device *vdev);
 int virtio_compat_add_message(const char *device, const char *config);
 const char* virtio_trans_name(enum virtio_trans trans);
-void virtio_init_device_vq(struct kvm *kvm, struct virtio_device *vdev,
+bool virtio_init_device_vq(struct kvm *kvm, struct virtio_device *vdev,
 			   struct virt_queue *vq, size_t nr_descs);
 void virtio_exit_vq(struct kvm *kvm, struct virtio_device *vdev, void *dev,
 		    int num);
diff --git a/virtio/9p.c b/virtio/9p.c
index fb08d0d..07dd244 100644
--- a/virtio/9p.c
+++ b/virtio/9p.c
@@ -1325,7 +1325,9 @@ static struct p9_pdu *virtio_p9_pdu_init(struct kvm *kvm, struct virt_queue *vq)
 	pdu->read_offset	= VIRTIO_9P_HDR_LEN;
 	pdu->write_offset	= VIRTIO_9P_HDR_LEN;
 	pdu->queue_head		= virt_queue__get_inout_iov(kvm, vq, pdu->in_iov,
-					pdu->out_iov, &pdu->in_iov_cnt, &pdu->out_iov_cnt);
+					ARRAY_SIZE(pdu->in_iov), pdu->out_iov,
+					ARRAY_SIZE(pdu->out_iov),
+					&pdu->in_iov_cnt, &pdu->out_iov_cnt);
 	return pdu;
 }
 
@@ -1427,7 +1429,8 @@ static int init_vq(struct kvm *kvm, void *dev, u32 vq)
 	queue		= &p9dev->vqs[vq];
 	job		= &p9dev->jobs[vq];
 
-	virtio_init_device_vq(kvm, &p9dev->vdev, queue, VIRTQUEUE_NUM);
+	if (!virtio_init_device_vq(kvm, &p9dev->vdev, queue, VIRTQUEUE_NUM))
+		return -EINVAL;
 
 	*job		= (struct p9_dev_job) {
 		.vq		= queue,
diff --git a/virtio/balloon.c b/virtio/balloon.c
index 5b3e062..e966d97 100644
--- a/virtio/balloon.c
+++ b/virtio/balloon.c
@@ -9,6 +9,7 @@
 #include "kvm/threadpool.h"
 #include "kvm/guest_compat.h"
 #include "kvm/kvm-ipc.h"
+#include "kvm/iovec.h"
 
 #include <linux/virtio_ring.h>
 #include <linux/virtio_balloon.h>
@@ -22,6 +23,7 @@
 #include <sys/mman.h>
 #include <pthread.h>
 #include <sys/eventfd.h>
+#include <stdint.h>
 
 #define NUM_VIRT_QUEUES		3
 #define VIRTIO_BLN_QUEUE_SIZE	128
@@ -52,20 +54,33 @@ static int compat_id = -1;
 static bool virtio_bln_do_io_request(struct kvm *kvm, struct bln_dev *bdev, struct virt_queue *queue)
 {
 	struct iovec iov[VIRTIO_BLN_QUEUE_SIZE];
-	unsigned int len = 0;
+	u32 len = 0;
 	u16 out, in, head;
-	u32 *ptrs, i;
+	u32 i;
 	u32 actual;
 
-	head	= virt_queue__get_iov(queue, iov, &out, &in, kvm);
-	ptrs	= iov[0].iov_base;
-	len	= iov[0].iov_len / sizeof(u32);
+	head	= virt_queue__get_iov(queue, iov, ARRAY_SIZE(iov), &out, &in, kvm);
+	if (!out || in) {
+		virt_queue__set_used_elem(queue, head, 0);
+		return true;
+	}
+	for (i = 0; i < out; i++) {
+		if (iov[i].iov_len > UINT32_MAX - len)
+			goto invalid;
+		len += iov[i].iov_len;
+	}
+	if (len % sizeof(u32))
+		goto invalid;
 
 	actual = le32_to_cpu(bdev->config.actual);
-	for (i = 0 ; i < len ; i++) {
+	for (i = 0; i < len / sizeof(u32); i++) {
 		void *guest_ptr;
+		u32 pfn;
 
-		guest_ptr = guest_flat_to_host(kvm, (u64)ptrs[i] << VIRTIO_BALLOON_PFN_SHIFT);
+		memcpy_fromiovecend((unsigned char *)&pfn, iov,
+				    i * sizeof(pfn), sizeof(pfn));
+		guest_ptr = guest_flat_to_host(kvm,
+					       (u64)pfn << VIRTIO_BALLOON_PFN_SHIFT);
 		if (queue == &bdev->vqs[VIRTIO_BLN_INFLATE]) {
 			madvise(guest_ptr, 1 << VIRTIO_BALLOON_PFN_SHIFT, MADV_DONTNEED);
 			actual++;
@@ -75,8 +90,12 @@ static bool virtio_bln_do_io_request(struct kvm *kvm, struct bln_dev *bdev, stru
 	}
 	bdev->config.actual = cpu_to_le32(actual);
 
-	virt_queue__set_used_elem(queue, head, len);
+	virt_queue__set_used_elem(queue, head, len / sizeof(u32));
+
+	return true;
 
+invalid:
+	virt_queue__set_used_elem(queue, head, 0);
 	return true;
 }
 
@@ -84,10 +103,21 @@ static bool virtio_bln_do_stat_request(struct kvm *kvm, struct bln_dev *bdev, st
 {
 	struct iovec iov[VIRTIO_BLN_QUEUE_SIZE];
 	u16 out, in, head;
+	u16 i;
 	struct virtio_balloon_stat *stat;
+	size_t len = 0;
 	u64 wait_val = 1;
 
-	head = virt_queue__get_iov(queue, iov, &out, &in, kvm);
+	head = virt_queue__get_iov(queue, iov, ARRAY_SIZE(iov), &out, &in, kvm);
+	if (!out || in)
+		goto invalid;
+	for (i = 0; i < out; i++) {
+		if (iov[i].iov_len > sizeof(bdev->stats) - len)
+			goto invalid;
+		len += iov[i].iov_len;
+	}
+	if (len % sizeof(struct virtio_balloon_stat))
+		goto invalid;
 	stat = iov[0].iov_base;
 
 	/* Initial empty stat buffer */
@@ -98,9 +128,9 @@ static bool virtio_bln_do_stat_request(struct kvm *kvm, struct bln_dev *bdev, st
 		return true;
 	}
 
-	memcpy(bdev->stats, stat, iov[0].iov_len);
+	memcpy_fromiovec((unsigned char *)bdev->stats, iov, len);
 
-	bdev->stat_count = iov[0].iov_len / sizeof(struct virtio_balloon_stat);
+	bdev->stat_count = len / sizeof(struct virtio_balloon_stat);
 	bdev->cur_stat = stat;
 	bdev->cur_stat_head = head;
 
@@ -108,6 +138,10 @@ static bool virtio_bln_do_stat_request(struct kvm *kvm, struct bln_dev *bdev, st
 		return -EFAULT;
 
 	return 1;
+
+invalid:
+	virt_queue__set_used_elem(queue, head, 0);
+	return true;
 }
 
 static void virtio_bln_do_io(struct kvm *kvm, void *param)
@@ -214,7 +248,8 @@ static int init_vq(struct kvm *kvm, void *dev, u32 vq)
 
 	queue		= &bdev->vqs[vq];
 
-	virtio_init_device_vq(kvm, &bdev->vdev, queue, VIRTIO_BLN_QUEUE_SIZE);
+	if (!virtio_init_device_vq(kvm, &bdev->vdev, queue, VIRTIO_BLN_QUEUE_SIZE))
+		return -EINVAL;
 
 	thread_pool__init_job(&bdev->jobs[vq], kvm, virtio_bln_do_io, queue);
 
diff --git a/virtio/blk.c b/virtio/blk.c
index b2d6180..30bf3d7 100644
--- a/virtio/blk.c
+++ b/virtio/blk.c
@@ -146,10 +146,19 @@ static void virtio_blk_do_io(struct kvm *kvm, struct virt_queue *vq, struct blk_
 
 	while (virt_queue__available(vq)) {
 		head		= virt_queue__pop(vq);
+		if (head >= VIRTIO_BLK_QUEUE_SIZE || head >= vq->vring.num) {
+			virt_queue__set_used_elem(vq, head, 0);
+			continue;
+		}
 		req		= &bdev->reqs[head];
-		req->head	= virt_queue__get_head_iov(vq, req->iov, &req->out,
-					&req->in, head, kvm);
+		req->head	= virt_queue__get_head_iov(vq, req->iov,
+							   ARRAY_SIZE(req->iov), &req->out,
+							   &req->in, head, kvm);
 		req->vq		= vq;
+		if (!req->out || !req->in) {
+			virt_queue__set_used_elem(vq, head, 0);
+			continue;
+		}
 
 		virtio_blk_do_io_request(kvm, vq, req);
 	}
@@ -219,8 +228,9 @@ static int init_vq(struct kvm *kvm, void *dev, u32 vq)
 
 	compat__remove_message(compat_id);
 
-	virtio_init_device_vq(kvm, &bdev->vdev, &bdev->vqs[vq],
-			      VIRTIO_BLK_QUEUE_SIZE);
+	if (!virtio_init_device_vq(kvm, &bdev->vdev, &bdev->vqs[vq],
+				   VIRTIO_BLK_QUEUE_SIZE))
+		return -EINVAL;
 
 	if (vq != 0)
 		return 0;
diff --git a/virtio/console.c b/virtio/console.c
index 9a775f2..76e1cd8 100644
--- a/virtio/console.c
+++ b/virtio/console.c
@@ -62,8 +62,8 @@ static void virtio_console__inject_interrupt_callback(struct kvm *kvm, void *par
 	vq = param;
 
 	if (term_readable(0) && virt_queue__available(vq)) {
-		head = virt_queue__get_iov(vq, iov, &out, &in, kvm);
-		len = term_getc_iov(kvm, iov, in, 0);
+		head = virt_queue__get_iov(vq, iov, ARRAY_SIZE(iov), &out, &in, kvm);
+		len = in ? term_getc_iov(kvm, iov, in, 0) : 0;
 		virt_queue__set_used_elem(vq, head, len);
 		cdev.vdev.ops->signal_vq(kvm, &cdev.vdev, vq - cdev.vqs);
 	}
@@ -99,7 +99,7 @@ static void virtio_console_handle_callback(struct kvm *kvm, void *param)
 	 */
 
 	while (virt_queue__available(vq)) {
-		head = virt_queue__get_iov(vq, iov, &out, &in, kvm);
+		head = virt_queue__get_iov(vq, iov, ARRAY_SIZE(iov), &out, &in, kvm);
 		len = term_putc_iov(iov, out, 0);
 		virt_queue__set_used_elem(vq, head, len);
 	}
@@ -148,7 +148,8 @@ static int init_vq(struct kvm *kvm, void *dev, u32 vq)
 
 	queue		= &cdev.vqs[vq];
 
-	virtio_init_device_vq(kvm, &cdev.vdev, queue, VIRTIO_CONSOLE_QUEUE_SIZE);
+	if (!virtio_init_device_vq(kvm, &cdev.vdev, queue, VIRTIO_CONSOLE_QUEUE_SIZE))
+		return -EINVAL;
 
 	if (vq == VIRTIO_CONSOLE_TX_QUEUE) {
 		thread_pool__init_job(&cdev.jobs[vq], kvm, virtio_console_handle_callback, queue);
diff --git a/virtio/core.c b/virtio/core.c
index 96bbf96..6d1eeea 100644
--- a/virtio/core.c
+++ b/virtio/core.c
@@ -2,6 +2,8 @@
 #include <linux/types.h>
 #include <sys/uio.h>
 #include <stdlib.h>
+#include <stdint.h>
+#include <linux/list.h>
 
 #include "kvm/guest_compat.h"
 #include "kvm/barrier.h"
@@ -51,6 +53,118 @@ int virtio_transport_parser(const struct option *opt, const char *arg, int unset
 	return 0;
 }
 
+static size_t virtio_guest_span(struct kvm *kvm, u64 addr, size_t len,
+				void **host, bool write)
+{
+	struct kvm_mem_bank *bank;
+
+	list_for_each_entry(bank, &kvm->mem_banks, list) {
+		u64 offset;
+
+		if (addr < bank->guest_phys_addr)
+			continue;
+		offset = addr - bank->guest_phys_addr;
+		if (offset >= bank->size || !bank->host_addr ||
+		    bank->type & KVM_MEM_TYPE_RESERVED ||
+		    (write && bank->type & KVM_MEM_TYPE_READONLY))
+			continue;
+		*host = (char *)bank->host_addr + offset;
+		return min_t(u64, len, bank->size - offset);
+	}
+
+	return 0;
+}
+
+static bool virtio_guest_range_valid(struct kvm *kvm, u64 addr, size_t len)
+{
+	void *host;
+	size_t span;
+
+	if (len > UINT64_MAX - addr)
+		return false;
+	while (len) {
+		span = virtio_guest_span(kvm, addr, len, &host, false);
+		if (!span)
+			return false;
+		addr += span;
+		len -= span;
+	}
+
+	return true;
+}
+
+static void *virtio_guest_contiguous(struct kvm *kvm, u64 addr, size_t len,
+				     bool write)
+{
+	void *host, *base = NULL;
+	size_t done = 0, span;
+
+	if (!len || len > UINT64_MAX - addr)
+		return NULL;
+	while (done < len) {
+		span = virtio_guest_span(kvm, addr + done, len - done,
+					 &host, write);
+		if (!span)
+			return NULL;
+		if (base) {
+			if (done > UINTPTR_MAX - (uintptr_t)base)
+				return NULL;
+			if ((uintptr_t)host != (uintptr_t)base + done)
+				return NULL;
+		}
+		if (!base)
+			base = host;
+		done += span;
+	}
+
+	return base;
+}
+
+static bool virtio_guest_read(struct kvm *kvm, u64 addr, void *data, size_t len)
+{
+	void *host;
+	size_t span;
+
+	if (len > UINT64_MAX - addr)
+		return false;
+	while (len) {
+		span = virtio_guest_span(kvm, addr, len, &host, false);
+		if (!span)
+			return false;
+		memcpy(data, host, span);
+		data += span;
+		addr += span;
+		len -= span;
+	}
+
+	return true;
+}
+
+static int virtio_guest_iov(struct kvm *kvm, u64 addr, u32 len,
+			    struct iovec iov[], unsigned int capacity, bool write)
+{
+	void *host;
+	size_t span;
+	unsigned int count = 0;
+
+	if (len > UINT64_MAX - addr)
+		return -1;
+	while (len) {
+		if (count >= capacity)
+			return -1;
+		span = virtio_guest_span(kvm, addr, len, &host, write);
+		if (!span)
+			return -1;
+		iov[count].iov_base = host;
+		iov[count].iov_len = span;
+		count++;
+		addr += span;
+		len -= span;
+	}
+
+	return count;
+}
+
 void virt_queue__used_idx_advance(struct virt_queue *queue, u16 jump)
 {
 	u16 idx = virtio_guest_to_host_u16(queue->endian,
@@ -103,83 +217,154 @@ static inline bool virt_desc__test_flag(struct virt_queue *vq,
  * end.
  */
 static unsigned next_desc(struct virt_queue *vq, struct vring_desc *desc,
-			  unsigned int i, unsigned int max)
+			  unsigned int max)
 {
 	unsigned int next;
 
 	/* If this descriptor says it doesn't chain, we're done. */
-	if (!virt_desc__test_flag(vq, &desc[i], VRING_DESC_F_NEXT))
+	if (!virt_desc__test_flag(vq, desc, VRING_DESC_F_NEXT))
 		return max;
 
-	next = virtio_guest_to_host_u16(vq->endian, desc[i].next);
+	next = virtio_guest_to_host_u16(vq->endian, desc->next);
 
 	/* Ensure they're not leading us off end of descriptors. */
 	return min(next, max);
 }
 
-u16 virt_queue__get_head_iov(struct virt_queue *vq, struct iovec iov[], u16 *out, u16 *in, u16 head, struct kvm *kvm)
+static bool virt_queue__chain_has_room(unsigned int idx, unsigned int max,
+				       unsigned int *seen, unsigned int capacity)
 {
-	struct vring_desc *desc;
+	if (idx >= max || *seen >= max || *seen >= capacity)
+		return false;
+
+	++*seen;
+	return true;
+}
+
+u16 virt_queue__get_head_iov(struct virt_queue *vq, struct iovec iov[], unsigned int capacity,
+			     u16 *out, u16 *in, u16 head, struct kvm *kvm)
+{
+	struct vring_desc *desc, entry;
+	u64 table_addr = 0;
+	u32 table_len;
 	u16 idx;
-	u16 max;
+	bool indirect = false, write;
+	int added;
+	unsigned int max, seen = 0, limit;
 
 	idx = head;
 	*out = *in = 0;
 	max = vq->vring.num;
+	limit = min(capacity, max);
 	desc = vq->vring.desc;
+	if (!desc || idx >= max || !capacity)
+		return head;
 
 	if (virt_desc__test_flag(vq, &desc[idx], VRING_DESC_F_INDIRECT)) {
-		max = virtio_guest_to_host_u32(vq->endian, desc[idx].len) / sizeof(struct vring_desc);
-		desc = guest_flat_to_host(kvm, virtio_guest_to_host_u64(vq->endian, desc[idx].addr));
+		table_len = virtio_guest_to_host_u32(vq->endian, desc[idx].len);
+		table_addr = virtio_guest_to_host_u64(vq->endian, desc[idx].addr);
+		if (!table_len || table_len % sizeof(entry) ||
+		    !virtio_guest_range_valid(kvm, table_addr, table_len))
+			return head;
+		max = table_len / sizeof(entry);
+		indirect = true;
 		idx = 0;
 	}
 
 	do {
+		if (!virt_queue__chain_has_room(idx, max, &seen, limit) ||
+		    (indirect && !virtio_guest_read(kvm,
+						table_addr + idx * sizeof(entry),
+						&entry, sizeof(entry)))) {
+			*out = *in = 0;
+			break;
+		}
+		if (!indirect)
+			entry = desc[idx];
+		if (virt_desc__test_flag(vq, &entry, VRING_DESC_F_INDIRECT)) {
+			*out = *in = 0;
+			break;
+		}
 		/* Grab the first descriptor, and check it's OK. */
-		iov[*out + *in].iov_len = virtio_guest_to_host_u32(vq->endian, desc[idx].len);
-		iov[*out + *in].iov_base = guest_flat_to_host(kvm,
-							      virtio_guest_to_host_u64(vq->endian, desc[idx].addr));
+		write = virt_desc__test_flag(vq, &entry, VRING_DESC_F_WRITE);
+		if (!write && *in) {
+			*out = *in = 0;
+			break;
+		}
+		added = virtio_guest_iov(kvm,
+					 virtio_guest_to_host_u64(vq->endian, entry.addr),
+					 virtio_guest_to_host_u32(vq->endian, entry.len),
+					 &iov[*out + *in], capacity - *out - *in,
+					 write);
+		if (added < 0) {
+			*out = *in = 0;
+			break;
+		}
 		/* If this is an input descriptor, increment that count. */
-		if (virt_desc__test_flag(vq, &desc[idx], VRING_DESC_F_WRITE))
-			(*in)++;
+		if (write)
+			*in += added;
 		else
-			(*out)++;
-	} while ((idx = next_desc(vq, desc, idx, max)) != max);
+			*out += added;
+	} while ((idx = next_desc(vq, &entry, max)) != max);
 
 	return head;
 }
 
-u16 virt_queue__get_iov(struct virt_queue *vq, struct iovec iov[], u16 *out, u16 *in, struct kvm *kvm)
+u16 virt_queue__get_iov(struct virt_queue *vq, struct iovec iov[],
+			unsigned int capacity, u16 *out, u16 *in,
+			struct kvm *kvm)
 {
 	u16 head;
 
 	head = virt_queue__pop(vq);
 
-	return virt_queue__get_head_iov(vq, iov, out, in, head, kvm);
+	return virt_queue__get_head_iov(vq, iov, capacity, out, in, head, kvm);
 }
 
 /* in and out are relative to guest */
 u16 virt_queue__get_inout_iov(struct kvm *kvm, struct virt_queue *queue,
-			      struct iovec in_iov[], struct iovec out_iov[],
+			      struct iovec in_iov[], unsigned int in_capacity,
+			      struct iovec out_iov[], unsigned int out_capacity,
 			      u16 *in, u16 *out)
 {
 	struct vring_desc *desc;
 	u16 head, idx;
+	unsigned int max = queue->vring.num, seen = 0;
 
 	idx = head = virt_queue__pop(queue);
 	*out = *in = 0;
 	do {
 		u64 addr;
+		u32 len;
+		int added;
+
+		if (!virt_queue__chain_has_room(idx, max, &seen, max)) {
+			*out = *in = 0;
+			break;
+		}
 		desc = virt_queue__get_desc(queue, idx);
+		if (virt_desc__test_flag(queue, desc, VRING_DESC_F_INDIRECT)) {
+			*out = *in = 0;
+			break;
+		}
 		addr = virtio_guest_to_host_u64(queue->endian, desc->addr);
+		len = virtio_guest_to_host_u32(queue->endian, desc->len);
 		if (virt_desc__test_flag(queue, desc, VRING_DESC_F_WRITE)) {
-			in_iov[*in].iov_base = guest_flat_to_host(kvm, addr);
-			in_iov[*in].iov_len = virtio_guest_to_host_u32(queue->endian, desc->len);
-			(*in)++;
+			added = virtio_guest_iov(kvm, addr, len,
+						 &in_iov[*in], in_capacity - *in, true);
+			if (added < 0) {
+				*out = *in = 0;
+				break;
+			}
+			*in += added;
 		} else {
-			out_iov[*out].iov_base = guest_flat_to_host(kvm, addr);
-			out_iov[*out].iov_len = virtio_guest_to_host_u32(queue->endian, desc->len);
-			(*out)++;
+			added = virtio_guest_iov(kvm, addr, len,
+						 &out_iov[*out], out_capacity - *out, false);
+			if (added < 0) {
+				*out = *in = 0;
+				break;
+			}
+			*out += added;
 		}
 		if (virt_desc__test_flag(queue, desc, VRING_DESC_F_NEXT))
 			idx = virtio_guest_to_host_u16(queue->endian, desc->next);
@@ -190,33 +375,57 @@ u16 virt_queue__get_inout_iov(struct kvm *kvm, struct virt_queue *queue,
 	return head;
 }
 
-void virtio_init_device_vq(struct kvm *kvm, struct virtio_device *vdev,
+bool virtio_init_device_vq(struct kvm *kvm, struct virtio_device *vdev,
 			   struct virt_queue *vq, size_t nr_descs)
 {
 	struct vring_addr *addr = &vq->vring_addr;
+	size_t desc_len, avail_len, used_len;
+	void *desc, *avail, *used;
 
-	vq->endian		= vdev->endian;
-	vq->use_event_idx	= (vdev->features & (1UL << VIRTIO_RING_F_EVENT_IDX));
-	vq->enabled		= true;
-	vq->vdev		= vdev;
+	vq->enabled = false;
+	memset(&vq->vring, 0, sizeof(vq->vring));
+	if (!nr_descs || nr_descs > UINT16_MAX)
+		return false;
+	desc_len = nr_descs * sizeof(struct vring_desc);
+	avail_len = (nr_descs + 3) * sizeof(u16);
+	used_len = nr_descs * sizeof(struct vring_used_elem) + 3 * sizeof(u16);
 
 	if (addr->legacy) {
-		unsigned long base = (u64)addr->pfn * addr->pgsize;
-		void *p = guest_flat_to_host(kvm, base);
-
+		u64 base = (u64)addr->pfn * addr->pgsize;
+		u64 used_offset;
+		void *p;
+
+		if (!addr->align || addr->align & (addr->align - 1))
+			return false;
+		used_offset = (desc_len + avail_len + (u64)addr->align - 1) &
+			      ~((u64)addr->align - 1);
+		p = virtio_guest_contiguous(kvm, base, used_offset + used_len, true);
+		if (!p)
+			return false;
 		vring_init(&vq->vring, nr_descs, p, addr->align);
 	} else {
-		u64 desc = (u64)addr->desc_hi << 32 | addr->desc_lo;
-		u64 avail = (u64)addr->avail_hi << 32 | addr->avail_lo;
-		u64 used = (u64)addr->used_hi << 32 | addr->used_lo;
-
+		u64 desc_addr = (u64)addr->desc_hi << 32 | addr->desc_lo;
+		u64 avail_addr = (u64)addr->avail_hi << 32 | addr->avail_lo;
+		u64 used_addr = (u64)addr->used_hi << 32 | addr->used_lo;
+
+		desc = virtio_guest_contiguous(kvm, desc_addr, desc_len, false);
+		avail = virtio_guest_contiguous(kvm, avail_addr, avail_len, false);
+		used = virtio_guest_contiguous(kvm, used_addr, used_len, true);
+		if (!desc || !avail || !used)
+			return false;
 		vq->vring = (struct vring) {
-			.desc	= guest_flat_to_host(kvm, desc),
-			.used	= guest_flat_to_host(kvm, used),
-			.avail	= guest_flat_to_host(kvm, avail),
+			.desc	= desc,
+			.used	= used,
+			.avail	= avail,
 			.num	= nr_descs,
 		};
 	}
+
+	vq->endian		= vdev->endian;
+	vq->use_event_idx	= (vdev->features & (1UL << VIRTIO_RING_F_EVENT_IDX));
+	vq->enabled		= true;
+	vq->vdev		= vdev;
+	return true;
 }
 
 void virtio_exit_vq(struct kvm *kvm, struct virtio_device *vdev,
diff --git a/virtio/mmio.c b/virtio/mmio.c
index 0c66724..60a3123 100644
--- a/virtio/mmio.c
+++ b/virtio/mmio.c
@@ -87,7 +87,10 @@ int virtio_mmio_init_vq(struct kvm *kvm, struct virtio_device *vdev, int vq)
 		pr_err("couldn't add ioeventfd for vq %d: %d", vq, ret);
 		return ret;
 	}
-	return vdev->ops->init_vq(vmmio->kvm, vmmio->dev, vq);
+	ret = vdev->ops->init_vq(vmmio->kvm, vmmio->dev, vq);
+	if (ret)
+		ioeventfd__del_event(vmmio->addr + VIRTIO_MMIO_QUEUE_NOTIFY, vq);
+	return ret;
 }
 
 void virtio_mmio_exit_vq(struct kvm *kvm, struct virtio_device *vdev, int vq)
diff --git a/virtio/net.c b/virtio/net.c
index 492c576..563a4bc 100644
--- a/virtio/net.c
+++ b/virtio/net.c
@@ -17,6 +17,7 @@
 
 #include <arpa/inet.h>
 #include <net/if.h>
+#include <stddef.h>
 
 #include <unistd.h>
 #include <fcntl.h>
@@ -109,11 +110,12 @@ static void *virtio_net_rx_thread(void *p)
 
 		while (virt_queue__available(vq)) {
 			unsigned char buffer[MAX_PACKET_SIZE + sizeof(struct virtio_net_hdr_mrg_rxbuf)];
+			struct iovec hdr_iov[VIRTIO_NET_QUEUE_SIZE];
 			struct iovec dummy_iov = {
 				.iov_base = buffer,
 				.iov_len  = sizeof(buffer),
 			};
-			struct virtio_net_hdr_mrg_rxbuf *hdr;
+			u16 num_buffers_wire;
 			u16 num_buffers;
 
 			len = ndev->ops->rx(&dummy_iov, 1, ndev);
@@ -124,8 +126,15 @@ static void *virtio_net_rx_thread(void *p)
 			}
 
 			copied = num_buffers = 0;
-			head = virt_queue__get_iov(vq, iov, &out, &in, kvm);
-			hdr = iov[0].iov_base;
+			head = virt_queue__get_iov(vq, iov, ARRAY_SIZE(iov), &out, &in, kvm);
+			if (out || !in ||
+			    iov_size(iov, in) < (size_t)virtio_net_hdr_len(ndev)) {
+				virt_queue__set_used_elem(vq, head, 0);
+				if (virtio_queue__should_signal(vq))
+					ndev->vdev.ops->signal_vq(kvm, &ndev->vdev, queue->id);
+				continue;
+			}
+			memcpy(hdr_iov, iov, in * sizeof(*iov));
 			while (copied < len) {
 				size_t iovsize = min_t(size_t, len - copied, iov_size(iov, in));
 
@@ -136,7 +145,13 @@ static void *virtio_net_rx_thread(void *p)
 					break;
 				while (!virt_queue__available(vq))
 					sleep(0);
-				head = virt_queue__get_iov(vq, iov, &out, &in, kvm);
+				head = virt_queue__get_iov(vq, iov, ARRAY_SIZE(iov),
+							   &out, &in, kvm);
+				if (out || !in || !iov_size(iov, in)) {
+					virt_queue__set_used_elem_no_update(vq, head, 0,
+									    num_buffers++);
+					break;
+				}
 			}
 
 			/*
@@ -145,8 +160,15 @@ static void *virtio_net_rx_thread(void *p)
 			 * VIRTIO_NET_F_MRG_RXBUF and the field does not exist.
 			 */
 			if (has_virtio_feature(ndev, VIRTIO_NET_F_MRG_RXBUF) ||
-			    !ndev->vdev.legacy)
-				hdr->num_buffers = virtio_host_to_guest_u16(vq->endian, num_buffers);
+			    !ndev->vdev.legacy) {
+				num_buffers_wire = virtio_host_to_guest_u16(vq->endian,
+									    num_buffers);
+				memcpy_toiovecend(hdr_iov,
+						  (unsigned char *)&num_buffers_wire,
+						  offsetof(struct virtio_net_hdr_mrg_rxbuf,
+							   num_buffers),
+						  sizeof(num_buffers_wire));
+			}
 
 			virt_queue__used_idx_advance(vq, num_buffers);
 
@@ -184,7 +206,11 @@ static void *virtio_net_tx_thread(void *p)
 		mutex_unlock(&queue->lock);
 
 		while (virt_queue__available(vq)) {
-			head = virt_queue__get_iov(vq, iov, &out, &in, kvm);
+			head = virt_queue__get_iov(vq, iov, ARRAY_SIZE(iov), &out, &in, kvm);
+			if (!out) {
+				virt_queue__set_used_elem(vq, head, 0);
+				continue;
+			}
 			len = ndev->ops->tx(iov, out, ndev);
 			if (len < 0) {
 				pr_warning("%s: tx on vq %u failed (%d)\n",
@@ -220,7 +246,6 @@ static void *virtio_net_ctrl_thread(void *p)
 	struct kvm *kvm = ndev->kvm;
 	struct virtio_net_ctrl_hdr ctrl;
 	virtio_net_ctrl_ack ack;
-	size_t len;
 
 	kvm__set_thread_name("virtio-net-ctrl");
 
@@ -231,9 +256,14 @@ static void *virtio_net_ctrl_thread(void *p)
 		mutex_unlock(&queue->lock);
 
 		while (virt_queue__available(vq)) {
-			head = virt_queue__get_iov(vq, iov, &out, &in, kvm);
-			len = min(iov_size(iov, in), sizeof(ctrl));
-			memcpy_fromiovec((void *)&ctrl, iov, len);
+			head = virt_queue__get_iov(vq, iov, ARRAY_SIZE(iov), &out, &in, kvm);
+			if (!out || !in ||
+			    iov_size(iov, out) < sizeof(ctrl) ||
+			    iov_size(iov + out, in) < sizeof(ack)) {
+				virt_queue__set_used_elem(vq, head, 0);
+				continue;
+			}
+			memcpy_fromiovec((void *)&ctrl, iov, sizeof(ctrl));
 
 			switch (ctrl.class) {
 			case VIRTIO_NET_CTRL_MQ:
@@ -243,7 +273,7 @@ static void *virtio_net_ctrl_thread(void *p)
 				ack = VIRTIO_NET_ERR;
 				break;
 			}
-			memcpy_toiovec(iov + in, &ack, sizeof(ack));
+			memcpy_toiovec(iov + out, &ack, sizeof(ack));
 			virt_queue__set_used_elem(vq, head, sizeof(ack));
 		}
 
@@ -605,7 +635,8 @@ static int init_vq(struct kvm *kvm, void *dev, u32 vq)
 	net_queue->id	= vq;
 	net_queue->ndev	= ndev;
 	queue		= &net_queue->vq;
-	virtio_init_device_vq(kvm, &ndev->vdev, queue, VIRTIO_NET_QUEUE_SIZE);
+	if (!virtio_init_device_vq(kvm, &ndev->vdev, queue, VIRTIO_NET_QUEUE_SIZE))
+		return -EINVAL;
 
 	mutex_init(&net_queue->lock);
 	pthread_cond_init(&net_queue->cond, NULL);
diff --git a/virtio/pci.c b/virtio/pci.c
index 4852ce3..b450fd5 100644
--- a/virtio/pci.c
+++ b/virtio/pci.c
@@ -121,7 +121,14 @@ int virtio_pci_init_vq(struct kvm *kvm, struct virtio_device *vdev, int vq)
 		pr_err("couldn't add ioeventfd for vq %d: %d", vq, ret);
 		return ret;
 	}
-	return vdev->ops->init_vq(kvm, vpci->dev, vq);
+	ret = vdev->ops->init_vq(kvm, vpci->dev, vq);
+	if (ret) {
+		ioeventfd__del_event(virtio_pci__mmio_addr(vpci) +
+				     vpci->doorbell_offset, vq);
+		ioeventfd__del_event(virtio_pci__port_addr(vpci) +
+				     vpci->doorbell_offset, vq);
+	}
+	return ret;
 }
 
 void virtio_pci_exit_vq(struct kvm *kvm, struct virtio_device *vdev, int vq)
diff --git a/virtio/rng.c b/virtio/rng.c
index 505c4b2..c68b9cb 100644
--- a/virtio/rng.c
+++ b/virtio/rng.c
@@ -64,7 +64,7 @@ static bool virtio_rng_do_io_request(struct kvm *kvm, struct rng_dev *rdev, stru
 	ssize_t len;
 	u16 out, in, head;
 
-	head	= virt_queue__get_iov(queue, iov, &out, &in, kvm);
+	head	= virt_queue__get_iov(queue, iov, ARRAY_SIZE(iov), &out, &in, kvm);
 	len	= readv(rdev->fd, iov, in);
 	if (len < 0 && (errno == EAGAIN || errno == EINTR)) {
 		/*
@@ -110,7 +110,8 @@ static int init_vq(struct kvm *kvm, void *dev, u32 vq)
 
 	job = &rdev->jobs[vq];
 
-	virtio_init_device_vq(kvm, &rdev->vdev, queue, VIRTIO_RNG_QUEUE_SIZE);
+	if (!virtio_init_device_vq(kvm, &rdev->vdev, queue, VIRTIO_RNG_QUEUE_SIZE))
+		return -EINVAL;
 
 	*job = (struct rng_dev_job) {
 		.vq	= queue,
diff --git a/virtio/scsi.c b/virtio/scsi.c
index a842290..c5f7a7e 100644
--- a/virtio/scsi.c
+++ b/virtio/scsi.c
@@ -102,7 +102,8 @@ static int init_vq(struct kvm *kvm, void *dev, u32 vq)
 
 	queue		= &sdev->vqs[vq];
 
-	virtio_init_device_vq(kvm, &sdev->vdev, queue, VIRTIO_SCSI_QUEUE_SIZE);
+	if (!virtio_init_device_vq(kvm, &sdev->vdev, queue, VIRTIO_SCSI_QUEUE_SIZE))
+		return -EINVAL;
 
 	if (sdev->vhost_fd == 0)
 		return 0;
diff --git a/virtio/vsock.c b/virtio/vsock.c
index 7d4053a..6ccd420 100644
--- a/virtio/vsock.c
+++ b/virtio/vsock.c
@@ -77,7 +77,8 @@ static int init_vq(struct kvm *kvm, void *dev, u32 vq)
 	compat__remove_message(compat_id);
 
 	queue		= &vdev->vqs[vq];
-	virtio_init_device_vq(kvm, &vdev->vdev, queue, VIRTIO_VSOCK_QUEUE_SIZE);
+	if (!virtio_init_device_vq(kvm, &vdev->vdev, queue, VIRTIO_VSOCK_QUEUE_SIZE))
+		return -EINVAL;
 
 	if (vdev->vhost_fd == -1 || is_event_vq(vq))
 		return 0;
