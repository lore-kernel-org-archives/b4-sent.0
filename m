From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Sat, 20 Dec 2025 01:22:00 +0100
Subject: [PATCH v5 3/7] dt-bindings: wireless: ath12k: Allow disable-rfkill
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251220-surface-sp11-for-next-v5-3-16065bef8ef3@gmail.com>
References: <20251220-surface-sp11-for-next-v5-0-16065bef8ef3@gmail.com>
In-Reply-To: <20251220-surface-sp11-for-next-v5-0-16065bef8ef3@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, 
 Maximilian Luz <luzmaximilian@gmail.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Jeff Johnson <jjohnson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 platform-driver-x86@vger.kernel.org, ath12k@lists.infradead.org, 
 Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Dale Whinham <daleyo@gmail.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766190155; l=1122;
 i=jerome.debretagne@gmail.com; s=20251217; h=from:subject:message-id;
 bh=qxUYWgrkevDrzW7E3kqpqIBVkm0S8EYbX/8Sl2i9Gas=;
 b=HDpJFAGzTzB5pyD88o+QOrEljODlF7cCgrR9SyebLystn5VxlZgYVg3uagtZgdENepJt0kLLa
 a+F3uIzqOXxBbr1R0q7/T0VtIvb3vjw3XuxLtdJu4E5cq/heNZe6IhR
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=DcPD9n3oDMsPkt+12tU96swmGb5H86cxt+yiEVcUEGk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20251217 with auth_id=580
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reference the ieee80211.yaml schema to allow disable-rfkill to
be used for models that need to disable the rfkill feature,
otherwise the Wi-Fi radio is unusable.

This is required by the Surface Pro 11 with WCN7850.

Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 Documentation/devicetree/bindings/net/wireless/qcom,ath12k.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/wireless/qcom,ath12k.yaml b/Documentation/devicetree/bindings/net/wireless/qcom,ath12k.yaml
index dc68dd59988fc757e8f53e809128cb4e820d66d1..e18c87b21777bc6642e551f23feff69bfb7fb435 100644
--- a/Documentation/devicetree/bindings/net/wireless/qcom,ath12k.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/qcom,ath12k.yaml
@@ -21,6 +21,8 @@ properties:
   reg:
     maxItems: 1
 
+  disable-rfkill: true
+
   firmware-name:
     maxItems: 1
     description:
@@ -69,6 +71,9 @@ required:
 
 additionalProperties: false
 
+allOf:
+  - $ref: ieee80211.yaml#
+
 examples:
   - |
     #include <dt-bindings/clock/qcom,rpmh.h>

-- 
2.47.3

