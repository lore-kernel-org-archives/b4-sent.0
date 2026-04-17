From: Vishwas Rajashekar <vishwas.dev@vrajashkr.com>
Date: Sat, 18 Apr 2026 00:11:09 +0530
Subject: [PATCH v3] dt-bindings: iio: gyroscope: add mount-matrix for
 bmg160
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260418-bmg160-mount-matrix-dt-binding-v3-1-ce8020ecbf9a@vrajashkr.com>
X-B4-Tracking: v=1; b=H4sIAMR+4mkC/4WOQQ6CMBBFr0K6dgytMIIr72FcQDvAaCimLQ3Gc
 HdBY2LcuHzJz3v/ITw5Ji8OyUM4iux5sAvsNonQXWVbAjYLC5UqTDOZQd23ElPoh9EG6KvgeAI
 ToGZr2LZAezTGUJkViGKR3Bw1PL0Cp/Ob/VhfSIfVui469mFw99eDKNfdJ5b/i0UJElJSushLz
 IjwGF11qXx3dVs99GINRvWtxL9KtSgJUTe5bpqCil/lPM9PO6E29TUBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776451286; l=2793;
 i=vishwas.dev@vrajashkr.com; s=20260414; h=from:subject:message-id;
 bh=0hFO4pVSk29VQGp7JRnLEM4OixgjM26nPl8qocDmLp8=;
 b=mT7mV223BgKj7ZWEZJn3VqZ2EIir63jVXxPLfx9vXSf2O8OgVVd6O+ftcBRxN7lLdJ6rW/9m6
 HAHcRbKh0a2DmtX84n4DqNiVFG1X2kkMLKNkkGdrz7hEVDB2w3tf85Q
X-Developer-Key: i=vishwas.dev@vrajashkr.com; a=ed25519;
 pk=OvZgoGVJ7ofrIn3w/YijdoJ0IexAy1kREY51mGZPm9M=
X-Endpoint-Received: by B4 Relay for vishwas.dev@vrajashkr.com/20260414 with auth_id=734
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mount-matrix property supplies a 3x3 matrix that is used
to transform the values from the gyroscope to get vector
values that are relative to the way the sensor has been mounted
on the device. When the property is not specified, the identity
matrix is used.

This change adds mount-matrix as an optional property to the
dt-bindings for the bmg160 gyroscope.

Signed-off-by: Vishwas Rajashekar <vishwas.dev@vrajashkr.com>
---
The bmg160 driver reads an optional mount-matrix using
"iio_read_mount_matrix" in "bmg160_core_probe" and stores
this orientation data in "struct bmg160_data". As the "mount-matrix"
property is used by the driver, this change proposes to add it to
the corresponding dt-bindings.
---
Changes in v3:
- Addressed review feedback: updated the commit message to indicate
  relevance to hardware and remove references to the Linux driver.
- Link to v2: https://patch.msgid.link/20260416-bmg160-mount-matrix-dt-binding-v2-1-e66cf5cff8e8@vrajashkr.com

Changes in v2:
- Addressed review feedback: add mount-matrix example for bmg160
- Link to v1: https://patch.msgid.link/20260415-bmg160-mount-matrix-dt-binding-v1-1-0e2c85964ee6@vrajashkr.com

To: Jonathan Cameron <jic23@kernel.org>
To: David Lechner <dlechner@baylibre.com>
To: Nuno Sá <nuno.sa@analog.com>
To: Andy Shevchenko <andy@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: "H. Nikolaus Schaller" <hns@goldelico.com>
Cc: linux-iio@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 Documentation/devicetree/bindings/iio/gyroscope/bosch,bmg160.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/gyroscope/bosch,bmg160.yaml b/Documentation/devicetree/bindings/iio/gyroscope/bosch,bmg160.yaml
index 3c6fe74af0b8..ec97778cca78 100644
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
 
@@ -52,6 +55,9 @@ examples:
             reg = <0x69>;
             interrupt-parent = <&gpio6>;
             interrupts = <18 IRQ_TYPE_EDGE_RISING>;
+            mount-matrix = "0", "1", "0",
+                           "1", "0", "0",
+                           "0", "0", "1";
         };
     };
 ...

---
base-commit: 591cd656a1bf5ea94a222af5ef2ee76df029c1d2
change-id: 20260414-bmg160-mount-matrix-dt-binding-e76ddde94866

Best regards,
--  
Vishwas Rajashekar <vishwas.dev@vrajashkr.com>

