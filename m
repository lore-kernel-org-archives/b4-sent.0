From: Vasiliy Doylov <nekocwd@mainlining.org>
Date: Sat, 11 Apr 2026 16:13:10 +0300
Subject: [PATCH v5 3/3] MAINTAINERS: Add entry for Onsemi LC898217XC lens
 voice coil driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260411-media-i2c-lc898217xc-initial-driver-v5-3-c71ddcf40bad@mainlining.org>
References: <20260411-media-i2c-lc898217xc-initial-driver-v5-0-c71ddcf40bad@mainlining.org>
In-Reply-To: <20260411-media-i2c-lc898217xc-initial-driver-v5-0-c71ddcf40bad@mainlining.org>
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
 h=from:subject:message-id; bh=47zPYZVQfTlmz5yR21UDZYEArwVIUE2fjhcCknakC2A=;
 b=owGbwMvMwCVmXFbadLHr1XTG02pJDJm3PF7oOn+d/NHi/3RJ+9A9a9JL/c280jTeRNv+Ph/a5
 3Yt8XlSRykLgxgXg6yYIkv3+8P3HszjZS1V/8QLM4eVCWQIAxenAEzkmRjDP6scCb98vyzG8vR1
 KWvLc+dx3kzbqsf9/e7S3EednySXejD8d5rBWuY5jT/2h2DlscC7d+J+M6slPRfd0xUyQ8328qH
 P/AA=
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
index d4b396dccfe9..a87c03ad740b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -19938,6 +19938,13 @@ S:	Supported
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

