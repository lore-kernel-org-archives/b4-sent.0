From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH v3 0/3] usb: dwc2: Add Siflower SF19A2890 support
Date: Fri, 20 Nov 2026 15:31:05 -0500
Message-Id: <20261120-sf19a2890-dwc2-v3-0-de377bd408a0@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAmuAGsC/2WNzQ6CMBAGX4X0bA1dKKWefA/jobSLVA2YFquG8
 O62GBN/bjvJN7MT8egserLJJuIwWG+HPkKxyojuVH9Aak1kAjlUjOVAfcukglrm1Nw00FpwUbR
 CY4OGROnisLX3Jbjbv9hfmyPqMVXSorN+HNxj+RhY2r3j5W88MBovyWUhOEKlmu2IZ6VOa4OBp
 HqAD5+xPx+irxsljSlVCbz68ud5fgJVnBlR/wAAAA==
X-Change-ID: 20261102-sf19a2890-dwc2-87573f7cebed
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795206676; l=2375;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=5Fbe18oY4Op0Orls0kCxG//pb0Q6XyFf2Ud9BgK1RGo=;
 b=eMv2f/LlgjHl/vhxaWhaeobxe+GjTNRBWd504efnupfITibJXJTKjn/mtN0c3G47ZTamNkGLK
 TD3TVrSCQI8BCFt+VvFCiJmK3oxsApJXu7P3kl1/Vo4phe+sathJEAE
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Siflower SF19A2890, a MIPS SoC for home routers, has a DWC OTG 3.30a.
This series adds its compatible and parameters, and handles an
interrupt it raises without flagging it: with battery charger support
enabled, the core sets MultValIpChng in GOTGINT but not OTGINT in GINTSTS,
so the interrupt is never cleared. Chuanhong saw the line disabled with
"nobody cares"; on the GL-SFT1200 the system stalls instead (below).

The two driver patches are Chuanhong Guo's, from OpenWrt and his
SF19A2890 branch. The OTG one handled GOTGINT on every interrupt for
every core; here it does so only for cores that set the new
otg_int_unflagged parameter, which only the SF19A2890 does.

Tested on a GL.iNet GL-SFT1200 with the USB PHY driver: a USB stick
enumerates at 480 Mb/s, reads at 5.6 MB/s and comes back cleanly after
two replugs. Without patch 3, a couple of replugs leave the system
stuck, the console repeating its last message with the same timestamp
until a power cycle; no "nobody cares" message appears first.

---
Changes in v3:
- Send to Thinh Nguyen, who took over dwc2 in commit 688bee95b423
  ("MAINTAINERS: take over dwc2 maintainership") after v7.4-rc1 (Greg).
- No code changes.
- Link to v2: https://patch.msgid.link/20261111-sf19a2890-dwc2-v2-0-cba9dd4a4256@telaak.dev

Changes in v2:
- Write my notes on Chuanhong's patches as lists, with Co-developed-by
  on the OTG interrupt patch.
- Sort the new compatible in the binding and in the match table.
- Describe the OTG interrupt fix as it is now in its commit message.
- Patch 1: add Conor's Ack.
- Link to v1: https://patch.msgid.link/20261104-sf19a2890-dwc2-v1-0-d959375e26ab@telaak.dev

---
Chuanhong Guo (2):
      usb: dwc2: Add Siflower SF19A2890 support
      usb: dwc2: Handle OTG interrupts that GINTSTS does not flag

Joseph Telaak (1):
      dt-bindings: usb: dwc2: Add Siflower SF19A2890

 Documentation/devicetree/bindings/usb/dwc2.yaml |  1 +
 drivers/usb/dwc2/core.h                         |  6 ++++++
 drivers/usb/dwc2/core_intr.c                    |  5 ++++-
 drivers/usb/dwc2/params.c                       | 11 +++++++++++
 4 files changed, 22 insertions(+), 1 deletion(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261102-sf19a2890-dwc2-87573f7cebed

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

