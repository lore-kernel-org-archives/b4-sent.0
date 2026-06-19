From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 18 Jun 2026 17:31:51 -0700
Subject: [PATCH v8 14/46] KVM: guest_memfd: Ensure pages are not in use
 before conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260618-gmem-inplace-conversion-v8-14-9d2959357853@google.com>
References: <20260618-gmem-inplace-conversion-v8-0-9d2959357853@google.com>
In-Reply-To: <20260618-gmem-inplace-conversion-v8-0-9d2959357853@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 jmattson@google.com, jthoughton@google.com, michael.roth@amd.com, 
 oupton@kernel.org, pankaj.gupta@amd.com, qperret@google.com, 
 rick.p.edgecombe@intel.com, rientjes@google.com, shivankg@amd.com, 
 steven.price@arm.com, tabba@google.com, willy@infradead.org, 
 wyihan@google.com, yan.y.zhao@intel.com, forkloop@google.com, 
 pratyush@kernel.org, suzuki.poulose@arm.com, aneesh.kumar@kernel.org, 
 liam@infradead.org, Paolo Bonzini <pbonzini@redhat.com>, 
 Sean Christopherson <seanjc@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Shuah Khan <shuah@kernel.org>, Vishal Annapurve <vannapurve@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Youngjun Park <youngjun.park@lge.com>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Kiryl Shutsemau <kas@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Vlastimil Babka <vbabka@kernel.org>, 
 Baoquan He <baoquan.he@linux.dev>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781829104; l=4835;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=KBHEGQKuWpDe+njfLl+lpw15mu536qAG0wzEXp3jt9s=;
 b=v0wfXRaz/JzEqQAReRMEm6V1S/nL+U2ZG9xnhsKZvjeiujH0MEyKBRtCKPzgVc/HQcTX2fmKi
 lbSB0khyyz9BBYCKpl+J2MsjoQ8cnmjFnD/bldnwQ7x+oelEw/7km2R
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When converting memory to private in guest_memfd, it is necessary to ensure
that the pages are not currently being accessed by any other part of the
kernel or userspace to avoid any current user writing to guest private
memory.

guest_memfd checks for unexpected refcounts to determine whether a page is
still in use. The only expected refcounts after unmapping the range
requested for conversion are those that are held by guest_memfd itself.

Update the kvm_memory_attributes2 structure to include an error_offset
field. This allows KVM to report the exact offset where a conversion
failed to userspace. If the safety check fails, return -EAGAIN and copy
the error_offset back to userspace so that it can potentially retry the
operation or handle the failure gracefully.

Suggested-by: David Hildenbrand <david@kernel.org>
Co-developed-by: Vishal Annapurve <vannapurve@google.com>
Signed-off-by: Vishal Annapurve <vannapurve@google.com>
Reviewed-by: Fuad Tabba <tabba@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/uapi/linux/kvm.h |  3 ++-
 virt/kvm/guest_memfd.c   | 68 ++++++++++++++++++++++++++++++++++++++++++++----
 2 files changed, 65 insertions(+), 6 deletions(-)

diff --git a/include/uapi/linux/kvm.h b/include/uapi/linux/kvm.h
index 956877a6aab05..876c0429f9d4e 100644
--- a/include/uapi/linux/kvm.h
+++ b/include/uapi/linux/kvm.h
@@ -1659,7 +1659,8 @@ struct kvm_memory_attributes2 {
 	__u64 size;
 	__u64 attributes;
 	__u64 flags;
-	__u64 reserved[12];
+	__u64 error_offset;
+	__u64 reserved[11];
 };
 
 #define KVM_MEMORY_ATTRIBUTE_PRIVATE           (1ULL << 3)
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 0d14548c1ed22..433f79047b9d1 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -573,9 +573,45 @@ static int kvm_gmem_mas_preallocate(struct ma_state *mas, u64 attributes,
 	return mas_preallocate(mas, xa_mk_value(attributes), GFP_KERNEL);
 }
 
+static bool kvm_gmem_is_safe_for_conversion(struct inode *inode, pgoff_t start,
+					    size_t nr_pages, pgoff_t *err_index)
+{
+	struct address_space *mapping = inode->i_mapping;
+	const int filemap_get_folios_refcount = 1;
+	pgoff_t last = start + nr_pages - 1;
+	struct folio_batch fbatch;
+	bool safe = true;
+	pgoff_t next;
+	int i;
+
+	folio_batch_init(&fbatch);
+
+	next = start;
+	while (safe && filemap_get_folios(mapping, &next, last, &fbatch)) {
+
+		for (i = 0; i < folio_batch_count(&fbatch); ++i) {
+			struct folio *folio = fbatch.folios[i];
+
+			if (folio_ref_count(folio) !=
+			    folio_nr_pages(folio) + filemap_get_folios_refcount) {
+				safe = false;
+				*err_index = max(start, folio->index);
+				break;
+			}
+		}
+
+		folio_batch_release(&fbatch);
+		cond_resched();
+	}
+
+	return safe;
+}
+
 static int __kvm_gmem_set_attributes(struct inode *inode, pgoff_t start,
-				     size_t nr_pages, uint64_t attrs)
+				     size_t nr_pages, uint64_t attrs,
+				     pgoff_t *err_index)
 {
+	bool to_private = attrs & KVM_MEMORY_ATTRIBUTE_PRIVATE;
 	struct address_space *mapping = inode->i_mapping;
 	struct gmem_inode *gi = GMEM_I(inode);
 	pgoff_t end = start + nr_pages;
@@ -589,8 +625,21 @@ static int __kvm_gmem_set_attributes(struct inode *inode, pgoff_t start,
 
 	mas_init(&mas, mt, start);
 	r = kvm_gmem_mas_preallocate(&mas, attrs, start, nr_pages);
-	if (r)
+	if (r) {
+		*err_index = start;
 		goto out;
+	}
+
+	if (to_private) {
+		unmap_mapping_pages(mapping, start, nr_pages, false);
+
+		if (!kvm_gmem_is_safe_for_conversion(inode, start, nr_pages,
+						     err_index)) {
+			mas_destroy(&mas);
+			r = -EAGAIN;
+			goto out;
+		}
+	}
 
 	/*
 	 * From this point on guest_memfd has performed necessary
@@ -610,9 +659,10 @@ static long kvm_gmem_set_attributes(struct file *file, void __user *argp)
 	struct gmem_file *f = file->private_data;
 	struct inode *inode = file_inode(file);
 	struct kvm_memory_attributes2 attrs;
+	pgoff_t err_index;
 	size_t nr_pages;
 	pgoff_t index;
-	int i;
+	int i, r;
 
 	if (copy_from_user(&attrs, argp, sizeof(attrs)))
 		return -EFAULT;
@@ -638,8 +688,16 @@ static long kvm_gmem_set_attributes(struct file *file, void __user *argp)
 
 	nr_pages = attrs.size >> PAGE_SHIFT;
 	index = attrs.offset >> PAGE_SHIFT;
-	return __kvm_gmem_set_attributes(inode, index, nr_pages,
-					 attrs.attributes);
+	r = __kvm_gmem_set_attributes(inode, index, nr_pages, attrs.attributes,
+				      &err_index);
+	if (r) {
+		attrs.error_offset = ((uint64_t)err_index) << PAGE_SHIFT;
+
+		if (copy_to_user(argp, &attrs, sizeof(attrs)))
+			return -EFAULT;
+	}
+
+	return r;
 }
 
 static long kvm_gmem_ioctl(struct file *file, unsigned int ioctl,

-- 
2.55.0.rc0.738.g0c8ab3ebcc-goog

