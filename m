From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 07 Nov 2026 03:36:07 +0800
Subject: [PATCH 1/3] dt-bindings: vendor-prefixes: add Zhihe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-a210-pinctrl-v1-1-6ddedfb0b76b@iscas.ac.cn>
References: <20261107-a210-pinctrl-v1-0-6ddedfb0b76b@iscas.ac.cn>
In-Reply-To: <20261107-a210-pinctrl-v1-0-6ddedfb0b76b@iscas.ac.cn>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793993783; l=895;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=NfTLhXrzvQ5lJQxz8O7S6dCaG/HAPcHpRM6wkHRi+5Q=;
 b=jXSpmF5KYuPWmqUmA8jIye9cqYSZ78cKrjemBzTsQkLr4lAxawkA/NLoOQjMABq6qjFLYAyei
 vajxHFbcLs7D9lJUYcfjl+eCyQSqwyV74P4gAQNdWJoT63PX2PPpf/7
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>

Add the vendor prefix for Zhihe Computing.

Signed-off-by: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 5471a06f93f1..e6db332510bc 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1995,6 +1995,8 @@ patternProperties:
     description: Zealz
   "^zeitec,.*":
     description: ZEITEC Semiconductor Co., LTD.
+  "^zhihe,.*":
+    description: Zhihe Computing Limited
   "^zidoo,.*":
     description: Shenzhen Zidoo Technology Co., Ltd.
   "^zii,.*":

-- 
2.55.0

