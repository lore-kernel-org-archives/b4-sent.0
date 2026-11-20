From: ILYAS NHASSE <ilyas.nhasse@skf.com>
Subject: [PATCH 0/2] iio: adc: ad7124: support boards without RDY interrupt
Date: Fri, 20 Nov 2026 12:26:46 +0100
Message-Id: <20261120-ad7124-no-irq-v1-0-7826c5c3fd25@skf.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHYuAGsC/yXMTQ6CMBBA4auQWTtJ/5DEqxgXpTPgsCjSqjFpe
 ncKLr/FewUyJ+EMt65A4q9kWWODvnQQnj7OjELNYJS5amUVehq0cRhXlLQhMVnTE3vnA7TmlXi
 S3/m7P/7On3Hh8D4mUOsO9FM0enEAAAA=
X-Change-ID: 20261030-ad7124-no-irq-ded325dea4ac
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marcelo Schmitt <marcelo.schmitt@analog.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, ILYAS NHASSE <ilyas.nhasse@skf.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795174009; l=2214;
 i=ilyas.nhasse@skf.com; s=20261120; h=from:subject:message-id;
 bh=bCTZjYQqzky+qnBbt4zskphWPNqvvqYylRoFceegAkA=;
 b=XrY+1DgQTQzurTiTdSTmcm2xbCafCOp+fgphvI9Sdr68cWSlgcAzHQ0S0v3/6l961U9KUrQW9
 DiR4X2m1IMFBZIeDWzoRtypKA/63hisWMA2Bnf8KTVotSgINX18KNV4
X-Developer-Key: i=ilyas.nhasse@skf.com; a=ed25519;
 pk=DeEyhWzUoP0HCAWFV/8oy5EFF+41tZxPpWZhfGyiMS4=
X-Endpoint-Received: by B4 Relay for ilyas.nhasse@skf.com/20261120 with auth_id=1581
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Boards may wire the AD7124 DOUT/RDY pin to the SPI MISO line only, for
instance when the ADC sits behind a digital isolator that carries just
the SPI signals. Such boards can't use the driver today: the binding
requires an interrupt, and the sigma-delta core can't probe without one.

The end of a conversion or calibration is also reported by the RDY bit
of the status register. Analog Devices' no-OS driver waits for AD7124
conversions and calibrations this way (ad7124_wait_for_conv_ready()).

Patch 1 makes the interrupt optional in the AD7124 binding.
Patch 2 lets the sigma-delta core poll the RDY bit when there is no
interrupt, for single conversions and calibrations. These devices then
only support direct mode, as the RDY interrupt is the only trigger of
the triggered buffer. No AD7124 driver change is needed.

The polling applies to every device with registers, but only the AD7124
binding is relaxed: the other bindings still require the interrupt, so
boards using them are not affected.

Open questions:
- Poll period: 20 ms, a fifth of a conversion at the AD7124 default
  10 SPS. On our board the SPI clock runs at about 6 kHz through the
  isolator and the controller uses PIO, so each status read costs about
  2.7 ms of CPU time and the period directly sets the CPU load during a
  conversion.
- Should polling rather be opt-in per driver, with a flag in
  struct ad_sigma_delta_info?

Tested on a TI J721E based board with four AD7124-8 on one SPI bus
behind an isolator, without RDY interrupt: direct reads of all channels
with an equivalent implementation on a v6.12 based kernel. The polled
calibration path is build-tested only.

---
ILYAS NHASSE (2):
      dt-bindings: iio: adc: adi,ad7124: make interrupts optional
      iio: adc: ad_sigma_delta: support devices without RDY interrupt

 .../devicetree/bindings/iio/adc/adi,ad7124.yaml    |  1 -
 drivers/iio/adc/ad_sigma_delta.c                   | 47 +++++++++++++++++++---
 2 files changed, 41 insertions(+), 7 deletions(-)
---
base-commit: 7d80b4b383bc53b48abd3a30ca4a91cdab568bfa
change-id: 20261030-ad7124-no-irq-ded325dea4ac

Best regards,
--  
ILYAS NHASSE <ilyas.nhasse@skf.com>

