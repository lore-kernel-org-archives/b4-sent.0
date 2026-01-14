From: Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
Date: Wed, 14 Jan 2026 16:03:24 +0530
Subject: [PATCH v2 1/2] ASoC: dt-bindings: document dvdd-supply property
 for awinic,aw88261
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260114-aw88261-dvdd-v2-1-ef485b82a7a7@machinesoul.in>
References: <20260114-aw88261-dvdd-v2-0-ef485b82a7a7@machinesoul.in>
In-Reply-To: <20260114-aw88261-dvdd-v2-0-ef485b82a7a7@machinesoul.in>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Weidong Wang <wangweidong.a@awinic.com>
Cc: Bhushan Shah <bhushan.shah@machinesoul.in>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768386804; l=1347;
 i=bharadwaj.raju@machinesoul.in; s=20260111; h=from:subject:message-id;
 bh=ytR+KVyf/ePc8ymcKGXV0QZMqpvAJw8hDP+6Qezgv+4=;
 b=FzKAImxPg3NqbTQ0C4Kf35xzU8OrTOeaM3al7ov8KZQXNIk/mrJOsAcYDPDrCzgvHYR05paM5
 GJwlIPfjo1SD3LJ8W4IM94SqXch/LjSVTc5UzzWumexHz8JEiK9ZUxj
X-Developer-Key: i=bharadwaj.raju@machinesoul.in; a=ed25519;
 pk=0M1a+iMXDqasbx7bQL71NdtuutFXu+lVxsiSnEiyAIg=
X-Endpoint-Received: by B4 Relay for bharadwaj.raju@machinesoul.in/20260111 with auth_id=598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add (and require) the dvdd-supply property for awinic,aw88261 in
the awinic,aw88395.yaml binding.

The chip needs DVDD to power on, and currently there are no users of
this compatible in the kernel device trees, so we should be fine to
change the ABI in this case.

Signed-off-by: Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
---
 Documentation/devicetree/bindings/sound/awinic,aw88395.yaml | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/awinic,aw88395.yaml b/Documentation/devicetree/bindings/sound/awinic,aw88395.yaml
index bb92d6ca3144..994d68c074a9 100644
--- a/Documentation/devicetree/bindings/sound/awinic,aw88395.yaml
+++ b/Documentation/devicetree/bindings/sound/awinic,aw88395.yaml
@@ -33,6 +33,8 @@ properties:
   reset-gpios:
     maxItems: 1
 
+  dvdd-supply: true
+
   awinic,audio-channel:
     description:
       It is used to distinguish multiple PA devices, so that different
@@ -65,6 +67,17 @@ allOf:
     then:
       properties:
         reset-gpios: false
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: awinic,aw88261
+    then:
+      required:
+        - dvdd-supply
+    else:
+      properties:
+        dvdd-supply: false
 
 unevaluatedProperties: false
 

-- 
2.43.0

