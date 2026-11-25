From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/5] Pixel 3 display fixes
Date: Wed, 25 Nov 2026 14:08:11 +0100
Message-Id: <20261125-fix-blueline-panel-v3-0-914b4a30b73e@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTQ6CMBQE4KuQrq0pLQHrynsYF/15lWcIkhYal
 HB3W1zowricZOabhQTwCIEci4V4iBjw3qcgdgUxreqvQNGmTDjjNTswSR3OVHcTdNgDHVQPHVW
 O68bIunHckjQcPKTWhp4v7xwmfQMzZik3Wgzj3T+211jm3t+DWFJGoXFC1Rp06dQJZxz35kkyH
 /kXULKfAE+AFFVlndVGOPkB1nV9AWV5g/kFAQAA
X-Change-ID: 20260809-fix-blueline-panel-af2b7c967f2d
To: Abel Vesa <abelvesa@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Airlie <airlied@gmail.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, Jessica Zhang <jesszhan0024@gmail.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maxime Ripard <mripard@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Simona Vetter <simona@ffwll.ch>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Thomas Zimmermann <tzimmermann@suse.de>, Vinod Koul <vkoul@kernel.org>
Cc: devicetree@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1515; i=david@ixit.cz;
 h=from:subject:message-id; bh=hS+2R1WEEhHdtFJdBzf8GuRaPhYVXr3NowJRCDOllIQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBt3BGEprGvWIkV5M/UhQEk9sj1jUQjrHcBET+
 OWocuRD5+yJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawbdwQAKCRBgAj/E00kg
 cmrQEACDRepoXdI68OrR5HOo24wWyUqB069HLm4YtObpmSfgE1jxgVPVm/a7wvsK5GNTkU9fxDp
 5nnME1zxQoncc0mW/nFuEDaxQoXUBb6+n3vX9Qw7r88eT1KiUYv+jgyEIS8wMaKfO19/+L3B3UQ
 +du2GUGCz8KNKmZKMp2n/6FJlB7FLxc3PeJ8FFta7kMHhtxiqPFn92I5EHcxbUzj8MH7ez5A07N
 PU2kqQCCb/NZKeka+f6klGZwi5cZV71NmE4KWaD+vU+ZbcNGum0xl6FbVg+PQEOiUTdJSoiIV1x
 CJ02bWUudOgkbiMuWxkZWlkhQ/SGpGI2AagdQ6rj0vnuspHJIK2F6EUOBeYzzb4fBPMyExxfoBF
 X6l0bUlNCyYNwmEO366RXTCNWjXY9WHoIVf1jXRj6N0fiDCXQ4UrKb+Ap/GlIW04Z0s6ZRLATOm
 bOS0wGLhmILX8qaKAhUpbfjU7gRKRe4LotDsfqsfefstgO1LhGBqmbFtP3VvV/5h0Aq7K4Nsb/K
 9D6WEmJX6tsPTogO9cCOeVzE107Md7ea3ePxtIt8MJM3ZfaN7LtsYtOlDtzYRagtPyXQG0x8Esd
 KIVoLkGXyey1jC4fhv47XJIJ+LoOiG+dS91y10Sqxg74fdUjpXOfDR3+ETBD3UpRgOE99BZwVP/
 NvTWN9rnvWeDY6g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

1. Update backlight intensity up to what vendor use for production
   phones.

2. Keep panel power supplies in sync so panel can recover from blanking.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Properly fix the panel driver power-on/off cycle.
- Vendor in later downstream kernel commits increased BL limit to 900.
- Link to v2: https://patch.msgid.link/20260810-fix-blueline-panel-v2-0-9344dfdbc3f9@ixit.cz

Changes in v2:
- Unintended change 255 -> 256 for default brigtness. Drop it.
- Added R-bs.
- Link to v1: https://patch.msgid.link/20260809-fix-blueline-panel-v1-0-e7f3a6beb1fa@ixit.cz

---
David Heidelberg (5):
      drm/panel: lg-sw43408: use the full DCS brightness range
      drm/panel: lg-sw43408: skip backlight updates when unprepared
      drm/panel: lg-sw43408: split enable/disable from prepare/unprepare
      drm/panel: lg-sw43408: keep VPNL paired with VDDI and reset deasserted
      arm64: dts: qcom: sdm845-google: drop panel regulator-always-on

 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |   2 +
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |  10 --
 .../boot/dts/qcom/sdm845-google-crosshatch.dts     |   3 +
 drivers/gpu/drm/panel/panel-lg-sw43408.c           | 153 ++++++++++++++++++---
 4 files changed, 138 insertions(+), 30 deletions(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20260809-fix-blueline-panel-af2b7c967f2d

Best regards,
--  
David Heidelberg <david@ixit.cz>

