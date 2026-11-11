From: Darren Worrall <darren.worrall@shopify.com>
Date: Wed, 11 Nov 2026 19:31:39 +0000
Subject: [PATCH iwl-net] idpf: select AUXILIARY_BUS to fix link failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-idpf-auxiliary-bus-v1-1-e76b940fc929@shopify.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMSQ6DMAxFr4K8rtUQqeNVKhYZDLhCgcaEUiHu3
 qT9u/enDYQik8C92iDSwsJjyFAfKnC9CR0h+8yglT7XWRmnFk1aeWATP2iToFPqdCV9cf7mIQ+
 nSC2vv9MH8HvAQDM0/0CSfZKby2WpWiOENprg+mKNkTsOR08LvhIlgn3/AmLEkuGiAAAA
X-Change-ID: 20261111-idpf-auxiliary-bus-c0058e27cd9d
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Madhu Chittim <madhu.chittim@intel.com>, 
 Joshua Hay <joshua.a.hay@intel.com>, 
 Tatyana Nikolova <tatyana.e.nikolova@intel.com>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Darren Worrall <darren.worrall@shopify.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2450;
 i=darren.worrall@shopify.com; h=from:subject:message-id;
 bh=RbjW4ti8gsuFIX9ZjzwA73lhgVe0TsMd8tFgxZGXUIc=;
 b=owGbwMvMwCX2T4mx4WrYUgPG02pJDFlfDi1K9b6aINvzofyiZEOjge+28g0e39h3vWQV6XC4+
 NLgt9qbjlIWBjEuBlkxRZZJ28v+mU1q+VUe1bULZg4rE8gQBi5OAZjIBwGG/zmqa/U2nFimHeLt
 Fvcmu3CP2V2N1JI3lYLL1FgsLs1e4MzI8P3FuYc1cy/sZZJTuBTKY7a/aP7m5bMtItdqLI/ab+R
 yjwcA
X-Developer-Key: i=darren.worrall@shopify.com; a=openpgp;
 fpr=92B776FE369284FA775A8ABAFE220180D556A530
X-Endpoint-Received: by B4 Relay for darren.worrall@shopify.com/default with auth_id=1491
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The build can currently fail with

    ld: vmlinux.o: in function `idpf_plug_vport_aux_dev':
    drivers/net/ethernet/intel/idpf/idpf_idc.c:82: undefined reference to `auxiliary_device_init'
    ld: drivers/net/ethernet/intel/idpf/idpf_idc.c:86: undefined reference to `__auxiliary_device_add'
    ld: vmlinux.o: in function `idpf_plug_core_aux_dev':
    drivers/net/ethernet/intel/idpf/idpf_idc.c:223: undefined reference to `auxiliary_device_init'
    ld: drivers/net/ethernet/intel/idpf/idpf_idc.c:227: undefined reference to `__auxiliary_device_add'

if IDPF is enabled but no other driver pulls in AUXILIARY_BUS. We hit
this building a minimal kernel for hosts with IDPF NICs. It can be
reproduced on x86_64 from allnoconfig by enabling PCI, PCI_MSI, NET,
NETDEVICES, ETHERNET, NET_VENDOR_INTEL and IDPF.

Select AUXILIARY_BUS in IDPF, as ICE and I40E already do. The same
link failure was fixed for BNGE in commit d7065436e8a0 ("net: bnge: add
AUXILIARY_BUS to Kconfig dependencies").

Build-tested with that configuration on net-queue (dev-queue,
34a70a40c954) and on mainline (067c5c24cef2): vmlinux fails to link
without this patch and links with it. Boot-tested on bare metal (AMD
EPYC) with a Google Cloud IDPF NIC, using a 6.18.60 kernel carrying the
same change and IDPF built in: idpf probes the NIC and its link comes
up.

Fixes: f4312e6bfa2a ("idpf: implement core RDMA auxiliary dev create, init, and destroy")
Cc: stable@vger.kernel.org # 6.17+
Signed-off-by: Darren Worrall <darren.worrall@shopify.com>
---
The link failure was diagnosed, this patch drafted and the tests above
run with the help of an AI coding assistant. I reviewed the patch and
the test results.
---
 drivers/net/ethernet/intel/idpf/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/ethernet/intel/idpf/Kconfig b/drivers/net/ethernet/intel/idpf/Kconfig
index 586df3a4af..6b59173e0d 100644
--- a/drivers/net/ethernet/intel/idpf/Kconfig
+++ b/drivers/net/ethernet/intel/idpf/Kconfig
@@ -5,6 +5,7 @@ config IDPF
 	tristate "Intel(R) Infrastructure Data Path Function Support"
 	depends on PCI_MSI
 	depends on PTP_1588_CLOCK_OPTIONAL
+	select AUXILIARY_BUS
 	select DIMLIB
 	select LIBIE_CP
 	select LIBETH_XDP

---
base-commit: 34a70a40c954fb8044ecd124840a2c38cd3aa4cc
change-id: 20261111-idpf-auxiliary-bus-c0058e27cd9d

Best regards,
--  
Darren Worrall <darren.worrall@shopify.com>

