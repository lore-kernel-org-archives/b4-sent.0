From: Markus Probst <markus.probst@posteo.de>
Date: Sun, 29 Mar 2026 20:02:16 +0200
Subject: [PATCH v5 2/4] ACPI: of: match PRP0001 in of_match_device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260329-synology_microp_initial-v5-2-27cb80bdf591@posteo.de>
References: <20260329-synology_microp_initial-v5-0-27cb80bdf591@posteo.de>
In-Reply-To: <20260329-synology_microp_initial-v5-0-27cb80bdf591@posteo.de>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Saravana Kannan <saravanak@kernel.org>
Cc: platform-driver-x86@vger.kernel.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-acpi@vger.kernel.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3479;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=HMCBaJI1P1YqAkteFmwT2ODjJk1KjOq1Yh0ug86s1zs=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBpyWk64tit0EV5IRL2Ka6xmKM30y1j9EVJH02Ji
 fJerO0lS5+JAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCaclpOhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9J7HhAAjkadI0ejYpWk+cSPgdRrBvZshABIbgZ
 GQxgme4t6lF1yir06RFgZ4DX9OiuYb3uNNb9sEML4Rc+pmpQMqj49ucyUWhmJ8Ck8GsFJZy3uz1
 x52L159LhE7fnrRpft71UTe9QuN7KbK8hVW3l/HYQOpa+bh0K1s/dNcH8G7JMyJk6cLX9Dgu/uJ
 R1VWPjOcCyM+wQdZ9Nsx27sUInClzLYS3IkFFIF0aCm5K0X4GdsCQOzsNJHVEdNMQwtTfKSBZKo
 XDR1D46AGw8atrYG/Lz18Q0nKzjTnYrQimTiv2SkzON6c9z1o/OFC7jQNH1ewKTy8+pQ0omYHUN
 2QgE0iLkoSVJxW6CLIQd8r1V+wOurWApv0dI01lzIa28uNrn1uxLUCmtC3ugdxoudexVj3XR5xZ
 F0bbHkrm+1lVIA6cK46JaFCbJ/eFKCOx28q9uzRmHcCGnRuuItmtogtRiVVf5lIy+6uFp491/0l
 yFsIhX27UgnOEMGPdyEPKi9eskCdpM+F6Uzjhf+MIZxRB1bK5vtJV5mpKgJ5r+/DtKqCx+1+WGb
 VhtDnr91ra0PsNEKzqJoHjdfFZrZjDeQo5GReIeWr1BVPUVqHU7QfnotHPItj6dhzcSP3LyMIB3
 Dhd4hoPqw/HnYDOvAxwf5IhSzTTfCw/RQ7GuTNwZTmF5Gs2918pU=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Export `acpi_of_match_device` function and use it to match for PRP0001
in `of_match_device`, if the device does not have a device node.

This fixes the match data being NULL when using ACPI PRP0001, even though
the device was matched against an of device table.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 drivers/acpi/bus.c   |  7 ++++---
 drivers/of/device.c  |  9 +++++++--
 include/linux/acpi.h | 11 +++++++++++
 3 files changed, 22 insertions(+), 5 deletions(-)

diff --git a/drivers/acpi/bus.c b/drivers/acpi/bus.c
index 2ec095e2009e..cd02f04cf685 100644
--- a/drivers/acpi/bus.c
+++ b/drivers/acpi/bus.c
@@ -831,9 +831,9 @@ const struct acpi_device *acpi_companion_match(const struct device *dev)
  * identifiers and a _DSD object with the "compatible" property, use that
  * property to match against the given list of identifiers.
  */
-static bool acpi_of_match_device(const struct acpi_device *adev,
-				 const struct of_device_id *of_match_table,
-				 const struct of_device_id **of_id)
+bool acpi_of_match_device(const struct acpi_device *adev,
+			  const struct of_device_id *of_match_table,
+			  const struct of_device_id **of_id)
 {
 	const union acpi_object *of_compatible, *obj;
 	int i, nval;
@@ -866,6 +866,7 @@ static bool acpi_of_match_device(const struct acpi_device *adev,
 
 	return false;
 }
+EXPORT_SYMBOL_GPL(acpi_of_match_device);
 
 static bool acpi_of_modalias(struct acpi_device *adev,
 			     char *modalias, size_t len)
diff --git a/drivers/of/device.c b/drivers/of/device.c
index f7e75e527667..128682390058 100644
--- a/drivers/of/device.c
+++ b/drivers/of/device.c
@@ -11,6 +11,7 @@
 #include <linux/mod_devicetable.h>
 #include <linux/slab.h>
 #include <linux/platform_device.h>
+#include <linux/acpi.h>
 
 #include <asm/errno.h>
 #include "of_private.h"
@@ -26,8 +27,12 @@
 const struct of_device_id *of_match_device(const struct of_device_id *matches,
 					   const struct device *dev)
 {
-	if (!matches || !dev->of_node || dev->of_node_reused)
-		return NULL;
+	if (!matches || !dev->of_node || dev->of_node_reused) {
+		const struct of_device_id *id = NULL;
+
+		acpi_of_match_device(ACPI_COMPANION(dev), matches, &id);
+		return id;
+	}
 	return of_match_node(matches, dev->of_node);
 }
 EXPORT_SYMBOL(of_match_device);
diff --git a/include/linux/acpi.h b/include/linux/acpi.h
index 4d2f0bed7a06..1cf23edcbfbb 100644
--- a/include/linux/acpi.h
+++ b/include/linux/acpi.h
@@ -736,6 +736,10 @@ const struct acpi_device_id *acpi_match_acpi_device(const struct acpi_device_id
 const struct acpi_device_id *acpi_match_device(const struct acpi_device_id *ids,
 					       const struct device *dev);
 
+bool acpi_of_match_device(const struct acpi_device *adev,
+			  const struct of_device_id *of_match_table,
+			  const struct of_device_id **of_id);
+
 const void *acpi_device_get_match_data(const struct device *dev);
 extern bool acpi_driver_match_device(struct device *dev,
 				     const struct device_driver *drv);
@@ -965,6 +969,13 @@ static inline const struct acpi_device_id *acpi_match_device(
 	return NULL;
 }
 
+static inline bool acpi_of_match_device(const struct acpi_device *adev,
+					const struct of_device_id *of_match_table,
+					const struct of_device_id **of_id)
+{
+	return false;
+}
+
 static inline const void *acpi_device_get_match_data(const struct device *dev)
 {
 	return NULL;

-- 
2.52.0

