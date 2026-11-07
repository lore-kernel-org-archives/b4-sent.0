From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:23 -0800
Subject: [PATCH RFC v3 49/88] samples/kvm: Implement lookup_pfn_range
 provider operation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-49-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=1753;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=zF6/NHZXYKv9L/HYCXHQCrJDAKRuC7sUwZ4mNyf3Ilw=;
 b=ahCkSRHzo9omVJZMhhE6rfmRR1w5YCbKaLV2veN+koHtwyTZEPMuUJDWA4vp4xnnxkooZ1qco
 erjm1pX+7bACC1WV18Q1Je2NRoYM1uyGK8yLYYA8TUwGIp3C8gOY06l
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement .lookup_pfn_range to allow looking up index -> pfn mappings to
satisfy guest_memfd requirements and make this sample memory provider a
valid PFN mode provider.

This sample memory provider performs allocations upfront, so
.lookup_pfn_range doesn't do any allocations anyway and is only slightly
different from .get_pfn.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/memory_provider.c | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
index 926f3cf68ed49..7fb7365b65940 100644
--- a/samples/kvm/memory_provider.c
+++ b/samples/kvm/memory_provider.c
@@ -249,10 +249,34 @@ static int mp_gmem_get_pfn(void *provider, pgoff_t index, unsigned long *pfn,
 	return 0;
 }
 
+static int mp_gmem_lookup_pfn_range(void *provider, pgoff_t index,
+				     unsigned long *pfn, size_t *nr_pages)
+{
+	struct file *resource_file = provider;
+	struct mp_info *info = resource_file->private_data;
+
+	if (index >= info->npages)
+		return -EINVAL;
+
+	if (test_bit(index, info->absent)) {
+		unsigned long next_present;
+
+		next_present = find_next_zero_bit(info->absent, info->npages,
+						  index + 1);
+		*nr_pages = next_present - index;
+		return -ENOENT;
+	}
+
+	*pfn = info->base_pfn + index;
+	*nr_pages = find_next_bit(info->absent, info->npages, index + 1) - index;
+	return 0;
+}
+
 static const struct guest_memfd_provider_operations mp_gmem_provider_ops = {
 	.attach		= mp_gmem_attach,
 	.release	= mp_gmem_release,
 	.get_pfn	= mp_gmem_get_pfn,
+	.lookup_pfn_range = mp_gmem_lookup_pfn_range,
 	.put_pfn_range	= mp_gmem_put_pfn_range,
 };
 

-- 
2.56.0.455.g6c5a503b38-goog

