From: Ben Zong-You Xie <ben717@andestech.com>
Date: Mon, 30 Mar 2026 15:30:33 +0800
Subject: [PATCH v4 3/4] MAINTAINERS: add an entry for Andes I2C driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260330-atciic100-v4-3-d40822f63e4e@andestech.com>
References: <20260330-atciic100-v4-0-d40822f63e4e@andestech.com>
In-Reply-To: <20260330-atciic100-v4-0-d40822f63e4e@andestech.com>
To: Andi Shyti <andi.shyti@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-i2c@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774855834; l=761;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=YiEx76SInP9JPwiKbc2slZ7Do4K0fx/VOtW1zrmzoiE=;
 b=cGuKKUe2ItklPvrrHhtXXu6mGLNhsReLY7Aqk85OiXJ76fLYf7jOPjpYRCE7znqZPx2tryyT3
 YrhaGvbnU5HBw1Ibl3b+Ar480h6R3bFHIfpeiBvdnv725OlGsqi06VI
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
index 7d10988cbc62..7272ebe7a22b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1863,6 +1863,12 @@ S:	Supported
 F:	Documentation/devicetree/bindings/spi/andestech,ae350-spi.yaml
 F:	drivers/spi/spi-atcspi200.c
 
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

