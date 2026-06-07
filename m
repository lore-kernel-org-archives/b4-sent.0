From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v4 0/2] drm/panel: Add panel driver for Chipone ICNA35XX
 based panels
Date: Sun, 07 Jun 2026 15:11:43 -0500
Message-Id: <20260607-icna35xx-v4-0-64de514add34@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WPy26DMBBFfwV5XVfjJ4ZV/6Pqwh4PiaUCCaaIK
 OLf68KiqFKXdzTnPp4s05Qos7Z6somWlNM4FKFfKoZXP1yIp1g0kyAtSAk84eCVWVdO2PjOC0X
 Ce1bebxN1ad2t3j8OPdH9qzjOx5EFn4nj2PdpbitLTpuAoXbYGN81ykCjQUOImiIqlMHGWDvNz
 k3a6ughau4fA79jdsYAFxahDlZFkrZdHPuJv6Y8j9NjH7aIPX9nS8zvhkVw4Na5qEqqgK55u/Q
 +fb6WkrvJIk+g0CdQFlAbj1HEzhtr/4LqP1AVEBXoDjQqifoMbtv2DVzpjuaRAQAA
X-Change-ID: 20260220-icna35xx-ec9afa13e1aa
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780863114; l=2471;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=+oftQmEW5pT/mCCZUYM3/CYSfFCJ98f3GJKlfF1qTuo=;
 b=2LPwrUIrbPaRDm/C/IGBOR8zNhgN3s/2+Rq/Xv/EmakMASKN8Ns/pG2AGC06dL7DpisTdRjua
 vKaCEYwCSMqAOPXvQen18ndaJx+jLyRI8r85grK/cRd2oqitvzDcZir
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This driver is based on the one by Teguh Sobirin [0].
    
Due to [1], the AYN vendor description patch has been folded into the
AYN QCS8550 dt series. Which means this series depends on said series
and it must be picked up before this.

[0] https://github.com/AYNTechnologies/linux/commit/4c5e76e974db7cca853619ca138eecd8f004622f
[1] https://lore.kernel.org/linux-arm-msm/c7fb3f89-6574-4761-9ef2-2fdf6d4801b5@kernel.org

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v4:
- Drop all but one mode per variant, to avoid manual lookup of requested
  refresh rate
- Use more devm, eliminating the need for a remove function
- Don't lose lpm mode in brightness handling if an error happens
- Link to v3: https://lore.kernel.org/r/20260514-icna35xx-v3-0-c304f04c32c4@gmail.com

Changes in v3:
- Rename binding in patch 1 to icna3512 to match a compatible being used
- Edit commit messages in both patches 1 and 2 to better clarify the
  supported hardware and differences
- Link to v2: https://lore.kernel.org/r/20260514-icna35xx-v2-0-45acd1dfa566@gmail.com

Changes in v2:
- Fix lint warning in patch 1
- Add ayaneo,pocketds-panel-top compatible to patches 1 and 2, it uses the
  same init sequence as the odin 2 portal panel.
- Link to v1: https://lore.kernel.org/r/20260509-icna35xx-v1-0-688d3d4e10f9@gmail.com

---
Aaron Kling (1):
      dt-bindings: display: panel: Add Chipone ICNA3512 OLED driver bindings

Teguh Sobirin (1):
      drm/panel: Add panel driver for Chipone ICNA35XX based panels

 .../bindings/display/panel/chipone,icna3512.yaml   |  79 ++++
 drivers/gpu/drm/panel/Kconfig                      |  11 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-chipone-icna35xx.c     | 422 +++++++++++++++++++++
 4 files changed, 513 insertions(+)
---
base-commit: 6e845bcb78c95af935094040bd4edc3c2b6dd784
change-id: 20260220-icna35xx-ec9afa13e1aa
prerequisite-change-id: 20260217-ayn-qcs8550-16c07b63de26:v8
prerequisite-patch-id: 2b010637c46f5ea0e19a2fa87cc5ccb19bfd9204
prerequisite-patch-id: d0c633dc17f0aba726a8e8d21fee52b944bf67ff
prerequisite-patch-id: 11f4208bd788df984cec7404088c7d071ec49dfc
prerequisite-patch-id: 76b61799dba520fc7fa3ff39b044e24103337af3
prerequisite-patch-id: 3844bef2eda3cf59031b1d131eb6ba9295629bb4
prerequisite-patch-id: 3331648bc6f4ac3bb156f0525aa1ede92bfc57f1

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

