From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:56 -0800
Subject: [PATCH RFC v3 22/88] samples/kvm: Support marking page ranges
 present or absent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-22-8484dde66a7e@google.com>
References: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
In-Reply-To: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
To: Alexey Kardashevskiy <aik@amd.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, 
 David Hildenbrand <david@kernel.org>, David Woodhouse <dwmw2@infradead.org>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, Jianxiong Gao <jxgao@google.com>, 
 John Starks <John.Starks@microsoft.com>, 
 Michael Roth <michael.roth@amd.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Vishal Annapurve <vannapurve@google.com>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=5672;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=2aAtvWaVMFLs1DyMSWgKDsrYTk08ExBkcEnGdMCup6U=;
 b=FN3YnHse9NNd00ZJ6tUEz14740WtwjgOvcKLw/xxizDGT5VgohtqpKNVY2qr8NW56Ydpsd95G
 R5y1ppau9KbCSiMoTgYL1snTpXD18XnCOj4rMX9lX962RMBGnVl6nTL
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Fred Griffoul <fgriffo@amazon.co.uk>

Support the MP_SET_PRESENT ioctl on provider files to allow userspace to
dynamically mark page-aligned ranges of a provider file as present or
absent.

Track absent pages using a zero-initialized bitmap so that the entire
physical page range starts in the present state upon creation. Serialize
bitmap updates with a per-file mutex so concurrent ioctl calls do not race
when modifying page presence state.

Co-developed-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Fred Griffoul <fgriffo@amazon.co.uk>
---
 samples/kvm/memory_provider.c | 83 ++++++++++++++++++++++++++++++++++++++++++-
 samples/kvm/memory_provider.h | 15 ++++++++
 2 files changed, 97 insertions(+), 1 deletion(-)

diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
index e89ce55a357c0..6b8364afc5ed9 100644
--- a/samples/kvm/memory_provider.c
+++ b/samples/kvm/memory_provider.c
@@ -6,18 +6,21 @@
  *
  * The control device /dev/memory_provider creates provider files.
  * Each file allocates its own contiguous memory from alloc_contig_pages().
+ * Pages can be dynamically marked present or absent.
  * See memory_provider.h.
  *
  * Confidential VMs are not supported.
  */
 
 #include <linux/anon_inodes.h>
+#include <linux/bitmap.h>
 #include <linux/file.h>
 #include <linux/fs.h>
 #include <linux/gfp.h>
 #include <linux/miscdevice.h>
 #include <linux/mm.h>
 #include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/slab.h>
 #include <linux/uaccess.h>
 
@@ -30,21 +33,88 @@ struct mp_info {
 	unsigned long base_pfn;
 	unsigned long npages;
 	struct page *cma_pages;		/* from alloc_contig_pages() */
+
+	struct mutex lock;		/* the bitmaps */
+	unsigned long *absent;		/* taken away by MP_SET_PRESENT */
 };
 
+/* Byte range [offset, offset + len) of @info as page indices. */
+static int mp_range(struct mp_info *info, u64 offset, u64 len,
+		    unsigned long *start, unsigned long *end)
+{
+	if (!len || !PAGE_ALIGNED(offset) || !PAGE_ALIGNED(len))
+		return -EINVAL;
+
+	*start = offset >> PAGE_SHIFT;
+	*end = *start + (len >> PAGE_SHIFT);
+
+	if (*end > info->npages || *end < *start)
+		return -EINVAL;
+
+	return 0;
+}
+
+static void mp_set_present(struct mp_info *info, unsigned long start,
+			   unsigned long end, bool present)
+{
+	mutex_lock(&info->lock);
+
+	if (present)
+		bitmap_clear(info->absent, start, end - start);
+	else
+		bitmap_set(info->absent, start, end - start);
+
+	mutex_unlock(&info->lock);
+}
+
 static int mp_file_release(struct inode *inode, struct file *file)
 {
 	struct mp_info *info = file->private_data;
 
 	if (info->cma_pages)
 		free_contig_range(info->base_pfn, info->npages);
+	bitmap_free(info->absent);
 	kfree(info);
 	return 0;
 }
 
