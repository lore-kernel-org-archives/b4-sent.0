From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v2 0/2] ADRF5702/ADRF5703 Digital Attenuator support
Date: Thu, 26 Mar 2026 18:32:15 +0000
Message-Id: <20260326-adrf570x-iio-support-v2-0-b622a17335d0@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK97xWkC/4WNQQ6CMBBFr0Jm7Zi2UgRX3sOwKDCFSZQ2LRIM6
 d2tXMDle8l/f4dIgSnCrdgh0MqR3ZxBnQroJzOPhDxkBiVUJS5KoxmC1VexIbPD+PbehQVJNk0
 pa9uZUkCe+kCWtyP7aDNPHBcXPsfLKn/2T3CVKLAxqqo1dYq0vpvZPN147t0L2pTSF8ftO6G5A
 AAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774549942; l=986;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=CzsFZIJiKMsLWlfT0H5N9wCIpe9LumoDaQPCrhbfnfI=;
 b=TuNHdp+ljawlKp6O97s1DzuisbOEEDdcextDE34p8Mt70LsrYQpTHXumNirEjUzRJvPrvTbP7
 DERO2VcEXyGD1oxR8My5XngtUgyqr9XJth0tYG8MOZwhwIIsbiNOFdr
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a small patch series that adds support for two extra attenuators.
Basically, new chip info and device table entries are added into the
AD8366 IIO driver.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Changes in v2:
- Add more context to the dt-bindings commit message.
- Link to v1: https://lore.kernel.org/r/20260325-adrf570x-iio-support-v1-0-9a2685eb2e55@analog.com

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

