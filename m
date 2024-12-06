From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:50 -0800
Subject: [PATCH v2 20/35] xen/console: introduce console_owner_domid()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-20-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=1498;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=B93paIiJy8o1DGD2n2g3KcZoYn4UUAYMMgdZEki+Vh4=;
 b=Knkc/GPlePCDp77YoynQwfl3vAq4MXPN4bGfSacAecxhgdGewN2VzhLvq78O/rqeOAPhPSSP+
 d4gtAVUmJSEDCqv/TzQSACQbYlZC+3mE3ziOkjv6lNWXlNd0dODNmWy
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

console_owner_domid() is introduced to obtain the "console owner" domain ID.

The call is used in NS8250 emulator to identify the case when physical xen
console focus is owned by the domain w/ NS8250 emulator, in which case,
messages from guest OS are formatted w/o '(XEN)' prefix.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 5 +++++
 xen/include/xen/console.h  | 1 +
 2 files changed, 6 insertions(+)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 52cf64dbf6fd18d599cb88835d03501a23b3e3c4..a8ab5c2bcb98e4cadf9ad2c9ad28d297977d0557 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -498,6 +498,11 @@ struct domain *rcu_lock_domain_console_owner(void)
     return rcu_lock_domain_console_by_id(console_owner);
 }
 
+domid_t console_owner_domid(void)
+{
+    return console_owner;
+}
+
 static bool console_owner_possible(domid_t domid)
 {
     struct domain *d;
diff --git a/xen/include/xen/console.h b/xen/include/xen/console.h
index 57c482cfbf2da15b011e64841ea086e779f4588d..83be5794aff6630beaad46f910fcc0fc6d833808 100644
--- a/xen/include/xen/console.h
+++ b/xen/include/xen/console.h
@@ -33,6 +33,7 @@ void console_end_log_everything(void);
 
 struct domain *rcu_lock_domain_console_owner(void);
 int console_set_owner(domid_t);
+domid_t console_owner_domid(void);
 
 /*
  * Steal output from the console. Returns +ve identifier, else -ve error.

-- 
2.34.1

