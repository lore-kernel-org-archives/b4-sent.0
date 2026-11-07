From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:28 -0800
Subject: [PATCH RFC v3 54/88] KVM: guest_memfd: Support read and write
 operations and provider callbacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-54-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=6435;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=nv52q2gMdxzmaZix0sQpW+28+lbsXbZR5Bzi3YONHfM=;
 b=0Smvv2QfB+oDOaurG+jaFJgcG514sTC0qa6lYPTm/2BeRMYZZHkGuZX+04ozUeDdZmxbk+Jkx
 XdZPc9i4rl/DCPq1rqBcrjqqS0llXraTB6nFscVMeUJKbdfNyBSK/aL
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow reading and writing to shared memory backed by guest_memfd
descriptors.

Consolidate locking, file offset bounds checking, and memory attribute
validation into a shared kvm_gmem_rw helper used by both kvm_gmem_read
and kvm_gmem_write.

To decouple low-level provider operations from userspace copy semantics
and avoid AB-BA deadlocks between mapping.invalidate_lock and
mm->mmap_lock, transfer data in chunks using a small stack bounce buffer:
- For writes, copy from userspace into the bounce buffer outside
  filemap_invalidate_lock_shared before invoking provider callbacks with
  a kernel buffer.
- For reads, invoke provider callbacks under filemap_invalidate_lock_shared
  into the bounce buffer, release the lock, and copy out to userspace.

Verify while holding the shared filemap invalidation lock that the
requested file offset range does not exceed inode size and consists
solely of shared memory.

Forward read and write calls to the provider via gmem_provider_read and
gmem_provider_write, providing placeholder stubs for the native provider
until reading and writing to native folios is implemented.

Enable FMODE_PREAD and FMODE_PWRITE on guest_memfd file descriptors so
pread64 and pwrite64 are permitted by the VFS.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/guest_memfd.h |   4 ++
 virt/kvm/guest_memfd.c      | 115 ++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 119 insertions(+)

diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index cd634576c9af8..c85594b58112a 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -113,6 +113,10 @@ struct guest_memfd_provider_operations {
 				unsigned long *pfn, size_t *nr_pages);
 	void (*put_pfn_range)(void *provider, pgoff_t index, size_t nr_pages);
 	int (*mmap)(void *provider, struct vm_area_struct *vma);
+	ssize_t (*read)(void *provider, void *buf, size_t count,
+			loff_t *ppos);
+	ssize_t (*write)(void *provider, const void *buf, size_t count,
+			 loff_t *ppos);
 	int (*check_set_attributes)(void *provider, pgoff_t index,
 				    size_t nr_pages, u64 attributes);
 };
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 61a3ff7fcd84c..385b517b49ed5 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -80,9 +80,25 @@ static struct folio *gmem_native_alloc_folio(void *provider, pgoff_t index,
 	return folio;
 }
 
+static ssize_t gmem_native_read(void *provider, void *buf, size_t count,
+				loff_t *ppos)
+{
+	/* TODO: Support reading from native provider folios. */
+	return -EINVAL;
+}
+
+static ssize_t gmem_native_write(void *provider, const void *buf,
+				 size_t count, loff_t *ppos)
+{
+	/* TODO: Support writing to native provider folios. */
+	return -EINVAL;
+}
+
 static const struct guest_memfd_provider_operations gmem_native_provider_ops = {
 	.attach = gmem_native_attach,
 	.alloc_folio = gmem_native_alloc_folio,
+	.read = gmem_native_read,
+	.write = gmem_native_write,
 };
 
 static bool gmem_provider_ops_valid(struct gmem_inode *gi,
@@ -210,6 +226,25 @@ static int gmem_provider_mmap(struct gmem_inode *gi, struct vm_area_struct *vma)
 	return 0;
 }
 
