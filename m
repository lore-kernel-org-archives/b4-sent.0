From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:18 -0800
Subject: [PATCH RFC v3 44/88] samples/kvm: Implement attach and release
 provider ops in sample provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-44-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2754;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=wGkwYGWhWpUEbPcNoli9OVifhRpY95s9sJaKeYRfDoU=;
 b=2zBY4/UyvI/wD4fxk5n+1zA8wC8jypJ2hvfyGQousryL2X4dafvdKSl/QarQac9uuatqZ3yC7
 cRyw4A4lugaDN4Zps6HLSpdgi7cq6SIJHYldFyY/s718nvWW4wv8kWz
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
 samples/kvm/memory_provider.c | 39 ++++++++++++++++++++++++++++++++++++++-
 1 file changed, 38 insertions(+), 1 deletion(-)

diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
index 81ac94ae1a4e9..6f86e3e3262e3 100644
--- a/samples/kvm/memory_provider.c
+++ b/samples/kvm/memory_provider.c
@@ -17,6 +17,7 @@
 #include <linux/file.h>
 #include <linux/fs.h>
 #include <linux/gfp.h>
+#include <linux/guest_memfd.h>
 #include <linux/miscdevice.h>
 #include <linux/mm.h>
 #include <linux/module.h>
@@ -34,9 +35,11 @@ struct mp_info {
 	unsigned long npages;
 	struct page *cma_pages;		/* from alloc_contig_pages() */
 
-	struct mutex lock;		/* the bitmaps */
+	struct mutex lock;		/* the bitmaps and gmem_inode */
 	unsigned long *absent;		/* taken away by MP_SET_PRESENT */
 	unsigned long *readonly;	/* marked read-only by MP_SET_READONLY */
+
+	struct inode *gmem_inode;
 };
 
 /* Byte range [offset, offset + len) of @info as page indices. */
@@ -161,11 +164,45 @@ static long mp_file_ioctl(struct file *file, unsigned int cmd,
 	}
 }
 
+static void *mp_gmem_attach(struct inode *gmem_inode,
+			    struct file *resource_file)
+{
+	struct mp_info *info = resource_file->private_data;
+
+	mutex_lock(&info->lock);
+	if (info->gmem_inode) {
+		mutex_unlock(&info->lock);
+		return ERR_PTR(-EBUSY);
+	}
+	info->gmem_inode = gmem_inode;
+	mutex_unlock(&info->lock);
+
+	return get_file(resource_file);
+}
+
+static void mp_gmem_release(void *provider)
+{
+	struct file *resource_file = provider;
+	struct mp_info *info = resource_file->private_data;
+
+	mutex_lock(&info->lock);
+	info->gmem_inode = NULL;
+	mutex_unlock(&info->lock);
+
+	fput(resource_file);
+}
+
+static const struct guest_memfd_provider_operations mp_gmem_provider_ops = {
+	.attach		= mp_gmem_attach,
+	.release	= mp_gmem_release,
+};
+
 static const struct file_operations mp_file_fops = {
 	.owner		= THIS_MODULE,
 	.release	= mp_file_release,
 	.unlocked_ioctl	= mp_file_ioctl,
 	.compat_ioctl	= compat_ptr_ioctl,
+	.gmem_provider_ops = &mp_gmem_provider_ops,
 };
 
 static long mp_ctl_new_file(void __user *uarg)

-- 
2.56.0.455.g6c5a503b38-goog

