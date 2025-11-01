From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH 0/6] arm64: dts: qcom: x1e80100-vivobook-s15: add more
 missing features
Date: Sat, 01 Nov 2025 13:54:11 +0100
Message-Id: <20251101-asus_usbc_dp-v1-0-9fd4eb9935e8@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPMCBmkC/yWN24rCMBRFf6Xk2SO5tDEpg/gfg0iac6IB23SSV
 gTx3yfVx7Vhr/VihXKkwvrmxTI9YolpqiB2DfM3N10JIlZmksuOa9GCK2u5rGXwF5yBS66cbKX
 X1rB6mTOF+Pzofs9fzvS3VuvyHdlIpbiPtW9+NqngQsGS5ujhKchwwTnccIzw0MBBOetNONQ06
 tM9Ti6nfcrX4xYbXCHwaRzj0jfWDGgGoR11BzJBdt522FodPJLCgGikVNgKdn6//wG1sxP+9QA
 AAA==
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
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762001681; l=1678;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=u8wLUW6Z9fiKj5eOJYtlEh+2BUk0OgRlOVt2xpH117E=;
 b=zZCnXRfNh5ObdUMoRA0mRNkebgUnURd3FVRw3ClZhVV36UkJPFZ1zarismFBaXyve+lPr+fvc
 kaeH65WFNenAPU5QkTPWLPNiEoi1BjmzdZOjk+cYd85IxnBzVV8D7Zi
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
Maud Spierings (6):
      dt-bindings: display: bridge: simple: document the Parade PS185HDM DP-to-HDMI bridge
      drm/bridge: simple: add the Parade PS185HDM DP-to-HDMI bridge
      arm64: dts: qcom: x1e80100-vivobook-s15: enable ps8830 retimers
      arm64: dts: qcom: x1e80100-vivobook-s15: add HDMI port
      arm64: dts: qcom: x1e80100-vivobook-s15: add charge limit nvmem
      arm64: dts: qcom: x1e80100-vivobook-s15: enable IRIS

 .../bindings/display/bridge/simple-bridge.yaml     |   1 +
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 402 ++++++++++++++++++++-
 drivers/gpu/drm/bridge/simple-bridge.c             |   5 +
 3 files changed, 400 insertions(+), 8 deletions(-)
---
base-commit: 98bd8b16ae57e8f25c95d496fcde3dfdd8223d41
change-id: 20250614-asus_usbc_dp-0203a242c698
prerequisite-message-id: <20251013-topic-x1e80100-hdmi-v6-0-3a9c8f7506d6@linaro.org>
prerequisite-patch-id: 5af0a76cad087e18b0a2f771a78d030f9bf3bd68
prerequisite-patch-id: 5b908c1f0c5a0c52da384a181a75f17c5e2d19b5
prerequisite-patch-id: ed40af8d7e99a3f1bcb33b4c678b5f21b0618612

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

