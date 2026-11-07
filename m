From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:55 -0800
Subject: [PATCH RFC v3 21/88] samples/kvm: Support creating memory provider
 files
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-21-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=4749;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=XXTp8SdWg70OOlSfykbRC6MejUHDWKPgp0+KOuBNidk=;
 b=5RFhXgQAErb6ooWSjO2h2LLuBNBG+M12psdrf0zRpmzprvoxOn5g77SsRgDZdK81NEofXQKVd
 ZjHGZkeX1tqBraGtNTCPyfLjAP17YEJOBXzIpgHtEfmSANNbl79366s
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Fred Griffoul <fgriffo@amazon.co.uk>

Support creating memory provider files via the MP_NEW_FILE ioctl on the
control device.

Allocating contiguous physical memory at file creation time ensures that
every provider file descriptor exists in a fully initialized state with a
fixed physical page range throughout its lifetime. When the provider file
is closed, free the contiguous memory range and release the associated
tracking metadata.

Co-developed-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Fred Griffoul <fgriffo@amazon.co.uk>
---
 samples/kvm/memory_provider.c | 110 ++++++++++++++++++++++++++++++++++++++++++
 samples/kvm/memory_provider.h |  30 ++++++++++++
 2 files changed, 140 insertions(+)

diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
index d5272cb88b758..e89ce55a357c0 100644
--- a/samples/kvm/memory_provider.c
+++ b/samples/kvm/memory_provider.c
@@ -2,15 +2,125 @@
 /*
  * memory_provider - a sample memory provider.
  *
+ * The module provides physical memory through provider files.
+ *
+ * The control device /dev/memory_provider creates provider files.
+ * Each file allocates its own contiguous memory from alloc_contig_pages().
+ * See memory_provider.h.
+ *
  * Confidential VMs are not supported.
  */
 
+#include <linux/anon_inodes.h>
+#include <linux/file.h>
 #include <linux/fs.h>
+#include <linux/gfp.h>
 #include <linux/miscdevice.h>
+#include <linux/mm.h>
 #include <linux/module.h>
+#include <linux/slab.h>
+#include <linux/uaccess.h>
+
+#include "memory_provider.h"
+
+/*
+ * One provider file.
+ */
+struct mp_info {
+	unsigned long base_pfn;
+	unsigned long npages;
+	struct page *cma_pages;		/* from alloc_contig_pages() */
+};
+
+static int mp_file_release(struct inode *inode, struct file *file)
+{
+	struct mp_info *info = file->private_data;
+
+	if (info->cma_pages)
+		free_contig_range(info->base_pfn, info->npages);
+	kfree(info);
+	return 0;
+}
+
+static const struct file_operations mp_file_fops = {
+	.owner		= THIS_MODULE,
+	.release	= mp_file_release,
+};
+
+static long mp_ctl_new_file(void __user *uarg)
+{
+	struct mp_new_file nf;
+	struct mp_info *info;
+	struct page *pages;
+	struct file *file;
+	unsigned long npages;
+	int fd, ret;
+
+	if (copy_from_user(&nf, uarg, sizeof(nf)))
+		return -EFAULT;
+	if (nf.flags || nf.pad)
+		return -EINVAL;
+	if (!nf.size || !PAGE_ALIGNED(nf.size))
+		return -EINVAL;
+
+	npages = nf.size >> PAGE_SHIFT;
+
+	info = kzalloc_obj(*info);
+	if (!info)
+		return -ENOMEM;
+
+	pages = alloc_contig_pages(npages, GFP_KERNEL | __GFP_ZERO,
+				   numa_node_id(), NULL);
+	if (!pages) {
+		ret = -ENOMEM;
+		goto err_free_info;
+	}
+
+	info->cma_pages = pages;
+	info->base_pfn = page_to_pfn(pages);
+	info->npages = npages;
+
+	fd = get_unused_fd_flags(O_CLOEXEC);
+	if (fd < 0) {
+		ret = fd;
+		goto err_free_pages;
+	}
+
+	file = anon_inode_getfile("[memory-provider]", &mp_file_fops,
+				  info, O_RDWR);
+	if (IS_ERR(file)) {
+		put_unused_fd(fd);
+		ret = PTR_ERR(file);
+		goto err_free_pages;
+	}
+
+	fd_install(fd, file);
+	return fd;
+
+err_free_pages:
+	free_contig_range(page_to_pfn(pages), npages);
+err_free_info:
+	kfree(info);
+	return ret;
+}
+
+static long mp_ctl_ioctl(struct file *file, unsigned int cmd,
+			 unsigned long arg)
+{
+	void __user *uarg = (void __user *)arg;
+
+	switch (cmd) {
+	case MP_NEW_FILE:
+		return mp_ctl_new_file(uarg);
+	default:
+		return -ENOTTY;
+	}
+}
 
 static const struct file_operations mp_ctl_fops = {
 	.owner		= THIS_MODULE,
+	.unlocked_ioctl	= mp_ctl_ioctl,
+	.compat_ioctl	= compat_ptr_ioctl,
 };
 
 static struct miscdevice mp_dev = {
diff --git a/samples/kvm/memory_provider.h b/samples/kvm/memory_provider.h
new file mode 100644
index 0000000000000..0bd9e250aeaf5
--- /dev/null
+++ b/samples/kvm/memory_provider.h
@@ -0,0 +1,30 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef _SAMPLES_KVM_MEMORY_PROVIDER_H
+#define _SAMPLES_KVM_MEMORY_PROVIDER_H
+
+#include <linux/ioctl.h>
+#include <linux/types.h>
+
+/*
+ * A sample memory provider.
+ *
+ * Every fd that this module returns is a provider file. Pass it to
+ * KVM_CREATE_GUEST_MEMFD.
+ */
+
+#define MP_IOCTL_BASE		'P'
+
+/*
+ * ioctl on /dev/memory_provider: create a new provider fd of @size.
+ * Returns the provider fd.
+ */
+struct mp_new_file {
+	__u32 flags;	/* Reserved, must be 0 */
+	__u32 pad;
+	__u64 size;	/* bytes, page aligned */
+};
+
+#define MP_NEW_FILE \
+	_IOW(MP_IOCTL_BASE, 5, struct mp_new_file)
+
+#endif /* _SAMPLES_KVM_MEMORY_PROVIDER_H */

-- 
2.56.0.455.g6c5a503b38-goog

