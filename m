From: Ben Zong-You Xie <ben717@andestech.com>
Date: Thu, 25 Jun 2026 18:36:01 +0800
Subject: [PATCH v6 3/3] MAINTAINERS: add an entry for Andes PWM driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260625-andes-pwm-v6-3-3aef11711017@andestech.com>
References: <20260625-andes-pwm-v6-0-3aef11711017@andestech.com>
In-Reply-To: <20260625-andes-pwm-v6-0-3aef11711017@andestech.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782383760; l=754;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=yOiq6thqiSeGFGixy89XEZx9mM4JZgZkT7AgxcDK7ko=;
 b=3zYmry0MbDfZ6qEOXl09L9iveMPJuWXQdFkAsLJqEBaLVnC/WxE0FjOMNW2tHIGCW48tzduCu
 jW/JYPmXp5BCJRtCuy3qzrIjeTSODMUpfYS1829cqEChoOIeWRaQOWv
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for the Andes PWM driver to the MAINTAINERS file.

Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
---
 MAINTAINERS | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 2fb1c75afd16..2461683a5bbb 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1874,6 +1874,12 @@ S:	Supported
 F:	Documentation/devicetree/bindings/spi/andestech,ae350-spi.yaml
 F:	drivers/spi/spi-atcspi200.c
 
+ANDES PWM DRIVER
+M:	Ben Zong-You Xie <ben717@andestech.com>
+S:	Supported
+F:	Documentation/devicetree/bindings/pwm/andestech,ae350-pwm.yaml
+F:	drivers/pwm/pwm-andes.c
+
 ANDROID DRIVERS
 M:	Greg Kroah-Hartman <gregkh@linuxfoundation.org>
 M:	Arve Hjønnevåg <arve@android.com>

-- 
2.34.1

