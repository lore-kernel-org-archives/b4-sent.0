From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 13 Mar 2026 20:03:07 +0100
Subject: [PATCH v3 3/7] acpi: add acpi_of_match_device_ids
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260313-synology_microp_initial-v3-3-ad6ac463a201@posteo.de>
References: <20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de>
In-Reply-To: <20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de>
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Igor Korotin <igor.korotin.linux@gmail.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Robert Moore <robert.moore@intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-leds@vger.kernel.org, 
 linux-acpi@vger.kernel.org, acpica-devel@lists.linux.dev, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1613;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=GJ3md6hqtAxzfdBZYmqM+I2WL+pybDm9TmsuESz9lJ4=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBptF913ngpPcMcdUQwBIgHq7F7VzFVgL/AY67jx
 svY0kKc3OKJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCabRfdRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9LkNg//bCn1Kd+N6ljQZDQEebMvChN3dphvi1c
 JNF9qbgFodbcU4BIFx7T8XQ8KXpBoORI0YxeXgRHUnqGbPpcyeCObRFd7ciSKCMpniWpzDuN1GE
 55vld+kUH+kCJCAHxj3uD3aPxn8e7ewuDXqns8NaqWxPsDHE0mjkuKLtUoLdi0m8p0tCV1KNrF3
 WWQWPtoa0MpaVlIz68xUxfpKkWcwXSKisntVCuHRB7fUGbkoBG6ewFPxai7OwVz58wYYF8qaMY0
 KtM6BU6H2FBNZMZ4BXj/TkKtX9IXz2dhwacbiAXlICtp36ZFtDQDiqQdgKpbKg/U3A1bmDZoJev
 XWoeg+XwuLcI6BIRCSTnsWShSO8gZtCBSpjR8zIR96fADSNuSvNwze128AS4h2ApAf2a20w00FB
 JG983Sp8SXAezefYSb54K7tp3WJ7RSl9NXahg69vtzWSoLB9uU0p+0WlwJ9cF7mb3Xnkp34GgxJ
 fwN9IhRLjSZFFdF+9oXeNNdaob6iHiP4M1qZSFFK1cjV8vQ5t7Wpj/DGU+8EMKkN6/cOKdJZZd4
 A5g32ESjeTedyxOxFIOi1oD39zEBZCd7fiIqYj4uxT8tCLsYslNbegGBON1a2xTChUUOxAZ1yG0
 gtgcL/kW7JQ3IMZf4yAC3sOtDJwLqZ2CWL1uesYUXGav6f2WlaAI=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a function to match acpi devices against of_device_ids. This will be
used in the following commit ("mfd: match acpi devices against PRP0001")
to match mfd sub-devices against a of compatible string.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 drivers/acpi/bus.c      | 7 +++++++
 include/acpi/acpi_bus.h | 2 ++
 2 files changed, 9 insertions(+)

diff --git a/drivers/acpi/bus.c b/drivers/acpi/bus.c
index f6707325f582..5ddcc56edc87 100644
--- a/drivers/acpi/bus.c
+++ b/drivers/acpi/bus.c
@@ -1044,6 +1044,13 @@ int acpi_match_device_ids(struct acpi_device *device,
 }
 EXPORT_SYMBOL(acpi_match_device_ids);
 
+int acpi_of_match_device_ids(struct acpi_device *device,
+			  const struct of_device_id *ids)
+{
+	return __acpi_match_device(device, NULL, ids, NULL, NULL) ? 0 : -ENOENT;
+}
+EXPORT_SYMBOL(acpi_of_match_device_ids);
+
 bool acpi_driver_match_device(struct device *dev,
 			      const struct device_driver *drv)
 {
diff --git a/include/acpi/acpi_bus.h b/include/acpi/acpi_bus.h
index aad1a95e6863..0081b9e4aaee 100644
--- a/include/acpi/acpi_bus.h
+++ b/include/acpi/acpi_bus.h
@@ -677,6 +677,8 @@ void acpi_bus_trim(struct acpi_device *start);
 acpi_status acpi_bus_get_ejd(acpi_handle handle, acpi_handle * ejd);
 int acpi_match_device_ids(struct acpi_device *device,
 			  const struct acpi_device_id *ids);
+int acpi_of_match_device_ids(struct acpi_device *device,
+			  const struct of_device_id *ids);
 void acpi_set_modalias(struct acpi_device *adev, const char *default_id,
 		       char *modalias, size_t len);
 

-- 
2.52.0

