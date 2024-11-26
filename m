From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:21:58 -0800
Subject: [PATCH 08/36] arm/vuart: make domain_has_vuart() public
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-8-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=2314;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=uCztJF40iiw3Im/nqwTMa7qbljN2JkGzlchQ98JzHsE=;
 b=isneJVgwidpN8rhG/OkAiaRbJdUdO7yE2BwELU9Bp6jwr+k8o9BX8cUFkDWfx0RMKc2FRLugJ
 BGjQU6KqQiuBLLooUpXjSIHbWfvIAg5+S+qgjK4tEdnPv1tizdzO1OC
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move domain_has_vuart() to arch namespace as preparation code change for
architecture-agnostic way of forwarding physical console to the guest OS w/
in-hypervisor UART emulator.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/arm/include/asm/domain.h | 9 +++++++++
 xen/arch/arm/vpl011.c             | 2 ++
 xen/arch/arm/vuart.c              | 4 ++--
 3 files changed, 13 insertions(+), 2 deletions(-)

diff --git a/xen/arch/arm/include/asm/domain.h b/xen/arch/arm/include/asm/domain.h
index f1d72c6e48dfeba347b4cd091ca33603c368b7c0..2bbd3f472176bdcfbc0f95f9d8809343d11965c8 100644
--- a/xen/arch/arm/include/asm/domain.h
+++ b/xen/arch/arm/include/asm/domain.h
@@ -119,8 +119,17 @@ struct arch_domain
     void *tee;
 #endif
 
+    /* Emulated devices enabled bitmap. */
+    uint32_t emulation_flags;
+
 }  __cacheline_aligned;
 
+enum {
+    ARM_EMU_VUART           = BIT(0, U),
+};
+
+#define domain_has_vuart(d)     (!!((d)->arch.emulation_flags & ARM_EMU_VUART))
+
 struct arch_vcpu
 {
     struct {
diff --git a/xen/arch/arm/vpl011.c b/xen/arch/arm/vpl011.c
index 8ade6f2588b8bbcc58fb0f9edc324502a1992ce7..140dca48e0a3901cba289dbc6eb117358134d917 100644
--- a/xen/arch/arm/vpl011.c
+++ b/xen/arch/arm/vpl011.c
@@ -730,6 +730,8 @@ int domain_vpl011_init(struct domain *d, struct vpl011_init_info *info)
     register_mmio_handler(d, &vpl011_mmio_handler,
                           vpl011->base_addr, GUEST_PL011_SIZE, NULL);
 
+    d->arch.emulation_flags |= ARM_EMU_VUART;
+
     return 0;
 
 out1:
diff --git a/xen/arch/arm/vuart.c b/xen/arch/arm/vuart.c
index 38ce8cc14fac4132578059b696be952b29fab809..8ca8ae5523a7924846df4324f9e0a81f225756ad 100644
--- a/xen/arch/arm/vuart.c
+++ b/xen/arch/arm/vuart.c
@@ -31,8 +31,6 @@
 
 #include "vuart.h"
 
-#define domain_has_vuart(d) ((d)->arch.vuart.info != NULL)
-
 static int vuart_mmio_read(struct vcpu *v, mmio_info_t *info,
                            register_t *r, void *priv);
 static int vuart_mmio_write(struct vcpu *v, mmio_info_t *info,
@@ -63,6 +61,8 @@ int domain_vuart_init(struct domain *d)
                           d->arch.vuart.info->size,
                           NULL);
 
+    d->arch.emulation_flags |= ARM_EMU_VUART;
+
     return 0;
 }
 

-- 
2.34.1

