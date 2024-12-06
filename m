From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:37 -0800
Subject: [PATCH v2 07/35] ppc/domain: introduce domain_has_vuart()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-7-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=728;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=t3QJZEOM8PRrx5tFAM37Q5lrsCWx/ouiwIRJrERCogM=;
 b=Miqdv195rw9t1S3j6p1XRsugjWUwQ1EFx/shKs1eSw6d+ul8/IaMuWZDk+NDDthwgf90m1sxh
 3kbUZi6bZ/2BoWa5b05lZ0tlZtXQXK10znL6NDjaUHlqXg1kvLQo1tH
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

