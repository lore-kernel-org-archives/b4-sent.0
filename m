From: Sven Peter <sven@kernel.org>
Subject: [PATCH 0/3] Apple Silicon SMC RTC driver
Date: Tue, 12 Aug 2025 18:25:14 +0000
Message-Id: <20250812-wip-smc-rtc-v1-0-66a8e96dad60@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAqHm2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDC0Mj3fLMAt3i3GTdopJk3VQLU7MkszQjEzMDYyWgjoKi1LTMCrBp0bG
 1tQAIJoOQXQAAAA==
X-Change-ID: 20250812-wip-smc-rtc-e856b6f24603
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-rtc@vger.kernel.org, Sven Peter <sven@kernel.org>, 
 Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1886; i=sven@kernel.org;
 h=from:subject:message-id; bh=k8kF1P6bFlbBEzuzYgvwP5CIW+2qmHksP+KG9Qod3gY=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8bsdiH55MV3rVh+O/X9Tp18KtNRpYD9+sY/Nev/1+ucv
 r3ujdaDjlIWBjEOBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEAhsY/gee63BWXp5xaoNo
 Xvyps0Y7Izbf/umg7WMtE6pfWR+wLIXhv6cc2zRmsX8cyV9vfNiwjH2Sw2bp8+cctLj9sm96scn
 VMwMA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

Now that the core mfd device has been upstream I've prepared one of the
child drivers that is still missing: RTC support.
This driver is required to read and set the hardware clock and requires
a reference to an additional NVMEM cell to store the offset and thus
requires a device tree node.

The series applies cleanly to 6.17-rc1 but is based on a tree with three
additional commits to add the SMC nodes to the DTS which didn't make it
into 6.17. You can just ignore that and pretend this is based on
6.17-rc1 since I'll take the dts update through my tree anyway.

Next to this SMC child driver we're still working on an input/misc HID
driver for the powerbutton, a hwmon driver for the various sensors and a
power-supply driver to manage the batteries.

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Hector Martin (1):
      rtc: Add new rtc-macsmc driver for Apple Silicon Macs

Sven Peter (2):
      dt-bindings: rtc: Add Apple SMC RTC
      arm64: dts: apple: t8103,t600x,t8112: Add SMC RTC node

 .../devicetree/bindings/mfd/apple,smc.yaml         |   9 ++
 .../devicetree/bindings/rtc/apple,smc-rtc.yaml     |  35 +++++
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/apple/t600x-die0.dtsi          |   6 +
 arch/arm64/boot/dts/apple/t8103.dtsi               |   6 +
 arch/arm64/boot/dts/apple/t8112.dtsi               |   6 +
 drivers/mfd/macsmc.c                               |   1 +
 drivers/rtc/Kconfig                                |  11 ++
 drivers/rtc/Makefile                               |   1 +
 drivers/rtc/rtc-macsmc.c                           | 141 +++++++++++++++++++++
 10 files changed, 218 insertions(+)
---
base-commit: 772c260c9c7f916c9a2508839df4f03fc19f3773
change-id: 20250812-wip-smc-rtc-e856b6f24603

Best regards,
-- 
Sven Peter <sven@kernel.org>

