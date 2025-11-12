From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 12 Nov 2025 20:15:19 +0530
Subject: [PATCH 7/9] dt-bindings: connector: Add PCIe M.2 Mechanical Key E
 connector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251112-pci-m2-e-v1-7-97413d6bf824@oss.qualcomm.com>
References: <20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com>
In-Reply-To: <20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com>
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
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7404;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=s83ZX+5+i5VDAPG771sdizpD1jqft8fr1qXw80NJhok=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpFJ2HAPeWlv7bxfpUlwZrq2eqL3B2nVw3qpmIH
 bgfv2cgTneJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaRSdhwAKCRBVnxHm/pHO
 9e5yB/9c2QjpAQ2X7j7qFmJw54Xgp6/fZhxz1XrqzykT4/6U2xPB6br5UlaEPsdYY0S4tWN/rNl
 Bdh8O/MXRVpNH62jeumxFECbruUSWlZZcRy7RGtJLF32xcF9yKdeKtWrogWd6BiSL8uIlb2EdK7
 Bqyv6K8PCaXmjL6LiY9JD3szgTVH/VGJBbt4n31cboa4/e+yToAKTrpy+ssx0JWtPAq5G2ZObTU
 U3vttxrc9umk6WzybukzRadJai0JEpfc6RMsU8SJ8481FmJsw1e73JPioel5ZnHNOf0cV5bVjS4
 D2+lpTm6sXpYBVRfip9vTMlEH7j+N3GAznvKmzDctuXFnnou
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the devicetree binding for PCIe M.2 Mechanical Key E connector defined
in the PCI Express M.2 Specification, r4.0, sec 5.1.2. This connector
provides interfaces like PCIe or SDIO to attach the WiFi devices to the
host machine, USB or UART+PCM interfaces to attach the Bluetooth (BT)
devices along with additional interfaces like I2C for NFC solution. At any
point of time, the connector can only support either PCIe or SDIO as the
WiFi interface and USB or UART as the BT interface.

The connector provides a primary power supply of 3.3v, along with an
optional 1.8v VIO supply for the Adapter I/O buffer circuitry operating at
1.8v sideband signaling.

The connector also supplies optional signals in the form of GPIOs for fine
grained power management.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 .../bindings/connector/pcie-m2-e-connector.yaml    | 154 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 155 insertions(+)

