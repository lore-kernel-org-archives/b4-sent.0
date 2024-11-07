From: Oliver Facklam <oliver.facklam@zuehlke.com>
Subject: [PATCH 0/4] usb: typec: hd3ss3220: enhance driver with port type,
 power opmode, and role preference settings
Date: Thu, 07 Nov 2024 12:43:26 +0100
Message-Id: <20241107-usb-typec-controller-enhancements-v1-0-3886c1acced2@zuehlke.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN6nLGcC/x2NwQrCMBAFf6Xs2YUkBLX+injQ+KoLdVOyqVhK/
 73B48Aws5KhCIwu3UoFXzHJ2sAfOkrvu77A8mxMwYXovYs824PrMiFxylpLHkcUhjY34QOtxsf
 zyYfYx9APjlpnKhjk939cb9u2A+ddx6RzAAAA
X-Change-ID: 20241104-usb-typec-controller-enhancements-6871249429f0
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Oliver Facklam <oliver.facklam@zuehlke.com>, 
 Benedict von Heyl <benedict.vonheyl@zuehlke.com>, 
 Mathis Foerst <mathis.foerst@zuehlke.com>, 
 Michael Glettig <michael.glettig@zuehlke.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730979838; l=1040;
 i=oliver.facklam@zuehlke.com; s=20241107; h=from:subject:message-id;
 bh=XYYLn1zHeH3UNBGUAYyypY198vN0jFLiOM8L5eat9OE=;
 b=g+uONn75YrD3FrsvESNSt4vNkomXLwmCRwNYqfOvr1YLdbjQwB4//ktoGdzuJEdejKij7vmIN
 Tr4X2aUk+CKCMzpb8TWmvyc6HhDpxf/P8HeADh/TLaMoeXnqPfH0ugq
X-Developer-Key: i=oliver.facklam@zuehlke.com; a=ed25519;
 pk=bMlB+nko+ewJHQJLwq2t26VDbmRmNDPr/1woleqp7Lw=
X-Endpoint-Received: by B4 Relay for oliver.facklam@zuehlke.com/20241107 with auth_id=271
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TI HD3SS3220 Type-C controller supports configuring the port type,
the advertised power operation mode, and its role preference
through its I2C register map.

This patch series adds support for configuring these registers
based on existing fwnode properties and typec_operations.

Signed-off-by: Oliver Facklam <oliver.facklam@zuehlke.com>
---
Oliver Facklam (4):
      usb: typec: hd3ss3220: configure advertised power opmode based on fwnode property
      usb: typec: hd3ss3220: use typec_get_fw_cap() to fill typec_cap
      usb: typec: hd3ss3220: support configuring port type
      usb: typec: hd3ss3220: support configuring role preference based on fwnode property and typec_operation

 drivers/usb/typec/hd3ss3220.c | 171 +++++++++++++++++++++++++++++++++++-------
 1 file changed, 144 insertions(+), 27 deletions(-)
---
base-commit: afb92ad8733ef0a2843cc229e4d96aead80bc429
change-id: 20241104-usb-typec-controller-enhancements-6871249429f0

Best regards,
-- 
Oliver Facklam <oliver.facklam@zuehlke.com>

