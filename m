From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 0/2] sdm845: prepare pinctrl and clock for QUP0 SE4 SPI
Date: Fri, 16 Oct 2026 22:13:49 +0200
Message-Id: <20261016-b4-sdm845-qupv3-s4-v1-0-672e9be21fd2@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTNJpxZSvQphIe0AYyJiB4gJ4
 e5WWb7F/zsoJ2GFW7FD4k1UXlMGlQWE8T4NjBKzwRpbk6EaO4can95V+F7n7YLqkDzHcK28pWg
 gh3PiXj7/adOe1rV7cFh+JziOL7P5hG92AAAA
X-Change-ID: 20261016-b4-sdm845-qupv3-s4-18edc95821d0
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, David Wronek <david.wronek@mainlining.org>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792181640; l=1005;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=InkvlhzYHksg1npSo0OcjBFF+ncxgyp/zxriCIRZyuM=;
 b=4PxEnSzwIpVyOD9IvkFqAa7TtDCL+poPIhO4EI1ho23vFQlYwWN4TFzoWwsOPWIK6PhMFptbz
 eOc4BXxJi7MDCYI+XdHVcin5H7tZ1LOVb+UB8v+Ru6U7gTyOFEpkYoj
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I'm working on a GENI SPI driver for QUPv3 platforms and the SPI
controller on SDM845 is QUP0 SE4. U-Boot can currently only describe
the UART9 pins on this SoC and its clock driver cannot set the SE4
rate.

The mux value of the SE4 pins differs per pin which the per-function
pinctrl table cannot express.

Therefore the first patch makes the lookup per pin.

The second patch lets the clock driver set the SE4 SPI clock rate.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (2):
      pinctrl: qcom: sdm845: select the mux value per pin
      clk: qcom: sdm845: add GCC_QUPV3_WRAP0_S4_CLK case

 drivers/clk/qcom/clock-sdm845.c       | 10 ++++++--
 drivers/pinctrl/qcom/pinctrl-sdm845.c | 45 +++++++++++++++++++++++++++++++----
 2 files changed, 48 insertions(+), 7 deletions(-)
---
base-commit: 1bcb2fe324180d0a8cfbdb0511737eba1d5b8550
change-id: 20261016-b4-sdm845-qupv3-s4-18edc95821d0

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

