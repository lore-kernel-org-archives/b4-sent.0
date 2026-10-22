From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:17 -0700
Subject: [PATCH RFC v2 45/50] samples/kvm: Implement attach and release
 provider ops in sample provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-45-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=1898;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=KGuPGvRWcbKGcEsNC27FbqmF987N6l1g/xr1+ZAzxc4=;
 b=Z8JHLu6Ste4p8ZrYRqK06GDhAVo48QV4XZ+VWzhKHyf7aaqsyXhbrwWLtjaRHzGTMt3dr8qvY
 4A+I9EpN32UAecHoaXDspE+Lg0dT9WcHVIl7AcXBRh4n+ovXjEly61w
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the guest_memfd provider operations in the sample memory
provider module, providing .attach and .release callbacks.

In .attach, take a reference to the provider file (get_file) to keep the
provider context alive while attached. In .release, release the file
reference via fput.

Attach the provider operations to mps_file_fops.gmem_provider_ops so that
provider file descriptors created by the sample module can be passed as
resource_fd to guest_memfd.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/mem_provider_sample.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index 397ebb3773f39..d9e57484c3933 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -17,6 +17,7 @@
 #include <linux/file.h>
 #include <linux/fs.h>
 #include <linux/gfp.h>
+#include <linux/guest_memfd.h>
 #include <linux/io.h>
 #include <linux/miscdevice.h>
 #include <linux/mm.h>
@@ -118,11 +119,30 @@ static long mps_file_ioctl(struct file *file, unsigned int cmd,
 	}
 }
 
+static void *mps_gmem_attach(struct inode *gmem_inode,
+			     struct file *resource_file)
+{
+	return get_file(resource_file);
+}
+
+static void mps_gmem_release(void *provider)
+{
+	struct file *resource_file = provider;
+
+	fput(resource_file);
+}
+
+static const struct guest_memfd_provider_operations mps_gmem_provider_ops = {
+	.attach		= mps_gmem_attach,
+	.release	= mps_gmem_release,
+};
+
 static const struct file_operations mps_file_fops = {
 	.owner		= THIS_MODULE,
 	.release	= mps_file_release,
 	.unlocked_ioctl	= mps_file_ioctl,
 	.compat_ioctl	= compat_ptr_ioctl,
+	.gmem_provider_ops = &mps_gmem_provider_ops,
 };
 
 static long mps_ctl_new_file(void __user *uarg)

-- 
2.56.0.257.gf7497c7d27-goog

