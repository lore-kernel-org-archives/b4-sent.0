From: Sven Peter <sven@kernel.org>
Date: Sun, 08 Nov 2026 15:35:11 +0100
Subject: [PATCH] soc: apple: Fix swapped paddr and size shift
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-sart-fix-v1-1-dab7dc1e9adb@kernel.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBCF4VeRWZtEXRrxKmLR1mAskA4iaby7Y
 vmd5PwBhDyTQJME8HSy8LpEqDQBN5llJOQ+GvIs10plNdoSxfgdB76wsn3htCrNoDXEx+Ypzl+
 t7X7LYWdy+5uA+34Aa4Yrom8AAAA=
X-Change-ID: 20261108-b4-sart-fix-5bd3c614af66
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1075; i=sven@kernel.org;
 h=from:subject:message-id; bh=CxvqlaaGSLGOU+O2kAABji4s/QSx7FuuOM5btlD5e0o=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aHjvkrhfl3h+32X7JAaIXs7deRJkvUjt4zS7FrWJy3x
 m1RWdbEjlIWBjEuBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEZrky/JWcejTtg+WHhmVL
 2l3r9ayX+p+td9+0PVNc7dC9Gwnv3mkxMvwPyun98WiSwcOCdXaNDL8zr6/OVlMKcY4NsD1UY/t
 qPj8A
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Right now we assign the paddr shift to the size shift and vice-versa.
Luckily, this doesn't matter because they are the same for all SART
versions but fixing this doesn't hurt.

Fixes: b170143ae111 ("soc: apple: Add SART driver")
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/soc/apple/sart.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/soc/apple/sart.c b/drivers/soc/apple/sart.c
index 66b99955b395..5f1f9ec5d311 100644
--- a/drivers/soc/apple/sart.c
+++ b/drivers/soc/apple/sart.c
@@ -258,8 +258,8 @@ static int sart_set_entry(struct apple_sart *sart, int index, u8 flags,
 	if (paddr & ((1 << sart->ops->paddr_shift) - 1))
 		return -EINVAL;
 
-	paddr >>= sart->ops->size_shift;
-	size >>= sart->ops->paddr_shift;
+	paddr >>= sart->ops->paddr_shift;
+	size >>= sart->ops->size_shift;
 
 	if (size > sart->ops->size_max)
 		return -EINVAL;

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261108-b4-sart-fix-5bd3c614af66

Best regards,
--  
Sven Peter <sven@kernel.org>

