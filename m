From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH 0/2] ADRF5702/ADRF5703 Digital Attenuator support
Date: Wed, 25 Mar 2026 11:12:01 +0000
Message-Id: <20260325-adrf570x-iio-support-v1-0-9a2685eb2e55@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAHDw2kC/x3MPQqAMAxA4atIZgNt/fcq4lA11Sy2pCqCeHeL4
 ze890AkYYrQZw8IXRzZ7wk6z2De7L4S8pIMRplaFaZCu4irGnUjs8d4huDlQNJdV+rWTbZUkNI
 g5Pj+t8P4vh8P9djDZgAAAA==
X-Change-ID: 20260325-adrf570x-iio-support-e199418fba40
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774437143; l=808;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=6s60KjYjwOw1gKouJIv1rbJ9T2v6rnXR5nRknIdF0GA=;
 b=WeuRfH4St3KVL/xuGRUuA2Qs5GkPq1aVPv3shOLplBnzEEx6J6SVYouOOVp1O0u5S6+l6S9NY
 IqP8VuewfihAvZJQkvjMCLINNZAs8klQg8/T/tohFachBrVXVtifHHt
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a small patch series that adds support for two extra attenuators.
Basically, new chip info and device table entries are added into the
AD8366 IIO driver.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Rodrigo Alencar (2):
      dt-bindings: iio: amplifiers: ad8366: add adrf5702/3 support
      iio: amplifiers: ad8366: add support for adrf5702/3

 .../bindings/iio/amplifiers/adi,ad8366.yaml        |  4 ++++
 drivers/iio/amplifiers/Kconfig                     |  2 ++
 drivers/iio/amplifiers/ad8366.c                    | 22 ++++++++++++++++++++++
 3 files changed, 28 insertions(+)
---
base-commit: af980a79bfed43c4a0be12cca786be46f1a0c5e8
change-id: 20260325-adrf570x-iio-support-e199418fba40

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