diff --git a/Documentation/devicetree/bindings/connector/pcie-m2-e-connector.yaml b/Documentation/devicetree/bindings/connector/pcie-m2-e-connector.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..91cb56b1a75b7e3de3b9fe9a7537089f96875746
--- /dev/null
+++ b/Documentation/devicetree/bindings/connector/pcie-m2-e-connector.yaml
@@ -0,0 +1,154 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/connector/pcie-m2-e-connector.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: PCIe M.2 Mechanical Key E Connector
+
+maintainers:
+  - Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
+
+description:
+  A PCIe M.2 E connector node represents a physical PCIe M.2 Mechanical Key E
+  connector. Mechanical Key E connectors are used to connect Wireless
+  Connectivity devices including combinations of Wi-Fi, BT, NFC to the host
+  machine over interfaces like PCIe/SDIO, USB/UART+PCM, and I2C.
+
+properties:
+  compatible:
+    const: pcie-m2-e-connector
+
+  vpcie3v3-supply:
+    description: A phandle to the regulator for 3.3v supply.
+
+  vpcie1v8-supply:
+    description: A phandle to the regulator for VIO 1.8v supply.
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+    description: OF graph bindings modeling the interfaces exposed on the
+      connector. Since a single connector can have multiple interfaces, every
+      interface has an assigned OF graph port number as described below.
+
+    properties:
+      port@0:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: PCIe/SDIO interface
+
+      port@1:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: USB 2.0/UART interface
+
+      port@2:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: PCM/I2S interface
+
+      port@3:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: I2C interface
+
+    oneOf:
+      - required:
+          - port@0
+
+  clocks:
+    description: 32.768 KHz Suspend Clock (SUSCLK) input from the host system to
+      the M.2 card. Refer, PCI Express M.2 Specification r4.0, sec 3.1.12.1 for
+      more details.
+    maxItems: 1
+
+  w_disable1-gpios:
+    description: GPIO controlled connection to W_DISABLE1# signal. This signal
+      is used by the system to disable WiFi radio in the M.2 card. Refer, PCI
+      Express M.2 Specification r4.0, sec 3.1.12.3 for more details.
+    maxItems: 1
+
+  w_disable2-gpios:
+    description: GPIO controlled connection to W_DISABLE2# signal. This signal
+      is used by the system to disable BT radio in the M.2 card. Refer, PCI
+      Express M.2 Specification r4.0, sec 3.1.12.3 for more details.
+    maxItems: 1
+
+  led1-gpios:
+    description: GPIO controlled connection to LED_1# signal. This signal is
+      used by the M.2 card to indicate the card status via the system mounted
+      LED. Refer, PCI Express M.2 Specification r4.0, sec 3.1.12.2 for more
+      details.
+    maxItems: 1
+
+  led2-gpios:
+    description: GPIO controlled connection to LED_2# signal. This signal is
+      used by the M.2 card to indicate the card status via the system mounted
+      LED. Refer, PCI Express M.2 Specification r4.0, sec 3.1.12.2 for more
+      details.
+    maxItems: 1
+
+  viocfg-gpios:
+    description: GPIO controlled connection to IO voltage configuration
+      (VIO_CFG) signal. This signal is used by the M.2 card to indicate to the
+      host system that the card supports an independent IO voltage domain for
+      the sideband signals. Refer, PCI Express M.2 Specification r4.0, sec
+      3.1.15.1 for more details.
+    maxItems: 1
+
+  uim_power_src-gpios:
+    description: GPIO controlled connection to UIM_POWER_SRC signal. This signal
+      is used when the NFC solution is implemented and receives the power output
+      from WWAN_UIM_PWR signal of the another WWAN M.2 card. Refer, PCI Express
+      M.2 Specification r4.0, sec 3.1.11.1 for more details.
+    maxItems: 1
+
+  uim_power_snk-gpios:
+    description: GPIO controlled connection to UIM_POWER_SNK signal. This signal
+      is used when the NFC solution is implemented and supplies power to the
+      Universal Integrated Circuit Card (UICC). Refer, PCI Express M.2
+      Specification r4.0, sec 3.1.11.2 for more details.
+    maxItems: 1
+
+  uim_swp-gpios:
+    description: GPIO controlled connection to UIM_SWP signal. This signal is
+      used when the NFC solution is implemented and implements the Single Wire
+      Protocol (SWP) interface to the UICC. Refer, PCI Express M.2 Specification
+      r4.0, sec 3.1.11.3 for more details.
+    maxItems: 1
+
+required:
+  - compatible
+  - vpcie3v3-supply
+
+additionalProperties: false
+
+examples:
+  # PCI M.2 Key E connector for WLAN/BT with PCIe/UART interfaces
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    connector {
+        compatible = "pcie-m2-e-connector";
+        vpcie3v3-supply = <&vreg_wcn_3p3>;
+        vpcie1v8-supply = <&vreg_l15b_1p8>;
+        w_disable1-gpios = <&tlmm 117 GPIO_ACTIVE_LOW>;
+        w_disable2-gpios = <&tlmm 116 GPIO_ACTIVE_LOW>;
+
+        ports {
+            #address-cells = <1>;
+            #size-cells = <0>;
+
+            port@0 {
+                reg = <0>;
+
+                endpoint {
+                    remote-endpoint = <&pcie4_port0_ep>;
+                };
+            };
+
+            port@3 {
+                reg = <3>;
+
+                endpoint {
+                    remote-endpoint = <&uart14_ep>;
+                };
+            };
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 9b3f689d1f50c62afa3772a0c6802f99a98ac2de..f707f29d0a37f344d8dd061b7e49dbb807933c9f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -20478,6 +20478,7 @@ PCIE M.2 POWER SEQUENCING
 M:	Manivannan Sadhasivam <mani@kernel.org>
 L:	linux-pci@vger.kernel.org
 S:	Maintained
+F:	Documentation/devicetree/bindings/connector/pcie-m2-e-connector.yaml
 F:	Documentation/devicetree/bindings/connector/pcie-m2-m-connector.yaml
 F:	drivers/power/sequencing/pwrseq-pcie-m2.c
 

-- 
2.48.1

