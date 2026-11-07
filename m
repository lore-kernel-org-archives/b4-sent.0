From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:35 -0800
Subject: [PATCH RFC v3 01/88] KVM: guest_memfd: Split folio allocation and
 insertion in kvm_gmem_get_folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-1-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=2189;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=o3ab3dp1L8d6gPAYkDQmoexjLd9lqXL7N+1eNWmNlKs=;
 b=XgrUtCJ/aWRVJB5VTE6gkAa9uuRn419O1xaO9zrTU5VolBTKlyZwWbNUC8vSaC1I22UUI+y/I
 lnN+VrNouelC2/BHQOpFwyUaGjqOIQU9E0vaik0bSRmm2KnM3CY6qQj
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Separate __filemap_get_folio_mpol() call in kvm_gmem_get_folio() into two
distinct steps:

1. Allocating a folio via filemap_alloc_folio() with the NUMA policy.
2. Inserting the allocated folio into the inode filemap.

Handle -EEXIST from filemap_add_folio() by retrying filemap_lock_folio()
safely to manage concurrent insertions.

Decouple folio allocation from filemap insertion to prepare for supporting
other memory providers.

No functional change intended.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 19 +++++++++++++++----
 1 file changed, 15 insertions(+), 4 deletions(-)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 93f3d29d5751a..f865fa0e46840 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -131,7 +131,9 @@ static struct folio *kvm_gmem_get_folio(struct inode *inode, pgoff_t index)
 	/* TODO: Support huge pages. */
 	struct mempolicy *policy;
 	struct folio *folio;
+	int r;
 
+retry:
 	/*
 	 * Fast-path: See if folio is already present in mapping to avoid
 	 * policy_lookup.
@@ -141,10 +143,19 @@ static struct folio *kvm_gmem_get_folio(struct inode *inode, pgoff_t index)
 		return folio;
 
 	policy = mpol_shared_policy_lookup(&GMEM_I(inode)->policy, index);
-	folio = __filemap_get_folio_mpol(inode->i_mapping, index,
-					 FGP_LOCK | FGP_CREAT,
-					 mapping_gfp_mask(inode->i_mapping), policy);
+	folio = filemap_alloc_folio(mapping_gfp_mask(inode->i_mapping), 0,
+				    policy);
 	mpol_cond_put(policy);
+	if (!folio)
+		return ERR_PTR(-ENOMEM);
+
+	r = filemap_add_folio(inode->i_mapping, folio, index, GFP_KERNEL);
+	if (r) {
+		folio_put(folio);
+		if (r == -EEXIST)
+			goto retry;
+		return ERR_PTR(r);
+	}
 
 	/*
 	 * External interfaces like kvm_gmem_get_pfn() support dealing
@@ -153,7 +164,7 @@ static struct folio *kvm_gmem_get_folio(struct inode *inode, pgoff_t index)
 	 * to be updated for anything otherwise (e.g. page-clearing
 	 * operations).
 	 */
-	WARN_ON_ONCE(!IS_ERR(folio) && folio_order(folio));
+	WARN_ON_ONCE(folio_order(folio));
 
 	return folio;
 }

-- 
2.56.0.455.g6c5a503b38-goog

