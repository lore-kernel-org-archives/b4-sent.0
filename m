From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 10 Jan 2026 12:26:29 +0530
Subject: [PATCH v3 11/14] dt-bindings: connector: m2: Add M.2 1620 LGA
 soldered down connector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260110-pci-m2-e-v3-11-4faee7d0d5ae@oss.qualcomm.com>
References: <20260110-pci-m2-e-v3-0-4faee7d0d5ae@oss.qualcomm.com>
In-Reply-To: <20260110-pci-m2-e-v3-0-4faee7d0d5ae@oss.qualcomm.com>
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
 Daniel Scally <djrscally@gmail.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-acpi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1302;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=RWekJdEKdic9EZu4rQGv0fBKORumjbEDCuN8SBTLMc4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpYfg+TRCoMWdJ2WYv0cU3v57JOA3eOkhRvc9NM
 QkwIwf2HymJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWH4PgAKCRBVnxHm/pHO
 9bSxCACn3aeHjikwTH34ED8GMiwZYePyUD6dpLxapg7iDk895cVBZ1IZOGZcvaOvrNc+F1Koz76
 PsxffieAiZaRoIL3PpDMyaQ49vZ+W/mecd7Q9MmnEPWcU7PF45xDGYGwcU9173vd6GbHICVxJ7a
 SHWSjXXiP8m3Jmu53tOznAuVAz2qfsbzn0TS3YlhlGRHhi96AmM2hux0doiV1dd0iF40NAEYwXd
 +n+dmeVZ2v8xXKF0GOHEzBlhU64ECcqKroJegmOdLcwwUdESsfpJS1GPP2IBN8jngvWuLIBasEn
 LSrsJ1XW1MpT922zo4+84wcVpbNDhq+/x0oz6xMM3qWWq2Y/
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Lenovo Thinkpad T14s is found to have a soldered down version of M.2 1620
LGA connector. Though, there is no 1620 LGA form factor defined in the M.2
spec, it looks very similar to the M.2 Key M connector. So add the
"pcie-m2-1620-lga-connector" compatible with "pcie-m2-e-connector" fallback
to reuse the Key M binding.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 .../devicetree/bindings/connector/pcie-m2-e-connector.yaml       | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/connector/pcie-m2-e-connector.yaml b/Documentation/devicetree/bindings/connector/pcie-m2-e-connector.yaml
index b65b39ddfd19..9757fe92907b 100644
--- a/Documentation/devicetree/bindings/connector/pcie-m2-e-connector.yaml
+++ b/Documentation/devicetree/bindings/connector/pcie-m2-e-connector.yaml
@@ -17,7 +17,14 @@ description:
 
 properties:
   compatible:
-    const: pcie-m2-e-connector
+    oneOf:
+      - items:
+          - enum:
+              - pcie-m2-1620-lga-connector
+          - const: pcie-m2-e-connector
+      - items:
+          - enum:
+              - pcie-m2-e-connector
 
   vpcie3v3-supply:
     description: A phandle to the regulator for 3.3v supply.

-- 
2.48.1

