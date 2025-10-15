From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 15 Oct 2025 15:52:19 +0100
Subject: [PATCH 1/3] dt-bindings: trivial-devices: add ADT7410, ADT7420 and
 ADT7422
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251015-dev-add-adt7422-v1-1-7cf72d3253ad@analog.com>
References: <20251015-dev-add-adt7422-v1-0-7cf72d3253ad@analog.com>
In-Reply-To: <20251015-dev-add-adt7422-v1-0-7cf72d3253ad@analog.com>
To: devicetree@vger.kernel.org, linux-hwmon@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760539940; l=1264;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=vofQw/rQ6b56oljOKSigkB7SRZD/pcZTXouUVgZJ6rk=;
 b=mnLk4naQnCqRbPazej4DF37wgL2ET3O7vHzSvSOuPiTl8DyF/3whe1oqS/OTF6VwDZwhNXaJM
 uJStHtKEidGBZm/Mqa7fzjDeeoETF+Jk2c4A8nOfOWzpnrscJNp5qye
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Analog Devices high accuracy digital temperature sensors to trivial
devices.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 Documentation/devicetree/bindings/trivial-devices.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index deccb119493e..884a071a1f14 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -43,8 +43,14 @@ properties:
           - adi,ad5110
             # Temperature sensor with integrated fan control
           - adi,adm1027
+            # Analog Devices ADT7410 High Accuracy Digital Temperature Sensor
+          - adi,adt7410
             # Analog Devices ADT7411 Temperature Sensor and 8-channel ADC
           - adi,adt7411
+            # Analog Devices ADT7420 High Accuracy Digital Temperature Sensor
+          - adi,adt7420
+            # Analog Devices ADT7422 High Accuracy Digital Temperature Sensor
+          - adi,adt7422
             # Temperature sensor with integrated fan control
           - adi,adt7463
             # Temperature sensor with integrated fan control

-- 
2.51.0

