From: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
Date: Sat, 21 Nov 2026 21:43:12 +0900
Subject: [PATCH RFC v2 02/13] dt-bindings: arm: add SiRF AT550 and Yupiteru
 YPL514si
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-at550-rfc-v1-v2-2-b0309d0789b2@gmail.com>
References: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
In-Reply-To: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795264991; l=1613;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=PQrX/FspDA33PekWwNtkQNVgZAR2YGwuuowr8uCQ39A=;
 b=hnIFHkpO/fOjyh207yCGUwqWuFV7rTti8wsPk3qoG+YRunLsOlNp/PFVSab7tls06HaRhzjRt
 Ty67dTXHUS3CP/JdaxriOUFj5TyhAF6X889ETQ40JFnH3O2TKbZ6Rz6
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Devicetree binding schema for the SiRF AT550 SoC and the
Yupiteru YPL514si board, and create the SIRF AT550 PLATFORM MAINTAINERS
entry.

Signed-off-by: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
---
 .../devicetree/bindings/arm/sirf,at550.yaml        | 22 ++++++++++++++++++++++
 MAINTAINERS                                        |  5 +++++
 2 files changed, 27 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/sirf,at550.yaml b/Documentation/devicetree/bindings/arm/sirf,at550.yaml
new file mode 100644
index 000000000..0234324e2
--- /dev/null
+++ b/Documentation/devicetree/bindings/arm/sirf,at550.yaml
@@ -0,0 +1,22 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/arm/sirf,at550.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SiRF AT550 platforms
+
+maintainers:
+  - Yuugo Yoneda <yogo.0917.sabu@gmail.com>
+
+properties:
+  $nodename:
+    const: '/'
+  compatible:
+    items:
+      - const: yupiteru,ypl514si
+      - const: sirf,at550
+
+additionalProperties: true
+
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index d73899016..a825b3bae 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25847,6 +25847,11 @@ F:	drivers/gpio/gpio-siox.c
 F:	drivers/siox/*
 F:	include/trace/events/siox.h
 
+SIRF AT550 PLATFORM
+M:	Yuugo Yoneda <yogo.0917.sabu@gmail.com>
+S:	Odd Fixes
+F:	Documentation/devicetree/bindings/arm/sirf,at550.yaml
+
 SIS 190 ETHERNET DRIVER
 M:	Francois Romieu <romieu@fr.zoreil.com>
 L:	netdev@vger.kernel.org

-- 
2.56.0

