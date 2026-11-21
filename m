From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sat, 21 Nov 2026 10:30:20 +0100
Subject: [PATCH 1/3] dt-bindings: power: supply: summit,smb347: Clarify the
 USB current limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-upstream-smb347-apsd-v1-1-ca46b92bfd44@tsv-stahl-riesa.de>
References: <20261121-upstream-smb347-apsd-v1-0-ca46b92bfd44@tsv-stahl-riesa.de>
In-Reply-To: <20261121-upstream-smb347-apsd-v1-0-ca46b92bfd44@tsv-stahl-riesa.de>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Dmitry Osipenko <digetx@gmail.com>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Bruce Robertson <brucer42@gmail.com>, 
 =?utf-8?q?Martin_J=C3=BCcker?= <martin.juecker@gmail.com>, 
 Mithil Bavishi <bavishimithil@gmail.com>, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795253429; l=1563;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=ifkvy1uzmYxpX0CrPq5nsb8+MrGYX8Ejrb1HsNv+EbI=;
 b=739a63rcbeB+QL7ELhbH759wYAFiDfto32DVJ4diSfd1pILRe4DM7Xk1AaB+7wm4sypmPeQld
 lsHfSn4memdBtAxZtBE5TGaunVGUjklhi950tb0U1zFKWewr5u+L7K+
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SMB347 detects whether its USB input is connected to a standard
downstream port, a charging downstream port or a dedicated charger.
The input current limit then depends on the port type: a PC port must
not be loaded with the current a dedicated charger can deliver.

Describe "summit,usb-current-limit-microamp" as the limit with a
dedicated charger, which is what boards set it to today (1.8 A on
exynos4412-p4note and omap4-samsung-espresso10).

Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 .../devicetree/bindings/power/supply/summit,smb347-charger.yaml      | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/power/supply/summit,smb347-charger.yaml b/Documentation/devicetree/bindings/power/supply/summit,smb347-charger.yaml
index 65ed92bb05f3..67e6d4055af0 100644
--- a/Documentation/devicetree/bindings/power/supply/summit,smb347-charger.yaml
+++ b/Documentation/devicetree/bindings/power/supply/summit,smb347-charger.yaml
@@ -54,7 +54,10 @@ properties:
     description: Maximum input current from AC/DC input (in uA)
 
   summit,usb-current-limit-microamp:
-    description: Maximum input current from USB input (in uA)
+    description:
+      Maximum input current from USB input (in uA). This is the limit with a
+      dedicated charger. A port detected as standard or charging downstream
+      port may be limited further.
 
   summit,charge-current-compensation-microamp:
     description: Charge current compensation (in uA)

-- 
2.56.1

