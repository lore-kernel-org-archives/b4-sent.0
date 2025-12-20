From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH v3 0/3] arm64: dts: qcom: x1e80100-vivobook-s15: add more
 missing features
Date: Sat, 20 Dec 2025 12:38:56 +0100
Message-Id: <20251220-asus_usbc_dp-v3-0-5e244d420d0f@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANCKRmkC/12NzQ6CMBAGX4X0bE1/oKGefA9jSClbaSIUW2g0h
 He34EHxON9mZmcUwFsI6JTNyEO0wbo+AT9kSLeqvwG2TWLECCuIoDlWYQrVFGpdNQMmjHDFcqa
 FLFFSBg/GPrfc5fphD48pVcfv2NowOv/aXka6rludUkL39UgxwdI0OdRS8gLKc+vGTtn7UbsOr
 anIfnQq/nSWdK1Lk25caGn2+rIsb9Xtudf+AAAA
X-Change-ID: 20250614-asus_usbc_dp-0203a242c698
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766230738; l=1498;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=TGiVH1O1BaiBopdUw2gkpw7DmrxZfIrUFSr5F56AaSY=;
 b=F8/YRwOlXoGGF5HmjbtgIHp/0i7lIYXo5TLYYwg8+F1iZG0IGp2fsyJ4YHYtN0xAKYFWweLEH
 AviZ9MPR6JEBB8uWD1POJx0tpsfnkSXovMthf/fnVhob/c24RpHDl03
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are still many missing features on this machine, add the ps8830
retimers for display over usb-c, the simple bridge/HDMI port and set up
to use IRIS.

Currently IRIS gives a ETIMEDOUT, not sure what that is coming from.

lots of these patches are very strongly based on the work of other
maintainers of these snapdragon machines, like the HDMI part on that of
Neil Armstrong, many thanks to those who laid the baseline for me to
follow.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
Changes in v3:
- drop merged patches
- drop nvmem patch as it wasn't tested properly and didn't seem to work
- update tags
- rebase on the latest next as there was a conflict
- Link to v2: https://lore.kernel.org/r/20251116-asus_usbc_dp-v2-0-cc8f51136c9f@hotmail.com

Changes in v2:
- Fix the place of the rtmr regs to maintain alphabetical order
- Link to v1: https://lore.kernel.org/r/20251101-asus_usbc_dp-v1-0-9fd4eb9935e8@hotmail.com

---
Maud Spierings (3):
      arm64: dts: qcom: x1e80100-vivobook-s15: enable ps8830 retimers
      arm64: dts: qcom: x1e80100-vivobook-s15: add HDMI port
      arm64: dts: qcom: x1e80100-vivobook-s15: enable IRIS

 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 396 ++++++++++++++++++++-
 1 file changed, 388 insertions(+), 8 deletions(-)
---
base-commit: cc3aa43b44bdb43dfbac0fcb51c56594a11338a8
change-id: 20250614-asus_usbc_dp-0203a242c698

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

