From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH 0/4] arm64: dts: apple: t8122: Add SMC and NUB SPMI device
 tree nodes
Date: Sat, 21 Nov 2026 08:34:14 +0000
Message-Id: <20261121-t8122-smc-dt-v1-0-898f3f5d6228@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMAyA4VeRnA2YoMXtVYaH2sYtg7nR1DEQ3
 91Oj9/h/1cwSSoG12qFJF81fc8FVFcQHn6+C2osBm7YETFh7okZ7RUwZhypbaK7UO9dByX5JJn
 0d+xuw2lbxqeE/H/Atu1f/uXLcAAAAA==
X-Change-ID: 20261121-t8122-smc-dt-b140d6918a65
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Stephen Boyd <sboyd@kernel.org>, 
 Abel Vesa <abelvesa@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sasha Finkelstein <k@chaosmail.tech>, 
 Lee Jones <lee@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 mfd@lists.linux.dev, Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795250077; l=1103;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=+VGF3OgM8McNO1QrReHnnifTPEONvOY5aVFINlqg0P4=;
 b=69QOjr6tPfcAJvARlYWO+HNGBJ4V7g5KBF7WR4kbSxBU+WYYhLiE4W9uYoqIXgUgRiOS4i/cP
 Cehpxr6632hAPeZrX20exaiB+Uk2tfLDKDlfjfZUfaEmQzbBiuS5+BQ
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi folks,

This series adds the System Management Controller and its NUB SPMI
bindings and device tree nodes for the Apple M3 (T8122) SoC.

The SMC node includes its ASC mailbox, GPIO, hwmon, reboot, and RTC
child nodes.

It is based off apple-soc/dt-7.5.

Thanks,
Michael

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
Janne Grunau (2):
      dt-bindings: mfd: apple,smc: Add t8122-smc compatible
      arm64: dts: apple: t8122: Add NUB SPMI controller and PMIC

Michael Reeves (1):
      arm64: dts: apple: t8122: Add SMC and its mailbox

Sasha Finkelstein (1):
      dt-bindings: spmi: apple,spmi: Add t8122-spmi compatible

 .../devicetree/bindings/mfd/apple,smc.yaml         |   4 +-
 .../devicetree/bindings/spmi/apple,spmi.yaml       |   1 +
 arch/arm64/boot/dts/apple/t8122.dtsi               | 102 +++++++++++++++++++++
 3 files changed, 106 insertions(+), 1 deletion(-)
---
base-commit: 477f3d0f46b0d885f162a64d13ca51e2f7afa542
change-id: 20261121-t8122-smc-dt-b140d6918a65

Best regards,
--  
Michael Reeves <michael.reeves077@gmail.com>

