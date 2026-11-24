From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Tue, 24 Nov 2026 18:43:01 +0100
Subject: [PATCH 2/4] dt-bindings: vendor-prefixes: Add Fingerprint Cards AB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-fpc1540-tee-v1-2-6c6985f05b06@proton.me>
References: <20261124-fpc1540-tee-v1-0-6c6985f05b06@proton.me>
In-Reply-To: <20261124-fpc1540-tee-v1-0-6c6985f05b06@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795542180; l=802;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=bb1E4uO7yTmae2IdZoOdJAzIoFi+Onctna6tkTmtNX4=;
 b=IF4dBQyJ2xQca/bjfj3E9mICaY7LIC9mawwx/9jbS+KZ9Sh7CHqidQKi9qdqtWPeJ9WMzSYsa
 Xf+Jj9DMJKUAQenRokC+lCdW6mnLcjoJ1ulQNQBJRxcUDzJQwWF+e/C
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the vendor prefix for Fingerprint Cards AB.

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 5471a06f93f1..f0153a5f0687 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -628,6 +628,8 @@ patternProperties:
     description: Shanghai FourSemi Semiconductor Co.,Ltd.
   "^foxlink,.*":
     description: Foxlink Group
+  "^fpc,.*":
+    description: Fingerprint Cards AB
   "^freebox,.*":
     description: Freebox SAS
   "^freecom,.*":

-- 
2.56.0

