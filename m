From: Sven Peter <sven@svenpeter.dev>
Date: Tue, 15 Apr 2025 15:36:59 +0000
Subject: [PATCH v2 5/6] i2c: pasemi: Enable the unjam machine
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250415-pasemi-fixes-v2-5-c543bf53151a@svenpeter.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1300; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=avtSs0p55pNQJTNl3swTi6LwCmUmFUOOKuZ3dOr9VMk=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/q/Ws2ndfPmtB3bbO2jqvDW5Ev4LGcDy+r+knvZS59Pe
 X71jezqjlIWBjEOBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEbHkZGU6nTbw1R/BPS4jk
 jcyrs3Uk5026L3Qj8fylVBc5TZurXrMYGd5u+bD78K+fK15NMFWyPLghsbbqqc4xs/jri+yaTOL
 5uXgB
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

The I2C bus can get stuck under some conditions (desync between
controller and device). The pasemi controllers include an unjam feature
that is enabled on reset, but was being disabled by the driver. Keep it
enabled by explicitly setting the UJM bit in the CTL register. This
should help recover the bus from certain conditions, which would
otherwise remain stuck forever.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index 2f31f039bedfd7f78d6572fe925125b1a6d0724b..41db38d82fe62c73614b8fafe4cb73c7d1a24762 100644
--- a/drivers/i2c/busses/i2c-pasemi-core.c
+++ b/drivers/i2c/busses/i2c-pasemi-core.c
@@ -78,7 +78,7 @@ static inline int reg_read(struct pasemi_smbus *smbus, int reg)
 
 static void pasemi_reset(struct pasemi_smbus *smbus)
 {
-	u32 val = (CTL_MTR | CTL_MRR | (smbus->clk_div & CTL_CLK_M));
+	u32 val = (CTL_MTR | CTL_MRR | CTL_UJM | (smbus->clk_div & CTL_CLK_M));
 
 	if (smbus->hw_rev >= 6)
 		val |= CTL_EN;

-- 
2.34.1

