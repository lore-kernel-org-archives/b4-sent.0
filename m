From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH 0/3] ADF41513/ADF41510 PLL frequency synthesizers
Date: Mon, 10 Nov 2025 15:44:43 +0000
Message-Id: <20251110-adf41513-iio-driver-v1-0-2df8be0fdc6e@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGsIEmkC/x3MPQqAMAxA4atIZgONP1i8ijgEm2qWVlIQQby7x
 fEb3nugiKkUmJsHTC4tmlMFtQ1sB6ddUEM1dK4bicghhzjQSD2qZgymlxgyb+x5it55gVqeJlH
 v/7qs7/sBBLFJPWUAAAA=
X-Change-ID: 20251110-adf41513-iio-driver-aaca8a7f808e
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762789528; l=2258;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=9poQJZ13bmkoyTIkEY6uFwCthMZYSqe1hiLBYCBG2RQ=;
 b=ph+VaieH/2Z1pTAj3636B8hO3V/PMBRLThavszgki4+Kc7lATv3vHdTtOy5DCLCeHLVYoUdj5
 1s4e+RFUqZ1BT0haeDUEgzR6apGngS/46uTGDhIOb5nODT6XVMdV5mY
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the Analog Devices ADF41513 and ADF41510
ultralow noise PLL frequency synthesizers. These devices are designed for
implementing local oscillators (LOs) in high-frequency applications.

The ADF41513 covers frequencies from 1 GHz to 26.5 GHz, while the ADF41510
operates from 1 GHz to 10 GHz. Both devices feature exceptional phase noise
performance and flexible frequency synthesis capabilities.

Key features supported by this driver:
- Integer-N and fractional-N operation modes
- Ultra-low phase noise (-235 dBc/Hz integer-N, -231 dBc/Hz fractional-N)
- High maximum PFD frequency (250 MHz integer-N, 125 MHz fractional-N)
- 25-bit fixed modulus or 49-bit variable modulus fractional modes
- Programmable charge pump currents with 16x range
- Digital lock detect functionality
- Phase resync capability for consistent output phase
- Clock framework integration for system clock generation

The series includes:
1. Core driver implementation with full register programming support
2. Device tree bindings documentation
3. IIO subsystem documentation with usage examples

The driver integrates with both the IIO subsystem (for direct hardware control)
and the Linux clock framework (for use as a system clock source), providing
flexibility for different use cases.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Rodrigo Alencar (3):
      iio: frequency: adf41513: driver implementation
      dt-bindings: iio: frequency: add adf41513
      docs: iio: add documentation for adf41513 driver

 .../bindings/iio/frequency/adi,adf41513.yaml       |  268 ++++
 Documentation/iio/adf41513.rst                     |  377 +++++
 Documentation/iio/index.rst                        |    1 +
 MAINTAINERS                                        |    9 +
 drivers/iio/frequency/Kconfig                      |   11 +
 drivers/iio/frequency/Makefile                     |    1 +
 drivers/iio/frequency/adf41513.c                   | 1435 ++++++++++++++++++++
 7 files changed, 2102 insertions(+)
---
base-commit: d16d1c2553248f9b859b86c94344d8b81f0297cd
change-id: 20251110-adf41513-iio-driver-aaca8a7f808e

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

