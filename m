From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 12 Mar 2026 03:10:28 +0000
Subject: [PATCH] dt-bindings: pwm: amlogic: Document A4 A5 and T7 PWM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260312-pwm_binding-v1-1-515cb65add98@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAKMusmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY0Mj3YLy3PikzLyUzLx03cRUCxPz5BSDZHODNCWgjoKi1LTMCrBp0bG
 1tQAUhH9uXQAAAA==
X-Change-ID: 20260312-pwm_binding-ae847cd0c70f
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773285063; l=1236;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=rZ9QHTXWFZRqKa+SSVPHCPcz3e3bqLwWkz+549SNkJs=;
 b=nCAlE7mTXsh7iJIhsnjsTzTdnSzEartep4/j6/p29SArKM/1M981N35XrdR0lQe8Y3m1odx6y
 oopsOuPC/llAFRibGywSNp5xR7kFauRQA6AMKg1MiqbaJAHmZLQMjDA
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document amlogic,a4-pwm amlogic,a5-pwm and amlogic,t7-pwm
compatible, which falls back to the meson-s4-pwm group.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
After the clock module is merged, the PWM node will be submitted
together with the nodes of other modules. For now, we submit the
PWM DT binding first.
---
 Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml b/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
index cc3ebd4deeb6..c337d85da40f 100644
--- a/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
+++ b/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
@@ -39,7 +39,10 @@ properties:
           - amlogic,meson-s4-pwm
       - items:
           - enum:
+              - amlogic,a4-pwm
+              - amlogic,a5-pwm
               - amlogic,c3-pwm
+              - amlogic,t7-pwm
               - amlogic,meson-a1-pwm
           - const: amlogic,meson-s4-pwm
       - items:

---
base-commit: e3194dfb772304a1b7ca3bcfccacefec3468b7bf
change-id: 20260312-pwm_binding-ae847cd0c70f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

