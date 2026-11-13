From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 13 Nov 2026 08:59:21 -0800
Subject: [PATCH net-next v11 02/14] Documentation: networking: Add
 timestamp related APIs to OA TC6 framework
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-s2500-mac-phy-support-v11-2-7a186141952c@onsemi.com>
References: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
In-Reply-To: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794589162; l=4611;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=xLdBSJ9hFuyUdf3dNQON5EpLXynKnlUGzimRNIU+R1o=;
 b=+7nG5t3gQxiDacdX9/lrKvBWWH/v/7RhVFW7b71tO3z8FTPj5ERm+jsJuBuIb8XltSdg8a3Zy
 7p7A5ayWk50BCqQJPzaGnhTDp0e//GYT5V0Z3miUen33pH3Rt+qshkx
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new APIs to support hardware timestamp feature as defined in
OPEN Alliance 10BASE-T1x MAC-PHY serial interface specification.

Add the newer read/write APIs that take MMS as one of its parameters
as these were not documented so far.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v11
  - Changed the wording of timestamp support to make it more clear
changes in v10
  - Added new API oa_tc6_tx_credit_threshold_set
  - Vendor introduced APIs to vendor support patch
changes in v9
  - Added Reviewed tag
changes in v8
  - Updated the order of the parameters in oa_tc6_read_register_mms
    and oa_tc6_write_register_mms apis.
  - Removed the reference to ioctl
changes in v7
  - No change
changes in v6
  - No change
changes in v5
  - Fixed "no blank line" issues in four places
changes in v4
  - Added information for new APIs in OA TC6 framework
changes in v3
  - Added more information for documentation
changes in v2
  - Removed the changes to the existing API
  - Updated information about newly added APIs
changes in v1
  - Added changes to an existing API
  - Added documentation to new hardware timestamp related APIs
---
 Documentation/networking/oa-tc6-framework.rst | 54 +++++++++++++++++++++++++++
 1 file changed, 54 insertions(+)

diff --git a/Documentation/networking/oa-tc6-framework.rst b/Documentation/networking/oa-tc6-framework.rst
index 2545ef694016..111583609933 100644
--- a/Documentation/networking/oa-tc6-framework.rst
+++ b/Documentation/networking/oa-tc6-framework.rst
@@ -153,6 +153,11 @@ OPEN Alliance TC6 Framework
 - Forwards the received Ethernet frame from 10Base-T1x MAC-PHY to n/w
   subsystem.
 
+- If supported and enabled, timestamps are stored in the skb. Transmit
+  timestamps are requested via the TSC header field and read from
+  timestamp capture register A, B or C. Receive timestamps are
+  prepended to the frame when the RTSA footer bit is set.
+
 Data Transaction
 ~~~~~~~~~~~~~~~~
 
@@ -496,3 +501,52 @@ the MAC-PHY.
 Zero align receive frame feature can be enabled to align all receive ethernet
 frames data to start at the beginning of any receive data chunk payload with a
 start word offset (SWO) of zero.
+
+.. c:function:: int oa_tc6_ptp_register(struct oa_tc6 *tc6, \
+                                        struct ptp_clock_info *info);
+
+Registers the PTP hardware clock (PHC) with the kernel. Returns 0 immediately
+when the MAC-PHY does not support hardware timestamp. Otherwise it sets the
+name field of ptp_clock_info and registers the clock. Initialization of the
+other fields in the ptp_clock_info structure is left to the vendor as the
+PHC registers and their programming are vendor specific. The fields max_adj,
+owner, and all the functions for the clock operations, like adjfine,
+gettimex64, settime64, adjtime are expected to be initialized in the
+structure before registering the hardware clock.
+
+.. c:function:: void oa_tc6_ptp_unregister(struct oa_tc6 *tc6);
+
+Unregisters the PTP hardware clock.
+
+.. c:function:: int oa_tc6_get_ts_info(struct oa_tc6 *tc6, \
+                                       struct kernel_ethtool_ts_info *info);
+
+Provides timestamp related settings that are supported to ethtool.
+
+.. c:function:: void oa_tc6_hwtstamp_get(struct oa_tc6 *tc6, \
+                                         struct kernel_hwtstamp_config *cfg);
+
+Returns hardware timestamp configuration. Part of net_device_ops callbacks.
+
+.. c:function:: void oa_tc6_get_ts_stats(struct oa_tc6 *tc6, \
+                                         struct ethtool_ts_stats *stats);
+
+Provides hardware timestamp related traffic statistics for ethtool.
+
+.. c:function:: int oa_tc6_hwtstamp_set(struct oa_tc6 *tc6, \
+                                        struct kernel_hwtstamp_config *cfg);
+
+Helper to set hardware timestamp configuration. Part of net_device_ops
+callbacks.
+
+.. c:function:: int oa_tc6_write_register_mms(struct oa_tc6 *tc6, \
+                                              u8 mms, u16 address, \
+                                              u32 value);
+
+Write a single register addressed by @mms and @address in the MAC-PHY.
+
+.. c:function:: int oa_tc6_read_register_mms(struct oa_tc6 *tc6, \
+                                             u8 mms, u16 address, \
+                                             u32 *value);
+
+Read a single register addressed by @mms and @address in the MAC-PHY.

-- 
2.43.0

