From: Yassine Oudjana <y.oudjana@protonmail.com>
Subject: [PATCH v2 0/4] MediaTek MT6735+MT6328 SoC/PMIC pair base support
Date: Sun, 31 May 2026 11:10:41 +0200
Message-Id: <20260531-mt6735-pwrap-mt6328-pmic-v2-0-dac37bf92894@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6DIBBA0auYWTuJQlHqVUwXFkYdEy0BrCbGu
 xfr8i3+PyCQZwrQZAd4+nLgz5Ig8gzM2C0DIdtkEIWoCiVLnGNVS4Vu8527IIVGN7NBSw9dWmU
 U6Sek3Hnqef+v29ftsL4nMvH6wXn+ACxelj58AAAA
X-Change-ID: 20260531-mt6735-pwrap-mt6328-pmic-de481d5c5e89
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Flora Fu <flora.fu@mediatek.com>, Alexandre Mergnat <amergnat@baylibre.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: Yassine Oudjana <y.oudjana@protonmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-input@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780218643; l=1752;
 i=y.oudjana@protonmail.com; s=20260531; h=from:subject:message-id;
 bh=qCSXdL7UxE/qWT/uKT+Nivjqkn1rjsbMggSsnxkbbJI=;
 b=BErCPRXo/UmHpL4V4wTM++8swxKEM9ihvG6lllxqkHzSSemqvXk3gF3LIB3ZuJUlbddkmnxdG
 LzTHPsEoeuCA68WBkRzcvpASMMtAFSnN9O0TMQ330sRYmlETgOTzC57
X-Developer-Key: i=y.oudjana@protonmail.com; a=ed25519;
 pk=sr7uwnyVqGKAIhvwnIwormkDM3d2VNc3VOTEU1GmsEM=
X-Endpoint-Received: by B4 Relay for y.oudjana@protonmail.com/20260531 with auth_id=802
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These patches are part of a larger effort to support the MT6735 SoC family in
mainline Linux. More patches (unsent or sent and pending review or revision)
can be found here[1].

This series adds base support for the MediaTek MT6735 SoC and MT6328 PMIC pair.
This includes PMIC wrapper support on the SoC side and regulators and keys on
the PMIC side. The PMIC has other blocks such as an audio codec and battery
charger which can be supported in the future.

Changes since v1:
- Fit regulator definitions in 2 lines and 100 characters whenever possible.
- Remove get_mode and set_mode ops for regulators that don't support them.

[1] https://gitlab.com/mt6735-mainline/linux/-/commits/mt6735-staging

Signed-off-by: Yassine Oudjana <y.oudjana@protonmail.com>
---
Yassine Oudjana (4):
      dt-bindings: mediatek: pwrap: Add MT6735 compatible
      soc: mediatek: pwrap: Add support for MT6735 and MT6328 SoC/PMIC pair
      regulator: Add driver for MediaTek MT6328 PMIC regulators
      Input: mtk-pmic-keys - Add support for MT6328

 .../bindings/soc/mediatek/mediatek,pwrap.yaml      |   1 +
 drivers/input/keyboard/mtk-pmic-keys.c             |  15 +
 drivers/regulator/Kconfig                          |   9 +
 drivers/regulator/Makefile                         |   1 +
 drivers/regulator/mt6328-regulator.c               | 500 +++++++++++++++++++++
 drivers/soc/mediatek/mtk-pmic-wrap.c               | 177 +++++++-
 include/linux/regulator/mt6328-regulator.h         |  49 ++
 7 files changed, 749 insertions(+), 3 deletions(-)
---
base-commit: 7da7f07112610a520567421dd2ffcb51beaefbcc
change-id: 20260531-mt6735-pwrap-mt6328-pmic-de481d5c5e89

Best regards,
--  
Yassine Oudjana <y.oudjana@protonmail.com>

