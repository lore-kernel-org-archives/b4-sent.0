From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH wireless-next 0/4] wifi: brcmfmac: Add support for 6 GHz
 operation
Date: Fri, 13 Nov 2026 06:31:54 +0000
Message-Id: <20261113-6ghz-v1-0-0b9a67e413a9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBQFr0Le2iYWIhCvYlyU8oBvTDX9KATC3
 a2wnMxkViijUHHNVkR+ReUVEthTBj+40NNImxj5OS+ttYUp+2Exrm4vdeWawnsipe/ITuZ9c8M
 kkU+qmsB5xP3Q+mke9ON/hW37AfWOKtx3AAAA
X-Change-ID: 20261113-6ghz-a8d587ab3cce
To: Arend van Spriel <arend.vanspriel@broadcom.com>
Cc: asahi@lists.linux.dev, linux-wireless@vger.kernel.org, 
 brcm80211@lists.linux.dev, brcm80211-dev-list.pdl@broadcom.com, 
 linux-kernel@vger.kernel.org, Michael Reeves <michael.reeves077@gmail.com>, 
 Daniel Berlin <dberlin@dberlin.org>, Yureka Lilian <yureka@cyberchaos.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794551523; l=1842;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=O2HbX3PGoxwHaTzbO9NvLzP3Q0NQYtRhPhMh4oU9kEY=;
 b=lpongLP+YiC0s/OvTNBUYPbK8V7Ti1fI4slD5KFcSIQVYpJMBlgTvJiZHV0uHW+ThRZJLLo4Q
 XJAEiUAm+87DmvZDEUY3SDYprUoQ4KrQo/2ch8hLJ9cr5EKTqF2NU+M
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Arend, all,

This series adds support for 6 GHz (Wi-Fi 6E) operation to brcmfmac.

It includes HE capability advertisement, 6 GHz chanspec and band
handling and PNO version 3 support. The PNO support is required to avoid
channel-number collisions with 2.4/5 GHz during scheduled scans.

It is adapted from our downstream work in the Asahi kernel by Daniel
Berlin, but reworked to make the code cleaner and more maintainable.

As I don't have a 6 GHz AP to test with, Yureka Lilian tested this
series on my behalf, on her Apple Silicon M3 Mac (BCM4388). Connection
and use of a 6 GHz network was successful, without regressions on 2.4 
GHz or 5 GHz operation.

Thank you for your time,
Michael

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
Daniel Berlin (2):
      wifi: brcmfmac: Add support for 6 GHz chanspecs
      wifi: brcmfmac: Add support for the 6 GHz band

Michael Reeves (2):
      wifi: brcmfmac: Advertise HE capabilities
      wifi: brcmfmac: Add support for PNO version 3

 .../broadcom/brcm80211/brcmfmac/cfg80211.c         | 477 +++++++++++++++------
 .../broadcom/brcm80211/brcmfmac/cfg80211.h         |   2 +
 .../broadcom/brcm80211/brcmfmac/fwil_types.h       |  68 +++
 .../net/wireless/broadcom/brcm80211/brcmfmac/p2p.c |   6 +-
 .../net/wireless/broadcom/brcm80211/brcmfmac/pno.c | 147 ++++++-
 .../net/wireless/broadcom/brcm80211/brcmfmac/pno.h |  41 +-
 .../net/wireless/broadcom/brcm80211/brcmutil/d11.c |   7 +-
 .../broadcom/brcm80211/include/brcmu_d11.h         |   3 +-
 .../broadcom/brcm80211/include/brcmu_wifi.h        |   1 +
 9 files changed, 585 insertions(+), 167 deletions(-)
---
base-commit: 3c311bf321442d4c4f452a1a08bc9efce242a1f9
change-id: 20261113-6ghz-a8d587ab3cce

Best regards,
--  
Michael Reeves <michael.reeves077@gmail.com>

