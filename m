From: =?utf-8?q?Stanis=C5=82aw_Titenko?= <kernel@resetko.pl>
Subject: [PATCH v2 0/2] usb: typec: ucsi: acpi: Zero version quirk for
 Lenovo ThinkPad T14 Gen 2a
Date: Tue, 03 Nov 2026 17:10:19 +0100
Message-Id: <20261103-ucsi-lenovo-t14g2a-v2-0-e85c659b56a2@resetko.pl>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBREr0L+2hpalKIr72FY1PILX0lL2tJoC
 He34N7M6iUzbxYI6AkDXIsFPCYK5GwGcShAD8r2yKjLDKIUNS8rzmYdiI1oXXIs8lMvFFOdQtk
 Zqc2lgTycPBp679J7++MwP56o42baGgOF6Pxnf0186/09SJzlNJU8c6wrXYpbNmJ8ueM0Qruu6
 xei3gP8xwAAAA==
X-Change-ID: 20261031-ucsi-lenovo-t14g2a-adae7df7cf98
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, 
 =?utf-8?q?Stanis=C5=82aw_Titenko?= <kernel@resetko.pl>, 
 stable@vger.kernel.org, Daniel Dev <daniel.dev@noex.uk>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793722249; l=1240;
 i=kernel@resetko.pl; s=20261031; h=from:subject:message-id;
 bh=p//gIxG0/4XKWUIu5qLUQ3pQMFy2I5L0ehYWw5C0oIU=;
 b=ryKdmPp1FcjTXd/ovnXlgELckP5xFn69Zq5k4covVsZxy7P2b5G5oKryYK2v4unLl8GGrCQ+s
 PchvYToK+ckAffIKzuAD4AH+zqBeWCP+17CGYPk42tDs9BWlUBWEOtx
X-Developer-Key: i=kernel@resetko.pl; a=ed25519;
 pk=xMhqzbyPNWfeOgdmzSHsSlr5qjH779F5SD6BBHXixlY=
X-Endpoint-Received: by B4 Relay for kernel@resetko.pl/20261031 with auth_id=1372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ThinkPad T14 Gen 2a firmware leaves the UCSI VERSION field at zero,
so ucsi_acpi does not register the Type-C ports. Mark Pearson is asking
Lenovo's firmware team to look at it; this quirk is the fallback in case
a firmware fix is not possible.

Patch 1 renames the existing Acer quirk to a neutral name, patch 2 uses
it for the ThinkPad T14 Gen 2a.

Signed-off-by: Stanisław Titenko <kernel@resetko.pl>
---
Changes in v2:
- Reuse the Acer zero version quirk instead of a new Lenovo copy, so the
  assumed version is now 1.2 instead of 1.0 (Mark Pearson).
- Match on DMI_BOARD_NAME 20XK and 20XL instead of the product version
  string (Mark Pearson).
- Link to v1: https://patch.msgid.link/20261031-ucsi-lenovo-t14g2a-v1-1-183751e63c02@resetko.pl

---
Stanisław Titenko (2):
      usb: typec: ucsi: acpi: Rename the Acer zero version quirk
      usb: typec: ucsi: acpi: Assume UCSI 1.2 on Lenovo ThinkPad T14 Gen 2a

 drivers/usb/typec/ucsi/ucsi_acpi.c | 24 ++++++++++++++++++++----
 1 file changed, 20 insertions(+), 4 deletions(-)
---
base-commit: e9954f3fbddd25e1a01b7e5a0b72fb8b564204e0
change-id: 20261031-ucsi-lenovo-t14g2a-adae7df7cf98

Best regards,
--  
Stanisław Titenko <kernel@resetko.pl>

