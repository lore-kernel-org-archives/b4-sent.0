From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:02 -0800
Subject: [PATCH 12/36] x86/domain: print emulation_flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-12-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=1263;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=732gIMLcaCgGTFTHv9vAjNIT6ES/ZZttjeIUCT3F6PI=;
 b=2D1GntxceEk8CMvCOGVcGx8ZV/nfrqT6w+jxAmtSvt6YKGse6dADcw0/VXr3voTosV5dqLTi0
 bWeqzqNK8CfARQ2L2mPeU6iFTzP8vSKt5Jjr+TxraPvuDidph2v/E57
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Print d->arch.emulation_flags on the console for better traceability while
debugging in-hypervisor hardware emulators.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/x86/domain.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/xen/arch/x86/domain.c b/xen/arch/x86/domain.c
index 78a13e6812c9120901d0a70fb3bc1bd6a8b6917d..c88d422a64544531c1e1058fa484364bb4277d1e 100644
--- a/xen/arch/x86/domain.c
+++ b/xen/arch/x86/domain.c
@@ -818,11 +818,15 @@ int arch_domain_create(struct domain *d,
 
     if ( !emulation_flags_ok(d, emflags) )
     {
-        printk(XENLOG_G_ERR "d%d: Xen does not allow %s domain creation "
+        printk(XENLOG_G_ERR "d%d: Xen does not allow %s %sdomain creation "
                "with the current selection of emulators: %#x\n",
-               d->domain_id, is_hvm_domain(d) ? "HVM" : "PV", emflags);
+               d->domain_id,
+               is_hvm_domain(d) ? "HVM" : "PV",
+               is_hardware_domain(d) ? "(hardware) " : "",
+               emflags);
         return -EOPNOTSUPP;
     }
+    printk(XENLOG_G_INFO "d%d: emulation_flags %#x\n", d->domain_id, emflags);
     d->arch.emulation_flags = emflags;
 
 #ifdef CONFIG_PV32

-- 
2.34.1

