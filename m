From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:39 -0800
Subject: [PATCH v2 09/35] x86/domain: print emulation_flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-9-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=1263;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=732gIMLcaCgGTFTHv9vAjNIT6ES/ZZttjeIUCT3F6PI=;
 b=Y7HK/z6jmiAxr9LffbLx3VzuTnpvsJKN4W5zpRGYQrcHh7C1xfTaL3qBH1d/hc6odnj49z0ll
 kg3ON+vpt6nA9uN2Ik2YEXEG2SpMz1AzDdlcvsmncdiJ05m4eO9kdq9
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

