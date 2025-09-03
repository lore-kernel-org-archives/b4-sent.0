From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v2 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Wed, 03 Sep 2025 11:04:58 +0100
Message-Id: <20250903-ltc4283-support-v2-0-6bce091510bf@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMoSuGgC/2WNQQ6CMBBFr0JmbQ0MCNWV9zAsyjhAE6RNWxsN6
 d2tJK5cvpf89zfw7DR7uBQbOI7aa7NmwEMBNKt1YqHvmQFLPJWyQrEEalDWwj+tNS4I7EhSw+2
 Z2gHyyjoe9Wsv3vrMs/bBuPd+EKuv/bWav1asRCmkHJB47Lp6xKta1WKmI5kH9CmlDz6FV4avA
 AAA
X-Change-ID: 20250812-ltc4283-support-27c8c4e69c6b
To: linux-hwmon@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756893904; l=1868;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=jJDm398o/PQUOO/PqYBt0YkNR5iks/1VGE1vFW3OeEc=;
 b=eJjKsNbH0FJuhzg4gT9i/d0rAuEi9J84idpe5trIcPOXe5Vvzz+nFebIcK4T2IJ7zcZRdPe4h
 jzV/YMFZBJjAebyqCREHSJsg7vFXpQ0fMR7l9bFIF2WM5sLAV67ppyx
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is v2 for the LTC4283 how swap controller. Main change is that I'm
now using the auxiliary bus for adding the GPIO device (done depending
on FW properties).

Similar to the LTC4282 device, we're clearing some fault logs in the
reset_history attributes. 

I also feels this is basically "v1" so the changelog will be a bit more
generic.

Linus, I'm not using the gpio-regmap helpers because I'm using the
.init_valid_mask() callback and I don't think we can use it with the
gpio-regmap interface (unless I missed something). If you feel you
should change the interface to allow it, I can think on something for
v3.. 

---
Changes in v2:
- Dropped MFD related patches and bindings (now just one binding file
  for the hwmon device);
- Moved to the auxiliary bus; 
- Link to v1: https://lore.kernel.org/r/20250814-ltc4283-support-v1-0-88b2cef773f2@analog.com

---
Nuno Sá (3):
      dt-binbings: hwmon: Document the LTC4283 Swap Controller
      hwmon: ltc4283: Add support for the LTC4283 Swap Controller
      gpio: gpio-ltc4283: Add support for the LTC4283 Swap Controller

 .../devicetree/bindings/hwmon/adi,ltc4283.yaml     |  280 ++++
 Documentation/hwmon/ltc4283.rst                    |  266 +++
 MAINTAINERS                                        |    9 +
 drivers/gpio/Kconfig                               |   10 +
 drivers/gpio/Makefile                              |    1 +
 drivers/gpio/gpio-ltc4283.c                        |  217 +++
 drivers/hwmon/Kconfig                              |   12 +
 drivers/hwmon/Makefile                             |    1 +
 drivers/hwmon/ltc4283.c                            | 1748 ++++++++++++++++++++
 9 files changed, 2544 insertions(+)
---
base-commit: 9703c672af8dd3573c76ce509dfff26bf6c4768d
change-id: 20250812-ltc4283-support-27c8c4e69c6b
--

Thanks!
- Nuno Sá

