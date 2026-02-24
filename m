From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 24 Feb 2026 11:00:50 +0530
Subject: [PATCH v5 4/9] dt-bindings: serial: Document the graph port
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260224-pci-m2-e-v5-4-dd9b9501d33c@oss.qualcomm.com>
References: <20260224-pci-m2-e-v5-0-dd9b9501d33c@oss.qualcomm.com>
In-Reply-To: <20260224-pci-m2-e-v5-0-dd9b9501d33c@oss.qualcomm.com>
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, 
 "Derek J. Clark" <derekjohn.clark@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-acpi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Hans de Goede <johannes.goede@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1136;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=GL3e+NsnxRKZAnbhCXHzDHMKMZEirA8W+47KdhQACxY=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYsica96h277e1mjKV56q0/LmB3awLD5x31z57eMMbc09s
 +cJXKgp7GQ0ZmFg5GKQFVNkSV/qrNXocfrGkgj16TCDWJlApjBwcQrARO5pcTA0eZTuv7x4Q2bn
 uqCt8enKuUzNLMv5LoWutl67SpRndqlnBrvSg7qeLvN+eQ6Vh+8+fNu+hyF/lpPATPUyluu+ZzV
 deabMr3vRf/Ful1XgnoYH936r7N6js910QZeVgFyGXVi3k2NYPu/35qLQkIcv5dR8FJXv/1aUNW
 BLeO9uImTs5BIdlDqt5buX7uEwLaE1uzhLJzyuDH4npOhxulcl9Zq9VP+NDHVT2cIJpSEdzUHTC
 g+LsduJmzK56xxNEZxfdoilPP5jesIGRvuvMcr7U6c/VFf+pPFz0ZGdxw5rbXfOZN91zv+2Y+ih
 I58qmg+6Cdic/5k8jVfP8YJWxtrsuR5qcz1/KjFLyP4AAA==
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A serial controller could be connected to an external connector like PCIe
M.2 for controlling the serial interface of the card. Hence, document the
OF graph port.

Tested-by: Hans de Goede <johannes.goede@oss.qualcomm.com> # ThinkPad T14s gen6 (arm64)
Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/serial/serial.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/serial/serial.yaml b/Documentation/devicetree/bindings/serial/serial.yaml
index 6aa9cfae417b..96eb1de8771e 100644
--- a/Documentation/devicetree/bindings/serial/serial.yaml
+++ b/Documentation/devicetree/bindings/serial/serial.yaml
@@ -87,6 +87,9 @@ properties:
     description:
       TX FIFO threshold configuration (in bytes).
 
+  port:
+    $ref: /schemas/graph.yaml#/properties/port
+
 patternProperties:
   "^(bluetooth|bluetooth-gnss|embedded-controller|gnss|gps|mcu|onewire)$":
     if:

-- 
2.51.0

