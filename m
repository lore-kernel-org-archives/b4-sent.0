From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:14 -0800
Subject: [PATCH RFC v3 40/88] KVM: guest_memfd: Add TODO for memory failure
 handling in PFN mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-40-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=995;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=RMoXxdr7unZnobL7R1i/MK8zqw1q/jitBNuF2OvUGw8=;
 b=hjk6HdU81k97DczNhIQxswAsxYsu4tIqPkDlpmZd+T6wio0f6skkcsf8gsFCP0CMvMeZH6Uiq
 yEe+MejhQ7bCc8jLcDgoJYyK2pebq3F6/hjkDqs/RM2tzA/djMSle1h
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a TODO comment noting that PFN mode does not use page-cache folios, so
->error_remove_folio() will not be called by the core memory failure
infrastructure when physical memory errors occur.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 501c3e250fc98..ffe1508985d61 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -1127,6 +1127,11 @@ static int kvm_gmem_migrate_folio(struct address_space *mapping,
 	return -EINVAL;
 }
 
+/*
+ * TODO: Support memory failure notification for PFN mode. In PFN mode, memory
+ * is not backed by page cache folios, so ->error_remove_folio() will not be
+ * invoked by the core memory failure handler.
+ */
 static int kvm_gmem_error_folio(struct address_space *mapping, struct folio *folio)
 {
 	struct inode *inode = mapping->host;

-- 
2.56.0.455.g6c5a503b38-goog

