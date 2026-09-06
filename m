From: Ryan Brue <ryanbrue.dev@gmail.com>
Subject: [PATCH 0/2] drm/panel: add the Novatek NT51021 panel in the Amazon
 Fire HD 10
Date: Sat, 05 Sep 2026 20:34:33 -0500
Message-Id: <20260905-rbrue-drm-panel-add-novatek-nt51021-v1-0-939f59e89fc9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNSw7CIBRG4a00d+xNAC0+ttI4gPKr+KDNhTYmT
 fcu6vCbnLNQhkRkOjULCeaY45Aq9Kah/ubSFRxDNRllrDqqlsXLBA7y4tElPNmFwGmYXcGDU2m
 1Mpq9OVhn99gFbKmWRsElvn+X7vx3nvwdffmmaV0/SGaatYcAAAA=
X-Change-ID: 20260905-rbrue-drm-panel-add-novatek-nt51021-b286a67e4de3
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Ryan Brue <ryanbrue.dev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788658475; l=2651;
 i=ryanbrue.dev@gmail.com; s=20260906; h=from:subject:message-id;
 bh=avEl6Sz+TjiLyylxOf8PD9ekUp90PnIXR/pxu3BUxLI=;
 b=IM9PZI28G1lsl2IHZmyHX/r5dytfWQ+wNiSCk8fbEACgafyEcl7++eFRZXKVKGsEqGm2VIT8y
 NYtLQvN0fL0Dz6Y2Q0icOzhiwm9RZ9b+m0ngUZM3OweE12+z99l4ydr
X-Developer-Key: i=ryanbrue.dev@gmail.com; a=ed25519;
 pk=KsUvVaP//v/2q+ZBuacc7cLbsyEYn+AD71Sn28oZWKo=
X-Endpoint-Received: by B4 Relay for ryanbrue.dev@gmail.com/20260906 with auth_id=1007
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the 1200x1920 DSI panel fitted to the Amazon Fire HD 10 (2017), an
MT8173 tablet. The controller is a Novatek NT51021; the module carries
BOE glass.

The controller has no readable panel identity. MediaTek's LCM framework
identifies panels through a .compare_id callback and the vendor's driver
for this one leaves it unset, and the glass part number is not recorded
anywhere in the vendor tree -- it names the module only "BOE". I had the
compatible name the module after the board it ships in, the way
xiaomi,elish-boe-nt36523 and lenovo,j606f-boe-nt36523w do for this
situation.

The vendor's bootloader and kernel both carry a second register sequence
for Innolux glass, selected from two board ID straps, so a second module
exists as far as the vendor firmware is concerned. I didn't have an
Innolux unit to test with, and I don't know its part number, so it is not
described here. Naming the glass in the compatible leaves room for it as
a second compatible should someone have the hardware and the need.

This controller accepts commands either over I2C or in-band over DSI, and
on the shipping boards it does not default to DSI. Writing 0xa5 to
register 0x8f opens a window in which DSI commands are accepted and
writing 0x00 closes it, so every command the driver sends, including
sleep in/out and display on/off, has to sit inside such a window. That is
why those are not simply issued from enable()/disable() as most panel
drivers do.

The vendor's timings are used verbatim.

The board DTS that uses this is not in this series -- it's a whole new
board file that I plan on upstreaming over time after getting its
components upstreamed.

Tested on the Amazon Fire HD 10 (2017) driven by mediatek-drm: 1200x1920
at 62.5 Hz across a cold boot, three display off and on cycles and a
suspend/resume, with the MIPI TX PLL read back at the intended rate.

Signed-off-by: Ryan Brue <ryanbrue.dev@gmail.com>
---
Ryan Brue (2):
      dt-bindings: display: panel: add Novatek NT51021
      drm/panel: add Novatek NT51021 1200x1920 DSI panel driver

 .../bindings/display/panel/novatek,nt51021.yaml    |  65 ++++
 MAINTAINERS                                        |   7 +
 drivers/gpu/drm/panel/Kconfig                      |  11 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-novatek-nt51021.c      | 329 +++++++++++++++++++++
 5 files changed, 413 insertions(+)
---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260905-rbrue-drm-panel-add-novatek-nt51021-b286a67e4de3

Best regards,
--  
Ryan Brue <ryanbrue.dev@gmail.com>

