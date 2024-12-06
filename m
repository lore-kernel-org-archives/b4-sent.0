From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:32 -0800
Subject: [PATCH v2 02/35] xen/irq: introduce NO_IRQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-2-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=616;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=dP3fe+TbEoRyzDIKnwZpy2zc7XNhJoHUDN0gqSrT6Sc=;
 b=GKp4UmHhqYd4CVUECgv6TOG2tNjpaTsfFbUI/8w7Tg/1Iubs7IfYMbYiQH2BZuSCKukEeBIRd
 dw9amfh326NCUqU9lJxyOuAS13v+83XcJtUb9tN5Gt5oIKGchFjF22K
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce definition for IRQ resource checks.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/include/xen/irq.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/xen/include/xen/irq.h b/xen/include/xen/irq.h
index 95034c0d6bb5f0aa7d5bb572aca59872508a438a..aee878293ecc0de6a938bcfea1140d36b4de745a 100644
--- a/xen/include/xen/irq.h
+++ b/xen/include/xen/irq.h
@@ -53,6 +53,7 @@ struct irqaction {
 #define AUTO_ASSIGN_IRQ         (-1)
 #define NEVER_ASSIGN_IRQ        (-2)
 #define FREE_TO_ASSIGN_IRQ      (-3)
+#define NO_IRQ                  (-4)
 
 struct irq_desc;
 

-- 
2.34.1

