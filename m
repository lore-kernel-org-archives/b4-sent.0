From: Sven Peter <sven@svenpeter.dev>
Subject: [PATCH v4 0/9] Apple Mac System Management Controller
Date: Sat, 03 May 2025 10:06:47 +0000
Message-Id: <20250503-smc-6-15-v4-0-500b9b6546fc@svenpeter.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALfqFWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyTHQUlJIzE
 vPSU3UzU4B8JSMDI1MDYwMT3eLcZF0zXUNT3TSD1BQzQ8tUY8MUEyWg8oKi1LTMCrBR0bG1tQA
 Ek3W/WgAAAA==
X-Change-ID: 20250304-smc-6-15-f0ed619e31d4
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Hector Martin <marcan@marcan.st>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Lee Jones <lee@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4267; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=A6sW0fHhezyvxJw0ueUn7VDzoKCJ4EosNM854fVXIRc=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4boq0N7VfUk+HOu9n5tUfVrDzzUWbhHOXfvjIrjV9t+r
 bmcH87TUcrCIMbBICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZhI61JGhvbsBZzL3Nfuexwz
 f+s5qXfXdjc/2ioW+epGWmng1aCPwWqMDKeYWrwfNV2a32pislHjxtaobe75f0/bPzc8HRhV+Uj
 lISMA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

It's been quite a while (end of 2022) since the last version of this
series was sent by Russel. I'd like to pick this up again and get SMC
upstream.

I've taken the last version from the ML and worked in the review
comments and some other changed:

  - Added documentation for all functions and structs
  - Fixed dt-bindings and re-ordered commits so that the mfd one comes
    last and can include the gpio subdevice
  - Added the reset driver and corresponding bindings
  - Reworked the atomic mode inside SMC since the previous implementation
    called mutex_lock from atomic context
  - Removed the backend split for now which lead to a quite intense discussion
    for the previous versions which hadn't been solved as far as I could tell
    from the old threads.
    It's also been 2+ years and I haven't heard of any backend implementation
    for T2 or even older macs. It's also unclear to me which sub-devices
    are actually useful there because at least GPIO and shutdown/reboot
    from this series will not work as-is there.
    I'd rather have this initial version which only supports M1+ macs upstream
    and then iterate there if any other backend is developed.
    I'll gladly help to re-introduce backend support if it's ever required.

Dependencies:
The code and dt-bindings themselves apply cleanly to 6.15-rc1 but
the device tree changes require the already merged SPMI controller
and SPMI NVMEM series which will be part of 6.16.
The series is also using the printf format specifiers which will
land in 6.16 via the drm-misc tree.
A tree with all dependencies for testing is available at
https://github.com/AsahiLinux/linux/commits/sven/smc-v4/.

Merging:
The dt-binding patches all depend on each other such that they all
should probably go together with the mfd device itself.
The following commits also depend on mfd due to the new header file and
will either have to go through the mfd tree as well or we'll need an
immutable branch there.
I'll take the device tree updates through our tree which also has the
previous device tree updates these depend on.

v3: https://lore.kernel.org/asahi/Y2qEpgIdpRTzTQbN@shell.armlinux.org.uk/
v2: https://lore.kernel.org/asahi/YxdInl2qzQWM+3bs@shell.armlinux.org.uk/
v1: https://lore.kernel.org/asahi/YxC5eZjGgd8xguDr@shell.armlinux.org.uk/

Best,

Sven

---
Hector Martin (5):
      gpio: Add new gpio-macsmc driver for Apple Macs
      power: reset: macsmc-reboot: Add driver for rebooting via Apple SMC
      arm64: dts: apple: t8103: Add SMC node
      arm64: dts: apple: t8112: Add SMC node
      arm64: dts: apple: t600x: Add SMC node

Russell King (Oracle) (2):
      dt-bindings: gpio: Add Apple Mac SMC GPIO block
      dt-bindings: mfd: Add Apple Mac System Management Controller

Sven Peter (2):
      dt-bindings: power: reboot: Add Apple Mac SMC Reboot Controller
      mfd: Add Apple Silicon System Management Controller

 .../devicetree/bindings/gpio/apple,smc-gpio.yaml   |  37 ++
 .../devicetree/bindings/mfd/apple,smc.yaml         |  71 +++
 .../bindings/power/reset/apple,smc-reboot.yaml     |  52 ++
 MAINTAINERS                                        |   7 +
 arch/arm64/boot/dts/apple/t600x-die0.dtsi          |  35 ++
 arch/arm64/boot/dts/apple/t8103.dtsi               |  35 ++
 arch/arm64/boot/dts/apple/t8112.dtsi               |  35 ++
 drivers/gpio/Kconfig                               |  10 +
 drivers/gpio/Makefile                              |   1 +
 drivers/gpio/gpio-macsmc.c                         | 246 ++++++++
 drivers/mfd/Kconfig                                |  15 +
 drivers/mfd/Makefile                               |   1 +
 drivers/mfd/macsmc.c                               | 657 +++++++++++++++++++++
 drivers/power/reset/Kconfig                        |  11 +
 drivers/power/reset/Makefile                       |   1 +
 drivers/power/reset/macsmc-reboot.c                | 362 ++++++++++++
 include/linux/mfd/macsmc.h                         | 337 +++++++++++
 17 files changed, 1913 insertions(+)
---
base-commit: 8b7e6734e2231a549a23943678ee3452bd19a1fe
change-id: 20250304-smc-6-15-f0ed619e31d4

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

