From: Sven Peter <sven@svenpeter.dev>
Date: Tue, 15 Apr 2025 15:36:56 +0000
Subject: [PATCH v2 2/6] i2c: pasemi: Sort includes alphabetically
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250415-pasemi-fixes-v2-2-c543bf53151a@svenpeter.dev>
References: <20250415-pasemi-fixes-v2-0-c543bf53151a@svenpeter.dev>
In-Reply-To: <20250415-pasemi-fixes-v2-0-c543bf53151a@svenpeter.dev>
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Neal Gompa <neal@gompa.dev>, Hector Martin <marcan@marcan.st>
Cc: linuxppc-dev@lists.ozlabs.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1747; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=d4SrViBETCvEIVGrCu813u0fCI79k8TBuEJCcmGpDI0=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/q/WtWl7ddnLW1MubOp8d16cesWr2/7U2cXBHtceHk94
 Xb343vXOkpZGMQ4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQATyZrO8D+9Oq6hSL4vb+s3
 aes9x67wXZ7ywlla4kKDZuwqy/eW7yMY/ik9+WNdy5A+zzfXXDRK0vDdoZPBj/T0lJ3n3axrt+s
 uZwUA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No functional changes.

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 10 +++++-----
 drivers/i2c/busses/i2c-pasemi-pci.c  | 10 +++++-----
 2 files changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index 71cc8cfc7c5cbf3924269f6217712d42008c03ff..df1b0087dcacb0a3b94196368137d5e20b0e6d7e 100644
--- a/drivers/i2c/busses/i2c-pasemi-core.c
+++ b/drivers/i2c/busses/i2c-pasemi-core.c
@@ -6,15 +6,15 @@
  */
 
 #include <linux/bits.h>
+#include <linux/delay.h>
+#include <linux/i2c.h>
+#include <linux/io.h>
+#include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/pci.h>
-#include <linux/kernel.h>
-#include <linux/stddef.h>
 #include <linux/sched.h>
-#include <linux/i2c.h>
-#include <linux/delay.h>
 #include <linux/slab.h>
-#include <linux/io.h>
+#include <linux/stddef.h>
 
 #include "i2c-pasemi-core.h"
 
diff --git a/drivers/i2c/busses/i2c-pasemi-pci.c b/drivers/i2c/busses/i2c-pasemi-pci.c
index 77f90c7436eda2df16afd7f1cac79355fb005bfd..b9ccb54ec77e22bb1b77848c858e2e0cc51db7e3 100644
--- a/drivers/i2c/busses/i2c-pasemi-pci.c
+++ b/drivers/i2c/busses/i2c-pasemi-pci.c
@@ -5,15 +5,15 @@
  * SMBus host driver for PA Semi PWRficient
  */
 
+#include <linux/delay.h>
+#include <linux/i2c.h>
+#include <linux/io.h>
+#include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/pci.h>
-#include <linux/kernel.h>
-#include <linux/stddef.h>
 #include <linux/sched.h>
-#include <linux/i2c.h>
-#include <linux/delay.h>
 #include <linux/slab.h>
-#include <linux/io.h>
+#include <linux/stddef.h>
 
 #include "i2c-pasemi-core.h"
 

-- 
2.34.1

