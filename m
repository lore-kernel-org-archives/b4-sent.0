From: Arthur Becker <arthur.becker@sentec.com>
Subject: [PATCH v3 0/2] Add driver for Vishay VEML6040
Date: Mon, 27 May 2024 17:12:07 +0200
Message-Id: <20240527-veml6040-v3-0-6f3bbfd42960@sentec.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMiiVGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHUUlJIzE
 vPSU3UzU4B8JSMDIxMDUyNz3bLU3BwzAxMDXQNjQ5O0ZANTE2NjcyWg8oKi1LTMCrBR0bG1tQA
 NU0qIWgAAAA==
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Arthur Becker <arthur.becker@sentec.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716822728; l=935;
 i=arthur.becker@sentec.com; s=20240521; h=from:subject:message-id;
 bh=3TIcAQi2/9dfC8qhlCEi0dXTPr4blkbXwfz9/iRnzJE=;
 b=f2u7rFyobvpBdch0ALMVecwwaYCyHKuTeMnZww3hvZMllZIRMVdwEBwhmzEEVqSJxSExX9Z1d
 myA6vZXuI8oBEcQPnNb3R8Vx5cVh/so7HQc6BYQLIIJlnjIxl0DXQD8
X-Developer-Key: i=arthur.becker@sentec.com; a=ed25519;
 pk=1GLsDBF6GZKt9oNFsvdnAB6sHyKKrSISlwM3AyWbx/k=
X-Endpoint-Received: by B4 Relay for arthur.becker@sentec.com/20240521 with auth_id=163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Thank you Jonathan, Krzysztof and Conor for your comments on my previous
submission attempts. I hope that I addressed all points!

Changes since v2:
- formatting, renaming of variables
- power supply added in dt-binding file and turned on in driver
(- using b4!)

Signed-off-by: Arthur Becker <arthur.becker@sentec.com>
---
Arthur Becker (2):
      iio: light: driver for Vishay VEML6040
      dt-bindings: iio: light: add VEML6040 RGBW-LS bindings

 .../bindings/iio/light/vishay,veml6040.yaml        |  44 ++++
 drivers/iio/light/Kconfig                          |  11 +
 drivers/iio/light/Makefile                         |   1 +
 drivers/iio/light/veml6040.c                       | 283 +++++++++++++++++++++
 4 files changed, 339 insertions(+)
---
base-commit: 1613e604df0cd359cf2a7fbd9be7a0bcfacfabd0
change-id: 20240527-veml6040-0314fc054337

Best regards,
-- 
Arthur Becker <arthur.becker@sentec.com>

