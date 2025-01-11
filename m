From: Vasiliy Doylov <nekodevelopper@gmail.com>
Date: Sat, 11 Jan 2025 23:11:09 +0300
Subject: [PATCH 4/4] dt-bindings: iio: accel: mc3230: document mc3510c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250111-mainlining-mc3510c-v1-4-57be503addf8@gmail.com>
References: <20250111-mainlining-mc3510c-v1-0-57be503addf8@gmail.com>
In-Reply-To: <20250111-mainlining-mc3510c-v1-0-57be503addf8@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1060;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=kKqPGqcAMrV8Q/3yZlxILQP7a1DF7juDcij9I0w4AmM=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNKbLsRsbOf57LUpY1Gc8NOvEnNuVggs/qV4PsKL5f6mi
 bJqZisPdpSyMIhxMciKKbLYbPSYLZYfLjlp2lMFmDmsTCBDGLg4BWAiEQyMDC8Z1PhlP+yUbotb
 ZJYgo3bTQ3CiooDiZnc/211fAuXEtBgZ5gkvzPVpmpmaxx9378CsxprO5XYrJtXcUbP9OOt9h0I
 WGwA=
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MC3510C is a 3 asix digital accelerometer.
It handled by the same driver as MC3230.
Document it as a trivial device.

Signed-off-by: Vasiliy Doylov <nekodevelopper@gmail.com>
---
 Documentation/devicetree/bindings/trivial-devices.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index fadbd3c041c8c39faedfe62874d4eba25a0bf30e..6c34e4c0dcc6df5a4d8edc5effb80980de820db9 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -187,6 +187,8 @@ properties:
           - maxim,max6621
             # mCube 3-axis 8-bit digital accelerometer
           - mcube,mc3230
+            # mCube 3-axis 8-bit digital accelerometer
+          - mcube,mc3510c
             # Measurement Specialities I2C temperature and humidity sensor
           - meas,htu21
             # Measurement Specialities I2C pressure and temperature sensor

-- 
2.47.1

