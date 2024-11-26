From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:22 -0800
Subject: [PATCH 32/36] x86/hvm: add helpers for raising guest IRQs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-32-87b9a8375b7a@ford.com>
References: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
In-Reply-To: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
To: Jan Beulich <jbeulich@suse.com>, 
 Andrew Cooper <andrew.cooper3@citrix.com>, 
 =?utf-8?q?Roger_Pau_Monn=C3=A9?= <roger.pau@citrix.com>, 
 "Daniel P. Smith" <dpsmith@apertussolutions.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, Julien Grall <julien@xen.org>, 
 Bertrand Marquis <bertrand.marquis@arm.com>, 
 Michal Orzel <michal.orzel@amd.com>, Rahul Singh <rahul.singh@arm.com>, 
 Volodymyr Babchuk <Volodymyr_Babchuk@epam.com>, 
 Alistair Francis <alistair.francis@wdc.com>, 
 Bob Eshleman <bobbyeshleman@gmail.com>, 
 Connor Davis <connojdavis@gmail.com>, 
 Oleksii Kurochko <oleksii.kurochko@gmail.com>, 
 Shawn Anastasio <sanastasio@raptorengineering.com>, 
 Anthony PERARD <anthony.perard@vates.tech>, Juergen Gross <jgross@suse.com>, 
 Christian Lindig <christian.lindig@citrix.com>, 
 David Scott <dave@recoil.org>, 
 =?utf-8?q?Marek_Marczykowski-G=C3=B3recki?= <marmarek@invisiblethingslab.com>
Cc: xen-devel@lists.xenproject.org, Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=1876;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=7BbjWtYddozrVOKtAkZI0QGQoqm6ofyyNdgxey+37YU=;
 b=ThSK3I1nGSONSUOI8mLhfE3bYgxEWNIeTGmqKGF4Wt0hASsaBfM9mvC9LGsCTP8xT/H1gbzAI
 1Ak2zfg3dNeDPlENUq8QeW8vsLJWhYmLYPD53ex/4VN5v6wLCj5aagQ
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Added convenience wrappers for asserting/de-asserting interrupts in the
hardware emulation code.

That will be used for PCI-based NS8250 emulator.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/x86/hvm/irq.c             | 24 ++++++++++++++++++++++++
 xen/arch/x86/include/asm/hvm/irq.h |  3 +++
 2 files changed, 27 insertions(+)

diff --git a/xen/arch/x86/hvm/irq.c b/xen/arch/x86/hvm/irq.c
index 1eab44defca4c82ec35769617c66c380cc07d1b6..9e3a50d21dcf281c1015116094e47795c51ed5d0 100644
--- a/xen/arch/x86/hvm/irq.c
+++ b/xen/arch/x86/hvm/irq.c
@@ -242,6 +242,30 @@ void hvm_isa_irq_deassert(
     spin_unlock(&d->arch.hvm.irq_lock);
 }
 
+void hvm_irq_raise(struct domain *d, unsigned int irq)
+{
+    if ( irq < NR_ISAIRQS )
+    {
+        hvm_isa_irq_assert(d, irq, NULL);
+    }
+    else
+    {
+        hvm_gsi_assert(d, irq);
+    }
+}
+
+void hvm_irq_lower(struct domain *d, unsigned int irq)
+{
+    if ( irq < NR_ISAIRQS )
+    {
+        hvm_isa_irq_deassert(d, irq);
+    }
+    else
+    {
+        hvm_gsi_deassert(d, irq);
+    }
+}
+
 static void hvm_set_callback_irq_level(struct vcpu *v)
 {
     struct domain *d = v->domain;
diff --git a/xen/arch/x86/include/asm/hvm/irq.h b/xen/arch/x86/include/asm/hvm/irq.h
index 87e89993a44f48f366fa84e851688f383cb562d4..27bb9f64171c1b8aac2cf119699e60c91e727177 100644
--- a/xen/arch/x86/include/asm/hvm/irq.h
+++ b/xen/arch/x86/include/asm/hvm/irq.h
@@ -210,6 +210,9 @@ void hvm_maybe_deassert_evtchn_irq(void);
 void hvm_assert_evtchn_irq(struct vcpu *v);
 void hvm_set_callback_via(struct domain *d, uint64_t via);
 
+void hvm_irq_raise(struct domain *d, unsigned int irq);
+void hvm_irq_lower(struct domain *d, unsigned int irq);
+
 struct pirq;
 bool hvm_domain_use_pirq(const struct domain *d, const struct pirq *pirq);
 

-- 
2.34.1

