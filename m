From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:36 -0800
Subject: [PATCH v2 06/35] riscv/domain: introduce domain_has_vuart()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-6-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>, 
 Oleksii Kurochko <oleksii.kurochko@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=737;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=+kPk8EKdgpPKuThGSrouRJGm0Vji6pKcYMUo97PKO3Q=;
 b=6hYpirrUtuGFg5SJ0XrKEsxgzUe45RwgR0LajeGuvIJ0aB25n1VGtzPpVnNKCGGGKS7oUgfI4
 8U4z97HHmmfBzikcouSM5h0MFyMmyrQbcm5azQxSjCr9Bq6EhZyi00j
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce domain_has_vuart() for RISC-V port to be used in the console driver.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
Reviewed-by: Oleksii Kurochko <oleksii.kurochko@gmail.com>
---
 xen/arch/riscv/include/asm/domain.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/xen/arch/riscv/include/asm/domain.h b/xen/arch/riscv/include/asm/domain.h
index c3d965a559b6ce3661bf17166d0c51853ff295a2..efbc4f1ea2619a187fe30ede17d96de01e599220 100644
--- a/xen/arch/riscv/include/asm/domain.h
+++ b/xen/arch/riscv/include/asm/domain.h
@@ -10,6 +10,8 @@ struct hvm_domain
     uint64_t              params[HVM_NR_PARAMS];
 };
 
+#define domain_has_vuart(d)         false
+
 struct arch_vcpu_io {
 };
 

-- 
2.34.1

