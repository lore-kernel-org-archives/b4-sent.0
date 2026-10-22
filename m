From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:18 -0700
Subject: [PATCH RFC v2 46/50] samples/kvm: Implement get_pfn provider
 operation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-46-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=2288;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=bXiMo/29sunbuD+D3YtdW/0ZD1dlMXBq3S4o9V1nmWA=;
 b=LubVvmekbGEL4qJWwfPec8oSMZvh3Y2RjF8dyEzW5bd0aBY8/BgAlTFxHuNlSCp1RS5cnvglh
 ae7FJdAKp5oA3R/ugOUNqkjkZb/wJiuqKvcMsFXTMemQ+V6m+xh7YEl
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the .get_pfn callback in mps_gmem_provider_ops to operate as a
direct PFN provider for guest_memfd.

Implementing .get_pfn satisfies guest_memfd's provider operations
requirement, enabling mem_provider_sample files to be attached as
resource_fd memory providers for guest_memfd.

In mps_gmem_get_pfn(), return the physical frame number corresponding to
the requested index from the CMA reservation, returning -EFAULT if the
page was marked absent via MPS_SET_PRESENT.

Checking test_bit(index, info->absent) is done locklessly without
holding info->lock:
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
 samples/kvm/mem_provider_sample.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index d9e57484c3933..a43c76d2259e7 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -132,9 +132,29 @@ static void mps_gmem_release(void *provider)
 	fput(resource_file);
 }
 
+static int mps_gmem_get_pfn(void *provider, pgoff_t index, unsigned long *pfn,
+			    int *max_order)
+{
+	struct file *resource_file = provider;
+	struct mps_info *info = resource_file->private_data;
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
+
+	return 0;
+}
+
 static const struct guest_memfd_provider_operations mps_gmem_provider_ops = {
 	.attach		= mps_gmem_attach,
 	.release	= mps_gmem_release,
+	.get_pfn	= mps_gmem_get_pfn,
 };
 
 static const struct file_operations mps_file_fops = {

-- 
2.56.0.257.gf7497c7d27-goog

