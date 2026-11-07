From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:54 -0800
Subject: [PATCH RFC v3 20/88] samples/kvm: Introduce memory provider module
 skeleton
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-20-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=3200;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=nt2cs3RpI5IUFgJs4dsgiWZl0HfyGKiOhLkBsycGpfo=;
 b=4cdyeAJ7HccYK8NGv9Q29bFTAR/IcMhIOFe8+7RU78D738bkU/WshB9UbwT/KAILWqam4ykOd
 CO6Tw3GiatGC9mriP8x0CMuJxG1AZn5inkS4uDdxzwnFtZL/sbetXox
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Fred Griffoul <fgriffo@amazon.co.uk>

Introduce the memory provider sample module skeleton under samples/kvm/.

The memory provider module will serve as a sample in-tree memory provider
for guest_memfd and iommufd. Register a miscdevice at /dev/memory_provider
upon module initialization and deregister it upon module exit.

Co-developed-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Fred Griffoul <fgriffo@amazon.co.uk>
---
 samples/Kconfig               | 11 +++++++++++
 samples/Makefile              |  1 +
 samples/kvm/Makefile          |  2 ++
 samples/kvm/memory_provider.c | 35 +++++++++++++++++++++++++++++++++++
 4 files changed, 49 insertions(+)

diff --git a/samples/Kconfig b/samples/Kconfig
index a75e8e78330da..d4e79e1a9286b 100644
--- a/samples/Kconfig
+++ b/samples/Kconfig
@@ -326,6 +326,17 @@ source "samples/rust/Kconfig"
 
 source "samples/damon/Kconfig"
 
+config SAMPLE_KVM_MEMORY_PROVIDER
+	tristate "Build sample memory provider -- loadable module only"
+	depends on CONTIG_ALLOC && X86_64 && m
+	help
+	  This builds a sample memory provider.
+	  Its files can back a guest_memfd and be mapped by iommufd.
+	  It allocates a contiguous region with alloc_contig_pages()
+	  and carves out child provider files on the fly.
+
+	  If unsure, say N.
+
 endif # SAMPLES
 
 config HAVE_SAMPLE_FTRACE_DIRECT
diff --git a/samples/Makefile b/samples/Makefile
index 07641e177bd8b..3933ef6a323ed 100644
--- a/samples/Makefile
+++ b/samples/Makefile
@@ -37,6 +37,7 @@ obj-$(CONFIG_SAMPLE_TPS6594_PFSM)	+= pfsm/
 subdir-$(CONFIG_SAMPLE_WATCHDOG)	+= watchdog
 subdir-$(CONFIG_SAMPLE_WATCH_QUEUE)	+= watch_queue
 obj-$(CONFIG_SAMPLE_KMEMLEAK)		+= kmemleak/
+obj-$(CONFIG_SAMPLE_KVM_MEMORY_PROVIDER)	+= kvm/
 obj-$(CONFIG_SAMPLE_CORESIGHT_SYSCFG)	+= coresight/
 obj-$(CONFIG_SAMPLE_FPROBE)		+= fprobe/
 obj-$(CONFIG_SAMPLES_RUST)		+= rust/
diff --git a/samples/kvm/Makefile b/samples/kvm/Makefile
new file mode 100644
index 0000000000000..9668dc57aa458
--- /dev/null
+++ b/samples/kvm/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0
+obj-$(CONFIG_SAMPLE_KVM_MEMORY_PROVIDER) += memory_provider.o
diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
new file mode 100644
index 0000000000000..d5272cb88b758
--- /dev/null
+++ b/samples/kvm/memory_provider.c
@@ -0,0 +1,35 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * memory_provider - a sample memory provider.
+ *
+ * Confidential VMs are not supported.
+ */
+
+#include <linux/fs.h>
+#include <linux/miscdevice.h>
+#include <linux/module.h>
+
+static const struct file_operations mp_ctl_fops = {
+	.owner		= THIS_MODULE,
+};
+
+static struct miscdevice mp_dev = {
+	.minor	= MISC_DYNAMIC_MINOR,
+	.name	= "memory_provider",
+	.fops	= &mp_ctl_fops,
+};
+
+static int __init mp_init(void)
+{
+	return misc_register(&mp_dev);
+}
+module_init(mp_init);
+
+static void __exit mp_exit(void)
+{
+	misc_deregister(&mp_dev);
+}
+module_exit(mp_exit);
+
+MODULE_LICENSE("GPL");
+MODULE_DESCRIPTION("Sample memory provider for guest_memfd and iommufd");

-- 
2.56.0.455.g6c5a503b38-goog

