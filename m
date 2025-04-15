From: Sven Peter <sven@svenpeter.dev>
Date: Tue, 15 Apr 2025 15:36:55 +0000
Subject: [PATCH v2 1/6] i2c: pasemi: Use correct bits.h include
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250415-pasemi-fixes-v2-1-c543bf53151a@svenpeter.dev>
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
 linux-kernel@vger.kernel.org, Sven Peter <sven@svenpeter.dev>, 
 Andy Shevchenko <andy.shevchenko@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=990; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=T4ctk5KZpkF4MCpfLgWPh46S+YQwBJlk0+PfdZqRe6g=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/q/WpVo9+5foQ6z5vcxp3SHJe/Yv2n3g66G6UzbKwXuL
 tgouymoo5SFQYyDQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCRbQ4M/70DXfKzoxxXTxOc
 uo9dNH/jlYrXT2ck/Xx1InsiY6tQ80ZGho+/F3tc3uDmaXHgnMfKKX0nLK4sFYvyXBK8OMPl/06
 9o5wA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When changing the #defines to use BIT and GENMASK the bitfield.h include
was added instead of the correct bits.h include.

Reported-by: Andy Shevchenko <andy.shevchenko@gmail.com>
Closes: https://lore.kernel.org/asahi/Z965tVhC5jxy1kqZ@surfacebook.localdomain/
Fixes: 8b4da3ef9206 ("i2c: pasemi: Add registers bits and switch to BIT()")
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index bd128ab2e2ebb64929f2f6a3525835a880c3114d..71cc8cfc7c5cbf3924269f6217712d42008c03ff 100644
--- a/drivers/i2c/busses/i2c-pasemi-core.c
+++ b/drivers/i2c/busses/i2c-pasemi-core.c
@@ -5,7 +5,7 @@
  * SMBus host driver for PA Semi PWRficient
  */
 
-#include <linux/bitfield.h>
+#include <linux/bits.h>
 #include <linux/module.h>
 #include <linux/pci.h>
 #include <linux/kernel.h>

-- 
2.34.1

