From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:16 -0700
Subject: [PATCH RFC 04/12] Documentation: KVM: Turn - into bullet point
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-4-4fe8b602ff47@google.com>
References: <20260527-kvm-locking-docs-v1-0-4fe8b602ff47@google.com>
In-Reply-To: <20260527-kvm-locking-docs-v1-0-4fe8b602ff47@google.com>
To: Paolo Bonzini <pbonzini@redhat.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Tianrui Zhao <zhaotianrui@loongson.cn>, Bibo Mao <maobibo@loongson.cn>, 
 Huacai Chen <chenhuacai@kernel.org>, WANG Xuerui <kernel@xen0n.name>, 
 Sean Christopherson <seanjc@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, Fuad Tabba <tabba@google.com>, 
 vannapurve@google.com, x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, loongarch@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=909;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=CVJlxPT0bvHHOwHsW6J5heOXwU/ZjkdVD+6fUMJnWDE=;
 b=KkPJHF+eM7NDmHDSEhDOiOBWhwesjg7rIQXxnzpWgTB9I02vfYnNi5BaXX0a183XJ1mq7TDDx
 YhG5/AGb4N7Df+nmEUADJYfEvIEoR/I+w01Jm8766xS2x9bSTAeKxa+
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For the :Protects: section of kvm->mmu_lock, a missing space causes the -
to render as a literal - instead of a bullet point. Add space to make it
render as a bullet point.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/locking.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/virt/kvm/locking.rst b/Documentation/virt/kvm/locking.rst
index 67dd2066f6d98..e349c2cb94943 100644
--- a/Documentation/virt/kvm/locking.rst
+++ b/Documentation/virt/kvm/locking.rst
@@ -283,7 +283,7 @@ time it will be set using the Dirty tracking mechanism described above.
 ^^^^^^^^^^^^^^^^^
 :Type:		spinlock_t or rwlock_t
 :Arch:		any
-:Protects:	-shadow page/shadow tlb entry
+:Protects:	- shadow page/shadow tlb entry
 :Comment:	it is a spinlock since it is used in mmu notifier.
 
 ``kvm->srcu``

-- 
2.54.0.823.g6e5bcc1fc9-goog

