From: Vasiliy Doylov <nekocwd@mainlining.org>
Date: Wed, 25 Mar 2026 01:15:01 +0300
Subject: [PATCH v4 3/3] MAINTAINERS: Add entry for Onsemi LC898217XC lens
 voice coil driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-media-i2c-lc898217xc-initial-driver-v4-3-6ad6fd74915e@mainlining.org>
References: <20260325-media-i2c-lc898217xc-initial-driver-v4-0-6ad6fd74915e@mainlining.org>
In-Reply-To: <20260325-media-i2c-lc898217xc-initial-driver-v4-0-6ad6fd74915e@mainlining.org>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, david@ixit.cz
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Antonio Rische <nt8r@protonmail.com>, 
 Vasiliy Doylov <nekocwd@mainlining.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=790; i=nekocwd@mainlining.org;
 h=from:subject:message-id; bh=Eo9bvXngPWC2RV/8gKjXFNTG4Tj+h2xSlMxai/WWYLE=;
 b=owGbwMvMwCVmXFbadLHr1XTG02pJDJmHeZ4ITU5akp/LM9/n+M0dnHXvi+dMkWzYttPa4dB1H
 t1/Ih9zOkpZGMS4GGTFFFm63x++92AeL2up+idemDmsTCBDGLg4BWAi9U0M/+vSi72OeM2I7HDO
 deEtF/ndW3p/lf290JSmAq3WleKfDjAyHFwh8vJ6/1HpZ01M+5xP/s/9p1JyLdSSw8SsXiJn0XE
 uZgA=
X-Developer-Key: i=nekocwd@mainlining.org; a=openpgp;
 fpr=8BEFC3DEE09E0D057527F20D33767582D18AEA97
X-Endpoint-Received: by B4 Relay for nekocwd@mainlining.org/default with auth_id=692
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add entry for Onsemi LC898217XC lens voice coil driver

Signed-off-by: Vasiliy Doylov <nekocwd@mainlining.org>
---
 MAINTAINERS | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index e61b4abb95fc..08ace2642f36 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -19817,6 +19817,13 @@ S:	Supported
 W:	http://www.onsemi.com
 F:	drivers/net/phy/ncn*
 
+ONSEMI LC898217XC LENS VOICE COIL DRIVER
+M:	Vasiliy Doylov <nekocwd@mainlining.org>
+L:	linux-media@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/media/i2c/onnn,lc898217xc.yaml
+F:	drivers/media/i2c/lc898217xc.c
+
 OP-TEE DRIVER
 M:	Jens Wiklander <jens.wiklander@linaro.org>
 L:	op-tee@lists.trustedfirmware.org (moderated for non-subscribers)

-- 
2.50.1

