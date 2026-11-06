From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH 0/3] pinctrl: add Zhihe A210 pin controller support
Date: Sat, 07 Nov 2026 03:36:06 +0800
Message-Id: <20261107-a210-pinctrl-v1-0-6ddedfb0b76b@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDXpVELjKmJBTRmRkhaRNO6uW
 L7F/xECeaYAdRbB08mBV5eAeQZm6txIgodkUFKViLISnUIpNnZm94tQhZYV6sLaUkNKNk+Wr2/
 XtL/D0c9k9vcB9/0ASGCkjXAAAAA=
X-Change-ID: 20261107-a210-pinctrl-23807183ff68
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793993783; l=1226;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=lI0jPaIXPZUKAJwf6sStoxzn6nqviOYKQAzrRSANV4Q=;
 b=Yn+bD4PSpOp1/GW1CAi4yUtLp/rW1nacSB/RPLf7sk18TzrvqNG7Uohp3yHDbRkLFgavbYT44
 eG8QIW5zlkjArpcNvk2zkv3F86hcN/n6+UzAFAuYfjZBpz8hdyDS4n0
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds the binding and driver for the Zhihe A210 pin controllers
(AON, PERI1 and PERI2).

As Conor suggested, the patches are split out of the A210 SoC series
[1] and are unchanged from its v3, except that Han Gao is added as a
maintainer of the binding and as a copyright holder of the driver. The
vendor prefix patch is included so the series applies on its own.
ARCH_ZHIHE comes with [1].

[1] https://patch.msgid.link/20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Zhiguo Zhu (3):
      dt-bindings: vendor-prefixes: add Zhihe
      dt-bindings: pinctrl: add Zhihe A210 pin controller
      pinctrl: zhihe: add A210 support

 .../bindings/pinctrl/zhihe,a210-pinctrl.yaml       | 147 +++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 drivers/pinctrl/Kconfig                            |  13 +
 drivers/pinctrl/Makefile                           |   1 +
 drivers/pinctrl/pinctrl-zhihe-a210.c               | 997 +++++++++++++++++++++
 5 files changed, 1160 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261107-a210-pinctrl-23807183ff68

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

