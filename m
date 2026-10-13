From: Mizuno Miotsuki <founder@crepuse.com>
Date: Wed, 14 Oct 2026 06:45:09 +0800
Subject: [PATCH v5 1/3] dt-bindings: vendor-prefixes: add Nsiway
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-review-self-ns2009-v4-20261013-v5-1-0851740cd939@crepuse.com>
References: <20261014-review-self-ns2009-v4-20261013-v5-0-0851740cd939@crepuse.com>
In-Reply-To: <20261014-review-self-ns2009-v4-20261013-v5-0-0851740cd939@crepuse.com>
To: dmitry.torokhov@gmail.com
Cc: krzk+dt@kernel.org, linux-input@vger.kernel.org, 
 linux-kernel@vger.kernel.org, icenowy@aosc.io, conor+dt@kernel.org, 
 robh@kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=918; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=WXZF/+u+SPxCj0mvhT/nD0fF7Smil0RflWNMJKJzf6A=;
 b=owGbwMvMwCUmds2G2fVJ/hLG02pJDFnntpRdmvg+7J367zwvy2V3ttRZzvLW2D1bf3HhlMnfd
 7K2Hjou2zGRhUGMi8FSTJFltih7+aHmFdfmTmiyg5nDygQyRFqkgQEIWBj4chPzSo10jPRMtQ31
 DI10DHSMGbg4BWCq91YxMnyWeytvNk9vJ0f2pIfZwU2rPjxawfLo7K/P7nf8pobMtnvGyNDBeVK
 iik/DfN7ElNWMHHGZcx+WzmGf+upHJcOjzuur5zECAA==
X-Developer-Key: i=founder@crepuse.com; a=openpgp;
 fpr=9B150777C283A8D69D90823E16D63C0345E46FA4
X-Endpoint-Received: by B4 Relay for founder@crepuse.com/20261012 with auth_id=1166
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Nsiway manufactures the NS2009 I2C resistive touchscreen controller.
Add its vendor prefix for the touchscreen binding.

Signed-off-by: Mizuno Miotsuki <founder@crepuse.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index ba2002969373..a180012054c9 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1214,6 +1214,8 @@ patternProperties:
     description: Novatek
   "^novtech,.*":
     description: NovTech, Inc.
+  "^nsiway,.*":
+    description: Shenzhen Nsiway Technology Co., Ltd.
   "^nuclei,.*":
     description: Nuclei System Technology
   "^numonyx,.*":

-- 
2.56.0

