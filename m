From: Andy Chung <Andy.Chung@amd.com>
Date: Tue, 21 Jul 2026 14:31:32 +0800
Subject: [PATCH v3 1/4] dt-bindings: Add vendor prefix for Kandou
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260721-kb9002-upstream-v3-1-70563922be8d@amd.com>
References: <20260721-kb9002-upstream-v3-0-70563922be8d@amd.com>
In-Reply-To: <20260721-kb9002-upstream-v3-0-70563922be8d@amd.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Chung <andy.chung@amd.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784615506; l=789;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=3lNslbOQdXYZMYDoyDnFtx7x1pZDPtfgEkyZivjTfbY=;
 b=cVJXoQgL+20qL0b5gsAGWZ3YQVRFpuaE2kyLpHSo+GfASJD30FrHzrZYg/iTbyn+MIbf07Eo9
 gQY40mfJ7jiCZQmd9UBroDG+T6pfREx7cc3Dn8l3KPFY/uWDl0iwD7v
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kandou Bus, S.A. is the vendor of the KB9002 PCIe retimer.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 396044f368e7..727871970d97 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -879,6 +879,8 @@ patternProperties:
     description: JuTouch Technology Co., Ltd.
   "^kam,.*":
     description: Kamstrup A/S
+  "^kandou,.*":
+    description: Kandou Bus, S.A.
   "^karo,.*":
     description: Ka-Ro electronics GmbH
   "^keithkoep,.*":

-- 
2.34.1

