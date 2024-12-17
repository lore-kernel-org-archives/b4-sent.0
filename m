From: Hans-Frieder Vogt <hfdevel@gmx.net>
Date: Tue, 17 Dec 2024 22:07:38 +0100
Subject: [PATCH net-next v3 7/7] net: tn40xx: add pci-id of the
 aqr105-based Tehuti TN4010 cards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241217-tn9510-v3a-v3-7-4d5ef6f686e0@gmx.net>
References: <20241217-tn9510-v3a-v3-0-4d5ef6f686e0@gmx.net>
In-Reply-To: <20241217-tn9510-v3a-v3-0-4d5ef6f686e0@gmx.net>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, Hans-Frieder Vogt <hfdevel@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734469657; l=1228;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=aJL2+Qt1fXp1c8Nkhc4Qvp7fWnaLIrf+lqxUzAEbh+w=;
 b=ykcDIxI1JWhHGDCGeBp/uszL6eStVzeak/U/tdYGxkuh67ZfBvP/SyieLLLsMWqxADcAkyS0O
 PUm2L9mpc+QDbt4EIfovsq189psHzM9/jnw8yM7fdegdfICNc9Lr0I3
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
---
 drivers/net/ethernet/tehuti/tn40.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/ethernet/tehuti/tn40.c b/drivers/net/ethernet/tehuti/tn40.c
index 5f73eb1f7d9f74294cd5546c2ef4797ebc24c052..2f4e0dad388f84d6daf651d67ef99c6f62244586 100644
--- a/drivers/net/ethernet/tehuti/tn40.c
+++ b/drivers/net/ethernet/tehuti/tn40.c
@@ -1840,6 +1840,10 @@ static const struct pci_device_id tn40_id_table[] = {
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
2.45.2

