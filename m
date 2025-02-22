From: Hans-Frieder Vogt <hfdevel@gmx.net>
Date: Sat, 22 Feb 2025 10:49:34 +0100
Subject: [PATCH net-next v5 7/7] net: tn40xx: add pci-id of the
 aqr105-based Tehuti TN4010 cards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250222-tn9510-v3a-v5-7-99365047e309@gmx.net>
References: <20250222-tn9510-v3a-v5-0-99365047e309@gmx.net>
In-Reply-To: <20250222-tn9510-v3a-v5-0-99365047e309@gmx.net>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hans-Frieder Vogt <hfdevel@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740217800; l=1329;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=dE9RmcpNBtcvMxg1vX89VIDp9W8qYafc8S1ojRZqfFQ=;
 b=Jca7171c2uczNOMWGlSjnywuy7MH4h3qJirWdBJgy1NgIZl6wUT0ArOXOYPo6xeFox8EG50uG
 FBwaZOTvq9KCcieSWwSm6BiO+AnNBJqM4JsTOcpkAzU+wp5SYbs5IE2
X-Developer-Key: i=hfdevel@gmx.net; a=ed25519;
 pk=s3DJ3DFe6BJDRAcnd7VGvvwPXcLgV8mrfbpt8B9coRc=
X-Endpoint-Received: by B4 Relay for hfdevel@gmx.net/20240915 with auth_id=209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PCI-ID of the AQR105-based Tehuti TN4010 cards to allow loading
of the tn40xx driver on these cards. Here, I chose the detailed definition
with the subvendor ID similar to the QT2025 cards with the PCI-ID
TEHUTI:0x4022, because there is a card with an AQ2104 hiding amongst the
AQR105 cards, and they all come with the same PCI-ID (TEHUTI:0x4025). But
the AQ2104 is currently not supported.

Signed-off-by: Hans-Frieder Vogt <hfdevel@gmx.net>
Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Reviewed-by: FUJITA Tomonori <fujita.tomonori@gmail.com>
---
 drivers/net/ethernet/tehuti/tn40.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/ethernet/tehuti/tn40.c b/drivers/net/ethernet/tehuti/tn40.c
index a4dd04fc6d89e7f7efd77145a5dd883884b30c4b..aaad40c916ef83f457e1b5983c01dff2de148fea 100644
--- a/drivers/net/ethernet/tehuti/tn40.c
+++ b/drivers/net/ethernet/tehuti/tn40.c
@@ -1835,6 +1835,10 @@ static const struct pci_device_id tn40_id_table[] = {
 			 PCI_VENDOR_ID_ASUSTEK, 0x8709) },
 	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_TEHUTI, 0x4022,
 			 PCI_VENDOR_ID_EDIMAX, 0x8103) },
+	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_TEHUTI, 0x4025,
+			 PCI_VENDOR_ID_TEHUTI, 0x3015) },
+	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_TEHUTI, 0x4025,
+			 PCI_VENDOR_ID_EDIMAX, 0x8102) },
 	{ }
 };
 

-- 
2.47.2

