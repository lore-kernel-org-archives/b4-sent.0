From: Junyi Zhao <junyi.zhao@amlogic.com>
Subject: [PATCH v2 0/2] Add Amlogic A9 I3C support
Date: Mon, 02 Nov 2026 19:05:38 +0800
Message-Id: <20261102-a9_i3c-v2-0-0c474bfccffa@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIJu6GoC/zWNyw6DIBQFf8XcdWkAH5Gu/I/GNBRQb1OlAUvaG
 P69YONykjlzNvDGofFwKTZwJqBHuyTgpwLUJJfRENSJgVPeMMookeKGpSJC17yqNRWVaiHJL2c
 G/Oyha/9n/74/jFrzOhsT+tW67/4UWPaOqDiigRFKSi50y4RuOBs6OT/tiOqs7Ax9jPEHtvKD/
 rAAAAA=
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
 Kelvin.Zhang@amlogic.com, Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793617545; l=1695;
 i=junyi.zhao@amlogic.com; s=20260924; h=from:subject:message-id;
 bh=UJx6v15t+vGPfwRUpHt2I4ZrP80lRsdJGExEg/joTkI=;
 b=18IKIcD3tbqV1AO5x5M/aDMWsCEGnolOANX6OlHDU5VZtiKG9Yc8hSPlxSfaAGD1RSWjtCX/g
 RqH0pwQyVEiC/nAKTPWnya0TuURq6v+ASS1FxJPezuDRnUqKoehW52b
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

  - Add a vendor_init callback for the clock setup and a
    vendor_quirks field for AO-specific behaviour to the Silvaco I3C
    master driver, and enable the existing Silvaco workaround quirks
    for both Amlogic variants.
  - Add the Amlogic compatibles and per-variant clock
    constraints to the silvaco,i3c-master binding schema.

Verified on Amlogic A9 (BY401) with both EE and AO controller
instances.  dt_binding_check and dtbs_check pass with this series.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
---
Changes in v2:

  - No need rework the Silvaco I3C driver. 
  - Based on vanilla driver, adapt A9 SoCS through callback 
    and quirks to handle the variant.

- Link to v1: https://patch.msgid.link/20261019-a9_i3c-v1-0-329d819d621f@amlogic.com

---
Junyi Zhao (2):
      i3c: master: svc: Add amlogic a9 support
      dt-bindings: i3c: silvaco,i3c-master: Add Amlogic A9 support

 .../bindings/i3c/silvaco,i3c-master.yaml           |  24 ++-
 drivers/i3c/master/svc-i3c-master.c                | 214 ++++++++++++++++++++-
 2 files changed, 231 insertions(+), 7 deletions(-)
---
base-commit: aac26bee2287c88af5be5a5ff96d783b19a28790
change-id: 20261010-a9_i3c-9d5245d094c8

Best regards,
--  
Junyi Zhao <junyi.zhao@amlogic.com>

