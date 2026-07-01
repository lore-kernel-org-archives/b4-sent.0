From: Enrico Pozzobon <enrico.pozzobon@dissecto.com>
Date: Wed, 01 Jul 2026 15:09:17 +0200
Subject: [PATCH net v2] net: usb: lan78xx: disable VLAN filter in
 promiscuous mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260701-lan78xx-vlan-promisc-v2-1-fe3b18066728@dissecto.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBBFr0JmbU1pDVRX3sOwKGUqNdKSDjYYw
 t0tsHU3f/L/ewsQRocEt2KBiMmRCz4HcSrA9No/kbkuZxBcVLwSkr21r9U8s5QPNsYwODJMSW2
 Vvihdo4E8HSNaN+/YB3icoDme9GlfaKYNuNV6R1OI312eyr18eCT/70klK5ltLbdXLttO2Xvni
 DIxnE0YoFnX9Qc2Xx2z0gAAAA==
X-Change-ID: 20260623-lan78xx-vlan-promisc-83af8a48a7ec
To: Thangaraj Samynathan <Thangaraj.S@microchip.com>, 
 Rengarajan Sundararajan <Rengarajan.S@microchip.com>, 
 UNGLinuxDriver@microchip.com, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Woojung.Huh@microchip.com
Cc: netdev@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Enrico Pozzobon <enrico.pozzobon@dissecto.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3269;
 i=enrico.pozzobon@dissecto.com; h=from:subject:message-id;
 bh=rGcMhaGh8vx4flQNrrguekcQBVNvDJ+Fjwh146Hf4xE=;
 b=owGbwMvMwMX4ocx1yy5WiZWMp9WSGLJcBes6Ff5trmPR/SewrJa5WaaFryTmc/KtZ24fUv6xq
 q3cVLWlk9GYhYGRi0FWTJHl52eBq7P6ssoWmx7UghnEygQyhYGLUwAmIt7MwXBkZ9s+3pLnph2X
 Z+c6tt6+Ei1ixXH62os0vdozEZXPP8w4IBG+8kjqVqXWMFmrF69NtNLYbKanbN+8pUD5TMzxo8r
 HK45n3zgT3n3pwpaUh16STy5b2DqwqBzgF37dZlL2bs1S8R15tQZuoaYWGnl+E1tfTOqO6dd0L4
 z8V6Epm8Tx8kemwskz7MkPZu/frSBrKrBQ+pxTie8dls4ffso5zRd1Sgvil7xosVCYK3RaVHVfy
 1m9G4Jz5q1nvWvVxirzwTI96+P2lAdFa3ViJMIlGwqq++rWdVnkHnc+q8Cv9kvBYL96rd3GTym/
 /5+O8d1skCNcIG3I9F505vwLEVnuj091+s7pO6R5sE4YAA==
X-Developer-Key: i=enrico.pozzobon@dissecto.com; a=openpgp;
 fpr=53D697CA0B11F68C9552A59DA3D0B3A0924EA5BB
X-Endpoint-Received: by B4 Relay for enrico.pozzobon@dissecto.com/default with auth_id=836
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The hardware VLAN filter (RFE_CTL_VLAN_FILTER_) drops VLAN-tagged frames
whose VID has not been registered via lan78xx_vlan_rx_add_vid(). It is
left enabled in promiscuous mode, so packet capture (e.g. tcpdump or
Wireshark) does not see tagged frames for unregistered VIDs.

Clear the filter while the interface is promiscuous and restore it from
NETIF_F_HW_VLAN_CTAG_FILTER otherwise. Enforce the same condition in
lan78xx_set_features() so netdev_update_features() cannot re-enable the
filter while promiscuous.

Fixes: 55d7de9de6c3 ("Microchip's LAN7800 family USB 2/3 to 10/100/1000 Ethernet device driver")
Signed-off-by: Enrico Pozzobon <enrico.pozzobon@dissecto.com>
---
Currently, on microchip lan7801, enabling promiscuous mode does not
result in VLAN tagged packets being captured. This patch fixes this,
forcing the RFE_CTL_VLAN_FILTER_ flag to be off when promiscuous mode is
enabled.
---
Changes in v2:
- moved VLAN filter logic into lan78xx_update_vlan_filter()
- Link to v1: https://patch.msgid.link/20260630-lan78xx-vlan-promisc-v1-1-fbf0f903bd8f@dissecto.com

To: Thangaraj Samynathan <Thangaraj.S@microchip.com>
To: Rengarajan Sundararajan <Rengarajan.S@microchip.com>
To: UNGLinuxDriver@microchip.com
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: "David S. Miller" <davem@davemloft.net>
To: Eric Dumazet <edumazet@google.com>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Woojung.Huh@microchip.com
Cc: netdev@vger.kernel.org
Cc: linux-usb@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 drivers/net/usb/lan78xx.c | 18 ++++++++++++++----
 1 file changed, 14 insertions(+), 4 deletions(-)

diff --git a/drivers/net/usb/lan78xx.c b/drivers/net/usb/lan78xx.c
index c4cebacabcb5..cb782d81d84f 100644
--- a/drivers/net/usb/lan78xx.c
+++ b/drivers/net/usb/lan78xx.c
@@ -1499,6 +1499,17 @@ static void lan78xx_deferred_multicast_write(struct work_struct *param)
 	return;
 }
 
+static void lan78xx_update_vlan_filter(struct lan78xx_priv *pdata,
+				       struct net_device *netdev,
+				       netdev_features_t features)
+{
+	if ((features & NETIF_F_HW_VLAN_CTAG_FILTER) &&
+	    !(netdev->flags & IFF_PROMISC))
+		pdata->rfe_ctl |= RFE_CTL_VLAN_FILTER_;
+	else
+		pdata->rfe_ctl &= ~RFE_CTL_VLAN_FILTER_;
+}
+
 static void lan78xx_set_multicast(struct net_device *netdev)
 {
 	struct lan78xx_net *dev = netdev_priv(netdev);
@@ -1533,6 +1544,8 @@ static void lan78xx_set_multicast(struct net_device *netdev)
 		}
 	}
 
+	lan78xx_update_vlan_filter(pdata, dev->net, dev->net->features);
+
 	if (netdev_mc_count(dev->net)) {
 		struct netdev_hw_addr *ha;
 		int i;
@@ -3074,10 +3087,7 @@ static int lan78xx_set_features(struct net_device *netdev,
 	else
 		pdata->rfe_ctl &= ~RFE_CTL_VLAN_STRIP_;
 
-	if (features & NETIF_F_HW_VLAN_CTAG_FILTER)
-		pdata->rfe_ctl |= RFE_CTL_VLAN_FILTER_;
-	else
-		pdata->rfe_ctl &= ~RFE_CTL_VLAN_FILTER_;
+	lan78xx_update_vlan_filter(pdata, netdev, features);
 
 	spin_unlock_irqrestore(&pdata->rfe_ctl_lock, flags);
 

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260623-lan78xx-vlan-promisc-83af8a48a7ec

Best regards,
--  
Enrico Pozzobon <enrico.pozzobon@dissecto.com>

