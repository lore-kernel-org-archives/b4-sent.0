From: Vasiliy Doylov <nekodevelopper@gmail.com>
Date: Sun, 12 Jan 2025 15:06:02 +0300
Subject: [PATCH v2 1/5] dt-bindings: iio: accel: mc3230: document mc3510c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250112-mainlining-mc3510c-v2-1-322804a545cf@gmail.com>
References: <20250112-mainlining-mc3510c-v2-0-322804a545cf@gmail.com>
In-Reply-To: <20250112-mainlining-mc3510c-v2-0-322804a545cf@gmail.com>
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
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNKbN2jxT9hxW2Q3S+P0vDNTAoSmscfsvfgq3Mp9UsHV/
 bHiUjO7O0pZGMS4GGTFFFlsNnrMFssPl5w07akCzBxWJpAhDFycAjCR2CWMDGdZtxpInSyyZ/s/
 d2v4Bpf81z2PV1+L4tOSO5wf4PasI4bhf+6CmzxLvVssmj/NDVZqajAubV9z+szFj5nTXNPV2X+
 y8AIA
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