+static ssize_t gmem_provider_read(struct gmem_inode *gi, void *buf,
+				  size_t count, loff_t *ppos)
+{
+	if (gi->provider_ops && gi->provider_ops->read)
+		return gi->provider_ops->read(gi->provider, buf, count, ppos);
+
+	return -EINVAL;
+}
+
+static ssize_t gmem_provider_write(struct gmem_inode *gi,
+				   const void *buf, size_t count,
+				   loff_t *ppos)
+{
+	if (gi->provider_ops && gi->provider_ops->write)
+		return gi->provider_ops->write(gi->provider, buf, count, ppos);
+
+	return -EINVAL;
+}
+
 static int gmem_provider_check_set_attributes(struct gmem_inode *gi, pgoff_t index,
 					      size_t nr_pages, u64 attributes)
 {
@@ -1204,7 +1239,86 @@ static long kvm_gmem_ioctl(struct file *file, unsigned int ioctl,
 	}
 }
 
+static ssize_t kvm_gmem_rw(struct file *file, void __user *buf, size_t count,
+			   loff_t *ppos, bool is_write)
+{
+	struct inode *inode = file_inode(file);
+	struct gmem_inode *gi = GMEM_I(inode);
+	size_t total_done = 0;
+	loff_t isize;
+
+	if (!count)
+		return 0;
+
+	if (*ppos < 0)
+		return -EINVAL;
+
+	isize = i_size_read(inode);
+	if (*ppos >= isize)
+		return 0;
+
+	count = min_t(size_t, count, isize - *ppos);
+
+	while (count) {
+		u8 bounce[256];
+		size_t chunk = min_t(size_t, count, sizeof(bounce));
+		pgoff_t start = *ppos >> PAGE_SHIFT;
+		pgoff_t end = (*ppos + chunk - 1) >> PAGE_SHIFT;
+		pgoff_t nr_pages = end - start + 1;
+		ssize_t ret;
+
+		if (is_write) {
+			if (copy_from_user(bounce, (const char __user *)buf + total_done, chunk))
+				return total_done ?: -EFAULT;
+		}
+
+		filemap_invalidate_lock_shared(inode->i_mapping);
+
+		if (!kvm_gmem_range_has_attributes(inode, start, nr_pages, 0)) {
+			filemap_invalidate_unlock_shared(inode->i_mapping);
+			return total_done ?: -EFAULT;
+		}
+
+		if (is_write)
+			ret = gmem_provider_write(gi, bounce, chunk, ppos);
+		else
+			ret = gmem_provider_read(gi, bounce, chunk, ppos);
+
+		filemap_invalidate_unlock_shared(inode->i_mapping);
+
+		if (ret < 0)
+			return total_done ?: ret;
+
+		if (!ret)
+			break;
+
+		if (!is_write) {
+			if (copy_to_user((char __user *)buf + total_done, bounce, ret))
+				return total_done ?: -EFAULT;
+		}
+
+		total_done += ret;
+		count -= ret;
+	}
+
+	return total_done;
+}
+
+static ssize_t kvm_gmem_read(struct file *file, char __user *buf, size_t count,
+			     loff_t *ppos)
+{
+	return kvm_gmem_rw(file, buf, count, ppos, false);
+}
+
+static ssize_t kvm_gmem_write(struct file *file, const char __user *buf,
+			      size_t count, loff_t *ppos)
+{
+	return kvm_gmem_rw(file, (void __user *)buf, count, ppos, true);
+}
+
 static struct file_operations kvm_gmem_fops = {
+	.read		= kvm_gmem_read,
+	.write		= kvm_gmem_write,
 	.mmap		= kvm_gmem_mmap,
 	.open		= generic_file_open,
 	.release	= kvm_gmem_release,
@@ -1395,6 +1509,7 @@ static int __kvm_gmem_create(struct kvm *kvm, loff_t size, u64 flags, int resour
 		goto err_inode;
 	}
 
+	file->f_mode |= FMODE_PREAD | FMODE_PWRITE;
 	file->f_flags |= O_LARGEFILE;
 	file->private_data = f;
 

-- 
2.56.0.455.g6c5a503b38-goog

