From: Arthur Becker <arthur.becker@sentec.com>
Subject: [PATCH v4 0/2] Add driver for Vishay VEML6040
Date: Tue, 04 Jun 2024 10:01:47 +0200
Message-Id: <20240604-veml6040-v4-0-5a4d59597874@sentec.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOvJXmYC/23MQQrCMBCF4auUWRsZM9MUXXkP6cKmExuwqSQlK
 CV3N3bt8n88vg2SRC8JLs0GUbJPfgk1+NCAne7hIcqPtUGjZmx1p7LMT4OMCunEzmLLRB3U+yu
 K8++duvW1J5/WJX52OdNv/YNkUqiMo2FwI+uzwWuSsIo92mWGvpTyBaIWJLKhAAAA
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Javier Carrasco <javier.carrasco.cruz@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Arthur Becker <arthur.becker@sentec.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717488152; l=1495;
 i=arthur.becker@sentec.com; s=20240521; h=from:subject:message-id;
 bh=uHvOv9aK9XOoj9fYBdiwGn2AO8p3JyKaBsQ+U6DRHZU=;
 b=e/8TVxIokVEEUaj0I6HWTrOfYy+gzUjubml8W4SUO62Y3Zmho2fHunG2eTyV1OO1tqQ60TjCB
 ddSwCdykvITAltsCXDcGDuN6e8By9eL+H9IFEnw7tXh62kv8pnca5vM
X-Developer-Key: i=arthur.becker@sentec.com; a=ed25519;
 pk=1GLsDBF6GZKt9oNFsvdnAB6sHyKKrSISlwM3AyWbx/k=
X-Endpoint-Received: by B4 Relay for arthur.becker@sentec.com/20240521 with auth_id=163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver allows to turn the module on/off, set the integration time
(in MS) for the sensors, and read the raw measurements of the Red,
Green, Blue and White sensors.

Thank you Jonathan, Krzysztof, Conor and Rob for your comments on the
driver, dt-bindings and my workflow!

To: Jonathan Cameron <jic23@kernel.org>
To: Lars-Peter Clausen <lars@metafoo.de>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Javier Carrasco <javier.carrasco.cruz@gmail.com>
Cc: linux-kernel@vger.kernel.org
Cc: linux-iio@vger.kernel.org
Cc: devicetree@vger.kernel.org
Signed-off-by: Arthur Becker <arthur.becker@sentec.com>

Changes in v4:
- Minor adjustments to the driver
- Merged dt-bindings with veml6075
- Link to v3: https://lore.kernel.org/r/20240527-veml6040-v3-0-6f3bbfd42960@sentec.com

---
Arthur Becker (2):
      iio: light: driver for Vishay VEML6040
      dt-bindings: iio: light: add VEML6040 RGBW-LS bindings

 .../bindings/iio/light/vishay,veml6075.yaml        |   9 +-
 drivers/iio/light/Kconfig                          |  11 +
 drivers/iio/light/Makefile                         |   1 +
 drivers/iio/light/veml6040.c                       | 281 +++++++++++++++++++++
 4 files changed, 300 insertions(+), 2 deletions(-)
---
base-commit: 1613e604df0cd359cf2a7fbd9be7a0bcfacfabd0
change-id: 20240527-veml6040-0314fc054337

Best regards,
-- 
Arthur Becker <arthur.becker@sentec.com>

