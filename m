From: Sven Peter <sven@kernel.org>
Subject: [PATCH 0/5] Apple Silicon USB3 support - dwc3
Date: Mon, 13 Oct 2025 16:03:24 +0000
Message-Id: <20251013-b4-aplpe-dwc3-v1-0-12a78000c014@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMwi7WgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDA0Nj3SQT3cSCnIJU3ZTyZGNdkzRzSwNDS3MTwzRLJaCegqLUtMwKsHn
 RsbW1AN+dgqhfAAAA
X-Change-ID: 20251013-b4-aplpe-dwc3-4f79019741f9
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, stable@kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1811; i=sven@kernel.org;
 h=from:subject:message-id; bh=rWotubb4CBnANwxKjnVhMxklcZzF6pHwe+WDhBKK4YI=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8ZbpYd7Mhtrgqq4uP7eSDjAe5Oh40mhc8r+3ScKNr/ep
 HnR08qwo5SFQYyDQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCRnS2MDIuq1yQ2fuqavHjV
 5alW85k9jS1uHLeYZ/z2ykovNZujv4MYGSbO5L1yrmPb1RniF8WmJm/Yz3Rl364lh8+Xn28uZ4+
 TXsMCAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

As discussed in v2 of the combined Apple Silicon USB3 support series
this one only contains the dwc3 changes without the DTS changes.

Link to v2 of the combined series: https://lore.kernel.org/asahi/20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org/
Changes since v2 of that series:
- Documented all functions in glue.h
- Fixed a typo in the example for the dt-bindings
- Added detailed documentation about how the dwc3 hardware needs to be
  driven on this platform to the glue driver
- Renamed dwc3_apple.mode to state and folded in the probe check into
  the new DWC3_APPLE_PROBE_PENDING state
- Collected tags

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Sven Peter (5):
      dt-bindings: usb: Add Apple dwc3
      usb: dwc3: dwc3_power_off_all_roothub_ports: Use ioremap_np when required
      usb: dwc3: glue: Add documentation
      usb: dwc3: glue: Allow more fine grained control over mode switches
      usb: dwc3: Add Apple Silicon DWC3 glue layer driver

 .../devicetree/bindings/usb/apple,dwc3.yaml        |  80 ++++
 MAINTAINERS                                        |   2 +
 drivers/usb/dwc3/Kconfig                           |  11 +
 drivers/usb/dwc3/Makefile                          |   1 +
 drivers/usb/dwc3/core.c                            |  16 +-
 drivers/usb/dwc3/dwc3-apple.c                      | 488 +++++++++++++++++++++
 drivers/usb/dwc3/gadget.c                          |   2 +
 drivers/usb/dwc3/glue.h                            | 143 ++++++
 drivers/usb/dwc3/host.c                            |   7 +-
 9 files changed, 744 insertions(+), 6 deletions(-)
---
base-commit: 3a8660878839faadb4f1a6dd72c3179c1df56787
change-id: 20251013-b4-aplpe-dwc3-4f79019741f9

Best regards,
-- 
Sven Peter <sven@kernel.org>

