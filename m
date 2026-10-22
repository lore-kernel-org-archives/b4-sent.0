From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:27:54 -0700
Subject: [PATCH RFC v2 22/50] samples/kvm: Remove readonly support from
 sample provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-22-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=7719;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=KmuNfE164jdZmg6x8NSbkgPNCkgJMfiXBEIOVKni6Sw=;
 b=NL8RHxzlaCihqsS2rYaBHXsTcQILZKtBgbc3euu5fec8+gL9zqbjfaRemzqOwNdyAhjq8IGUg
 6gC107g7fskDQKFCsZTkog+JKUugHvc0npKmSYNKVZ/XAJMRqHoC1fo
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the MPS_CTL_SET_READONLY ioctl, MEM_PROVIDER_ATTR_READONLY
attribute, and readonly tracking bitmap from the sample memory provider.

Keeping only the present versus absent control interface focuses
attention on the essential interface design for page backing and
revocation.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/mem_provider_sample.c | 52 ++++++++-------------------------------
 samples/kvm/mem_provider_sample.h | 13 ++++------
 2 files changed, 15 insertions(+), 50 deletions(-)

diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index 5afc433dce6e8..37538dce40cf8 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -66,7 +66,6 @@ struct mps_info {
 	bool fixed_wb;			/* holds a ref on the fixed-region WB alias */
 
 	unsigned long *absent;		/* taken away by CTL_SET_PRESENT */
-	unsigned long *readonly;
 
 	/*
 	 * A child of the root: its first page in the root, and the pages it
@@ -146,7 +145,7 @@ static bool mps_page_present(struct mps_info *info, unsigned long index)
 
 /*
  * The length of the run from @index of pages with the same state as @index:
- * present, and the same read-only bit.
+ * present.
  */
 static unsigned long mps_run(struct mps_info *info, unsigned long index)
 {
@@ -156,12 +155,6 @@ static unsigned long mps_run(struct mps_info *info, unsigned long index)
 	if (info->owned)
 		end = min(end, find_next_zero_bit(info->owned, info->npages,
 						  index + 1));
-	if (test_bit(index, info->readonly))
-		end = min(end, find_next_zero_bit(info->readonly, info->npages,
-						  index + 1));
-	else
-		end = min(end, find_next_bit(info->readonly, info->npages,
-					     index + 1));
 	return end - index;
 }
 
@@ -211,8 +204,6 @@ static int mps_mp_get_page(struct mem_provider_file *mpf, pgoff_t index,
 	}
 
 	*pfn = info->base_pfn + index;
-	if (test_bit(index, info->readonly))
-		*attrs |= MEM_PROVIDER_ATTR_READONLY;
 	/* The creator of the file decides whether the host may map it. */
 	if (!info->mmap_capable)
 		*attrs |= MEM_PROVIDER_ATTR_NO_USER_MAP;
@@ -249,18 +240,6 @@ static int mps_range(struct mps_info *info, u64 offset, u64 len,
 	return 0;
 }
 
-static void mps_set_readonly(struct mps_info *info, unsigned long start,
-			     unsigned long end, bool readonly)
-{
-	mutex_lock(&info->lock);
-	if (readonly)
-		bitmap_set(info->readonly, start, end - start);
-	else
-		bitmap_clear(info->readonly, start, end - start);
-	mps_revoke(info, start, end);
-	mutex_unlock(&info->lock);
-}
-
 static void mps_set_present(struct mps_info *info, unsigned long start,
 			    unsigned long end, bool present)
 {
@@ -283,7 +262,6 @@ static long mps_get_stats(struct mps_info *info, void __user *uarg)
 	st.owned_pages = info->owned ?
 		bitmap_weight(info->owned, info->npages) : info->npages;
 	st.absent_pages = bitmap_weight(info->absent, info->npages);
-	st.readonly_pages = bitmap_weight(info->readonly, info->npages);
 	mutex_unlock(&info->lock);
 
 	return copy_to_user(uarg, &st, sizeof(st)) ? -EFAULT : 0;
@@ -291,8 +269,8 @@ static long mps_get_stats(struct mps_info *info, void __user *uarg)
 
 /*
  * A child fd is read-only to its holder: only GET_STATS.  The owner changes a
- * child's pages through the control device (MPS_CTL_SET_PRESENT and
- * MPS_CTL_SET_READONLY), so a VMM that holds a child cannot.
+ * child's pages through the control device (MPS_CTL_SET_PRESENT), so a VMM
+ * that holds a child cannot.
  */
 static long mps_file_ioctl(struct file *file, unsigned int cmd,
 			   unsigned long arg)
@@ -335,7 +313,6 @@ static int mps_file_release(struct inode *inode, struct file *file)
 	if (info->cma_pages)
 		free_contig_range(info->base_pfn, info->npages);
 	bitmap_free(info->absent);
-	bitmap_free(info->readonly);
 	kfree(info);
 	return 0;
 }
@@ -372,8 +349,7 @@ static int mps_new_file(unsigned long base_pfn, unsigned long npages,
 	info->npages = npages;
 	info->mmap_capable = flags & MPS_FLAG_MMAP_CAPABLE;
 	info->absent = bitmap_zalloc(npages, GFP_KERNEL);
-	info->readonly = bitmap_zalloc(npages, GFP_KERNEL);
-	if (!info->absent || !info->readonly) {
+	if (!info->absent) {
 		ret = -ENOMEM;
 		goto err_free;
 	}
@@ -398,7 +374,6 @@ static int mps_new_file(unsigned long base_pfn, unsigned long npages,
 
 err_free:
 	bitmap_free(info->absent);
-	bitmap_free(info->readonly);
 	kfree(info);
 	return ret;
 }
@@ -675,11 +650,10 @@ static bool mps_child_owns(struct mps_info *info, unsigned long first,
 }
 
 /*
- * CTL_SET_READONLY and CTL_SET_PRESENT change a child's pages, by the owner on
- * the control device.  A VMM that holds the child fd cannot, so it cannot undo
- * them.
+ * CTL_SET_PRESENT changes a child's pages, by the owner on the control device.
+ * A VMM that holds the child fd cannot, so it cannot undo them.
  */
-static long mps_ctl_set_range(void __user *uarg, bool readonly)
+static long mps_ctl_set_present(void __user *uarg)
 {
 	struct mps_ctl_range cr;
 	unsigned long start, end;
@@ -695,12 +669,8 @@ static long mps_ctl_set_range(void __user *uarg, bool readonly)
 	if (IS_ERR(file))
 		return PTR_ERR(file);
 	ret = mps_range(info, cr.offset, cr.len, &start, &end);
-	if (!ret) {
-		if (readonly)
-			mps_set_readonly(info, start, end, cr.value);
-		else
-			mps_set_present(info, start, end, cr.value);
-	}
+	if (!ret)
+		mps_set_present(info, start, end, cr.value);
 	fput(file);
 	return ret;
 }
@@ -715,10 +685,8 @@ static long mps_ctl_ioctl(struct file *file, unsigned int cmd,
 		return mps_ctl_setup(uarg);
 	case MPS_NEW_CHILD:
 		return mps_ctl_new_child(uarg);
-	case MPS_CTL_SET_READONLY:
-		return mps_ctl_set_range(uarg, true);
 	case MPS_CTL_SET_PRESENT:
-		return mps_ctl_set_range(uarg, false);
+		return mps_ctl_set_present(uarg);
 	default:
 		return -ENOTTY;
 	}
diff --git a/samples/kvm/mem_provider_sample.h b/samples/kvm/mem_provider_sample.h
index acff5785099b5..5955c1c0fbf80 100644
--- a/samples/kvm/mem_provider_sample.h
+++ b/samples/kvm/mem_provider_sample.h
@@ -48,8 +48,8 @@ struct mps_setup {
  * RECLAIM them.  Each change revokes the range, so KVM and iommufd follow.
  *
  * The owner changes a child's pages through the control device
- * (CTL_SET_READONLY, CTL_SET_PRESENT).  A child fd is read-only to its
- * holder: a VMM can only GET_STATS, never change the memory.
+ * (CTL_SET_PRESENT).  A child fd is read-only to its holder: a VMM can
+ * only GET_STATS, never change the memory.
  */
 
 /*
@@ -74,16 +74,15 @@ struct mps_stats {
 	__u64 region_len;
 	__u64 owned_pages;	/* pages the child has */
 	__u64 absent_pages;	/* pages taken away by CTL_SET_PRESENT */
-	__u64 readonly_pages;
 };
 
 #define MPS_GET_STATS \
 	_IOR(MPS_IOCTL_BASE, 10, struct mps_stats)
 
 /*
- * ioctls on /dev/mem_provider_sample: CTL_SET_READONLY or CTL_SET_PRESENT on
- * child @fd, by the owner.  @value is the readonly or present value, and
- * @offset and @len are a byte range within the child, page aligned.
+ * ioctl on /dev/mem_provider_sample: CTL_SET_PRESENT on child @fd, by the
+ * owner. @value is the present value (1 = present, 0 = absent), and @offset
+ * and @len are a byte range within the child, page aligned.
  */
 struct mps_ctl_range {
 	__s32 fd;
@@ -92,8 +91,6 @@ struct mps_ctl_range {
 	__u64 len;	/* bytes, page aligned */
 };
 
-#define MPS_CTL_SET_READONLY \
-	_IOW(MPS_IOCTL_BASE, 11, struct mps_ctl_range)
 #define MPS_CTL_SET_PRESENT \
 	_IOW(MPS_IOCTL_BASE, 12, struct mps_ctl_range)
 

-- 
2.56.0.257.gf7497c7d27-goog

