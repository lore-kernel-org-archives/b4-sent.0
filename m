From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 07 May 2026 13:22:28 -0700
Subject: [PATCH v6 09/43] KVM: Move kvm_supported_mem_attributes() to
 kvm_host.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260507-gmem-inplace-conversion-v6-9-91ab5a8b19a4@google.com>
References: <20260507-gmem-inplace-conversion-v6-0-91ab5a8b19a4@google.com>
In-Reply-To: <20260507-gmem-inplace-conversion-v6-0-91ab5a8b19a4@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 ira.weiny@intel.com, jmattson@google.com, jthoughton@google.com, 
 michael.roth@amd.com, oupton@kernel.org, pankaj.gupta@amd.com, 
 qperret@google.com, rick.p.edgecombe@intel.com, rientjes@google.com, 
 shivankg@amd.com, steven.price@arm.com, tabba@google.com, 
 willy@infradead.org, wyihan@google.com, yan.y.zhao@intel.com, 
 forkloop@google.com, pratyush@kernel.org, suzuki.poulose@arm.com, 
 aneesh.kumar@kernel.org, liam@infradead.org, 
 Paolo Bonzini <pbonzini@redhat.com>, 
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778185365; l=1904;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=H4KenV13dLeEqjvdyE3y5jRrxlJdQyrngi+fJmKc/3M=;
 b=RI14MMkYeomt+WbAOHuBgg1ipOXRaDDHI21XNVAJPh2YQQwbvdvhCfGFJ1+t3mohkUod3jgSE
 fkJgCBIWStfA2NuMm46M2fR+ccsXJzBqsgPFmYmUiI/IgKu6LsfGM3J
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move kvm_supported_mem_attributes() from kvm_main.c to kvm_host.h and
make it a static inline function. This allows the helper to be used in
other parts of the KVM subsystem outside of kvm_main.c. This helper will be
used later by guest_memfd.

No functional change intended.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/kvm_host.h | 10 ++++++++++
 virt/kvm/kvm_main.c      | 10 ----------
 2 files changed, 10 insertions(+), 10 deletions(-)

diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index 1deab76dc0a2c..f9ea95e33d050 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -2529,6 +2529,16 @@ static inline bool kvm_memslot_is_gmem_only(const struct kvm_memory_slot *slot)
 }
 
 #ifdef CONFIG_KVM_MEMORY_ATTRIBUTES
+static inline u64 kvm_supported_mem_attributes(struct kvm *kvm)
+{
+#ifdef kvm_arch_has_private_mem
+	if (!kvm || kvm_arch_has_private_mem(kvm))
+		return KVM_MEMORY_ATTRIBUTE_PRIVATE;
+#endif
+
+	return 0;
+}
+
 typedef unsigned long (kvm_get_memory_attributes_t)(struct kvm *kvm, gfn_t gfn);
 DECLARE_STATIC_CALL(__kvm_get_memory_attributes, kvm_get_memory_attributes_t);
 
diff --git a/virt/kvm/kvm_main.c b/virt/kvm/kvm_main.c
index 0a4024948711a..ff20e63143642 100644
--- a/virt/kvm/kvm_main.c
+++ b/virt/kvm/kvm_main.c
@@ -2428,16 +2428,6 @@ static int kvm_vm_ioctl_clear_dirty_log(struct kvm *kvm,
 #endif /* CONFIG_KVM_GENERIC_DIRTYLOG_READ_PROTECT */
 
 #ifdef CONFIG_KVM_MEMORY_ATTRIBUTES
-static u64 kvm_supported_mem_attributes(struct kvm *kvm)
-{
-#ifdef kvm_arch_has_private_mem
-	if (!kvm || kvm_arch_has_private_mem(kvm))
-		return KVM_MEMORY_ATTRIBUTE_PRIVATE;
-#endif
-
-	return 0;
-}
-
 #ifdef CONFIG_KVM_VM_MEMORY_ATTRIBUTES
 static unsigned long kvm_get_vm_memory_attributes(struct kvm *kvm, gfn_t gfn)
 {

-- 
2.54.0.563.g4f69b47b94-goog

