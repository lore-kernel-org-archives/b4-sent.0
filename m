From: David Heidelberg <david@ixit.cz>
Date: Fri, 20 Mar 2026 17:44:42 +0100
Subject: [PATCH v7 1/7] dt-bindings: input: syna,rmi4: Document
 syna,rmi4-s3706b
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-synaptics-rmi4-v7-1-379360de18d0@ixit.cz>
References: <20260320-synaptics-rmi4-v7-0-379360de18d0@ixit.cz>
In-Reply-To: <20260320-synaptics-rmi4-v7-0-379360de18d0@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Casey Connolly <casey.connolly@linaro.org>, phone-devel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1250; i=david@ixit.cz;
 h=from:subject:message-id; bh=sEfAUOYzG1M4zvx/Xv8wME49V12PqhPhJ6Tk21Hc6yo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpvXl6DQoVjnt6AUjpK6l5YSqeNhZzWp2I7/L/S
 gRrU92ruVuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab15egAKCRBgAj/E00kg
 cnlaD/9GRWZMPIKiTohJQYNue8Ey+/mhCM0p030duqBy4yVAV+yGqsT+DJuI/79njzgOVVfJ0nR
 87MSeH6uER7+Oco7eXBYx+izh2vaSkhUS9GYPftdMl6n1Me/bl344FtY/y5Z8CC3aiNsmrgdk/4
 yY9CkWYZYZk3hTEGeKv5Y+F/RWb2ge8LIpMjzU5OcdbGfKTzXFlYKRsepAxA9fdtQC+A9A7L0PL
 Dc0677JIuV5Wg918OCtKqkfcPWXcPyaUdBY5+fS2UEyymCL/b86MbkzPZpzIoLeM4phAF1MUBy+
 /HCG4KU15EckBLE5/Q9Y8m0BrzxcxKuE+TdVjDRwzPE22I9cJXNKXXxi/G2h6B/a+hft8ACRMJ3
 LU9qP4YD8SK1E1P97PNYl7ORnf2fDvmgMvhbaOthu6omZNAmvh7K1yHi4oWMfgg1NhCS5MGBmGT
 orZZrUYT7HMw6pX5LpsEN+2Zi2rQ3RAQjYD401A6aVO+NRI70gxA50c+VMOIJfNtctRxzIodhxH
 oIM2lo6J8LH21SQreek3IJhrZHutHgJe6LgcrTfGroi/5d1F5qC39lpORJ7dXyUS+9iswzzRJcW
 hh73xvCA/8FJIXGphU98uF+CqU9W8aUFUYgYrCzZyaptzTWxw23fIuZZ5CsMnyO2E4By6Xjhaoo
 6mfHIDH0TMXzboQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mostly irrelevant for authentic Synaptics touchscreens, but very important
for applying workarounds to cheap TS knockoffs.

These knockoffs work well with the downstream driver, and since the user
has no way to distinguish them, later in this patch set, we introduce
workarounds to ensure they function as well as possible.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/input/syna,rmi4.yaml | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/syna,rmi4.yaml b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
index 8685ef4481f4a..fb4804ac3544d 100644
--- a/Documentation/devicetree/bindings/input/syna,rmi4.yaml
+++ b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
@@ -18,9 +18,14 @@ description: |
 
 properties:
   compatible:
-    enum:
-      - syna,rmi4-i2c
-      - syna,rmi4-spi
+    oneOf:
+      - enum:
+          - syna,rmi4-i2c
+          - syna,rmi4-spi
+      - items:
+          - enum:
+              - syna,rmi4-s3706b  # OnePlus 6/6T
+          - const: syna,rmi4-i2c
 
   reg:
     maxItems: 1

-- 
2.53.0

