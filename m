From: Mizuno Miotsuki <founder@crepuse.com>
Date: Tue, 13 Oct 2026 23:04:20 +0800
Subject: [PATCH v4 1/3] dt-bindings: vendor-prefixes: add Nsiway
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-review-self-ns2009-v4-20261013-v4-1-98bb21712282@crepuse.com>
References: <20261013-review-self-ns2009-v4-20261013-v4-0-98bb21712282@crepuse.com>
In-Reply-To: <20261013-review-self-ns2009-v4-20261013-v4-0-98bb21712282@crepuse.com>
To: dmitry.torokhov@gmail.com
Cc: linux-input@vger.kernel.org, icenowy@aosc.io, 
 linux-kernel@vger.kernel.org, krzk+dt@kernel.org, conor+dt@kernel.org, 
 robh@kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=918; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=WXZF/+u+SPxCj0mvhT/nD0fF7Smil0RflWNMJKJzf6A=;
 b=owGbwMvMwCUmds2G2fVJ/hLG02pJDFnnPEqmZPht1crXz/zcLGRUfPxi2eNngWsTvSITlxptl
 jC58/5ux0QWBjEuBksxRZbZouzlh5pXXJs7ockOZg4rE8gQaZEGBiBgYeDLTcwrNdIx0jPVNtQz
 NNIx0DFm4OIUgKkOFmBk+P56juGjN0q/sj4EmzIfOZC8+ULI1ptKolMa2Nda+iQp1TL8L1jsV5Z
 0W3nOvEK+3uYAja8uYq+3qFdnFbvdiefMsS7gBwA=
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

