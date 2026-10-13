From: Mizuno Miotsuki <founder@crepuse.com>
Subject: [PATCH v4 0/3] Add Nsiway NS2009 resistive touchscreen support
Date: Tue, 13 Oct 2026 23:04:19 +0800
Message-Id: <20261013-review-self-ns2009-v4-20261013-v4-0-98bb21712282@crepuse.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHNIzmoC/z2NwQ7CIBBEf6XZsxspxUb8lcYD4GIxBg2r1aTpv
 wtUPb6ZyZsZmFIghkMzQ6IpcLjFDGrTgBtNPBOGU2aQQvataDssI3oh09VjZCmExknhv+51573
 eWyV3HrLknsiHdz0Yjivz017IPYq1LKxhQptMdGOJVv+2+mv1Pfk9wLJ8ADxV6VO1AAAA
X-Change-ID: 20261013-review-self-ns2009-v4-20261013-693ff98b425f
To: dmitry.torokhov@gmail.com
Cc: linux-input@vger.kernel.org, icenowy@aosc.io, 
 linux-kernel@vger.kernel.org, krzk+dt@kernel.org, conor+dt@kernel.org, 
 robh@kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1963; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=8yu9dNhZBhpIpdz+VxK7CfQMxfHf1h6XaO6awx5q90A=;
 b=owGbwMvMwCUmds2G2fVJ/hLG02pJDFnnPErS2MP3VQioBvCGcmhIuGVsMJo3LdGhqaZx2grT9
 8dP1m3omMjCIMbFYCmmyDJblL38UPOKa3MnNNnBzGFlAhkiLdLAAAQsDHy5iXmlRjpGeqbahnqG
 RjoGOsYMXJwCMNU3BRn+CsxdWhPNNN9gActBfbeJtZOFOMVPpd7IF9DnWfmz//ccLYb/aYEnDv6
 Z3HIvpmrNqjkPq/5yvwhKaN2xmHWHkVLu5p1b2AE=
X-Developer-Key: i=founder@crepuse.com; a=openpgp;
 fpr=9B150777C283A8D69D90823E16D63C0345E46FA4
X-Endpoint-Received: by B4 Relay for founder@crepuse.com/20261012 with auth_id=1166
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Nsiway vendor prefix, hardware binding and standalone polling
input driver for the NS2009.

Changes since v3:
- Require vdd-supply following Conor Dooley's review; keep vref-supply
  optional, including for the 10-pin package without a VREF pin.
- Manage declared supplies over the input open/close lifecycle and retain
  an outstanding enable reference if disabling fails.
- Use a named I2C device-ID initializer following the bot review.
- Preserve Conor's Acked-by on the unchanged vendor-prefix patch.

Tested on UNIHIKER M10 V1.2 with the real vcc_io regulator: touch, release,
dragging, open/close and inhibit/uninhibit passed. Tests used a validation
module and a temporary live-DT supply property; the final DTB has not been
booted. s2idle resume passed; deep wake remains unresolved.

TSC2007 reuse was investigated, but polling and raw-contact handling still
need separate policy and TI hardware regression coverage is outstanding.

The board DTS is a separate Rockchip series depending on this binding and
the previously submitted common I2C2 enablement.

Signed-off-by: Mizuno Miotsuki <founder@crepuse.com>
---
Mizuno Miotsuki (3):
      dt-bindings: vendor-prefixes: add Nsiway
      dt-bindings: input: touchscreen: add Nsiway NS2009
      Input: add Nsiway NS2009 resistive touchscreen driver

 .../bindings/input/touchscreen/nsiway,ns2009.yaml  |  79 +++++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |   7 +
 drivers/input/touchscreen/Kconfig                  |  10 +
 drivers/input/touchscreen/Makefile                 |   1 +
 drivers/input/touchscreen/ns2009.c                 | 230 +++++++++++++++++++++
 6 files changed, 329 insertions(+)
---
base-commit: 24a19b953e2a3d0ea5a8c4951a0ab8f32720c907
change-id: 20261013-review-self-ns2009-v4-20261013-693ff98b425f

Best regards,
--  
Mizuno Miotsuki <founder@crepuse.com>

