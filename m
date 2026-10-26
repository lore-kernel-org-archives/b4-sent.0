From: Alex Ousherovitch <aousherovitch@rambus.com>
Date: Mon, 26 Oct 2026 12:45:01 -0700
Subject: [PATCH v7 5/5] MAINTAINERS: add Rambus CryptoManager Hub (CMH)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-cmh-b4-a-v7-v7-5-500a83faf500@rambus.com>
References: <20261026-cmh-b4-a-v7-v7-0-500a83faf500@rambus.com>
In-Reply-To: <20261026-cmh-b4-a-v7-v7-0-500a83faf500@rambus.com>
To: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>, 
 Joel Wittenauer <Joel.Wittenauer@cryptography.com>, 
 Thi Nguyen <thin@rambus.com>, Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-crypto@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Alex Ousherovitch <aousherovitch@rambus.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793043902; l=1310;
 i=aousherovitch@rambus.com; s=20261026; h=from:subject:message-id;
 bh=dgueTQsK9wIwgcKIQgHilK9irQV6fL/qq/pSePk/7A4=;
 b=q/GuuokYWIbpwqksRzqM3X32r7VqWkn4efeSgdkdwBn6ropn0yPBy5LfoFXISxNtq0gZ7imvY
 rEviUpwk5t5Ds9ytvDqNztVdA5O4bKsc+sfLleBU9Q71NcYDtRKd7Bp
X-Developer-Key: i=aousherovitch@rambus.com; a=ed25519;
 pk=ECFtTdQUPAolK+qGZ6v7Xm3sRf7rnM7wxpTeFzbqpmA=
X-Endpoint-Received: by B4 Relay for aousherovitch@rambus.com/20261026 with auth_id=1330
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MAINTAINERS entry for the Rambus CryptoManager Hub (CMH) hardware
crypto accelerator driver under drivers/crypto/cmh/.

Co-developed-by: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>
Signed-off-by: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>
Signed-off-by: Alex Ousherovitch <aousherovitch@rambus.com>
---
 MAINTAINERS | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index c3bcdcaa9b92..a803cd2a3c9a 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -22760,6 +22760,19 @@ L:	linux-wireless@vger.kernel.org
 S:	Maintained
 F:	drivers/net/wireless/ralink/
 
+RAMBUS CRYPTOMANAGER HUB (CMH) HARDWARE CRYPTO ACCELERATOR
+M:	Alex Ousherovitch <aousherovitch@rambus.com>
+M:	Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>
+R:	Joel Wittenauer <Joel.Wittenauer@cryptography.com>
+R:	Thi Nguyen <thin@rambus.com>
+L:	linux-crypto@vger.kernel.org
+S:	Maintained
+F:	Documentation/ABI/testing/debugfs-driver-cmh
+F:	Documentation/ABI/testing/sysfs-driver-cmh
+F:	Documentation/crypto/device_drivers/cmh.rst
+F:	Documentation/devicetree/bindings/crypto/rambus,cmh-v1030.yaml
+F:	drivers/crypto/cmh/
+
 RAMDISK RAM BLOCK DEVICE DRIVER
 M:	Jens Axboe <axboe@kernel.dk>
 S:	Maintained

-- 
2.43.7

