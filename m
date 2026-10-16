From: HuskerMinion <mocker-mug-unwoven@duck.com>
Subject: [PATCH 0/2] iio: light: tcs3472: Add TCS3400 support
Date: Fri, 16 Oct 2026 02:15:40 -0600
Message-Id: <20261016-tcs3400-v1-0-3d79d2a7f449@duck.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACzd0WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0NT3ZLkYmMTAwPdVKNUU9NU80QTSwsDJaDqgqLUtMwKsEnRsRB+cWl
 SVmpyCUi7Um0tAH5knnNrAAAA
X-Change-ID: 20261015-tcs3400-e2e55e7a4980
To: Jonathan Cameron <jic23@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Meerwald-Stadler <pmeerw@pmeerw.net>, 
 Arka Mondal <arka@arkamondal.net>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 HuskerMinion <mocker-mug-unwoven@duck.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792138543; l=1468;
 i=mocker-mug-unwoven@duck.com; s=20261016; h=from:subject:message-id;
 bh=5PXqI2wvHJ33gaVZwqw9mkgCl7xLEsI377R7OfghUec=;
 b=Nhc4hw5+szeJCF+P/ywM7I1pAQOJ8DAOvTHsLYyTVh2Y7J/gZB/Kg8eQVDjTC6n7t6bcVhbR4
 SwIFQ2X57jqB1xVWAWCIzWNwk+mTw7v9q85gpayCUd6jQqRzoNsHZ+v
X-Developer-Key: i=mocker-mug-unwoven@duck.com; a=ed25519;
 pk=Q7l9BnP4XnFimCK28K+NVowcECqTaJNXicdBAInot0k=
X-Endpoint-Received: by B4 Relay for mocker-mug-unwoven@duck.com/20261016 with auth_id=1206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the AMS TCS3400 to the tcs3472 driver. The TCS3400 is
the ambient light sensor in the Amazon Echo Show 8 (2nd gen). I added
it while bringing up mainline Linux on that device.

The TCS3400 has the TCS3472 register map, but no command type field,
other gains, a 2.78 ms time step and its own interrupt clear register.
The driver picks the variant from the ID register, so nothing changes
for the TCS3472.

Patch 1 adds a binding. The TCS3472 had none, so it covers both
families. I listed myself as its maintainer, since the driver has no
MAINTAINERS entry.

Patch 2 adds the driver support.

On the device, raw reads follow the light. I tested that on a 6.18
based kernel. The sampling frequency code that is new in togreg now
uses the 2.78 ms step for WTIME and the init time as well. That part
and the threshold interrupt are only build tested on the TCS3400.

---
HuskerMinion (2):
      dt-bindings: iio: light: Add AMS TCS3472 and TCS3400
      iio: light: tcs3472: Add TCS3400 support

 .../devicetree/bindings/iio/light/ams,tcs3472.yaml |  57 ++++++++
 drivers/iio/light/Kconfig                          |   7 +-
 drivers/iio/light/tcs3472.c                        | 162 ++++++++++++++++-----
 3 files changed, 189 insertions(+), 37 deletions(-)
---
base-commit: a3b3580713f3ac5a32dc2874ee546828977a1d68
change-id: 20261015-tcs3400-e2e55e7a4980

Best regards,
--  
HuskerMinion <mocker-mug-unwoven@duck.com>

