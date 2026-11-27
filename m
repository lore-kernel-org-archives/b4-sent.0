From: Jiebing Chen <jiebing.chen@amlogic.com>
Subject: [PATCH 0/2] Add Amlogic S4 audio clock controller support.
Date: Fri, 27 Nov 2026 17:11:25 +0800
Message-Id: <20261127-clock_audio-v1-0-cf3ccf6b2bf0@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD1JCWsC/yXMQQqDMBBG4avIrA00WRjwKkUknfy2o2IkURHEu
 xvr8lu8d1BCFCSqi4MiNkkSpgxdFsQ/N32hxGeTeZlKa2MVj4GH1q1egrIV4C1g2RnKxRzRyf6
 /vZvHaf304OVe0Hle7APduW8AAAA=
X-Change-ID: 20261127-clock_audio-76eed7ee7ca2
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Jiebing Chen <jiebing.chen@amlogic.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795770705; l=968;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=t9o7jatpCUgt1xoj3DYtJg0jt8VnLSQZmNVddOcUCTo=;
 b=UpqLeufWoTZWPnz2qm2CvQdel5yKKS226bkqZcwgQJn5qPiNF14twhN+9YdZg/aLERJNBxsOx
 sriSjv4mAZrCAcf8K130Bj2uTQmzb/2A0pDnW1pO26z3hpnjcH1IfBA
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S4 uses the existing AXG audio clock driver and reuses the SM1 and
G12A clock hardware. Pad clock and data selection is done by pinmux,
so those pad clocks are not registered. The controller has an internal
reset line, like G12A and SM1, and an audio power domain that must be
enabled before use. The new compatible is amlogic,s4-audio-clkc;
power-domains is required for S4 and forbidden for the other
compatibles.

Signed-off-by: Jiebing Chen <jiebing.chen@amlogic.com>
---
Jiebing Chen (2):
      clk: meson: axg_audio: add S4 support
      ASoC:dt-bindings:clock: Add audio power domain for S4 soc

 .../bindings/clock/amlogic,axg-audio-clkc.yaml     |  17 +++
 drivers/clk/meson/axg-audio.c                      | 165 +++++++++++++++++++++
 2 files changed, 182 insertions(+)
---
base-commit: a0c666c25aeefd16f4b088c6549a6fb6b65a8a1d
change-id: 20261127-clock_audio-76eed7ee7ca2

Best regards,
--  
Jiebing Chen <jiebing.chen@amlogic.com>

