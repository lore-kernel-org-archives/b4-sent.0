From: Ben Zong-You Xie <ben717@andestech.com>
Date: Tue, 11 Aug 2026 14:29:50 +0800
Subject: [PATCH v5 3/4] MAINTAINERS: add an entry for Andes I2C driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260811-atciic100-v5-3-1d306c21dba3@andestech.com>
References: <20260811-atciic100-v5-0-1d306c21dba3@andestech.com>
In-Reply-To: <20260811-atciic100-v5-0-1d306c21dba3@andestech.com>
To: Andi Shyti <andi.shyti@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-i2c@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-09770
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786429789; l=771;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=uExPQvJDzXhEA4CaNzsQ8AegVCh731pt3gwkmiHcb3E=;
 b=Qv/zV69Wu6HC8PkNbTRV3bFVeZx8Xd3H6PePxXOGXirwnr3BcsnCsmKgTx0MDSDunYSZTIUkF
 mElc1UcXubvAR+nSfTCnDThPxpXxj5/++ZNJJSu/+n+BdoGDccKwBZy
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for the Andes I2C driver to the MAINTAINERS file.

Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
---
 MAINTAINERS | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 15011f5752a9..d1727fd0e83e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1938,6 +1938,12 @@ S:	Supported
 F:	Documentation/devicetree/bindings/watchdog/andestech,ae350-wdt.yaml
 F:	drivers/watchdog/atcwdt200_wdt.c
 
+ANDES I2C DRIVER
+M:	Ben Zong-You Xie <ben717@andestech.com>
+S:	Supported
+F:	Documentation/devicetree/bindings/i2c/andestech,ae350-i2c.yaml
+F:	drivers/i2c/busses/i2c-andes.c
+
 ANDROID DRIVERS
 M:	Greg Kroah-Hartman <gregkh@linuxfoundation.org>
 M:	Arve Hjønnevåg <arve@android.com>

-- 
2.34.1

