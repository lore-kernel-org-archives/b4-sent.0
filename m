From: Vishwas Rajashekar <vishwas.dev@vrajashkr.com>
Date: Thu, 16 Apr 2026 20:33:21 +0530
Subject: [PATCH v2] dt-bindings: iio: gyroscope: add mount-matrix for
 bmg160
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260416-bmg160-mount-matrix-dt-binding-v2-1-e66cf5cff8e8@vrajashkr.com>
X-B4-Tracking: v=1; b=H4sIADj64GkC/4WOwQ6CMBAFf4X07BralAqe/A/DodAVFkNr2tJgC
 P8uYDx7nGTy5i0soCcM7JotzGOiQM5uIE4Za3ttOwQyGzORC5VLLqEZO65yGN1kI4w6eprBRGj
 IGrId4EUZY7CSpVJsG3l5fNB8BO71l8PUDNjGfXU3egrR+ffxIPHd+8WKf7HEgUOOoi2LSklEd
 UteDzr0T39u3cjqdV0/YT6KAuIAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776351838; l=2298;
 i=vishwas.dev@vrajashkr.com; s=20260414; h=from:subject:message-id;
 bh=qRb9CnV1TwnBxT50+KBIUXpmD3krYMm9jJ/eSLpyL4w=;
 b=3rJPFOLddnYeZ6nDRzDvfyekFvmCXMJ+FQJDwf7lncGsDgttqUVf5PNmHjbJoD146/VhjQ30t
 38st+cWJm2TAvCvFCuWJ20gZkDyctIHZeP6ZzDUsQWs5adzDWRK6HrI
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

