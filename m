From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:00 -0800
Subject: [PATCH 10/36] ppc/domain: introduce domain_has_vuart()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-10-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=728;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=t3QJZEOM8PRrx5tFAM37Q5lrsCWx/ouiwIRJrERCogM=;
 b=f8wXFvd3jIkFIxNMBQ/Axu1bbqXBT0SUKFv83mK3ibYkFiQYPB/1CIit84amN75UuJ8kKxZhP
 qoa3sZDsWsYBHULljtv9I1Vynu51trtpjkriYMTMTyEbSz/qdAX7tC/
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce domain_has_vuart() for PPC port to be used in the console driver.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/ppc/include/asm/domain.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/xen/arch/ppc/include/asm/domain.h b/xen/arch/ppc/include/asm/domain.h
index 3a447272c6f28586bf0d610929adbf228579e13f..764978e6a61b9d7220ec10fe0763e3424d07d27a 100644
--- a/xen/arch/ppc/include/asm/domain.h
+++ b/xen/arch/ppc/include/asm/domain.h
@@ -10,6 +10,8 @@ struct hvm_domain
     uint64_t              params[HVM_NR_PARAMS];
 };
 
+#define domain_has_vuart(d)         false
+
 /* TODO: Implement */
 #define guest_mode(r) ({ (void)(r); BUG_ON("unimplemented"); 0; })
 

-- 
2.34.1

