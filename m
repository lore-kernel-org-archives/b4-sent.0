From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:21:54 -0800
Subject: [PATCH 04/36] xen/irq: introduce NO_IRQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-4-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=616;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=dP3fe+TbEoRyzDIKnwZpy2zc7XNhJoHUDN0gqSrT6Sc=;
 b=ZK/Egrhd1ftyBDG8fHCbgj99AZ9DcnZ5TxuavepL4iKCTofpCdmvmPQJY/yN3M2p29rTI4mg6
 v8M76j0gxtADkBiXTcySpLMh1uQQabkcw/KIGK4vj4s7sXp5Zfzx7iQ
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

