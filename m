From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:38 -0800
Subject: [PATCH v2 08/35] x86/domain: introduce domain_has_vuart()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-8-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=889;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=d8+eK1EX7G4dAD9MTJCuZscRKOX31WZGg59AsNpMxsU=;
 b=cG7SkKjK5QUHyRM3m5wrGnS1pgFt0n85Fs1Xe2pmZs5Vlb0KOvwBf5tETIrxKlEyd7jpRII9O
 toWVU7GmrsPCS+fsxc/qQNc08AGwg1KYEmN2hQEgOOrZFF13XuOGfCc
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce domain_has_vuart() for x86 port to be used in the console driver.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/x86/include/asm/domain.h | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/xen/arch/x86/include/asm/domain.h b/xen/arch/x86/include/asm/domain.h
index b79d6badd71c4d96279555df62fad75fe817a2b6..c1d0d1f47324e8cc678a4c76c43f86820a89e7b3 100644
--- a/xen/arch/x86/include/asm/domain.h
+++ b/xen/arch/x86/include/asm/domain.h
@@ -506,6 +506,9 @@ struct arch_domain
 #define has_pirq(d)        (!!((d)->arch.emulation_flags & X86_EMU_USE_PIRQ))
 #define has_vpci(d)        (!!((d)->arch.emulation_flags & X86_EMU_VPCI))
 
+/* NB: same symbol as in Arm port */
+#define domain_has_vuart(d) false
+
 #define gdt_ldt_pt_idx(v) \
       ((v)->vcpu_id >> (PAGETABLE_ORDER - GDT_LDT_VCPU_SHIFT))
 #define pv_gdt_ptes(v) \

-- 
2.34.1

