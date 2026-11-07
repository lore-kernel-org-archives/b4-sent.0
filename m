From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:20 -0800
Subject: [PATCH RFC v3 46/88] samples/kvm: Implement get_pfn provider
 operation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-46-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2542;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=tCKXiyHtpuefvmYVDpsKn5DHw0pcR3E0UpVIb8EHbec=;
 b=XcS77Ehs2dDxmkzR+K+/PQQXHnS5i/ylsKXkNTcKFJYWNqfe/67XQ4asLhBTtPVhKbokfrsMk
 9fTuOHWRmeiB9cV4r08Y2XGxaZrDeKXDmooUisiB2STC9cUFglVZQI2
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the .get_pfn callback in mp_gmem_provider_ops to operate as a
direct PFN provider for guest_memfd.

Implementing .get_pfn satisfies guest_memfd's provider operations
requirement, enabling memory_provider files to be attached as
resource_fd memory providers for guest_memfd.

In mp_gmem_get_pfn(), return the physical frame number corresponding to
the requested index from the CMA reservation, returning -EFAULT if the
page was marked absent via MP_SET_PRESENT. Also report
GUEST_MEMFD_PFN_ATTRS_READONLY in pfn_attrs if the page was marked
read-only via MP_SET_READONLY.

Checking test_bit(index, info->absent) and info->read_only is done
locklessly without holding info->lock:
- test_bit() is an atomic memory read.
- Locklessness prevents lock inversion and deadlocks. In guest_memfd,
  the guest page fault path (kvm_gmem_get_pfn()) holds
  filemap_invalidate_lock_shared while calling .get_pfn(). Avoiding
  info->lock in .get_pfn() ensures no lock inversions exist between
  filemap_invalidate_lock and info->lock.
- Similarly, while kvm_gmem_revoke() now takes an explicit pfn and avoids
  calling back into .get_pfn(), avoiding info->lock in .get_pfn() keeps
  the lookup path completely lock-free and robust.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/memory_provider.c | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
index 168c1d90edacd..1db69a8f58758 100644
--- a/samples/kvm/memory_provider.c
+++ b/samples/kvm/memory_provider.c
@@ -198,9 +198,34 @@ static void mp_gmem_release(void *provider)
 	fput(resource_file);
 }
 
+static int mp_gmem_get_pfn(void *provider, pgoff_t index, unsigned long *pfn,
+			   int *max_order, u64 *pfn_attrs)
+{
+	struct file *resource_file = provider;
+	struct mp_info *info = resource_file->private_data;
+
+	if (index >= info->npages)
+		return -EINVAL;
+
+	if (test_bit(index, info->absent))
+		return -EFAULT;
+
+	*pfn = info->base_pfn + index;
+	if (max_order)
+		*max_order = 0;
+	if (pfn_attrs) {
+		*pfn_attrs = 0;
+		if (test_bit(index, info->readonly))
+			*pfn_attrs |= GUEST_MEMFD_PFN_ATTRS_READONLY;
+	}
+
+	return 0;
+}
+
 static const struct guest_memfd_provider_operations mp_gmem_provider_ops = {
 	.attach		= mp_gmem_attach,
 	.release	= mp_gmem_release,
+	.get_pfn	= mp_gmem_get_pfn,
 };
 
 static const struct file_operations mp_file_fops = {

-- 
2.56.0.455.g6c5a503b38-goog

