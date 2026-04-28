From: Ackerley Tng <ackerleytng@google.com>
Date: Tue, 28 Apr 2026 16:25:01 -0700
Subject: [PATCH RFC v5 06/53] KVM: x86/mmu: Bug the VM if gmem attributes
 are queried to determine max mapping level
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-gmem-inplace-conversion-v5-6-d8608ccfca22@google.com>
References: <20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com>
In-Reply-To: <20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 ira.weiny@intel.com, jmattson@google.com, jthoughton@google.com, 
 michael.roth@amd.com, oupton@kernel.org, pankaj.gupta@amd.com, 
 qperret@google.com, rick.p.edgecombe@intel.com, rientjes@google.com, 
 shivankg@amd.com, steven.price@arm.com, tabba@google.com, 
 willy@infradead.org, wyihan@google.com, yan.y.zhao@intel.com, 
 forkloop@google.com, pratyush@kernel.org, suzuki.poulose@arm.com, 
 aneesh.kumar@kernel.org, Paolo Bonzini <pbonzini@redhat.com>, 
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
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <bhe@redhat.com>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Youngjun Park <youngjun.park@lge.com>, Qi Zheng <qi.zheng@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Vlastimil Babka <vbabka@kernel.org>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777418714; l=1802;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=mE1k3tJABrFyLvPsAUThPSR13SSUuI4MykLoB5ZQsPI=;
 b=CMxTYYNPO2Cg0DwwVYx4rM0CeYzUOqMMYtEiADkSrj386FCCj4wMlpDsBDm5m+GMCeMOCbzOi
 lMB9ng0Vh81CYdMxjc8AIWrpzjoE01tqhLnJELjyZNXaKHIOyygmT3c
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the maximum mapping level is queried, KVM's MMU lock is held, and
while the MMU lock is held, guest_memfd cannot take the
filemap_invalidate_lock() to look up the current shared/private state of
the gfn, for these reasons:

+ The MMU lock is a spinlock or rwlock and cannot be held while taking a
  lock that can sleep.
+ In guest_memfd's code paths (such as truncate), the
  filemap_invalidate_lock() is held while taking the MMU lock, and taking
  the locks in reverse order would introduce a AB-BA deadlock.

Currently, the maximum mapping level is only queried from guest_memfd in
the process of recovering huge pages, if dirty logging is disabled on a
memslot. Dirty logging is not currently supported for guest_memfd, and
guest_memfd memslots also cannot be updated.

For now, bug the VM if guest_memfd needs to be queried to determine the
maximum mapping level. This guard can be removed if/when support is added.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/x86/kvm/mmu/mmu.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index 8276d7ca02036..2cc848bddf190 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -3364,6 +3364,15 @@ int kvm_mmu_max_mapping_level(struct kvm *kvm, struct kvm_page_fault *fault,
 		max_level = fault->max_level;
 		is_private = fault->is_private;
 	} else {
+		/*
+		 * Memory attributes cannot be obtained from guest_memfd while
+		 * the MMU lock is held.
+		 */
+		if (KVM_BUG_ON(static_call_query(__kvm_get_memory_attributes) ==
+			       kvm_gmem_get_memory_attributes, kvm)) {
+			return 0;
+		}
+
 		max_level = PG_LEVEL_NUM;
 		is_private = kvm_mem_is_private(kvm, gfn);
 	}

-- 
2.54.0.545.g6539524ca2-goog

