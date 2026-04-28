From: David Heidelberg <david@ixit.cz>
Date: Tue, 28 Apr 2026 16:24:38 +0200
Subject: [PATCH net] MAINTAINERS: Add myself as NFC subsystem maintainer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-nfc-maintainer-v1-1-4cb9d9e121f3@ixit.cz>
X-B4-Tracking: v=1; b=H4sIACXD8GkC/x2MQQqAIBAAvxJ7TjCLtL4SHUzX2kNbqEQQ/T3pM
 Ic5zDyQMBImGKsHIl6U6OAiTV2B2yyvKMgXByVVLztlBAcndkucCxiFWgxK3Q5SOw8lOiMGuv/
 hBIwZ5vf9AM4Q/sFlAAAA
X-Change-ID: 20260428-nfc-maintainer-2b8e073907cd
To: Jakub Kicinski <kuba@kernel.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 oe-linux-nfc@lists.linux.dev, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1098; i=david@ixit.cz;
 h=from:subject:message-id; bh=l6GCIdQ39L6+WcAMCIoelwcZypwDUixePdWvyKCAZ8Q=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp8MMnHps7MFKV1kNGTk/fEYaGbLDN8GvIuYFWB
 j50YZGtST+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCafDDJwAKCRBgAj/E00kg
 ciVjD/9EOsjFTYPuYzrgDUFKmKvA59BuFz4TJgTbiiIpawkjUtFOxUJOFgT5A4KrWj9q+oAOWoe
 Omkz3QmXQQfeWaT2j3OvVBNT/dhK5TFgmZxxn3lA9D3/TsCP//NA+4kYFKBLHVlLP3xKDws3ewL
 fFFauToM2i6xjl6o4zbsC8dcvxohaSRJUhywQKxBT5CNoy/UJjY1yHOF5unb5LqO1phg4gaFTfM
 V2vvWkcREEUoDeFr/9NnyAtfd/FGIQV0xNR1nGjXajx84pB7sc8MMOaBzV9eV6nPsYxccdbo9XN
 nGHbH48zeHtG73EzHXHNBzeexq3WneJurwOdMm2ZyI4n4hlHre6S2j0s5UWdZJvnI7nHr/3c5QO
 5M8uIaH82aaovaItqnf3JGXmvG842ursIaUZ5nu13AoYnJ7aP0lNc7Wl0X2H1Fff4nTYnEl0p60
 kZfjysqWaX6i2mH/CfHsFOEYl56EadnpMlfhpsPSb/iHn0YftxYHF67Q5PztMvnWC7s+5i9KCt8
 s5vJeZbXkpeWCB9UsxFMl7AlnnsDG6wWw5DECNQ4BMFfq0eHNI0+G/6sfyTbHj3U7WWEpWDsi/z
 +FqJVppBOKOGcFw/cRln0zveKBBcrlFA8DNKZB2u2FUd3Cxk4L9VB0VXLsLVPSvh+LyP+B8lwUd
 6xQBsNV7hXw/B2Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add myself and update the mailing list.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 MAINTAINERS | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 21288a3a7d930..176390ef4275d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -18824,18 +18824,20 @@ M:	David Ahern <dsahern@kernel.org>
 L:	netdev@vger.kernel.org
 S:	Maintained
 F:	include/net/netns/nexthop.h
 F:	include/net/nexthop.h
 F:	include/uapi/linux/nexthop.h
 F:	net/ipv4/nexthop.c
 
 NFC SUBSYSTEM
-L:	netdev@vger.kernel.org
-S:	Orphan
+M:	David Heidelberg <david+nfc@ixit.cz>
+L:	oe-linux-nfc@lists.linux.dev
+S:	Maintained
+T:	git https://codeberg.org/linux-nfc/linux.git
 F:	Documentation/devicetree/bindings/net/nfc/
 F:	drivers/nfc/
 F:	include/net/nfc/
 F:	include/uapi/linux/nfc.h
 F:	net/nfc/
 
 NFC VIRTUAL NCI DEVICE DRIVER
 M:	Bongsu Jeon <bongsu.jeon@samsung.com>

---
base-commit: 46f74a3f7d57d9cc0110b09cbc8163fa0a01afa2
change-id: 20260428-nfc-maintainer-2b8e073907cd

Best regards,
-- 
David Heidelberg <david@ixit.cz>

