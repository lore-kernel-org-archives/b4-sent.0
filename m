From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:21 -0800
Subject: [PATCH RFC v3 47/88] samples/kvm: Implement put_pfn_range provider
 operation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-47-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2017;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=EQ1vkfs4Fq6dVy8Tnqa73wtDRnEOHzF5D2kx/MOFQjw=;
 b=qfpeXyJrdfzBNnklBH6lKmbtKPRh5QoMQFABGup6qT5nifmvAegwKuVsurgtDqdWAfCwzbars
 NPUayoqo7OoB5MiAYyY6K29oiVQj15R/7ZFXTkTxKp16tREgjIDIaTq
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When guest_memfd hole punches or destroys an instance backed by a PFN
provider, it invokes .put_pfn_range to release the physical memory back
to the provider.

Implement the .put_pfn_range callback in mps_gmem_provider_ops to clear
the CMA pages across the released range via clear_highpage(). This
ensures that subsequent accesses to punched ranges observe zeroed memory,
matching POSIX fallocate hole-punching semantics and preventing stale data
from being observed when pages are reused.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/memory_provider.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
index 1db69a8f58758..0a03623492f4c 100644
--- a/samples/kvm/memory_provider.c
+++ b/samples/kvm/memory_provider.c
@@ -17,6 +17,7 @@
 #include <linux/file.h>
 #include <linux/fs.h>
 #include <linux/gfp.h>
+#include <linux/highmem.h>
 #include <linux/guest_memfd.h>
 #include <linux/miscdevice.h>
 #include <linux/mm.h>
@@ -198,6 +199,21 @@ static void mp_gmem_release(void *provider)
 	fput(resource_file);
 }
 
+static void mp_gmem_put_pfn_range(void *provider, pgoff_t index,
+				   size_t nr_pages)
+{
+	struct file *resource_file = provider;
+	struct mp_info *info = resource_file->private_data;
+	size_t i;
+
+	if (index >= info->npages)
+		return;
+
+	nr_pages = min_t(size_t, nr_pages, info->npages - index);
+	for (i = 0; i < nr_pages; i++)
+		clear_highpage(info->cma_pages + index + i);
+}
+
 static int mp_gmem_get_pfn(void *provider, pgoff_t index, unsigned long *pfn,
 			   int *max_order, u64 *pfn_attrs)
 {
@@ -226,6 +242,7 @@ static const struct guest_memfd_provider_operations mp_gmem_provider_ops = {
 	.attach		= mp_gmem_attach,
 	.release	= mp_gmem_release,
 	.get_pfn	= mp_gmem_get_pfn,
+	.put_pfn_range	= mp_gmem_put_pfn_range,
 };
 
 static const struct file_operations mp_file_fops = {

-- 
2.56.0.455.g6c5a503b38-goog

