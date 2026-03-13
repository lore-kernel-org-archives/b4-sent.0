From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 13 Mar 2026 20:03:08 +0100
Subject: [PATCH v3 4/7] mfd: match acpi devices against PRP0001
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260313-synology_microp_initial-v3-4-ad6ac463a201@posteo.de>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2049;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=hBb7npui0bE9foF8ScZ10sjTmUwGIOBRFmkU8LUvBWM=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBptF93eoVl4DjsVgQ72oaZooBCN5wvnCfEb4Bga
 W4Ay9kmUaiJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCabRfdxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9L3fhAAhjV2cdrYE2uf7iM0x/J1I4s8JWTDwfI
 xc+elomemxd+j6pR0OhuKw3DggNCb1dc8H6scm/wv+zqfc0xBKay+QT8Ff3XjZvcfV1U4R3Oyct
 eyEhtj30Es5qqTjIPLNA1R3NAU3H7lhnUTviHadma7MR00Va9hVUetjEmHx4YDlIepo5n1NNIfU
 XYlU+dEoRsJ0f74IAhjc0He6zdNLSlLzP7pde5aQLNMq1egTwt42unDrVA6N6Ds++Dzm3ufmCTx
 fcFTLqoTm9S+A0E+Iie9+3KsPkqsyDY79insqEc8Liv7iqCRtzPrE4GLHh3zYT6pXSMDf/t85Cg
 IvRUpVxq7plwWrYa7C/s17zVOPhv9NxYSsIldWuUZKqwzJ6Q8xS9HXLA8BCW3XY7OMU6+Qrudjp
 Qoq/uDrkEHNgAxFHJcxq/L+o89nhnf7dWy0kbljzJaFs4ahpWzmX+BCWp7NtPKfppwnUoTK16va
 AayxkUxyh1wVVjMwONb4gJImT9Db6YrEzenviJbys/YZpUwQibiBDgRqO0vEuNntLTzChNLekHd
 bwO+Ca+pBIF05iMu5dk+WfKPtFU8QnXMkSbn7rVm3rkCLGJgYqUz4kTbLWWkCO66okvXGyT20ul
 nZnHj0MwmDpnd7JKqoESSpaXvpiIAb85zKiiOJMc8kBZFfobEKLQ=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PRP0001 can be used to provide DT-compatible device identification in
ACPI. If the mfd device is bound to a acpi fwnode and no acpi_match data
is provided by the driver, match against PRP0001 and the provided
`of_compatible` string.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 drivers/mfd/mfd-core.c | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/drivers/mfd/mfd-core.c b/drivers/mfd/mfd-core.c
index 6be58eb5a746..29bf54664acf 100644
--- a/drivers/mfd/mfd-core.c
+++ b/drivers/mfd/mfd-core.c
@@ -39,6 +39,10 @@ struct match_ids_walk_data {
 	struct acpi_device_id *ids;
 	struct acpi_device *adev;
 };
+struct match_of_ids_walk_data {
+	const struct of_device_id *ids;
+	struct acpi_device *adev;
+};
 
 static int match_device_ids(struct acpi_device *adev, void *data)
 {
@@ -52,10 +56,23 @@ static int match_device_ids(struct acpi_device *adev, void *data)
 	return 0;
 }
 
+static int match_of_device_ids(struct acpi_device *adev, void *data)
+{
+	struct match_of_ids_walk_data *wd = data;
+
+	if (!acpi_of_match_device_ids(adev, wd->ids)) {
+		wd->adev = adev;
+		return 1;
+	}
+
+	return 0;
+}
+
 static void mfd_acpi_add_device(const struct mfd_cell *cell,
 				struct platform_device *pdev)
 {
 	const struct mfd_cell_acpi_match *match = cell->acpi_match;
+	const char *of_compatible = cell->of_compatible;
 	struct acpi_device *adev = NULL;
 	struct acpi_device *parent;
 
@@ -86,6 +103,16 @@ static void mfd_acpi_add_device(const struct mfd_cell *cell,
 		} else {
 			adev = acpi_find_child_device(parent, match->adr, false);
 		}
+	} else if (of_compatible) {
+		struct of_device_id ids[2] = {};
+		struct match_of_ids_walk_data wd = {
+			.adev = NULL,
+			.ids = ids,
+		};
+
+		strscpy(ids[0].compatible, of_compatible, sizeof(ids[0].compatible));
+		acpi_dev_for_each_child(parent, match_of_device_ids, &wd);
+		adev = wd.adev;
 	}
 
 	device_set_node(&pdev->dev, acpi_fwnode_handle(adev ?: parent));

-- 
2.52.0

