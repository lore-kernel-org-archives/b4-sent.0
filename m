From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 03 Oct 2026 16:45:21 -0300
Subject: [PATCH 1/4] dt-bindings: power: supply: qcom,pmi8998-charger: add
 chg-state-change
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-qcom-smbx-chg-state-change-v1-1-fffaef446932@gmail.com>
References: <20261003-qcom-smbx-chg-state-change-v1-0-fffaef446932@gmail.com>
In-Reply-To: <20261003-qcom-smbx-chg-state-change-v1-0-fffaef446932@gmail.com>
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, David Heidelberg <david@ixit.cz>, 
 phone-devel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791056720; l=1039;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=ACxRf9zQSp49WZNPI7O//QWImpQWoDmjFCaFFKAHtmI=;
 b=+t0z1QY9OEqXZpMHKaaitOEWXzs7uGy8M364T2NPNEKO6I6HKcQ+nOAjfVVCQUstxzj0OVdv7
 758Z/kRv9NQCvAzmNIGESkKKVA4OY1mYE2xLXihRjaEwmIDovipNxPh
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The charger raises an interrupt when its charging state changes. Allow
it as an optional fifth interrupt.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 .../devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml       | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
index 70f5cd6eaeab..7dfb0823ccbb 100644
--- a/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
+++ b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
@@ -19,14 +19,17 @@ properties:
     maxItems: 1
 
   interrupts:
-    maxItems: 4
+    minItems: 4
+    maxItems: 5
 
   interrupt-names:
+    minItems: 4
     items:
       - const: usb-plugin
       - const: bat-ov
       - const: wdog-bark
       - const: usbin-icl-change
+      - const: chg-state-change
 
   io-channels:
     items:

-- 
2.55.0

