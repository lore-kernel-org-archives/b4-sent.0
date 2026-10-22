From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:27:53 -0700
Subject: [PATCH RFC v2 21/50] samples/kvm: Remove donate, reclaim, and move
 operations from sample provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-21-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=5139;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=WTi8GNiGg+F2aaBuaZCq/EDwN8kKCvY/mAo+mn6OX58=;
 b=v3QhsSEVYXAd028viNm8E7C+qHr9nyYz39aTz3RD6uY14m1o/VGPWhbErWNd6ZfBbEsWDSTBQ
 MLBj6iPluokDwyJ+aEIZoq+Eozr60nK1kdDQ10JAa8cCaEYuDLEqG3P
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the MPS_MOVE, MPS_DONATE, and MPS_RECLAIM ioctls from the sample
memory provider.

These operations manage dynamic ownership transfers and returning memory
to the root pool, which adds complexity that is not needed for the core
interface design.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/mem_provider_sample.c | 86 ---------------------------------------
 samples/kvm/mem_provider_sample.h | 35 ----------------
 2 files changed, 121 deletions(-)

diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index 8180959ab78ff..5afc433dce6e8 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -674,86 +674,6 @@ static bool mps_child_owns(struct mps_info *info, unsigned long first,
 	       find_next_zero_bit(info->owned, e, s) >= e;
 }
 
-static long mps_ctl_move(void __user *uarg)
-{
-	struct mps_move mv;
-	struct mps_info *src, *dst;
-	unsigned long first, last;
-	struct file *sf, *df;
-	long ret;
-
-	if (copy_from_user(&mv, uarg, sizeof(mv)))
-		return -EFAULT;
-	sf = mps_get_child(mv.src_fd, &src);
-	if (IS_ERR(sf))
-		return PTR_ERR(sf);
-	df = mps_get_child(mv.dst_fd, &dst);
-	if (IS_ERR(df)) {
-		fput(sf);
-		return PTR_ERR(df);
-	}
-
-	mutex_lock(&mps_root.lock);
-	ret = mps_root_range(mv.offset, mv.len, &first, &last);
-	if (ret)
-		goto out;
-	if (src == dst || !mps_child_owns(src, first, last) ||
-	    !mps_child_covers(dst, first, last)) {
-		ret = -EINVAL;
-		goto out;
-	}
-	/* Revoke from the source before the destination gets the pages. */
-	mps_child_lose(src, first, last);
-	mps_child_gain(dst, first, last);
-out:
-	mutex_unlock(&mps_root.lock);
-	fput(df);
-	fput(sf);
-	return ret;
-}
-
-static long mps_ctl_donate(void __user *uarg, bool reclaim)
-{
-	struct mps_donate d;
-	unsigned long first, last;
-	struct mps_info *info;
-	struct file *file;
-	long ret;
-
-	if (copy_from_user(&d, uarg, sizeof(d)))
-		return -EFAULT;
-	if (d.pad)
-		return -EINVAL;
-	file = mps_get_child(d.fd, &info);
-	if (IS_ERR(file))
-		return PTR_ERR(file);
-
-	mutex_lock(&mps_root.lock);
-	ret = mps_root_range(d.offset, d.len, &first, &last);
-	if (ret)
-		goto out;
-	if (!reclaim) {
-		if (!mps_child_owns(info, first, last)) {
-			ret = -EINVAL;
-			goto out;
-		}
-		mps_child_lose(info, first, last);
-		bitmap_set(mps_root.donated, first, last - first);
-	} else {
-		if (!mps_child_covers(info, first, last) ||
-		    find_next_zero_bit(mps_root.donated, last, first) < last) {
-			ret = -EINVAL;
-			goto out;
-		}
-		bitmap_clear(mps_root.donated, first, last - first);
-		mps_child_gain(info, first, last);
-	}
-out:
-	mutex_unlock(&mps_root.lock);
-	fput(file);
-	return ret;
-}
-
 /*
  * CTL_SET_READONLY and CTL_SET_PRESENT change a child's pages, by the owner on
  * the control device.  A VMM that holds the child fd cannot, so it cannot undo
@@ -795,12 +715,6 @@ static long mps_ctl_ioctl(struct file *file, unsigned int cmd,
 		return mps_ctl_setup(uarg);
 	case MPS_NEW_CHILD:
 		return mps_ctl_new_child(uarg);
-	case MPS_MOVE:
-		return mps_ctl_move(uarg);
-	case MPS_DONATE:
-		return mps_ctl_donate(uarg, false);
-	case MPS_RECLAIM:
-		return mps_ctl_donate(uarg, true);
 	case MPS_CTL_SET_READONLY:
 		return mps_ctl_set_range(uarg, true);
 	case MPS_CTL_SET_PRESENT:
diff --git a/samples/kvm/mem_provider_sample.h b/samples/kvm/mem_provider_sample.h
index 0e036d1c76a45..acff5785099b5 100644
--- a/samples/kvm/mem_provider_sample.h
+++ b/samples/kvm/mem_provider_sample.h
@@ -68,41 +68,6 @@ struct mps_new_child {
 #define MPS_NEW_CHILD \
 	_IOW(MPS_IOCTL_BASE, 5, struct mps_new_child)
 
-/*
- * ioctl on /dev/mem_provider_sample: move [@offset, @offset + @len) of the root
- * from child @src_fd to child @dst_fd.  @src_fd must have every page of the
- * range, and the range must be inside @dst_fd's.  The pages are revoked from
- * the source before the destination gets them, so the consumers of the two
- * children never map them at the same time.
- */
-struct mps_move {
-	__s32 src_fd;
-	__s32 dst_fd;
-	__u64 offset;	/* bytes into the root, page aligned */
-	__u64 len;	/* bytes, page aligned */
-};
-
-#define MPS_MOVE \
-	_IOW(MPS_IOCTL_BASE, 6, struct mps_move)
-
-/*
- * ioctls on /dev/mem_provider_sample: DONATE takes [@offset, @offset + @len) of
- * the root from child @fd, which must have all of it, and keeps it at the
- * root.  RECLAIM gives a donated range to child @fd, whose range must
- * contain it.  The sample does not scrub the pages.
- */
-struct mps_donate {
-	__s32 fd;
-	__u32 pad;
-	__u64 offset;	/* bytes into the root, page aligned */
-	__u64 len;	/* bytes, page aligned */
-};
-
-#define MPS_DONATE \
-	_IOW(MPS_IOCTL_BASE, 7, struct mps_donate)
-#define MPS_RECLAIM \
-	_IOW(MPS_IOCTL_BASE, 8, struct mps_donate)
-
 /* ioctl on a child fd: read the child's state, for tests. */
 struct mps_stats {
 	__u64 region_offset;	/* the child's range in the root */

-- 
2.56.0.257.gf7497c7d27-goog

