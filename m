From: Ben Zong-You Xie <ben717@andestech.com>
Date: Wed, 12 Aug 2026 11:24:06 +0800
Subject: [PATCH v7 3/3] MAINTAINERS: add an entry for Andes PWM driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260812-andes-pwm-v7-3-a806da8185d1@andestech.com>
References: <20260812-andes-pwm-v7-0-a806da8185d1@andestech.com>
In-Reply-To: <20260812-andes-pwm-v7-0-a806da8185d1@andestech.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-09770
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786505045; l=764;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=gjO6IZe5Ik4Z5BEicWOc/F1VbekVfs+WHY+c4FTLRSM=;
 b=wJ+LQWuuwY7kOate1QP4hWImy2xdHaluN1e2FeIkIeGyTo1DYF4fQSmp958EGGWqU5yKyH1wT
 hmIRtz+XJzSD8RWJ+n0pzIt2RqDDbUoq0qu147d40XqqpQlj8ZfPu4P
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
index 15011f5752a9..dcf16c40a99e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1938,6 +1938,12 @@ S:	Supported
 F:	Documentation/devicetree/bindings/watchdog/andestech,ae350-wdt.yaml
 F:	drivers/watchdog/atcwdt200_wdt.c
 
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

