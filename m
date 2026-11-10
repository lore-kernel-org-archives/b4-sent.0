From: Alex Ousherovitch <aousherovitch@rambus.com>
Date: Tue, 10 Nov 2026 08:52:31 -0800
Subject: [PATCH v8 5/5] MAINTAINERS: add Rambus CryptoManager Hub (CMH)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-cmh-b4-a-v8-v8-5-4cea8ebc1d40@rambus.com>
References: <20261110-cmh-b4-a-v8-v8-0-4cea8ebc1d40@rambus.com>
In-Reply-To: <20261110-cmh-b4-a-v8-v8-0-4cea8ebc1d40@rambus.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794329557; l=1310;
 i=aousherovitch@rambus.com; s=20261026; h=from:subject:message-id;
 bh=Bd9aCgWNbaQADX7NBB116ORW6UoH7r2h1um/oYEgcMw=;
 b=nO90tJhXY6S1PtQe/PK8Kdy1Wpn5+UM55CWJzXecGinv5ZsAsVrvlzhqXx3EFf476dViQWDkG
 sTztDp6V4e6CkVuz/wgD7JW2J9bZDuiYnjaQl3dYAnIsefR4IqNluMg
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
index 93abbb315065..0dc921a090ec 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -23305,6 +23305,19 @@ L:	linux-wireless@vger.kernel.org
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

