From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 09 Jul 2024 16:48:25 +0800
Subject: [PATCH 1/2] dt-bindings: watchdog: add support for Amlogic A4 SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240709-a4-a5_watchdog-v1-1-2ae852e05ec2@amlogic.com>
References: <20240709-a4-a5_watchdog-v1-0-2ae852e05ec2@amlogic.com>
In-Reply-To: <20240709-a4-a5_watchdog-v1-0-2ae852e05ec2@amlogic.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-watchdog@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Huqiang Qin <huqiang.qin@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720514906; l=894;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=WSePT+XFO2cODMzffP2GQB75+cxcIunyp22iaEGOG9k=;
 b=/GnnQaw8grZyQF6/wV6MN5no6SKlMc27aNZXcXDnmTwLzDJ7SnyUU0p+7MFhekaNcJ6jZ0tkn
 +wRy6wjmoNDBQPJgq4mp00r+Ylgm11XR0Q+UudFI1wbZOVdHaLJmOnN
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Huqiang Qin <huqiang.qin@amlogic.com>

Update dt-binding document for watchdog of Amlogic A4 SoCs.

Signed-off-by: Huqiang Qin <huqiang.qin@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/watchdog/amlogic,meson-gxbb-wdt.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/watchdog/amlogic,meson-gxbb-wdt.yaml b/Documentation/devicetree/bindings/watchdog/amlogic,meson-gxbb-wdt.yaml
index 69845ec32e81..d0eff1ea52b4 100644
--- a/Documentation/devicetree/bindings/watchdog/amlogic,meson-gxbb-wdt.yaml
+++ b/Documentation/devicetree/bindings/watchdog/amlogic,meson-gxbb-wdt.yaml
@@ -21,6 +21,7 @@ properties:
           - amlogic,t7-wdt
       - items:
           - enum:
+              - amlogic,a4-wdt
               - amlogic,c3-wdt
               - amlogic,s4-wdt
           - const: amlogic,t7-wdt

-- 
2.37.1

