From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:17 -0700
Subject: [PATCH RFC 05/12] Documentation: KVM: Explain what rule the
 exception section is meant for
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-5-4fe8b602ff47@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=866;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=UhewnEFTG+HebdABX6t5eYYm+bNGAkoVsLLrTGAOeg4=;
 b=H1OQEdfNpvGS7THThfrjojW6x13TvDlSiVDOrcNRwD6ECzNiF+y3cEqXlnDWAXTlLltd+N+OR
 mklc0Q4Qr+BDr5L6d/govG1pkusRLLY1/lYMOt9RtFH8pqsWyDfELTw
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Exception section describes some exceptions but not the rule the
exception is for. Add a paragraph to clarify that detail.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/locking.rst | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/virt/kvm/locking.rst b/Documentation/virt/kvm/locking.rst
index e349c2cb94943..5161636cec481 100644
--- a/Documentation/virt/kvm/locking.rst
+++ b/Documentation/virt/kvm/locking.rst
@@ -61,6 +61,10 @@ sections.
 2. Exception
 ------------
 
+The general rule in KVM is that any modification to shadow page tables
+(and their entries (SPTEs)) must be protected by ``kvm->mmu_lock``,
+with the exceptions described below.
+
 Fast page fault:
 
 Fast page fault is the fast path which fixes the guest page fault out of

-- 
2.54.0.823.g6e5bcc1fc9-goog

