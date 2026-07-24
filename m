From: Andy Chung <Andy.Chung@amd.com>
Date: Fri, 24 Jul 2026 12:47:37 +0800
Subject: [PATCH v5 1/4] dt-bindings: Add vendor prefix for Kandou
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-kb9002-upstream-v5-1-9523c3ffe83a@amd.com>
References: <20260724-kb9002-upstream-v5-0-9523c3ffe83a@amd.com>
In-Reply-To: <20260724-kb9002-upstream-v5-0-9523c3ffe83a@amd.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Chung <andy.chung@amd.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784868474; l=775;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=q6TvzAvTe0szhLuDvDe9XDITXcBW5NjI89sOlniXt5M=;
 b=11G7/VUAkr34ZtgHlsoDDFb3idgC7ua5yzhFpeKzY2Huq5neZ63cBehfoZgKXIuzATU8AIsPz
 zbaXpf/WX/lCr+qunAyyLkb6LEhuc3N7McvpNQYUTsY8vFXT0nq4qtQ
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kandou AI is the vendor of the KB9002 PCIe retimer.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 396044f368e7..224b60686703 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -879,6 +879,8 @@ patternProperties:
     description: JuTouch Technology Co., Ltd.
   "^kam,.*":
     description: Kamstrup A/S
+  "^kandou,.*":
+    description: Kandou AI
   "^karo,.*":
     description: Ka-Ro electronics GmbH
   "^keithkoep,.*":

-- 
2.34.1