+static long mp_file_set_present(struct mp_info *info, void __user *uarg)
+{
+	struct mp_set_present sp;
+	unsigned long start, end;
+	int ret;
+
+	if (copy_from_user(&sp, uarg, sizeof(sp)))
+		return -EFAULT;
+	if (sp.value > 1 || sp.pad)
+		return -EINVAL;
+
+	ret = mp_range(info, sp.offset, sp.len, &start, &end);
+	if (!ret)
+		mp_set_present(info, start, end, sp.value);
+
+	return ret;
+}
+
+static long mp_file_ioctl(struct file *file, unsigned int cmd,
+			  unsigned long arg)
+{
+	struct mp_info *info = file->private_data;
+	void __user *uarg = (void __user *)arg;
+
+	switch (cmd) {
+	case MP_SET_PRESENT:
+		return mp_file_set_present(info, uarg);
+	default:
+		return -ENOTTY;
+	}
+}
+
 static const struct file_operations mp_file_fops = {
 	.owner		= THIS_MODULE,
 	.release	= mp_file_release,
+	.unlocked_ioctl	= mp_file_ioctl,
+	.compat_ioctl	= compat_ptr_ioctl,
 };
 
 static long mp_ctl_new_file(void __user *uarg)
@@ -64,21 +134,30 @@ static long mp_ctl_new_file(void __user *uarg)
 		return -EINVAL;
 
 	npages = nf.size >> PAGE_SHIFT;
+	if (npages > KMALLOC_MAX_SIZE * BITS_PER_BYTE)
+		return -EINVAL;
 
 	info = kzalloc_obj(*info);
 	if (!info)
 		return -ENOMEM;
 
+	info->absent = bitmap_zalloc(npages, GFP_KERNEL);
+	if (!info->absent) {
+		ret = -ENOMEM;
+		goto err_free_info;
+	}
+
 	pages = alloc_contig_pages(npages, GFP_KERNEL | __GFP_ZERO,
 				   numa_node_id(), NULL);
 	if (!pages) {
 		ret = -ENOMEM;
-		goto err_free_info;
+		goto err_free_absent;
 	}
 
 	info->cma_pages = pages;
 	info->base_pfn = page_to_pfn(pages);
 	info->npages = npages;
+	mutex_init(&info->lock);
 
 	fd = get_unused_fd_flags(O_CLOEXEC);
 	if (fd < 0) {
@@ -99,6 +178,8 @@ static long mp_ctl_new_file(void __user *uarg)
 
 err_free_pages:
 	free_contig_range(page_to_pfn(pages), npages);
+err_free_absent:
+	bitmap_free(info->absent);
 err_free_info:
 	kfree(info);
 	return ret;
diff --git a/samples/kvm/memory_provider.h b/samples/kvm/memory_provider.h
index 0bd9e250aeaf5..de07ffa482283 100644
--- a/samples/kvm/memory_provider.h
+++ b/samples/kvm/memory_provider.h
@@ -27,4 +27,19 @@ struct mp_new_file {
 #define MP_NEW_FILE \
 	_IOW(MP_IOCTL_BASE, 5, struct mp_new_file)
 
+/*
+ * ioctl on a provider fd: SET_PRESENT on [@offset, @offset + @len).
+ * @value is the present value (1 = present, 0 = absent), and @offset
+ * and @len are a byte range within the file, page aligned.
+ */
+struct mp_set_present {
+	__u32 value;
+	__u32 pad;
+	__u64 offset;	/* bytes into the file, page aligned */
+	__u64 len;	/* bytes, page aligned */
+};
+
+#define MP_SET_PRESENT \
+	_IOW(MP_IOCTL_BASE, 12, struct mp_set_present)
+
 #endif /* _SAMPLES_KVM_MEMORY_PROVIDER_H */

-- 
2.56.0.455.g6c5a503b38-goog

