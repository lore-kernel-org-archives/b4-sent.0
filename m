From: Junyi Zhao <junyi.zhao@amlogic.com>
Subject: [PATCH v5 0/2] Add Amlogic A9 I3C support
Date: Thu, 19 Nov 2026 12:22:45 +0800
Message-Id: <20261119-a9_i3c-v5-0-6ec51f8fb59d@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJV5/moC/2XO3W7CMAwF4FdBuV6Q7aSl3tXeY5qmxkkg06BTw
 6oh1HcnAfEzcXmk8x37qHIYU8jqdXFUY5hSTsOuhOZloWTT79ZBJ1+yIqAWAUH3/JmMaPYN2cY
 DW+lUKf+MIaa/89D7xyXnX/cVZF91bWxS3g/j4Xxpwtq7jvJ1dEIN2hD7Dtm3hPGt334P6yRLG
 baqzk50hwh0g1QgiF1ZF0Vi7J+heYTtDZoCO7CuZcfAjXuG9gHiHdr6qjdE5FZInf8P53k+AaC
 VN5lbAQAA
X-Change-ID: 20261010-a9_i3c-9d5245d094c8
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-i3c@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, imx@lists.linux.dev, 
 linux-hardening@vger.kernel.org, xianwei.zhao@amlogic.com, 
 Kelvin.Zhang@amlogic.com, Junyi Zhao <junyi.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795062168; l=3278;
 i=junyi.zhao@amlogic.com; s=20260924; h=from:subject:message-id;
 bh=xV4H0o4G83ywiHtiXYg2J/lDkmvf0Uuq0lK84mEN59U=;
 b=ASWcwZgj9n6dw2BnDntV1w4pXAefYU4kmHwXGxCQ7A2VkjXfTmf9bLqUvXPIrIjyFVzs5XuNO
 CEjjd0iNLcGAfKkz/H7NHz4FBgFQ0OMAqIX5vwTdcrAgHhF7tOaQzY4
X-Developer-Key: i=junyi.zhao@amlogic.com; a=ed25519;
 pk=hiL5PjGIksGFiWvEx9J3MhQqU/ro6vNbj72NIw4bbvA=
X-Endpoint-Received: by B4 Relay for junyi.zhao@amlogic.com/20260924 with auth_id=1054
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic A9 SoCs integrate the Silvaco I3C IP, but their peripheral
clock setup differs from the original implementation: the EE-domain
controller (amlogic,a9-i3c) takes two clocks, "pclk" and "fast_clk",
while the AO-domain controller (amlogic,a9-ao-i3c) exposes only
"pclk" and derives its bus clock from an internal divider inside the
controller's own register region.

This series consists of:

  - Add the Amlogic compatibles and per-variant clock
    constraints to the silvaco,i3c-master binding schema.

  - Add a vendor_init callback for the clock setup and an
    Amlogic-specific bit (AML_I3C_QUIRK_AO) for AO-specific behaviour
    to the Silvaco I3C master driver, and enable the existing
    Silvaco workaround quirks for both Amlogic variants.

Verified on Amlogic A9 (BY401) with both EE and AO controller
instances. dt_binding_check and dtbs_check pass with this series.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
---
Changes in v5:
- Check the clock count and name before dereferencing clks[0] in
  aml_i3c_init(); a DT node without clocks or clock-names would
  previously NULL-deref.
- Factor out the fast_clk lookup into a shared NULL-safe helper
  svc_i3c_master_find_clk().

- Link to v4: https://patch.msgid.link/20261116-a9_i3c-v4-0-3d3222b7128d@amlogic.com

Changes in v4:
  - Move the DT binding patch before the driver patch.
  - Add CLK_OPS_PARENT_ENABLE flag for ao tail clocks.
  - Enable fclk before allocating the new clk bulk array.

- Link to v3: https://patch.msgid.link/20261106-a9_i3c-v3-0-804b69b9095b@amlogic.com

Changes in v3:
  - Merge vendor quirks into the legacy quirks bitmask and add
    AML_I3C_QUIRK_AO for the AO variant.
  - Check the devm_kcalloc() return value when allocating the new
    clk bulk array.
  - Enable the clocks before aml_ao_i3c_tail_clocks(), because the
    divider registers are accessed during registration.
  - Rework the probe error paths so the clocks are disabled when
    vendor_init or later steps fail.
  - Reorder the local variables (longest first).
  - Convert comments to kernel-doc format.
  - Depend on COMMON_CLK in Kconfig.
  - Drop the silvaco,i3c-master-v1 fallback and add a blank line
    before the new if/then block in the binding.
  - Explain the I3C peripheral integration details in the binding
    commit message.

- Link to v2: https://patch.msgid.link/20261102-a9_i3c-v2-0-0c474bfccffa@amlogic.com

Changes in v2:

  - No need rework the Silvaco I3C driver. 
  - Based on vanilla driver, adapt A9 SoCs through callback 
    and quirks to handle the variant.

- Link to v1: https://patch.msgid.link/20261019-a9_i3c-v1-0-329d819d621f@amlogic.com

---
Junyi Zhao (2):
      dt-bindings: i3c: silvaco,i3c-master: Add Amlogic A9 support
      i3c: master: svc: Add amlogic a9 support

 .../bindings/i3c/silvaco,i3c-master.yaml           |  26 +-
 drivers/i3c/master/Kconfig                         |   1 +
 drivers/i3c/master/svc-i3c-master.c                | 301 ++++++++++++++++++++-
 3 files changed, 311 insertions(+), 17 deletions(-)
---
base-commit: aac26bee2287c88af5be5a5ff96d783b19a28790
change-id: 20261010-a9_i3c-9d5245d094c8

Best regards,
--  
Junyi Zhao <junyi.zhao@amlogic.com>

