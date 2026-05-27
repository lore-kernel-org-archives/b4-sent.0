From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:19 -0700
Subject: [PATCH RFC 07/12] Documentation: KVM: Drop mention of kvm->lock in
 SRCU documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-7-4fe8b602ff47@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=1115;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=AfvnWtgsVpXIKXd9EvhdAVtlR2WiGKaxMZJotHAsjr8=;
 b=q6xZf/5/u1rdMaAEebXfbdUD15CwiaRJEQv8wy+OHzvYq94cMmo+p9Vjs5r6IZMkazcCQ+cOA
 vGzpCQxTs4EDZVCNaYIQXAThy7QIfLWsIT9Wzdwv9O1z6Mi7/54mSVg
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original comment says that synchronize_srcu(&kvm->srcu) is called
inside critical sections for kvm->lock, vcpu->mutex and
kvm->slots_lock. Drop mention of kvm->lock since this is no longer true.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/locking.rst | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/virt/kvm/locking.rst b/Documentation/virt/kvm/locking.rst
index fc4537a7659a9..437dbfa0030b9 100644
--- a/Documentation/virt/kvm/locking.rst
+++ b/Documentation/virt/kvm/locking.rst
@@ -35,8 +35,8 @@ The acquisition orders for mutexes are as follows:
 For SRCU:
 
 - ``synchronize_srcu(&kvm->srcu)`` is called inside critical sections
-  for kvm->lock, vcpu->mutex and kvm->slots_lock.  These locks _cannot_
-  be taken inside a kvm->srcu read-side critical section; that is, the
+  for vcpu->mutex and kvm->slots_lock.  These locks _cannot_ be taken
+  inside a kvm->srcu read-side critical section; that is, the
   following is broken::
 
       srcu_read_lock(&kvm->srcu);

-- 
2.54.0.823.g6e5bcc1fc9-goog

