From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:21:55 -0800
Subject: [PATCH 05/36] xen/xmalloc: add kmalloc() and kfree() aliases
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-5-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=2077;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=izvZS5PqvGBio87RDretaNG85fhbAWhHk9N0az9Fz9c=;
 b=DxooxiraEmxSjKMVEBBQD4C5YYEkrJbAOK1wZaShOd6buUxM3dQFSSYYVIfElWUereMJvfwLg
 Wj8gFWn4yIjB0TL6qPikxL3D5RpBO5Qg26QYelUQogHdovGoR4kWouc
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move existing aliases to a common header so those could be used in the new
code.

The code looks simpler w/ kmalloc(): type specification of the
object being allocated is not required, e.g.:
...
  struct my_obj_s *obj;

  obj = kmalloc(sizeof(*obj), 0);
...

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/passthrough/arm/smmu.c | 4 ----
 xen/include/xen/xmalloc.h          | 5 +++++
 2 files changed, 5 insertions(+), 4 deletions(-)

diff --git a/xen/drivers/passthrough/arm/smmu.c b/xen/drivers/passthrough/arm/smmu.c
index aa6a968b574dce7cc753e8070fad3a6e585cd9e7..b343dbc32282136ccb95654ae2756eaa8a51149f 100644
--- a/xen/drivers/passthrough/arm/smmu.c
+++ b/xen/drivers/passthrough/arm/smmu.c
@@ -136,11 +136,7 @@ typedef enum irqreturn irqreturn_t;
 #define dev_name(dev) dt_node_full_name(dev_to_dt(dev))
 
 /* Alias to Xen allocation helpers */
-#define kfree xfree
-#define kmalloc(size, flags)		_xmalloc(size, sizeof(void *))
-#define kzalloc(size, flags)		_xzalloc(size, sizeof(void *))
 #define devm_kzalloc(dev, size, flags)	_xzalloc(size, sizeof(void *))
-#define kmalloc_array(size, n, flags)	_xmalloc_array(size, sizeof(void *), n)
 #define devm_kcalloc(dev, n, size, flags)			\
 	_xzalloc_array(size, sizeof(void *), n)
 
diff --git a/xen/include/xen/xmalloc.h b/xen/include/xen/xmalloc.h
index b903fa2e26e198fc80fc6010c3165cc50b1197c7..eea8cced51d9fe784b558201a68648e1672d624f 100644
--- a/xen/include/xen/xmalloc.h
+++ b/xen/include/xen/xmalloc.h
@@ -16,6 +16,11 @@
 #define xmalloc(_type) ((_type *)_xmalloc(sizeof(_type), __alignof__(_type)))
 #define xzalloc(_type) ((_type *)_xzalloc(sizeof(_type), __alignof__(_type)))
 
+#define kfree                           xfree
+#define kmalloc(size, flags)            _xmalloc(size, sizeof(void *))
+#define kzalloc(size, flags)            _xzalloc(size, sizeof(void *))
+#define kmalloc_array(size, n, flags)   _xmalloc_array(size, sizeof(void *), n)
+
 /*
  * Allocate space for a typed object and copy an existing instance.
  *

-- 
2.34.1

