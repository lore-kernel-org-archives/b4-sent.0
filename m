From: Vishwas Rajashekar <vishwas.dev@vrajashkr.com>
Date: Wed, 15 Apr 2026 21:13:40 +0530
Subject: [PATCH] dt-bindings: iio: gyroscope: add mount-matrix for bmg160
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260415-bmg160-mount-matrix-dt-binding-v1-1-0e2c85964ee6@vrajashkr.com>
X-B4-Tracking: v=1; b=H4sIACuy32kC/yXNTQqDMBBA4avIrDuQSEh/rlK6MM6YTiFjSWIRx
 Ls3tctv894GhbNwgVu3QeaPFJm1wZ46GJ+DRkahZuhN742zDkOK1htM86IV01CzrEgVgyiJRuS
 zJyK+uov30CLvzJOsx+D++Lss4cVj/VVh37+XPsTsggAAAA==
X-Change-ID: 20260414-bmg160-mount-matrix-dt-binding-e76ddde94866
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 "H. Nikolaus Schaller" <hns@goldelico.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, luca@lucaweiss.eu, 
 Vishwas Rajashekar <vishwas.dev@vrajashkr.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776267845; l=1356;
 i=vishwas.dev@vrajashkr.com; s=20260414; h=from:subject:message-id;
 bh=pcuRd/qLKaTlnrY5W5w/EZ94X8GzaogVmcptT8JzSSA=;
 b=uQx0SBFlnI+dg9jmGonNeL4eQ04Ym5InA6iB5YcWxwwhTuTMW8gSv+WrnBJbd7/TmVL0K9hZt
 9XlHHMTbG3dBXOZ3w1Z7qBCYe2NFkOuziTT7kXTkNz+b18VC+wwryLj
X-Developer-Key: i=vishwas.dev@vrajashkr.com; a=ed25519;
 pk=OvZgoGVJ7ofrIn3w/YijdoJ0IexAy1kREY51mGZPm9M=
X-Endpoint-Received: by B4 Relay for vishwas.dev@vrajashkr.com/20260414 with auth_id=734
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds mount-matrix as an optional property to dt-bindings
for the bmg160 gyroscope as the driver reads this optional
property during probe.

Signed-off-by: Vishwas Rajashekar <vishwas.dev@vrajashkr.com>
---
The bmg160 driver reads an optional mount-matrix using
"iio_read_mount_matrix" in "bmg160_core_probe" and stores
this orientation data in "struct bmg160_data". As the "mount-matrix"
property is used by the driver, this change proposes to add it to
the corresponding dt-bindings.
---
 Documentation/devicetree/bindings/iio/gyroscope/bosch,bmg160.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/gyroscope/bosch,bmg160.yaml b/Documentation/devicetree/bindings/iio/gyroscope/bosch,bmg160.yaml
index 3c6fe74af0b8..ea8689660adf 100644
--- a/Documentation/devicetree/bindings/iio/gyroscope/bosch,bmg160.yaml
+++ b/Documentation/devicetree/bindings/iio/gyroscope/bosch,bmg160.yaml
@@ -22,6 +22,9 @@ properties:
   vdd-supply: true
   vddio-supply: true
 
+  mount-matrix:
+    description: an optional 3x3 mounting rotation matrix.
+
   spi-max-frequency:
     maximum: 10000000
 

---
base-commit: 591cd656a1bf5ea94a222af5ef2ee76df029c1d2
change-id: 20260414-bmg160-mount-matrix-dt-binding-e76ddde94866

Best regards,
--  
Vishwas Rajashekar <vishwas.dev@vrajashkr.com>

