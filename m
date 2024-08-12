From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Subject: [PATCH v3 0/3] Add support for AD4113
Date: Mon, 12 Aug 2024 11:13:13 +0300
Message-Id: <20240812-ad4113-v3-0-046e785dd253@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABnEuWYC/1WMwQ7CIBAFf8VwFrMsVFpP/ofxsKXQkmgxYIim6
 b9LazR6nJc3M7Fko7eJHTYTizb75MNYQG43zAw09pb7rjBDQAUaK06dEkLylmgvnWsaVBUr51u
 0zj/W0OlcePDpHuJz7WaxrO9EDfqTyIIDx07K2mlAo9sjjXQJ/c6EK1saGX+95uvh4pEGI0CQc
 OrPm+f5BVsPcCvVAAAA
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: mitrutzceclan@gmail.com, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723450395; l=1967;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=l2cMsMW6WjSVkxY7LiRh1xYBXXYUhNx5oNMkZpw0QAc=;
 b=Qqh+HVkYK5/X4HNJyiP/mC68JLfIhLLtXLvFwceSn08y87V6PWDUqBFIVj3GQcWCdZoZkfmsh
 FlvUvCKSp/4Bf75fAjsV1tM5M0wH6AX1juyG6DVyPDGgNUJLipkgo93
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the AD4113 ADC within the existing
AD7173 driver.

The AD4113 is a low power, low noise, 16-bit, Σ-Δ analog-to-digital
converter (ADC) that integrates an analog front end (AFE) for four
fully differential or eight single-ended inputs.

The part is not released yet and the documentation is not public.
Register map is identical to AD4114 besides the lower width data
register and the GPIO register.

Particularities of this model:
- 16 bit data register
- no temperature sensor
- no current inputs
- input buffers
- internal reference
- external reference REF-/REF+
- no second external reference REF2-/REF2+
- no AVDD2 supply
- 2 GPIO pins with config bits starting at a higher position in register
- 8 VINx inputs with voltage divider
- 16 channel registers and 8 setup registers

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
Changes in v3:
- lowercase chip ID
- add patch to correctly order chip IDs defines
- picked up RB and ACK tags
- Link to v2: https://lore.kernel.org/r/20240809-ad4113-v2-0-2a70c101a1f4@analog.com

Changes in v2:
- correctly set realbits and storagebits to 16 in iio_chan_spec
- describe bindings restrictions in commit message due to lack of
  sufficient diff context
- describe model differences better in cover letter
- Link to v1: https://lore.kernel.org/r/20240807-ad4113-v1-0-2d338f702c7b@analog.com

---
Dumitru Ceclan (3):
      dt-bindings: adc: ad7173: add support for ad4113
      iio: adc: ad7173: order chipID by value
      iio: adc: ad7173: add support for ad4113

 .../devicetree/bindings/iio/adc/adi,ad7173.yaml    |  3 ++
 drivers/iio/adc/ad7173.c                           | 38 ++++++++++++++++++++--
 2 files changed, 39 insertions(+), 2 deletions(-)
---
base-commit: 1c61e13d7dc9003662bd7fd6064dfea67e64b014
change-id: 20240725-ad4113-baa63ff99245

Best regards,
-- 
Dumitru Ceclan <dumitru.ceclan@analog.com>

