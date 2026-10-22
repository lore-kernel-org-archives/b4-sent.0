From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:19 -0700
Subject: [PATCH RFC v2 47/50] samples/kvm: Implement put_pfn_range provider
 operation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-47-5dd1dc6c660a@google.com>
References: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
In-Reply-To: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
To: Alex Williamson <alex@shazbot.org>, Alexander Graf <graf@amazon.de>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Alexey Kardashevskiy <aik@amd.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Ashish Kalra <ashish.kalra@amd.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Baolu Lu <baolu.lu@linux.intel.com>, Bill Wendling <morbo@google.com>, 
 Borislav Petkov <bp@alien8.de>, Catalin Marinas <catalin.marinas@arm.com>, 
 Christian Brauner <brauner@kernel.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Connor Williamson <connordw@amazon.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, David Hildenbrand <david@kernel.org>, 
 David Rientjes <rientjes@google.com>, David Woodhouse <dwmw2@infradead.org>, 
 Erdem Aktas <erdemaktas@google.com>, Frank van der Linden <fvdl@google.com>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, Fred Griffoul <griffoul@gmail.com>, 
 Gregory Price <gourry@gourry.net>, "H. Peter Anvin" <hpa@zytor.com>, 
 Hugh Dickins <hughd@google.com>, Ingo Molnar <mingo@redhat.com>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, 
 James Houghton <jthoughton@google.com>, Jan Kara <jack@suse.cz>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Jianxiong Gao <jxgao@google.com>, 
 Joerg Roedel <joro@8bytes.org>, Joey Gouly <joey.gouly@arm.com>, 
 John Starks <John.Starks@microsoft.com>, Jonathan Corbet <corbet@lwn.net>, 
 Justin Stitt <justinstitt@google.com>, Kevin Tian <kevin.tian@intel.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Michael Roth <michael.roth@amd.com>, Mike Rapoport <rppt@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolin Chen <nicolinc@nvidia.com>, Oliver Upton <oupton@kernel.org>, 
 Paolo Bonzini <pbonzini@redhat.com>, Pratyush Yadav <pratyush@kernel.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Robin Murphy <robin.murphy@arm.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, Shuah Khan <shuah@kernel.org>, 
 Steffen Eiden <seiden@linux.ibm.com>, Steven Price <steven.price@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Tom Lendacky <thomas.lendacky@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Vishal Annapurve <vannapurve@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Will Deacon <will@kernel.org>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, x86@kernel.org, 
 Shuah Khan <skhan@linuxfoundation.org>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, llvm@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=2119;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=pi2zso59ygjDMW0jQ8vMvbcQ7Mg17Pfm1HpOzHVZMT4=;
 b=FeDMpombwEf/FE13JwARgBMWuXk+ng4trAiHCZK87Mj+RPNNvF/snx58olAl1/HscRsy0XR/d
 fXqX41lY3XdCh+hR/hmQDnI3YEr/FF1ORAq9/bz1EuVkc/iBWwk4zYH
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
 samples/kvm/mem_provider_sample.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index a43c76d2259e7..dee15179959b2 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -17,6 +17,7 @@
 #include <linux/file.h>
 #include <linux/fs.h>
 #include <linux/gfp.h>
+#include <linux/highmem.h>
 #include <linux/guest_memfd.h>
 #include <linux/io.h>
 #include <linux/miscdevice.h>
@@ -40,6 +41,21 @@ struct mps_info {
 	unsigned long *absent;		/* taken away by MPS_SET_PRESENT */
 };
 
+static void mps_gmem_put_pfn_range(void *provider, pgoff_t index,
+				   size_t nr_pages)
+{
+	struct file *resource_file = provider;
+	struct mps_info *info = resource_file->private_data;
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
 /* Byte range [offset, offset + len) of @info as page indices. */
 static int mps_range(struct mps_info *info, u64 offset, u64 len,
 		     unsigned long *start, unsigned long *end)
@@ -155,6 +171,7 @@ static const struct guest_memfd_provider_operations mps_gmem_provider_ops = {
 	.attach		= mps_gmem_attach,
 	.release	= mps_gmem_release,
 	.get_pfn	= mps_gmem_get_pfn,
+	.put_pfn_range	= mps_gmem_put_pfn_range,
 };
 
 static const struct file_operations mps_file_fops = {

-- 
2.56.0.257.gf7497c7d27-goog

